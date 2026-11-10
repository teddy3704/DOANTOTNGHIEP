import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/models/student_course.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/models/student_dashboard.dart';
import 'package:lms_mobile_app/models/teacher_analytics.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/student/student_dashboard_screen.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/student/student_task_center_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

void main() {
  final requests = <String>[];
  final failing = <String>{};
  var suggestionHasLink = true;
  final student = <String, dynamic>{
    'userid': 205,
    'fullname': 'An Demo',
    'student_code': null,
    'idnumber': null,
    'email': 'an.demo@example.invalid',
    'progress': 35,
    'pending_tasks': 3,
    'overdue_tasks': 1,
    'attendance': null,
    'days_since_last_activity': 12,
    'risk_level': 'HIGH',
    'needs_attention': true,
  };
  final activity = <String, dynamic>{
    'source_id': 14102,
    'task_type': 'assignment',
    'title': 'Bài tập API',
    'student_count': 2,
    'done_count': 1,
    'not_done_count': 1,
    'needs_grading_count': 1,
    'coursemoduleid': 24102,
    'moodle_path': '/mod/assign/view.php?id=24102',
  };
  ApiService api() {
    final service = testApi(
      client: MockClient((request) async {
        final end = request.url.pathSegments.last;
        requests.add(request.url.path);
        if (failing.contains(end)) {
          throw http.ClientException('SocketException errno=99');
        }
        final Object? data = switch (end) {
          'dashboard' => {
            'firstname': ' Mai ',
            'lastname': 'Anh',
            'course_count': 1,
            'average_progress': 35,
          },
          'courses' => [
            {
              'courseid': 14,
              'course_name': 'Mobile',
              'completed_activities': 7,
              'total_tracked_activities': 20,
            },
          ],
          'tasks' => [
            {
              'courseid': 14,
              'course_name': 'Mobile',
              'source_id': 14102,
              'title': 'Bài quá hạn từ API',
              'task_type': 'assignment',
              'task_status': 'overdue',
              'due_time': null,
              'coursemoduleid': 24102,
              'moodle_path': '/mod/assign/view.php?id=24102',
            },
          ],
          'continue-learning' => [
            {
              'courseid': 14,
              'course_name': 'Mobile',
              'section_name': 'Course Activities',
              'activity_name': 'Tài liệu học tiếp',
              'activity_type': 'resource',
              'coursemoduleid': 24301,
              'moodle_path': suggestionHasLink
                  ? '/mod/resource/view.php?id=24301'
                  : null,
            },
          ],
          'assignments' => [activity],
          'students' =>
            request.url.path.contains('/assignments/')
                ? [
                    {
                      ...student,
                      'done': true,
                      'source_status': 'submitted',
                      'finalgrade': 0,
                    },
                    {
                      ...student,
                      'userid': 206,
                      'fullname': 'Binh Demo',
                      'done': false,
                      'source_status': 'draft',
                      'finalgrade': null,
                    },
                  ]
                : request.url.path.contains('/quizzes/')
                ? [
                    {
                      ...student,
                      'fullname': 'SV Hoàn tất',
                      'done': true,
                      'quiz_state': 'finished',
                    },
                    {
                      ...student,
                      'fullname': 'SV Đang làm',
                      'done': false,
                      'quiz_state': 'inprogress',
                    },
                    {
                      ...student,
                      'fullname': 'SV Chưa bắt đầu',
                      'done': false,
                      'quiz_state': null,
                      'source_status': null,
                    },
                    {
                      ...student,
                      'fullname': 'SV Bỏ dở',
                      'done': false,
                      'quiz_state': 'abandoned',
                    },
                  ]
                : [student],
          '205' => {...student, 'average_grade': 0, 'tasks': []},
          'attendance' => null,
          _ => [],
        };
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.dispose);
    return service;
  }

  void viewport(
    WidgetTester tester, {
    double width = 800,
    double height = 2200,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() {
    requests.clear();
    failing.clear();
    suggestionHasLink = true;
  });

  test(
    'Overdue API flag wins over missing/future deadline; submitted still wins',
    () {
      final now = DateTime(2026, 9, 16);
      for (final due in [
        null,
        now.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
      ]) {
        final overdue = StudentTask.fromJson({
          'task_status': 'overdue',
          'due_time': due,
        });
        expect(overdue.isPending, true);
        expect(overdue.isOverdue(now), true);
        expect(overdue.isDueSoon(now), false);
        expect(overdue.statusLabel, 'Chưa hoàn thành');
        expect(filterTasks([overdue], TaskFilter.overdue, now), [overdue]);
        final submitted = StudentTask.fromJson({
          'task_type': 'assignment',
          'task_status': 'overdue',
          'source_status': 'submitted',
          'due_time': due,
        });
        expect(submitted.isOverdue(now), false);
      }
    },
  );
  test(
    'Names, activity counters and Teacher Analytics use the API contract',
    () {
      expect(
        StudentDashboard.fromJson({
          'fullname': 'Tên đầy đủ',
          'firstname': 'Khác',
        }).fullName,
        'Tên đầy đủ',
      );
      expect(
        StudentDashboard.fromJson({
          'name': ' ',
          'firstname': ' An ',
          'lastname': null,
        }).fullName,
        'An',
      );
      expect(
        StudentDashboard.fromJson({
          'firstname': null,
          'lastname': null,
        }).fullName,
        isNull,
      );
      final course = StudentCourse.fromJson({
        'courseid': 14,
        'completed_activities': null,
        'total_tracked_activities': null,
        'completed_tasks': 2,
        'total_tasks': 4,
      });
      expect(course.completedTasks, isNull);
      expect(course.totalTasks, isNull);
      final analytics = TeacherAnalytics.fromJson({
        'total_pending_tasks': 0,
        'pending_tasks': 9,
        'total_overdue_tasks': 4,
      });
      expect(analytics.pendingTasks, 0);
      expect(analytics.overdueTasks, 4);
      expect(
        TeacherAnalytics.fromJson({
          'pending_tasks': 3,
          'overdue_tasks': 2,
        }).pendingTasks,
        3,
      );
    },
  );
  for (final endpoint in [
    'dashboard',
    'tasks',
    'courses',
    'continue-learning',
  ]) {
    testWidgets(
      'Home isolates $endpoint failure and retries only that section',
      (tester) async {
        viewport(tester);
        failing.add(endpoint);
        await tester.pumpWidget(
          MaterialApp(home: StudentDashboardScreen(apiService: api())),
        );
        await tester.pumpAndSettle();
        expect(find.text('Không thể tải dữ liệu'), findsWidgets);
        expect(find.textContaining('SocketException'), findsNothing);
        if (endpoint != 'tasks') expect(find.byType(TaskCard), findsOneWidget);
        if (endpoint != 'courses') {
          expect(find.byType(CourseProgressCard), findsOneWidget);
        }
        if (endpoint != 'continue-learning') {
          expect(find.text('Tài liệu học tiếp'), findsOneWidget);
        }
        final before = List.of(requests);
        failing.clear();
        await tester.tap(find.text('Thử lại').first);
        await tester.pumpAndSettle();
        expect(find.text('Không thể tải dữ liệu'), findsNothing);
        expect(
          requests.skip(before.length).single.endsWith('/$endpoint'),
          true,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Notifications failure preserves Home and Task Center filter state',
    (tester) async {
      viewport(tester);
      failing.add('notifications');
      await tester.pumpWidget(
        MaterialApp(home: StudentMainScreen(apiService: api())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Quá hạn'));
      await tester.pumpAndSettle();
      expect(find.text('Bài quá hạn từ API'), findsOneWidget);
      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      await tester.tap(find.byType(NavigationDestination).at(0));
      await tester.pumpAndSettle();
      expect(find.text('Xin chào, Mai Anh'), findsOneWidget);
      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.byType(CourseProgressCard), findsOneWidget);
      expect(find.text('Không thể tải dữ liệu'), findsNothing);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Quá hạn'))
            .selected,
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Continue Learning falls back to the matching Course Detail', (
    tester,
  ) async {
    viewport(tester);
    suggestionHasLink = false;
    await tester.pumpWidget(
      MaterialApp(home: StudentDashboardScreen(apiService: api())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Course Activities'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCourseDetailScreen), findsOneWidget);
    expect(
      tester
          .widget<StudentCourseDetailScreen>(
            find.byType(StudentCourseDetailScreen),
          )
          .course
          .courseId,
      14,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Teacher searches email with null idnumber and opens student detail',
    (tester) async {
      viewport(tester, width: 360, height: 900);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TeacherStudentsTab(api: api(), courseId: 14)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('an.demo@example.invalid'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      await tester.enterText(find.byType(TextField), 'AN.DEMO@');
      await tester.pumpAndSettle();
      expect(find.byType(StudentMonitoringCard), findsOneWidget);
      await tester.tap(find.byType(StudentMonitoringCard));
      await tester.pumpAndSettle();
      expect(find.byType(StudentMonitoringDetailScreen), findsOneWidget);
      expect(find.text('an.demo@example.invalid'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Assignment API summary opens submitted/draft roster with zero/null grades',
    (tester) async {
      viewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeacherActivitiesTab(
              api: api(),
              courseId: 14,
              type: 'assignment',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã nộp'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Chưa nộp'), findsOneWidget);
      final metric = find
          .ancestor(of: find.text('Cần chấm'), matching: find.byType(Column))
          .first;
      expect(
        find.descendant(of: metric, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(find.text('Xem sinh viên'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SectionHeader, 'Đã nộp (1)'), findsOneWidget);
      expect(
        find.widgetWithText(SectionHeader, 'Chưa nộp (1)'),
        findsOneWidget,
      );
      expect(find.text('Bản nháp'), findsOneWidget);
      expect(find.text('Điểm hoạt động: 0,0%'), findsOneWidget);
      expect(find.text('Điểm hoạt động: Chưa chấm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Quiz groups finished, inprogress, no attempt and abandoned separately',
    (tester) async {
      viewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ActivityStudentsScreen(
            api: api(),
            courseId: 14,
            activity: MonitoredActivity.fromJson({
              ...activity,
              'task_type': 'quiz',
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Đã hoàn tất',
        'Đang làm',
        'Chưa bắt đầu',
        'Chưa hoàn tất',
      ]) {
        expect(
          find.widgetWithText(SectionHeader, '$label (1)'),
          findsOneWidget,
        );
      }
      for (final name in [
        'SV Hoàn tất',
        'SV Đang làm',
        'SV Chưa bắt đầu',
        'SV Bỏ dở',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('New Home and monitoring fit a narrow viewport with large text', (
    tester,
  ) async {
    viewport(tester, width: 320, height: 900);
    final service = api();
    Widget app(Widget home) => MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.8)),
        child: child!,
      ),
      home: home,
    );
    await tester.pumpWidget(app(StudentMainScreen(apiService: service)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: TeacherActivitiesTab(
            api: service,
            courseId: 14,
            type: 'assignment',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(Scaffold(body: TeacherStudentsTab(api: service, courseId: 14))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
