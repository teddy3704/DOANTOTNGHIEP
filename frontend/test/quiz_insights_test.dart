import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/class_insights.dart';
import 'package:lms_mobile_app/models/quiz_insights.dart';
import 'package:lms_mobile_app/screens/teacher/quiz_insights_section.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_analytics_widgets.dart';

import 'support/mock_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _quiz(
  int id,
  String name, {
  List<String> flags = const [],
  List<int> pending = const [],
  int finished = 3,
}) => {
  'quizId': id,
  'name': name,
  'timeClose': null,
  'timeLimitSeconds': 1800,
  'moodlePath': '/mod/quiz/view.php?id=${id * 10}',
  'courseModuleId': id * 10,
  'rosterSize': 5,
  'finished': finished,
  'attempted': 5 - pending.length,
  'notAttempted': pending.length,
  'notAttemptedPercent': pending.length * 20.0,
  'histogram': [2, 1, 0, 0, 0],
  'meanPercent': 22.5,
  'medianSeconds': 750,
  'flags': flags,
  'notAttemptedUserIds': pending,
};

void main() {
  test('model parsing, unknown flags dropped, duration text', () {
    final q = QuizInsight.fromJson(
      _quiz(7, 'Quiz 5.1', flags: ['TOO_HARD', 'SOMETHING_NEW'], pending: [4]),
    );
    expect(q.flags, [QuizFlag.tooHard]);
    expect(q.histogram, [2, 1, 0, 0, 0]);
    expect(q.courseModuleId, 70);
    expect(q.notAttemptedUserIds, [4]);
    expect(durationText(750), '12 phút 30 giây');
    expect(durationText(45), '45 giây');
    expect(durationText(1800), '30 phút');
  });

  testWidgets(
    'flagged quiz first, chips, stats, remind only roster students who skipped',
    (tester) async {
      final api = testApi(
        client: MockClient((r) async {
          expect(
            r.url.path,
            '/api/v1/dev/teachers/102/courses/14/quiz-insights',
          );
          return _json({
            'courseId': 14,
            'quizzes': [
              _quiz(1, 'Quiz ổn'),
              _quiz(
                2,
                'Quiz khó',
                flags: ['TOO_HARD', 'MANY_SKIPPED'],
                pending: [4, 5, 999],
              ),
            ],
          });
        }),
      );
      final students = [
        for (final (id, name) in [(4, 'Dung'), (5, 'Em'), (6, 'Giang')])
          InsightStudent.fromJson({'userid': id, 'fullname': name}),
      ];
      List<InsightStudent>? reminded;
      ReminderDraft? draft;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderScope(
              remind: (s, d) async {
                reminded = s;
                draft = d;
                return true;
              },
              child: SingleChildScrollView(
                child: QuizInsightsSection(
                  api: api,
                  courseId: 14,
                  students: students,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hard = tester.getTopLeft(find.byKey(const Key('quiz-insight-2')));
      final ok = tester.getTopLeft(find.byKey(const Key('quiz-insight-1')));
      expect(hard.dy, lessThan(ok.dy));
      expect(find.text('Quá khó'), findsOneWidget);
      expect(find.text('Nhiều sinh viên bỏ'), findsOneWidget);
      expect(find.text('Điểm TB 22,5%'), findsNWidgets(2));
      expect(
        find.textContaining('Thời gian trung vị 12 phút 30 giây / 30 phút'),
        findsNWidgets(2),
      );
      await tester.tap(find.text('Nhắc 2 SV chưa làm'));
      await tester.pump();
      expect(reminded!.map((s) => s.name), ['Dung', 'Em']);
      expect(draft!.sourceType, 'quiz');
      expect(draft!.sourceId, 2);
      expect(draft!.title, contains('Quiz khó'));
    },
  );

  testWidgets('empty and error states', (tester) async {
    var fail = true;
    final api = testApi(
      client: MockClient(
        (r) async => fail
            ? http.Response('', 500)
            : _json({'courseId': 14, 'quizzes': []}),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizInsightsSection(api: api, courseId: 14, students: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được phân tích bài kiểm tra'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Khóa học chưa có bài kiểm tra'), findsOneWidget);
  });
}
