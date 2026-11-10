import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/models/student_course.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/notifications_screen.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/student/student_task_center_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_home_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_analytics_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

void viewport(WidgetTester tester, double width, {double height = 900}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget app(Widget home, [double scale = 1]) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);
ApiService api(Object? Function(Uri) response) {
  final service = testApi(
    client: MockClient(
      (r) async => http.Response(
        jsonEncode(response(r.url)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
  addTearDown(service.dispose);
  return service;
}

final course = <String, dynamic>{
  'courseid': 14,
  'course_name': 'Mobile Application Development',
  'course_shortname': 'MOBILE101',
  'student_count': 4,
  'average_progress': 35,
  'students_need_attention': 4,
  'high_risk_students': 2,
  'needs_grading_count': 0,
  'upcoming_deadlines_7_days': 2,
};
final student = <String, dynamic>{
  'userid': 205,
  'fullname': 'Nguyễn Văn Sinh Viên',
  'idnumber': null,
  'email': 'student07@example.edu.vn',
  'progress': 28.6,
  'pending_tasks': 4,
  'overdue_tasks': 3,
  'days_since_last_activity': 25,
  'risk_level': 'HIGH',
};
final activity = <String, dynamic>{
  'source_id': 14102,
  'task_type': 'assignment',
  'title': 'Android API Assignment',
  'student_count': 4,
  'done_count': 3,
  'not_done_count': 1,
  'coursemoduleid': 24102,
  'moodle_path': '/mod/assign/view.php?id=24102',
};
final task = <String, dynamic>{
  'courseid': 14,
  'course_name': 'Mobile Application Development',
  'title': 'Android API Assignment',
  'task_type': 'assignment',
  'task_status': 'overdue',
  'due_time': 1789487940,
  'coursemoduleid': 24102,
  'moodle_path': '/mod/assign/view.php?id=24102',
};

void expectInside(WidgetTester tester, Finder child, Rect viewport) {
  final rect = tester.getRect(child);
  expect(rect.left, greaterThanOrEqualTo(viewport.left - .1));
  expect(rect.right, lessThanOrEqualTo(viewport.right + .1));
  expect(rect.top, greaterThanOrEqualTo(viewport.top - .1));
  expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + .1));
}

void main() {
  for (final width in [360.0, 384.0, 412.0]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      for (final teacher in [false, true]) {
        testWidgets(
          '${teacher ? 'Teacher' : 'Student'} first/last tab fully visible $width/$scale',
          (tester) async {
            viewport(tester, width);
            final labels = teacher
                ? [
                    'Tổng quan',
                    'Sinh viên',
                    'Bài tập',
                    'Bài kiểm tra',
                    'Phân tích',
                  ]
                : [
                    'Tổng quan',
                    'Nội dung',
                    'Việc cần làm',
                    'Điểm',
                    'Chuyên cần',
                  ];
            late TabController controller;
            await tester.pumpWidget(
              app(
                DefaultTabController(
                  length: 5,
                  child: Builder(
                    builder: (context) {
                      controller = DefaultTabController.of(context);
                      return Scaffold(
                        appBar: AppBar(
                          bottom: CourseTabBar(
                            labels: labels,
                            textScale: scale,
                          ),
                        ),
                        body: TabBarView(
                          children: List.generate(5, (_) => const SizedBox()),
                        ),
                      );
                    },
                  ),
                ),
                scale,
              ),
            );
            await tester.pumpAndSettle();
            final bar = tester.getRect(find.byType(TabBar));
            expectInside(tester, find.text(labels.first), bar);
            controller.animateTo(4);
            await tester.pumpAndSettle();
            expect(controller.index, 4);
            expectInside(tester, find.text(labels.last), bar);
            await tester.tap(find.text(labels.last));
            await tester.pumpAndSettle();
            expect(controller.index, 4);
            controller.animateTo(0);
            await tester.pumpAndSettle();
            expectInside(tester, find.text(labels.first), bar);
            expect(tester.takeException(), isNull);
          },
        );
      }
      testWidgets(
        'Task filter end chips visible and selectable $width/$scale',
        (tester) async {
          viewport(tester, width);
          await tester.pumpWidget(
            app(StudentTaskCenterScreen(api: api((_) => [])), scale),
          );
          await tester.pumpAndSettle();
          final area = tester.getRect(find.byType(LearningFilterBar));
          for (final label in [
            'Tất cả',
            'Chưa làm',
            'Sắp hạn',
            'Quá hạn',
            'Đã xong',
          ]) {
            expectInside(tester, find.widgetWithText(ChoiceChip, label), area);
          }
          expect(
            find.descendant(
              of: find.byType(LearningFilterBar),
              matching: find.byType(SingleChildScrollView),
            ),
            findsNothing,
          );
          final last = find.widgetWithText(ChoiceChip, 'Đã xong');
          await tester.tap(last);
          await tester.pumpAndSettle();
          expect(tester.widget<ChoiceChip>(last).selected, isTrue);
          final all = find.widgetWithText(ChoiceChip, 'Tất cả');
          await tester.tap(all);
          await tester.pumpAndSettle();
          expect(tester.widget<ChoiceChip>(all).selected, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets('Student and Teacher compact cards fit $width/$scale', (
        tester,
      ) async {
        viewport(tester, width, height: 1800);
        var tapped = false;
        await tester.pumpWidget(
          app(
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TaskCard(StudentTask.fromJson(task)),
                  ActivityCard(
                    StudentLearningItem.fromJson({
                      'activity_name': 'Tài liệu Android',
                      'activity_type': 'resource',
                      'course_name': 'Mobile Application Development',
                      'section_name': 'Bài giảng',
                      'coursemoduleid': 24301,
                      'moodle_path': '/mod/resource/view.php?id=24301',
                    }),
                    action: 'Tiếp tục',
                  ),
                  CourseProgressCard(
                    course: StudentCourse.fromJson({
                      ...course,
                      'completed_activities': 7,
                      'total_tracked_activities': 20,
                      'pending_tasks': 2,
                      'overdue_tasks': 1,
                    }),
                    onTap: () {},
                  ),
                  StudentMonitoringCard(
                    student: MonitoredStudent.fromJson(student),
                    onOpen: () => tapped = true,
                  ),
                ],
              ),
            ),
            scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('3 việc chưa hoàn thành'), findsOneWidget);
        await tester.ensureVisible(find.byType(StudentMonitoringCard));
        await tester.tap(find.byType(StudentMonitoringCard));
        expect(tapped, isTrue);
        expect(find.text('Xem chi tiết'), findsNothing);
        if (scale == 1) {
          expect(tester.getSize(find.byType(TaskCard)).height, lessThan(210));
          expect(
            tester.getSize(find.byType(ActivityCard)).height,
            lessThan(150),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final needs in <int?>[0, 1, null]) {
    testWidgets('Grading hint reflects needs_grading=$needs', (tester) async {
      viewport(tester, 360);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: TeacherActivitiesTab(
              api: api(
                (_) => [
                  {...activity, 'needs_grading_count': needs},
                ],
              ),
              courseId: 14,
              type: 'assignment',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Cần chấm: đã nộp và chưa có điểm hoạt động.'),
        needs == 1 ? findsOneWidget : findsNothing,
      );
      if (needs != null) {
        final metric = find
            .ancestor(of: find.text('Cần chấm'), matching: find.byType(Column))
            .first;
        expect(
          find.descendant(of: metric, matching: find.text('$needs')),
          findsOneWidget,
        );
      }
      expect(find.text('Đã xử lý chấm điểm'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final value in <double?>[null, 0.0]) {
    testWidgets('Analytics preserves null versus zero $value', (tester) async {
      viewport(tester, 384, height: 1800);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: TeacherAnalyticsTab(
              api: api(
                (_) => {
                  'generated_at': '2026-10-10T00:00:00Z',
                  'summary': {
                    'student_count': 10,
                    'watch_count': 2,
                    'average_progress': value,
                    'average_grade_percentage': value,
                  },
                },
              ),
              courseId: 14,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0.0%'), value == 0.0 ? findsNWidgets(2) : findsNothing);
      if (value == null) {
        expect(find.text('--'), findsNWidgets(2));
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Teacher Home explicitly counts enrolment occurrences', (
    tester,
  ) async {
    viewport(tester, 384);
    await tester.pumpWidget(
      app(
        TeacherHomeScreen(
          apiService: api(
            (_) => [
              {...course, 'students_need_attention': 9},
              {...course, 'courseid': 15, 'students_need_attention': 8},
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('17 trường hợp cần theo dõi'), findsOneWidget);
    expect(find.text('Được tổng hợp từ các khóa học'), findsOneWidget);
    expect(find.text('17 sinh viên cần theo dõi'), findsNothing);
    expect(find.text('Không có bài nào đang chờ chấm'), findsOneWidget);
  });
  testWidgets('Teacher Home course student and assignment back stack', (
    tester,
  ) async {
    viewport(tester, 412, height: 1800);
    final service = api(
      (uri) => switch (uri.pathSegments.last) {
        'courses' => [course],
        'students' => uri.path.contains('/assignments/') ? [] : [student],
        '205' => {...student, 'tasks': []},
        'assignments' => [activity],
        _ => [],
      },
    );
    await tester.pumpWidget(app(TeacherHomeScreen(apiService: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(course['course_name'] as String));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem sinh viên cần theo dõi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StudentMonitoringCard));
    await tester.pumpAndSettle();
    expect(find.byType(StudentMonitoringDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
    final context = tester.element(find.byType(TeacherStudentsTab));
    DefaultTabController.of(context).animateTo(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem sinh viên'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityStudentsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('HIGH empty state and Teacher end filter accessible', (
    tester,
  ) async {
    viewport(tester, 360);
    await tester.pumpWidget(
      app(
        Scaffold(body: TeacherStudentsTab(api: api((_) => []), courseId: 14)),
        1.5,
      ),
    );
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(ChoiceChip, 'Nguy cơ cao');
    expectInside(tester, chip, tester.getRect(find.byType(LearningFilterBar)));
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Không có sinh viên nguy cơ cao'), findsOneWidget);
  });
  testWidgets(
    'Notification without Moodle link opens Task Center and returns',
    (tester) async {
      viewport(tester, 360);
      final service = api(
        (uri) => uri.pathSegments.last == 'notifications'
            ? [
                {
                  'title': 'Nhắc bài tập',
                  'course_id': 14,
                  'message': 'Kiểm tra hạn nộp',
                },
              ]
            : [],
      );
      await tester.pumpWidget(app(NotificationsScreen(api: service)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiểm tra việc cần làm'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentTaskCenterScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    },
  );
  testWidgets('Home priorities leave Continue Learning visible at 384x844', (
    tester,
  ) async {
    viewport(tester, 384, height: 844);
    await tester.pumpWidget(
      app(
        StudentMainScreen(
          apiService: api(
            (uri) => switch (uri.pathSegments.last) {
              'dashboard' => {'fullname': 'Nguyễn Văn A'},
              'tasks' => [task, task, task],
              'continue-learning' => [
                {
                  'activity_name': 'Tài liệu Android',
                  'activity_type': 'resource',
                  'section_name': 'Bài giảng',
                },
              ],
              _ => [],
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaskCard), findsNWidgets(2));
    expect(
      tester.getRect(find.widgetWithText(SectionHeader, 'Tiếp tục học')).bottom,
      lessThan(tester.getRect(find.byType(NavigationBar)).top),
    );
    expect(tester.takeException(), isNull);
  });
  test('Course optional counters preserve missing data', () {
    expect(
      StudentCourse.fromJson({
        ...course,
        'pending_tasks': null,
        'overdue_tasks': 0,
      }).unfinishedTasks,
      isNull,
    );
    expect(
      StudentCourse.fromJson({
        ...course,
        'pending_tasks': 0,
        'overdue_tasks': 0,
      }).unfinishedTasks,
      0,
    );
  });
}
