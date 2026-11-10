import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/notifications_screen.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';

final _items = [
  {
    'id': 7,
    'source_kind': 'notification',
    'notification_type': 'system',
    'title': 'Điểm mới được cập nhật',
    'message': 'Bài tập 1 đã có điểm',
    'event_time': '2026-10-12T08:00:00Z',
    'is_read': false,
  },
  {
    'id': 9,
    'source_kind': 'notification',
    'notification_type': 'teacher_reminder',
    'sender_name': 'Tran Thanh Hoa',
    'title': 'Nhắc nộp bài: Quiz 5.2',
    'message': 'Em chưa nộp bài kiểm tra "Quiz 5.2".',
    'course_id': 14,
    'course_name': 'Mobile Application Development',
    'coursemoduleid': 3000020,
    'moodle_path': '/mod/quiz/view.php?id=3000020',
    'event_time': '2026-10-11T08:00:00Z',
    'is_read': false,
  },
  {
    'id': 8,
    'source_kind': 'notification',
    'notification_type': 'teacher_reminder',
    'sender_name': 'Tran Thanh Hoa',
    'title': 'Nhắc nhở học tập',
    'message': 'Em hãy vào khóa học để cập nhật bài.',
    'event_time': '2026-10-01T08:00:00Z',
    'is_read': true,
  },
];

void main() {
  testWidgets(
    'Teacher reminders are grouped first, name the sender and can be marked seen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final marked = <String>[];
      final client = MockClient((req) async {
        if (req.method == 'POST') {
          marked.add(req.url.path);
          return http.Response(
            jsonEncode({'updated': 1}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(_items),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(api: testApi(client: client)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhắc nhở từ giảng viên'), findsOneWidget);
      expect(find.text('1 mới'), findsOneWidget);
      expect(find.text('Giảng viên Tran Thanh Hoa'), findsNWidgets(2));
      expect(find.text('Mở bài trên LMS'), findsOneWidget);
      expect(find.text('Thông báo khác'), findsOneWidget);
      // Teacher reminders come before other notifications, the unread one first.
      final reminderY = tester
          .getTopLeft(find.text('Nhắc nộp bài: Quiz 5.2'))
          .dy;
      expect(
        reminderY,
        lessThan(tester.getTopLeft(find.text('Nhắc nhở học tập')).dy),
      );
      expect(
        reminderY,
        lessThan(tester.getTopLeft(find.text('Điểm mới được cập nhật')).dy),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Đã xem'));
      await tester.pumpAndSettle();
      expect(marked, [
        '${Uri.parse(mockApiBaseUrl).path}/dev/students/$mockStudentId/notifications/9/read',
      ]);
      expect(find.text('Mới'), findsNothing);
      expect(find.text('1 mới'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Marking seen rolls back when the server fails', (tester) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient(
      (req) async => req.method == 'POST'
          ? http.Response('{}', 500)
          : http.Response(
              jsonEncode(_items),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(api: testApi(client: client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Đã xem'));
    await tester.pumpAndSettle();
    expect(find.text('Mới'), findsOneWidget);
    expect(
      find.text('Không cập nhật được trạng thái. Vui lòng thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Student Home shows a badge and banner until the reminder is seen',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final served = [for (final i in _items) Map<String, Object?>.from(i)];
      final client = MockClient((req) async {
        final path = req.url.path;
        if (req.method == 'POST' && path.endsWith('/notifications/9/read')) {
          served.firstWhere((i) => i['id'] == 9)['is_read'] = true;
          return http.Response(
            jsonEncode({'updated': 1}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/notifications')) {
          return http.Response(
            jsonEncode(served),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: StudentMainScreen(apiService: testApi(client: client)),
        ),
      );
      await tester.pumpAndSettle();

      Badge badge() => tester.widget<Badge>(find.byType(Badge));
      expect(badge().isLabelVisible, isTrue);
      expect(
        find.text('Giảng viên Tran Thanh Hoa vừa nhắc bạn'),
        findsOneWidget,
      );

      await tester.tap(find.byType(TeacherReminderBanner));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc nhở từ giảng viên'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Đã xem'));
      await tester.pumpAndSettle();
      expect(badge().isLabelVisible, isFalse);

      await tester.tap(find.byType(NavigationDestination).first);
      await tester.pumpAndSettle();
      expect(find.byType(TeacherReminderBanner), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Teacher "students need support" alert opens the course analytics tab',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final alert = [
        {
          'id': 3,
          'source_kind': 'notification',
          'notification_type': 'risk_alert',
          'title': 'Sinh viên cần được hỗ trợ',
          'message': 'Có 1 sinh viên đang ở nhóm Cần hỗ trợ.',
          'course_id': 14,
          'course_name': 'Mobile Application Development',
          'source_type': 'course',
          'event_time': '2026-10-11T08:00:00Z',
          'is_read': false,
        },
      ];
      final client = MockClient(
        (req) async => req.url.path.endsWith('/notifications')
            ? http.Response(
                jsonEncode(alert),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )
            : http.Response(
                '{}',
                200,
                headers: {'content-type': 'application/json'},
              ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            api: testApi(client: client),
            teacher: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mở trang Phân tích'), findsOneWidget);
      await tester.tap(find.text('Sinh viên cần được hỗ trợ'));
      await tester.pumpAndSettle();
      expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
      expect(
        DefaultTabController.of(tester.element(find.byType(TabBar))).index,
        TeacherCourseDetailScreen.analyticsTab,
      );
    },
  );

  Future<int> openedTab(
    WidgetTester tester,
    List<Map<String, Object?>> items,
    String tap, {
    List<String>? posts,
  }) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient((req) async {
      if (req.method == 'POST') {
        posts?.add(req.url.path);
        return http.Response(
          '{"updated":1}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return req.url.path.endsWith('/notifications')
          ? http.Response(
              jsonEncode(items),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )
          : http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
            );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(api: testApi(client: client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tap));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCourseDetailScreen), findsOneWidget);
    return DefaultTabController.of(tester.element(find.byType(TabBar))).index;
  }

  Map<String, Object?> studentItem(String type, String title) => {
    'id': 21,
    'source_kind': 'notification',
    'notification_type': type,
    'title': title,
    'message': 'Nội dung',
    'course_id': 14,
    'course_name': 'Mobile Application Development',
    'event_time': '2026-10-11T08:00:00Z',
    'is_read': false,
  };

  testWidgets('Student "new grade" notification opens the course grades tab', (
    tester,
  ) async {
    expect(
      await openedTab(tester, [
        studentItem('grade_updated', 'Có điểm mới'),
      ], 'Xem điểm'),
      3,
    );
  });

  testWidgets(
    'Student deadline notification opens the course tasks tab by tapping the card',
    (tester) async {
      expect(
        await openedTab(tester, [
          studentItem('quiz_due', 'Bài kiểm tra sắp hết hạn'),
        ], 'Bài kiểm tra sắp hết hạn'),
        2,
      );
    },
  );

  testWidgets(
    'Student "continue learning" notification opens the course content tab',
    (tester) async {
      expect(
        await openedTab(tester, [
          studentItem('learning_reminder', 'Tiếp tục học'),
        ], 'Vào học tiếp'),
        1,
      );
    },
  );

  testWidgets(
    'Opening a teacher reminder goes to the course tasks and marks it seen',
    (tester) async {
      final posts = <String>[];
      final tab = await openedTab(
        tester,
        [studentItem('teacher_reminder', 'Nhắc nộp bài: Quiz 5.2')],
        'Nhắc nộp bài: Quiz 5.2',
        posts: posts,
      );
      expect(tab, 2);
      expect(posts.single, endsWith('/notifications/21/read'));
    },
  );

  testWidgets('Teacher view does not split out reminders', (tester) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode(_items),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(api: testApi(client: client), teacher: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhắc nhở từ giảng viên'), findsNothing);
  });
}
