import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/display_text.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/models/student_course.dart';
import 'package:lms_mobile_app/models/teacher_course.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_home_screen.dart';
import 'package:lms_mobile_app/screens/teacher/student_overview_details.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

const student = <String, dynamic>{
  'userid': 501,
  'fullname': 'Nguyễn Thị Minh Anh',
  'idnumber': null,
  'email': 'student07@example.edu.vn',
  'progress': 28.6,
  'attendance': null,
  'pending_tasks': 4,
  'overdue_tasks': 3,
  'days_since_last_activity': 30,
  'average_grade': 75.5,
  'risk_level': 'HIGH',
};
const course = <String, dynamic>{
  'courseid': 42,
  'course_name':
      'Khóa học phát triển ứng dụng di động và hỗ trợ học tập trên nền tảng quản lý học tập',
  'course_shortname': 'MOBILE101',
  'student_count': 4,
  'average_progress': 57.1,
  'students_need_attention': 4,
  'needs_grading_count': 3,
  'upcoming_deadlines_7_days': 1,
};
Map<String, dynamic> activity(String type) => {
  'source_id': 901,
  'coursemoduleid': 2901,
  'task_type': type,
  'title':
      'Bài ${type == 'quiz' ? 'kiểm tra' : 'tập'} vận dụng kiến thức phát triển ứng dụng di động',
  'student_count': 4,
  'done_count': 1,
  'not_done_count': 3,
  'needs_grading_count': type == 'assignment' ? 1 : null,
  'average_grade_percentage': type == 'quiz' ? 94.0 : null,
  'due_time': 1789488000,
  'moodle_path': '/mod/${type == 'quiz' ? 'quiz' : 'assign'}/view.php?id=2901',
};

ApiService service() => testApi(
  client: MockClient((request) async {
    final path = request.url.path;
    final end = request.url.pathSegments.last;
    final Object data;
    if (end == 'courses') {
      data = [course];
    } else if (path.contains('/901/students')) {
      final quiz = path.contains('/quizzes/');
      data = [
        {
          ...student,
          'done': true,
          'source_status': quiz ? null : 'submitted',
          'quiz_state': quiz ? 'finished' : null,
          'finalgrade': 0,
          'grade_percentage': 0,
        },
        {
          ...student,
          'userid': 502,
          'fullname': 'Sinh viên chưa có điểm',
          'done': false,
          'finalgrade': null,
          'grade_percentage': null,
        },
      ];
    } else {
      data = switch (end) {
        'students' => [student],
        '501' => {...student, 'tasks': <Object>[]},
        'assignments' => [activity('assignment')],
        'quizzes' => [activity('quiz')],
        'class-insights' => {
          'generated_at': '2026-10-10T00:00:00Z',
          'summary': {
            'student_count': 1,
            'watch_count': 1,
            'average_progress': 35.0,
          },
          'attention_students': [
            {
              'student_id': 501,
              'student_name': 'Học sinh rất dài và phức tạp',
              'progress_percentage': 0,
              'overdue_tasks': 1,
              'reasons': ['Missing assignment'],
              'suggested_actions': ['Message student'],
            },
          ],
        },
        'grades' => [
          {
            'activity_name': 'Bài tập có điểm bằng không',
            'category_id': 1,
            'finalgrade': 0,
            'grade_percentage': 0,
            'feedback': 'Kết quả hoạt động demo',
          },
          {
            'activity_name':
                'Bài tập đang chờ đánh giá và nhận xét từ giảng viên',
            'category_id': 1,
            'finalgrade': null,
          },
        ],
        'grade-categories' => [
          {
            'category_id': 1,
            'category_name': 'Điểm quá trình',
            'category_average_percentage': 0,
            'graded_item_count': 1,
            'grade_item_count': 2,
          },
        ],
        _ => <Object>[],
      };
    }
    return http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

Widget app(Widget home, double scale) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

Future<void> show(WidgetTester t, Widget home, double scale) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(app(home, scale));
  await t.pumpAndSettle();
  final ex = t.takeException();
  if (ex != null) {
    debugPrint('OVERFLOW IN: ${home.runtimeType}');
    throw ex;
  }
}

Future<void> scrollAll(WidgetTester t) async {
  final scroll = find.byType(ListView).first;
  for (var i = 0; i < 5; i++) {
    await t.drag(scroll, const Offset(0, -400));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }
}

void main() {
  test('Percentage helper keeps decimals, zero and missing distinct', () {
    expect(formatPercentageVi(62.3), '62,3%');
    expect(formatPercentageVi(95), '95,0%');
    expect(formatPercentageVi(0), '0,0%');
    expect(formatPercentageVi(null), 'Chưa có dữ liệu');
    expect(
      DemoDisplayNames.activity('Android API Assignment', demo: true),
      'Bài tập API Android',
    );
    expect(
      DemoDisplayNames.activity('Android API Assignment', demo: false),
      'Android API Assignment',
    );
    expect(
      DemoDisplayNames.activity('0. Giới thiệu học phần', demo: true),
      '0. Giới thiệu học phần',
    );
    final row = ActivityStudent.fromJson({
      ...student,
      'finalgrade': 9.5,
      'grade_percentage': 95,
    });
    expect(row.grade, 9.5);
    expect(row.gradePercentage, 95);
    expect(row.student.id, 501);
    expect(row.student.identityLabel, 'student07@example.edu.vn');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.5, 1.8]) {
      testWidgets('Product screens at width $width, text scale $scale', (
        t,
      ) async {
        t.view.physicalSize = Size(width, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final api = service();
        addTearDown(api.dispose);
        await show(t, TeacherHomeScreen(apiService: api), scale);
        final caseFinder = find.text('4 trường hợp cần theo dõi');
        try {
          expect(caseFinder, findsOneWidget);
        } catch (_) {
          await t.dragUntilVisible(
            caseFinder,
            find.byType(ListView).first,
            const Offset(0, -200),
          );
          expect(caseFinder, findsOneWidget);
        }
        await scrollAll(t);
        final courseTitle = t.widget<Text>(
          find.text(course['course_name'] as String),
        );
        expect(courseTitle.maxLines, 2);

        await show(
          t,
          TeacherCourseDetailScreen(
            course: TeacherCourse.fromJson(course),
            apiService: api,
            initialTab: 1,
          ),
          scale,
        );
        expect(find.byType(StudentMonitoringCard), findsOneWidget);
        expect(find.textContaining('null'), findsNothing);
        expect(find.text('Quiz'), findsNothing);
        expect(find.widgetWithText(Tab, 'Bài kiểm tra'), findsOneWidget);
        expect(t.getSize(find.byType(TextField)).height, lessThan(80));
        final highChip = find.widgetWithText(ChoiceChip, 'Nguy cơ cao');
        await t.ensureVisible(highChip);
        await t.pumpAndSettle();
        expect(highChip.hitTestable(), findsOneWidget);
        await t.tap(highChip);
        await t.pumpAndSettle();
        expect(
          t
              .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Nguy cơ cao'),
              )
              .selected,
          isTrue,
        );
        expect(t.takeException(), isNull);
        final controller = DefaultTabController.of(
          t.element(find.byType(TabBar)),
        );
        controller.animateTo(4);
        await t.pumpAndSettle();
        expect(find.text('Cần chú ý'), findsOneWidget);
        expect(find.text('Xem sinh viên cần theo dõi'), findsNothing);
        expect(t.takeException(), isNull);

        await show(
          t,
          StudentMonitoringDetailScreen(
            api: api,
            courseId: 42,
            userId: 501,
            name: 'Nguyễn Thị Minh Anh',
          ),
          scale,
        );
        try {
          await t.ensureVisible(find.byType(StudentOverviewDetails));
        } catch (_) {
          await t.dragUntilVisible(
            find.byType(StudentOverviewDetails),
            find.byType(Scrollable).last,
            const Offset(0, -200),
          );
        }
        await t.pumpAndSettle();
        final metrics = find.byType(StudentOverviewDetails);
        final missing = find
            .descendant(of: metrics, matching: find.text('Chưa có dữ liệu'))
            .first;
        final number = find.descendant(
          of: metrics,
          matching: find.text('28,6%'),
        );
        expect(
          t.widget<Text>(missing).style!.fontSize!,
          lessThan(t.widget<Text>(number).style!.fontSize!),
        );
        final cards = find.descendant(of: metrics, matching: find.byType(Card));
        // Four compact tiles, two per row.
        expect(cards, findsNWidgets(4));
        expect(t.getTopLeft(cards.at(0)).dy, t.getTopLeft(cards.at(1)).dy);
        expect(t.getTopLeft(cards.at(2)).dy, t.getTopLeft(cards.at(3)).dy);
        await scrollAll(t);

        for (final type in ['assignment', 'quiz']) {
          await show(
            t,
            Scaffold(
              body: TeacherActivitiesTab(api: api, courseId: 42, type: type),
            ),
            scale,
          );
          expect(
            t
                .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator),
                )
                .value,
            .25,
          );
          if (type == 'quiz') {
            expect(find.text('1 / 4'), findsOneWidget);
            expect(
              find.text('Trung bình các điểm đã ghi nhận: 94,0%'),
              findsOneWidget,
            );
          }
          await t.ensureVisible(find.text('Xem sinh viên'));
          await t.pumpAndSettle();
          await t.tap(find.text('Xem sinh viên'));
          await t.pumpAndSettle();
          expect(
            find.text(type == 'assignment' ? 'Đã nộp (1)' : 'Đã hoàn tất (1)'),
            findsOneWidget,
          );
          expect(find.text('Điểm hoạt động: 0,0%'), findsOneWidget);
          expect(find.widgetWithText(StatusChip, 'Đã chấm'), findsOneWidget);
          await scrollAll(t);
          expect(find.text('Điểm hoạt động: Chưa chấm'), findsOneWidget);
          expect(t.takeException(), isNull);
        }

        await show(
          t,
          StudentCourseDetailScreen(
            course: StudentCourse(
              courseId: 42,
              courseName: course['course_name'] as String,
            ),
            apiService: api,
            initialTab: 3,
          ),
          scale,
        );
        expect(find.text('Điểm hoạt động trong kỳ'), findsOneWidget);
        expect(find.text('Trung bình các hoạt động đã chấm'), findsOneWidget);
        expect(find.text('0,0%'), findsNWidgets(2));
        await scrollAll(t);
        expect(find.text('Chưa có điểm'), findsOneWidget);
        expect(find.widgetWithText(StatusChip, 'Chưa chấm'), findsOneWidget);
      });
    }
  }
}
