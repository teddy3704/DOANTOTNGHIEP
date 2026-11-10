import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/reminder_templates.dart';
import 'package:lms_mobile_app/core/support_csv.dart';
import 'package:lms_mobile_app/models/class_forecast.dart';
import 'package:lms_mobile_app/models/class_insights.dart';
import 'package:lms_mobile_app/screens/teacher/remind_one.dart';

import 'support/mock_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _student(
  int id,
  String name,
  String group,
  int score, {
  String? code,
  int overdue = 0,
  int? inactive,
  double? grade,
  List<String> signals = const [],
}) => {
  'userid': id,
  'fullname': name,
  'student_code': code,
  'group': group,
  'risk_score': score,
  'overdue_tasks': overdue,
  'days_since_last_activity': inactive,
  'average_grade': grade,
  'signals': [
    for (final s in signals) {'code': 'x', 'label': s},
  ],
  'tasks': [
    if (overdue > 0)
      {
        'source_id': 7,
        'title': 'Bài tập 5.1',
        'task_type': 'assignment',
        'status': 'overdue',
      },
  ],
};

void main() {
  group('reminderTemplates', () {
    test('only templates whose facts exist, with real numbers', () {
      final t = reminderTemplates(
        const ReminderFacts(
          name: 'Nguyễn An',
          courseName: 'Software Testing',
          overdueTitles: ['Bài 1', 'Bài 2', 'Bài 3', 'Bài 4'],
          inactiveDays: 30,
          averageGrade: 42.25,
        ),
      );
      expect(t.map((x) => x.kind), [
        TemplateKind.overdue,
        TemplateKind.inactive,
        TemplateKind.lowGrade,
        TemplateKind.general,
      ]);
      expect(t[0].title, 'Em có 4 bài quá hạn');
      expect(t[0].message, contains('"Bài 1", "Bài 2", "Bài 3" và 1 bài khác'));
      expect(t[0].message, contains('khóa "Software Testing"'));
      expect(t[1].title, 'Đã 30 ngày em chưa vào khóa học');
      expect(t[2].title, 'Điểm trung bình hiện là 42,3%');
      expect(t[2].message, contains('dưới mức qua môn 50%'));
    });

    test('a student doing fine gets only the general template', () {
      final t = reminderTemplates(
        const ReminderFacts(name: 'Bình', inactiveDays: 3, averageGrade: 80),
      );
      expect(t.single.kind, TemplateKind.general);
      expect(t.single.message, startsWith('Chào Bình'));
    });
  });

  group('CSV', () {
    test('escaping, Vietnamese, BOM, formula guard', () {
      expect(csvField('a,b'), '"a,b"');
      expect(csvField('nói "chào"'), '"nói ""chào"""');
      expect(csvField('dòng 1\ndòng 2'), '"dòng 1\ndòng 2"');
      expect(csvField('=SUM(A1)'), "'=SUM(A1)");
      expect(csvField(null), '');
      final bytes = supportCsvBytes([
        const SupportRow(
          studentCode: '2312005',
          name: 'Nguyễn Văn Ánh',
          riskScore: 70,
          reasons: ['77 ngày không truy cập', '2 bài quá hạn'],
          forecast: 'Nguy cơ cao',
          latestNote: 'Đã gọi, hẹn "tuần sau"',
        ),
      ]);
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(bytes.skip(3).toList());
      expect(
        text,
        'MSSV,Họ tên,Điểm theo dõi,Lý do,Dự báo qua môn,Ghi chú gần nhất\r\n'
        '2312005,Nguyễn Văn Ánh,70,77 ngày không truy cập; 2 bài quá hạn,Nguy cơ cao,'
        '"Đã gọi, hẹn ""tuần sau"""\r\n',
      );
    });

    test(
      'rows: flagged students only, highest score first, forecast + newest note',
      () {
        final students = [
          InsightStudent.fromJson(_student(1, 'An', 'watch', 40, code: 'A1')),
          InsightStudent.fromJson(_student(2, 'Bình', 'on_track', 5)),
          InsightStudent.fromJson(
            _student(3, 'Chi', 'needs_support', 80, signals: ['Quá hạn 2 bài']),
          ),
        ];
        final forecast = ClassForecast.fromJson({
          'passPercent': 50,
          'counts': {},
          'students': [
            {'userid': 3, 'fullname': 'Chi', 'band': 'HIGH_RISK'},
          ],
        });
        final rows = supportRows(
          students,
          forecast: forecast,
          notes: [
            {
              'student_id': 3,
              'note': 'cũ',
              'created_at': '2026-11-01T10:00:00Z',
            },
            {
              'student_id': 3,
              'note': 'mới',
              'created_at': '2026-11-09T10:00:00Z',
            },
          ],
        );
        expect(rows.map((r) => r.name), ['Chi', 'An']);
        expect(rows.first.forecast, 'Nguy cơ cao');
        expect(rows.first.latestNote, 'mới');
        expect(rows.first.reasons, ['Quá hạn 2 bài']);
        expect(rows.last.forecast, isNull);
      },
    );

    test('export: forecast/notes failing still shares the list', () async {
      final api = testApi(
        client: MockClient((r) async => http.Response('', 500)),
      );
      List<int>? shared;
      String? file;
      final n = await exportSupportList(
        api: api,
        courseId: 14,
        students: [
          InsightStudent.fromJson(_student(3, 'Chi', 'needs_support', 80)),
        ],
        share: (bytes, name) async {
          shared = bytes;
          file = name;
        },
        now: DateTime(2026, 11, 20),
      );
      expect(n, 1);
      expect(file, 'can-ho-tro-khoa-14-20261120.csv');
      expect(utf8.decode(shared!.skip(3).toList()), contains('Chi,80,,,'));
    });
  });

  testWidgets(
    'remind one: single recipient, templates fill the text, sends one id',
    (tester) async {
      final posts = <Map<String, dynamic>>[];
      final api = testApi(
        client: MockClient((r) async {
          posts.add(jsonDecode(r.body) as Map<String, dynamic>);
          expect(r.url.path, '/api/v1/dev/teachers/102/courses/14/reminders');
          return _json({'sent': 1});
        }),
      );
      final student = InsightStudent.fromJson(
        _student(3, 'Chi', 'needs_support', 80, overdue: 1, inactive: 30),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => remindOne(
                  context,
                  api: api,
                  courseId: 14,
                  userId: 3,
                  facts: factsFromInsight(student, courseName: 'Mobile'),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc riêng Chi'), findsOneWidget);
      expect(find.text('Em có 1 bài quá hạn'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('reminder-template-overdue')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('reminder-template-inactive')));
      await tester.pump();
      expect(find.text('Đã 30 ngày em chưa vào khóa học'), findsOneWidget);
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();
      expect(posts.single['student_ids'], [3]);
      expect(posts.single['title'], 'Đã 30 ngày em chưa vào khóa học');
      expect(posts.single['message'], contains('khóa "Mobile"'));
      expect(find.text('Đã gửi nhắc nhở tới 1 sinh viên.'), findsOneWidget);
    },
  );
}
