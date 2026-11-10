import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/models/student_course.dart';
import 'package:lms_mobile_app/models/teacher_course.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/student/student_task_center_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';
import 'package:lms_mobile_app/widgets/moodle_button.dart';

void main() {
  final now = DateTime.now();
  Map<String, dynamic> task(int id, int hours, String status) => {
    'source_id': id,
    'courseid': 14,
    'course_name': 'Mobile',
    'title': 'Bài $id',
    'task_type': 'assignment',
    'task_status': status,
    'due_time': now.add(Duration(hours: hours)).millisecondsSinceEpoch ~/ 1000,
    'coursemoduleid': 24000 + id,
    'moodle_path': '/mod/assign/view.php?id=${24000 + id}',
  };
  final tasks = [
    task(4, 120, 'pending'),
    task(3, 30, 'pending'),
    task(2, 8, 'pending'),
    task(1, -24, 'overdue'),
    task(5, -1, 'completed'),
  ];
  final roster = [
    {
      'userid': 205,
      'fullname': 'An Demo',
      'student_code': 'SV01',
      'progress': 35,
      'overdue_tasks': 2,
      'pending_tasks': 3,
      'risk_level': 'HIGH',
      'needs_attention': true,
      'days_since_last_activity': 12,
    },
    {
      'userid': 206,
      'fullname': 'Binh Demo',
      'student_code': 'SV02',
      'progress': 65,
      'overdue_tasks': 0,
      'pending_tasks': 1,
      'risk_level': 'MEDIUM',
      'needs_attention': true,
      'days_since_last_activity': 3,
    },
    {
      'userid': 207,
      'fullname': 'Chi Demo',
      'student_code': 'SV03',
      'progress': 100,
      'overdue_tasks': 0,
      'pending_tasks': 0,
      'risk_level': 'LOW',
      'needs_attention': false,
      'days_since_last_activity': 0,
    },
  ];
  final paths = <String>[];
  ApiService service() {
    final api = testApi(
      client: MockClient((request) async {
        paths.add(request.url.path);
        final Object data = switch (request.url.pathSegments.last) {
          'dashboard' => {
            'firstname': 'Mai',
            'lastname': 'Anh',
            'email': 'demo@example.invalid',
          },
          'courses' => [
            {'courseid': 14, 'course_name': 'Mobile'},
          ],
          'tasks' => tasks,
          'continue-learning' => [
            {
              'courseid': 14,
              'course_name': 'Mobile',
              'activity_name': 'Slide tiếp theo',
              'section_name': 'Bài giảng',
              'activity_type': 'resource',
              'coursemoduleid': 24301,
              'moodle_path': '/mod/resource/view.php?id=24301',
            },
          ],
          'students' =>
            request.url.path.contains('/assignments/')
                ? [
                    {
                      ...roster[0],
                      'done': true,
                      'source_status': 'submitted',
                      'finalgrade': 0,
                    },
                    {
                      ...roster[1],
                      'done': false,
                      'source_status': 'draft',
                      'finalgrade': null,
                    },
                  ]
                : roster,
          'analytics' => {
            'high_risk_students': 1,
            'medium_risk_students': 1,
            'low_risk_students': 1,
          },
          'notifications' => [
            {
              'id': 1,
              'source_kind': 'reminder',
              'title': 'Nhắc bài demo',
              'message': 'Kiểm tra hạn nộp',
              'event_time': '2026-09-15T10:00:00Z',
            },
          ],
          'class-insights' => {
            'generated_at': '2026-10-10T00:00:00Z',
            'summary': {'student_count': 3, 'watch_count': 1},
            'attention_students': [
              {
                'student_id': 205,
                'student_name': 'Sinh Demo',
                'progress_percentage': 28.6,
                'overdue_tasks': 3,
                'reasons': ['Progress drop'],
                'suggested_actions': ['Message student'],
              },
            ],
          },
          _ => [],
        };
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.dispose);
    return api;
  }

  test(
    'Actual overdue status remains pending and all filters preserve source completion',
    () {
      final parsed = tasks.map(StudentTask.fromJson).toList();
      expect(
        filterTasks(parsed, TaskFilter.pending, now).map((t) => t.sourceId),
        [1, 2, 3, 4],
      );
      expect(filterTasks(parsed, TaskFilter.soon, now).map((t) => t.sourceId), [
        2,
        3,
      ]);
      expect(filterTasks(parsed, TaskFilter.overdue, now).single.sourceId, 1);
      expect(filterTasks(parsed, TaskFilter.done, now).single.sourceId, 5);
      final submitted = StudentTask.fromJson({
        ...task(6, -24, 'overdue'),
        'source_status': 'submitted',
      });
      expect(submitted.isOverdue(now), false);
      expect(submitted.actionLabel, 'Xem bài trên LMS');
    },
  );
  test(
    'Course progress counts activities while support covers HIGH and MEDIUM',
    () {
      final course = StudentCourse.fromJson({
        'courseid': 14,
        'completed_activities': 13,
        'total_tracked_activities': 20,
        'completed_tasks': 2,
        'total_tasks': 4,
      });
      expect(course.completedTasks, 13);
      expect(course.totalTasks, 20);
      expect(
        roster
            .map(MonitoredStudent.fromJson)
            .where((s) => s.needsSupport)
            .length,
        2,
      );
      expect(
        MonitoredStudent.fromJson({
          ...roster[0],
          'needs_attention': false,
        }).needsSupport,
        false,
      );
    },
  );
  testWidgets(
    'Student Home prioritizes three tasks and bottom navigation loads notifications',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = service();
      await tester.pumpWidget(
        MaterialApp(home: StudentMainScreen(apiService: api)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Xin chào, Mai Anh'), findsOneWidget);
      final cards = tester.widgetList<TaskCard>(find.byType(TaskCard)).toList();
      expect(cards.map((c) => c.task.sourceId), [1, 2, 3]);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Quá hạn'));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<TaskCard>(find.byType(TaskCard)).single.task.sourceId,
        1,
      );
      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc bài demo'), findsOneWidget);
      expect(
        paths,
        contains('/api/v1/dev/students/$mockStudentId/notifications'),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Teacher search and support filter expose specific students', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TeacherStudentsTab(api: service(), courseId: 14)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cần theo dõi'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<StudentMonitoringCard>(find.byType(StudentMonitoringCard))
          .map((c) => c.student.id),
      [205, 206],
    );
    await tester.enterText(find.byType(TextField), 'SV02');
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<StudentMonitoringCard>(find.byType(StudentMonitoringCard))
          .single
          .student
          .id,
      206,
    );
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('Không có sinh viên cần theo dõi'), findsOneWidget);
  });
  testWidgets('Assignment roster preserves submitted, draft and zero score', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityStudentsScreen(
          api: service(),
          courseId: 14,
          activity: MonitoredActivity.fromJson({
            'source_id': 14102,
            'task_type': 'assignment',
            'title': 'Bài demo',
            'coursemoduleid': 24102,
            'moodle_path': '/mod/assign/view.php?id=24102',
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('An Demo'), findsOneWidget);
    expect(find.text('Bản nháp'), findsOneWidget);
    expect(find.text('Điểm hoạt động: 0,0%'), findsOneWidget);
    final button = tester.widget<MoodleButton>(find.byType(MoodleButton));
    expect(
      moodleActivityUri(button.path, button.courseModuleId).toString(),
      'https://lms.dlu.edu.vn/mod/assign/view.php?id=24102',
    );
  });
  testWidgets('Analytics overview has no roster shortcut button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherCourseDetailScreen(
          apiService: service(),
          course: TeacherCourse(courseId: 14, courseName: 'Mobile'),
          initialTab: 4,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan lớp học'), findsOneWidget);
    expect(find.text('Xem sinh viên cần theo dõi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
