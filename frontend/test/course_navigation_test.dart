import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/teacher_course.dart';
import 'package:lms_mobile_app/screens/student/student_courses_screen.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_courses_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';

void main() {
  testWidgets('Student course opens course detail, not analytics', (
    tester,
  ) async {
    final requests = <String>[];
    final api = testApi(
      client: MockClient((request) async {
        requests.add(request.url.path);
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/courses')
                ? [
                    {
                      'courseid': 10,
                      'course_name': 'Android',
                      'course_shortname': 'AND',
                    },
                  ]
                : [],
          ),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(home: StudentCoursesScreen(apiService: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCourseDetailScreen), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(5));
    expect(requests.any((path) => path.endsWith('/analytics')), isFalse);
  });

  testWidgets('Teacher navigation loads monitoring tabs and analytics last', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <String>[];
    final api = testApi(
      client: MockClient((request) async {
        requests.add(request.url.path);
        final data = request.url.path.endsWith('/courses')
            ? [
                {
                  'courseid': 10,
                  'course_name': 'Android',
                  'student_count': 4,
                  'students_need_attention': 1,
                  'high_risk_students': 0,
                  'average_progress': 35,
                },
              ]
            : request.url.path.endsWith('/class-insights')
            ? {
                'generated_at': '2026-10-10T00:00:00Z',
                'summary': {
                  'student_count': 4,
                  'watch_count': 1,
                  'average_progress': 35.0,
                },
                'watch_groups': {
                  'on_track': 1,
                  'watch': 2,
                  'needs_support': 1,
                  'unknown': 0,
                  'total': 4,
                },
              }
            : [];
        return http.Response(jsonEncode(data), 200);
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
        home: TeacherCoursesScreen(apiService: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Android'));
    await tester.pumpAndSettle();
    expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
    expect(find.text('1 sinh viên cần theo dõi'), findsOneWidget);
    expect(find.text('0 sinh viên nguy cơ cao'), findsOneWidget);
    for (final (tab, message) in [
      ('Sinh viên', 'Không có sinh viên phù hợp'),
      ('Bài tập', 'Khóa học chưa có bài tập'),
      ('Bài kiểm tra', 'Khóa học chưa có bài kiểm tra'),
      ('Phân tích', 'Cần chú ý'),
    ]) {
      final target = find.widgetWithText(Tab, tab);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Cần chú ý'), findsWidgets);
    expect(
      requests.every(
        (path) => [
          'courses',
          'students',
          'assignments',
          'quizzes',
          'class-insights',
          // V2-N4 pass forecast section in the analytics tab.
          'grade-forecast',
          // V2-N16 quiz analysis section in the analytics tab.
          'quiz-insights',
        ].contains(path.split('/').last),
      ),
      isTrue,
    );
  });

  testWidgets('Missing Teacher metrics are not converted into zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TeacherCourseSummary(
              course: TeacherCourse(courseId: 10, courseName: 'Demo'),
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('Sinh viên cần theo dõi: Chưa có dữ liệu'),
      findsOneWidget,
    );
    expect(find.text('0 sinh viên cần theo dõi'), findsNothing);
  });
}
