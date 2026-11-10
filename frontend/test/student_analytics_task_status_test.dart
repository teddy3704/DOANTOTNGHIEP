import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/student/student_analytics_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

Map<String, Object?> task(String title, String status, int dueInDays) => {
  'courseid': 14,
  'course_name': 'Mobile Application Development',
  'source_id': title.hashCode,
  'title': title,
  'task_type': 'assignment',
  'due_time':
      DateTime.now().add(Duration(days: dueInDays)).millisecondsSinceEpoch ~/
      1000,
  'task_status': status,
};

ApiService api() => testApi(
  client: MockClient((req) async {
    final path = req.url.path;
    final Object body = path.endsWith('/insights')
        ? {
            'generated_at': '2026-10-14T00:00:00Z',
            'task_status': {
              'total': 4,
              'completed': 2,
              'pending': 1,
              'overdue': 1,
            },
          }
        : path.endsWith('/tasks')
        ? [
            task('Bài đã nộp A', 'completed', -5),
            task('Bài đã nộp B', 'completed', -2),
            task('Bài còn hạn', 'pending', 3),
            task('Bài quá hạn', 'overdue', -1),
          ]
        : [];
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

void main() {
  Finder inSheet(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  testWidgets('Each task status opens exactly the tasks in that status', (
    t,
  ) async {
    t.view.physicalSize = const Size(400, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(home: StudentAnalyticsScreen(apiService: api())),
    );
    await t.pumpAndSettle();

    expect(find.text('2 bài (50%)'), findsOneWidget);
    expect(
      find.text(
        'Nhấn vào một màu hoặc một dòng để xem danh sách bài tương ứng.',
      ),
      findsOneWidget,
    );

    final done = find.text('Hoàn thành');
    await t.ensureVisible(done);
    await t.pumpAndSettle();
    await t.tap(done);
    await t.pumpAndSettle();
    expect(inSheet('Hoàn thành · 2 bài'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TaskCard),
      ),
      findsNWidgets(2),
    );
    expect(inSheet('Bài quá hạn'), findsNothing);
    await t.tap(find.byTooltip('Đóng'));
    await t.pumpAndSettle();

    await t.tap(find.text('Quá hạn'));
    await t.pumpAndSettle();
    expect(inSheet('Quá hạn · 1 bài'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TaskCard),
      ),
      findsOneWidget,
    );
    expect(inSheet('Bài đã nộp A'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
