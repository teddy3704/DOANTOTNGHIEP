import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/learning_health.dart';
import 'package:lms_mobile_app/screens/student/learning_health_screen.dart';

import 'support/mock_api.dart';

final overview = <String, dynamic>{
  'level': 'RED',
  'counts': {'RED': 1, 'YELLOW': 0, 'GREEN': 1},
  'courses': [
    {
      'courseId': 14,
      'courseName': 'Mobile',
      'score': 80,
      'level': 'RED',
      'reasons': [
        {
          'points': 40,
          'label': '20 ngày không truy cập (≥14 ngày)',
          'code': 'INACTIVE',
        },
        {'points': 30, 'label': '4 bài quá hạn (≥3 bài)', 'code': 'OVERDUE'},
        {
          'points': 10,
          'label': 'Không có hoạt động nào trong 7 ngày qua',
          'code': 'NO_RECENT_EVENTS',
        },
      ],
      'actions': [
        {
          'code': 'VISIT_COURSE',
          'title': 'Vào học tiếp: Quiz 3.1',
          'target': 'OPEN_LMS',
          'scoreDrop': 50,
          'courseId': 14,
          'moodlePath': '/mod/quiz/view.php?id=24102',
          'courseModuleId': 24102,
        },
        {
          'code': 'CLEAR_OVERDUE',
          'title': 'Hoàn thành 4 bài quá hạn',
          'target': 'TASKS',
          'scoreDrop': 30,
          'courseId': 14,
        },
      ],
    },
    {
      'courseId': 13,
      'courseName': 'Testing',
      'score': 0,
      'level': 'GREEN',
      'reasons': [],
      'actions': [],
    },
  ],
};

void main() {
  test('Overview parses levels, counts and summary', () {
    final o = LearningHealthOverview.fromJson(overview);
    expect(o.level, HealthLevel.red);
    expect(o.summary, '1 khóa Đỏ · 1 khóa Xanh');
    expect(o.courses.first.actions.first.target, HealthTarget.openLms);
    expect(o.courses.first.reasons.map((r) => r.points), [40, 30, 10]);
  });

  testWidgets('Home tile opens the detail with reasons and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = testApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(overview),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LearningHealthHomeTile(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tình trạng học tập: Đỏ'), findsOneWidget);
    expect(find.text('1 khóa Đỏ · 1 khóa Xanh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('learning-health-tile')));
    await tester.pumpAndSettle();
    expect(find.text('Đỏ · Cần hỗ trợ'), findsOneWidget);
    expect(find.text('Điểm theo dõi 80/100'), findsOneWidget);
    expect(find.text('+40'), findsOneWidget);
    expect(find.text('Làm gì để lên Xanh'), findsOneWidget);
    expect(find.text('Hoàn thành 4 bài quá hạn (−30 điểm)'), findsOneWidget);
    expect(find.text('Vào học tiếp: Quiz 3.1 (−50 điểm)'), findsOneWidget);
    expect(
      find.text('Không có dấu hiệu cần chú ý trong khóa này.'),
      findsOneWidget,
    );
  });

  testWidgets('Tile stays hidden when the request fails', (tester) async {
    final api = testApi(
      client: MockClient((request) async => http.Response('error', 500)),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LearningHealthHomeTile(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('learning-health-tile')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
