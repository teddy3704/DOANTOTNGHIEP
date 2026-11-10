import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/student_course.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/widgets/moodle_button.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12);
  StudentTask task(
    int id,
    int? hours, {
    String status = 'pending',
    String type = 'assignment',
    String? source,
    String? quiz,
  }) => StudentTask.fromJson({
    'source_id': id,
    'title': 'Task $id',
    'task_type': type,
    'task_status': status,
    'source_status': source,
    'quiz_state': quiz,
    'due_time': hours == null
        ? null
        : now.add(Duration(hours: hours)).millisecondsSinceEpoch ~/ 1000,
  });

  test(
    'Sort overdue, within 48h, other pending, then finished; source wins',
    () {
      final tasks = [
        task(4, -4, source: 'submitted'),
        task(3, null),
        task(2, 48),
        task(1, -1),
        task(5, -2, type: 'quiz', quiz: 'finished'),
      ];
      expect(StudentTask.sorted(tasks, now).map((task) => task.sourceId), [
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(tasks.first.statusLabel, 'Đã nộp');
      expect(tasks.first.isOverdue(now), isFalse);
      expect(tasks.last.statusLabel, 'Đã làm');
      expect(tasks.last.actionLabel, 'Xem bài kiểm tra trên LMS');
      expect(task(6, 49).isDueSoon(now), isFalse);
      expect(task(7, 48).isDueSoon(now), isTrue);
      expect(task(8, 0).isDueSoon(now), isTrue);
    },
  );

  test('Completion tracking never determines whether a task was submitted', () {
    final data = StudentTask.fromJson({
      'task_status': 'pending',
      'completionstate': 1,
    });
    expect(data.isPending, isTrue);
    expect(data.isDone, isFalse);
    expect(task(1, -1, status: 'completed').statusLabel, 'Đã hoàn thành');
  });

  test('Unix seconds and local date formatting', () {
    expect(
      formatDeadline(unixSeconds(now.millisecondsSinceEpoch ~/ 1000)),
      '14/09/2026 12:00',
    );
    expect(unixSeconds(0), isNull);
    expect(formatDeadline(null), 'Không có hạn');
  });

  test('Zero grades and attendance remain distinct from missing values', () {
    expect(
      StudentGrade.fromJson({
        'finalgrade': 0,
        'grade_percentage': 0,
      }).scoreLabel,
      '0,0%',
    );
    expect(
      StudentGrade.fromJson({'finalgrade': null}).scoreLabel,
      'Chưa có điểm',
    );
    expect(
      StudentAttendance.fromJson({'attendance_percentage': null}).percentage,
      isNull,
    );
    expect(
      StudentAttendance.fromJson({'attendance_percentage': 0}).percentage,
      0,
    );
  });

  test('Moodle URL uses the supplied course module ID and trusted host', () {
    expect(
      moodleActivityUri('/mod/assign/view.php?id=24102', 24102).toString(),
      'https://lms.dlu.edu.vn/mod/assign/view.php?id=24102',
    );
    expect(moodleActivityUri('/mod/assign/view.php?id=5', 24102), isNull);
    expect(
      moodleActivityUri('//example.com/mod/quiz/view.php?id=5', 5),
      isNull,
    );
    expect(
      moodleActivityUri('https://example.com/mod/quiz/view.php?id=5', 5),
      isNull,
    );
    expect(moodleActivityUri('/mod/quiz/view.php?id=5&id=6', 5), isNull);
    expect(moodleActivityUri(null, 5), isNull);
  });

  test('Attendance API accepts null, empty body and wrapped null', () async {
    for (final body in ['', 'null', '{"data":null}']) {
      final api = testApi(
        client: MockClient((request) async => http.Response(body, 200)),
      );
      expect(await api.getStudentAttendance(courseId: 10), isNull);
      api.dispose();
    }
  });

  testWidgets('Five student tabs render on narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = testApi(
      client: MockClient((request) async {
        final endpoint = request.url.pathSegments.last;
        final Object? data = switch (endpoint) {
          'learning-items' => [
            {
              'section_number': 0,
              'section_name': 'Tổng quan',
              'activity_name': 'Tài liệu giới thiệu',
              'activity_type': 'resource',
              'coursemoduleid': 6,
              'moodle_path': '/mod/resource/view.php?id=6',
            },
          ],
          'grades' => [
            {
              'activity_name': 'Bài tập mẫu',
              'finalgrade': 0,
              'grade_percentage': 0,
            },
          ],
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
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: StudentCourseDetailScreen(
          apiService: api,
          course: StudentCourse(
            courseId: 10,
            courseName: 'Lập trình Android',
            courseShortname: 'ANDROID',
            progressPercentage: 30,
            completedTasks: 3,
            totalTasks: 10,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Tab), findsNWidgets(5));
    for (final tab in ['Nội dung', 'Việc cần làm', 'Điểm', 'Chuyên cần']) {
      final target = find.widgetWithText(Tab, tab);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (tab == 'Điểm') expect(find.text('0,0%'), findsOneWidget);
      if (tab == 'Chuyên cần') {
        expect(
          find.text('Khóa học chưa có dữ liệu chuyên cần'),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('API failure shows safe text and retry recovers', (tester) async {
    var fail = true;
    final api = testApi(
      client: MockClient((request) async {
        if (fail) {
          throw http.ClientException('SocketException errno=99 secret detail');
        }
        return http.Response('[]', 200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: StudentCourseDetailScreen(
          apiService: api,
          course: StudentCourse(courseId: 10, courseName: 'Demo'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.textContaining('errno'), findsNothing);
    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải dữ liệu'), findsNothing);
    expect(find.text('Chưa hoàn thành: 0'), findsOneWidget);
  });
}
