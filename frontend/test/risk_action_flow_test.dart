import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/models/teacher_course.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/student/student_task_center_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_home_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/student_overview_details.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';
import 'package:lms_mobile_app/widgets/moodle_button.dart';

final high = <String, dynamic>{
  'userid': 501,
  'fullname': 'Sinh viên Cao',
  'progress': 28.6,
  'pending_tasks': 4,
  'overdue_tasks': 3,
  'days_since_last_activity': 25,
  'risk_level': 'HIGH',
  'needs_attention': true,
  'attendance': 0,
  'average_grade': 0,
  'email': 'high@example.edu.vn',
};
final medium = <String, dynamic>{
  ...high,
  'userid': 502,
  'fullname': 'Sinh viên Trung bình',
  'risk_level': 'MEDIUM',
};
final low = <String, dynamic>{
  ...high,
  'userid': 503,
  'fullname': 'Sinh viên Thấp',
  'risk_level': 'LOW',
  'needs_attention': false,
  'progress': 90,
  'overdue_tasks': 0,
  'days_since_last_activity': 1,
};
Map<String, dynamic> course(
  int id, {
  int attention = 2,
  int grading = 1,
  int upcoming = 1,
}) => {
  'courseid': id,
  'course_name': 'Khóa $id',
  'students_need_attention': attention,
  'needs_grading_count': grading,
  'upcoming_deadlines_7_days': upcoming,
  'student_count': 3,
};
Map<String, dynamic> activity(String type) => {
  'source_id': type == 'assignment' ? 901 : 902,
  'title': type == 'assignment' ? 'Bài tập API' : 'Quiz API',
  'task_type': type,
  'student_count': 3,
  'done_count': 1,
  'not_done_count': 2,
  'coursemoduleid': type == 'assignment' ? 2901 : 2902,
  'moodle_path':
      '/mod/${type == 'assignment' ? 'assign' : 'quiz'}/view.php?id=${type == 'assignment' ? 2901 : 2902}',
};
Map<String, dynamic> task(
  String type,
  String status, {
  String? source,
  String? quiz,
  int? due,
}) => {
  'task_type': type,
  'task_status': status,
  'source_status': source,
  'quiz_state': quiz,
  'title': 'Việc $type $status',
  'courseid': 42,
  'source_id': type == 'assignment' ? 901 : 902,
  'coursemoduleid': type == 'assignment' ? 2901 : 2902,
  'moodle_path':
      '/mod/${type == 'assignment' ? 'assign' : 'quiz'}/view.php?id=${type == 'assignment' ? 2901 : 2902}',
  'due_time': due,
};

void viewport(WidgetTester t, {double width = 384, double height = 1600}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Widget app(Widget home, {double scale = 1}) => MaterialApp(
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);
Future<void> tab(WidgetTester t, String label) async {
  final bar = find.byType(TabBar);
  final controller = DefaultTabController.of(t.element(bar));
  final tabs = t.widget<TabBar>(bar).tabs;
  final index = tabs.indexOf(t.widget<Tab>(find.widgetWithText(Tab, label)));
  controller.animateTo(index);
  await t.pumpAndSettle();
  // Also tap the visible label to exercise the tab's interaction.
  await t.tap(find.descendant(of: bar, matching: find.text(label)));
  await t.pumpAndSettle();
}

void main() {
  final requests = <String>[];
  final launches = <MethodCall>[];
  var suggestionPath = <String, dynamic>{};
  var courseData = <Map<String, dynamic>>[];
  var roster = <Map<String, dynamic>>[];
  var notificationData = <Map<String, dynamic>>[];
  var failStudents = false;
  ApiService service() {
    final api = testApi(
      client: MockClient((r) async {
        requests.add(r.url.path);
        final end = r.url.pathSegments.last;
        if (failStudents && end == 'students') {
          throw http.ClientException('SocketException errno=99');
        }
        final Object? response = switch (end) {
          'dashboard' => {'fullname': 'Bạn Demo'},
          'courses' => courseData,
          'tasks' => [task('assignment', 'overdue')],
          'continue-learning' => [
            {
              'activity_name': 'Tài liệu tiếp tục',
              'activity_type': 'resource',
              'course_name': 'Khóa 42',
              'section_name': 'Bài giảng',
              ...suggestionPath,
            },
          ],
          'learning-items' => [
            {'activity_name': 'Nội dung khóa học', 'activity_type': 'resource'},
          ],
          'notifications' => notificationData,
          'class-insights' => {
            'generated_at': '2026-10-10T00:00:00Z',
            'summary': {
              'student_count': 1,
              'watch_count': 1,
              'average_progress': 35.0,
            },
            'attention_students': [
              {
                'student_id': 205,
                'student_name': 'Sinh viên nguy cơ',
                'progress_percentage': 0,
                'overdue_tasks': 2,
                'reasons': ['Progress drop'],
                'suggested_actions': ['Message'],
              },
            ],
          },
          'students' =>
            r.url.path.contains('/assignments/') ||
                    r.url.path.contains('/quizzes/')
                ? roster
                : [high, medium, low],
          '501' => {...high, 'tasks': []},
          'assignments' => [activity('assignment')],
          'quizzes' => [activity('quiz')],
          'attendance' => null,
          _ => [],
        };
        return http.Response(
          jsonEncode(response),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.dispose);
    return api;
  }

  setUp(() {
    requests.clear();
    launches.clear();
    failStudents = false;
    suggestionPath = {
      'courseid': 42,
      'coursemoduleid': 2903,
      'moodle_path': null,
    };
    courseData = [course(42)];
    notificationData = [];
    roster = [
      {
        ...high,
        'done': true,
        'source_status': 'submitted',
        'quiz_state': 'finished',
      },
      {
        ...medium,
        'done': false,
        'source_status': 'draft',
        'quiz_state': 'inprogress',
      },
      {...low, 'done': false, 'source_status': null, 'quiz_state': null},
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            launches.add(call);
            return true;
          },
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
  );

  test(
    'HIGH reasons reflect overdue inactivity progress; backend level is unchanged',
    () {
      final s = MonitoredStudent.fromJson(high);
      expect(s.riskReasons, [
        '3 bài đã quá hạn',
        '25 ngày chưa hoạt động',
        'Tiến độ học tập dưới 30%',
      ]);
      expect(s.risk, 'HIGH');
      expect(
        MonitoredStudent.fromJson({...high, 'risk_level': 'LOW'}).risk,
        'LOW',
      );
    },
  );
  test('Risk rule boundaries and null never become zero signals', () {
    for (final n in [1, 2, 3, 7]) {
      expect(
        MonitoredStudent.fromJson({
          'userid': 1,
          'overdue_tasks': n,
        }).riskReasons,
        ['$n bài đã quá hạn'],
      );
    }
    for (final n in [7, 13, 14, 25]) {
      expect(
        MonitoredStudent.fromJson({
          'userid': 1,
          'days_since_last_activity': n,
        }).riskReasons,
        ['$n ngày chưa hoạt động'],
      );
    }
    for (final n in [0, 29.9, 30, 59.9, 60, 100]) {
      final reasons = MonitoredStudent.fromJson({
        'userid': 1,
        'progress': n,
      }).riskReasons;
      expect(
        reasons,
        n < 30
            ? ['Tiến độ học tập dưới 30%']
            : n < 60
            ? ['Tiến độ học tập còn thấp']
            : isEmpty,
      );
    }
    expect(
      MonitoredStudent.fromJson({
        'userid': 1,
        'progress': null,
        'overdue_tasks': 0,
        'days_since_last_activity': 6,
        'attendance': 0,
        'average_grade': 0,
      }).riskReasons,
      isEmpty,
    );
    final missing = MonitoredStudent.fromJson({
      'userid': 1,
      'risk_level': 'HIGH',
      'attendance': 0,
      'average_grade': 0,
    });
    expect(missing.riskReasons, isEmpty);
    expect(missing.riskExplanationFallback, contains('Chưa đủ dữ liệu'));
    expect(
      MonitoredStudent.fromJson(low).riskExplanationFallback,
      'Chưa phát hiện dấu hiệu cần ưu tiên theo dõi.',
    );
  });
  testWidgets('Detail shows explanations before metrics at narrow large text', (
    t,
  ) async {
    viewport(t, width: 360, height: 1600);
    await t.pumpWidget(
      app(
        StudentMonitoringDetailScreen(
          api: service(),
          courseId: 42,
          userId: 501,
          name: 'Sinh viên Cao',
        ),
        scale: 1.5,
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Lý do cần theo dõi'), findsOneWidget);
    for (final reason in MonitoredStudent.fromJson(high).riskReasons) {
      expect(find.text(reason), findsOneWidget);
    }
    expect(
      t.getTopLeft(find.text('Lý do cần theo dõi')).dy,
      lessThan(t.getTopLeft(find.byType(StudentOverviewDetails)).dy),
    );
    expect(t.takeException(), isNull);
  });
  // The overview tab keeps its shortcut; the analytics tab opens groups in a sheet instead.
  for (final action in ['support']) {
    testWidgets(
      '$action CTA repeatedly selects correct roster and clears stale search',
      (t) async {
        viewport(t, width: 360);
        await t.pumpWidget(
          app(
            TeacherCourseDetailScreen(
              course: TeacherCourse.fromJson(course(42)),
              apiService: service(),
            ),
          ),
        );
        await t.pumpAndSettle();
        const label = 'Xem sinh viên cần theo dõi';
        const chip = 'Cần theo dõi';
        for (var pass = 0; pass < 2; pass++) {
          await tab(t, 'Tổng quan');
          await t.tap(find.text(label));
          await t.pumpAndSettle();
          expect(
            DefaultTabController.of(t.element(find.byType(TabBar))).index,
            1,
          );
          final selected = find.widgetWithText(ChoiceChip, chip);
          expect(t.widget<ChoiceChip>(selected).selected, isTrue);
          expect(t.getRect(selected).right, lessThanOrEqualTo(344));
          expect(find.byType(StudentMonitoringCard), findsNWidgets(2));
          expect(find.text('Sinh viên Thấp'), findsNothing);
          expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
          await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Tất cả'));
          await t.pumpAndSettle();
          await t.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
          await t.pumpAndSettle();
          await t.enterText(find.byType(TextField), 'Thấp');
          await t.pumpAndSettle();
        }
        expect(
          requests
              .where((p) => p.endsWith('/students'))
              .every((p) => p.contains('/teachers/$mockTeacherId/courses/42/')),
          isTrue,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final action in [1, 2, -1]) {
    testWidgets('Teacher Home action $action offers only relevant courses', (
      t,
    ) async {
      viewport(t);
      courseData = [
        course(40, attention: 0, grading: 0, upcoming: 0),
        course(42),
        course(43),
      ];
      await t.pumpWidget(app(TeacherHomeScreen(apiService: service())));
      await t.pumpAndSettle();
      final label = action == 1
          ? '4 trường hợp cần theo dõi'
          : action == 2
          ? '2 bài cần chấm'
          : '2 hoạt động sắp đến hạn';
      await t.tap(find.text(label));
      await t.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Khóa 40')),
        findsNothing,
      );
      await t.tap(find.descendant(of: sheet, matching: find.text('Khóa 43')));
      await t.pumpAndSettle();
      final detail = t.widget<TeacherCourseDetailScreen>(
        find.byType(TeacherCourseDetailScreen),
      );
      expect(detail.course.courseId, 43);
      expect(
        DefaultTabController.of(t.element(find.byType(TabBar))).index,
        action < 0 ? 0 : action,
      );
      if (action == 1) {
        expect(
          t
              .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Cần theo dõi'),
              )
              .selected,
          isTrue,
        );
      }
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byType(TeacherHomeScreen), findsOneWidget);
    });
  }
  testWidgets('Teacher Home on real data totals only current-term courses', (
    t,
  ) async {
    viewport(t);
    courseData = [
      {...course(42, grading: 3), 'current_term': true},
      {...course(43, grading: 500, attention: 0), 'current_term': false},
    ];
    await t.pumpWidget(app(TeacherHomeScreen(apiService: service())));
    await t.pumpAndSettle();
    // Summary row (the course card below shows its own count too).
    expect(find.text('3 bài cần chấm'), findsWidgets);
    expect(find.text('503 bài cần chấm'), findsNothing);
    expect(find.text('2 trường hợp cần theo dõi'), findsOneWidget);
    expect(
      find.text('Được tổng hợp từ các khóa học · Học kỳ hiện tại'),
      findsOneWidget,
    );
    // Old course is not offered from the summary; with one match it opens directly.
    await t.tap(find.text('3 bài cần chấm').first);
    await t.pumpAndSettle();
    expect(
      t
          .widget<TeacherCourseDetailScreen>(
            find.byType(TeacherCourseDetailScreen),
          )
          .course
          .courseId,
      42,
    );
  });
  testWidgets(
    'Student Home actions reuse bottom navigation and course returns to Courses',
    (t) async {
      viewport(t);
      await t.pumpWidget(app(StudentMainScreen(apiService: service())));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.widgetWithText(SectionHeader, 'Ưu tiên hôm nay'),
          matching: find.text('Tất cả việc cần làm'),
        ),
      );
      await t.pumpAndSettle();
      expect(
        t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.byType(StudentTaskCenterScreen), findsOneWidget);
      await t.tap(find.byType(NavigationDestination).at(2));
      await t.pumpAndSettle();
      await t.tap(find.byType(CourseProgressCard));
      await t.pumpAndSettle();
      expect(
        t
            .widget<StudentCourseDetailScreen>(
              find.byType(StudentCourseDetailScreen),
            )
            .course
            .courseId,
        42,
      );
      await t.pageBack();
      await t.pumpAndSettle();
      expect(
        t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    },
  );
  test(
    'All filters exclude completed submitted finished tasks from overdue and soon',
    () {
      final now = DateTime(2026, 9, 21);
      final old =
          now.subtract(const Duration(days: 5)).millisecondsSinceEpoch ~/ 1000;
      final soon =
          now.add(const Duration(hours: 12)).millisecondsSinceEpoch ~/ 1000;
      final rows = [
        task('assignment', 'overdue'),
        task('assignment', 'pending', due: soon),
        task('assignment', 'completed', due: old),
        task('assignment', 'overdue', source: 'submitted', due: old),
        task('quiz', 'overdue', quiz: 'finished', due: old),
        task('quiz', 'completed', due: soon),
      ].map(StudentTask.fromJson).toList();
      expect(filterTasks(rows, TaskFilter.all, now).length, 6);
      expect(filterTasks(rows, TaskFilter.pending, now).length, 2);
      expect(filterTasks(rows, TaskFilter.overdue, now), [rows[0]]);
      expect(filterTasks(rows, TaskFilter.soon, now), [rows[1]]);
      expect(filterTasks(rows, TaskFilter.done, now).length, 4);
    },
  );
  for (final type in ['assignment', 'quiz']) {
    for (final done in [false, true]) {
      testWidgets(
        '$type ${done ? 'done' : 'overdue'} CTA launches correct Moodle activity externally',
        (t) async {
          viewport(t);
          final row = StudentTask.fromJson(
            task(type, done ? 'completed' : 'overdue'),
          );
          final label = type == 'assignment'
              ? (done ? 'Xem bài trên LMS' : 'Mở LMS để nộp bài')
              : (done ? 'Xem bài kiểm tra trên LMS' : 'Mở LMS để làm bài');
          await t.pumpWidget(app(Scaffold(body: TaskCard(row))));
          await t.pumpAndSettle();
          await t.tap(find.text(label));
          await t.pumpAndSettle();
          expect(
            launches.single.arguments['url'],
            'https://lms.dlu.edu.vn${row.moodlePath}',
          );
          expect(launches.single.arguments['useWebView'], isFalse);
          expect(launches.single.arguments['useSafariVC'], isFalse);
        },
      );
    }
    testWidgets(
      'Teacher $type opens correct roster and Back retains course tab',
      (t) async {
        viewport(t);
        await t.pumpWidget(
          app(
            TeacherCourseDetailScreen(
              course: TeacherCourse.fromJson(course(42)),
              apiService: service(),
            ),
          ),
        );
        await t.pumpAndSettle();
        await tab(t, type == 'assignment' ? 'Bài tập' : 'Bài kiểm tra');
        await t.tap(find.text('Xem sinh viên'));
        await t.pumpAndSettle();
        expect(find.byType(ActivityStudentsScreen), findsOneWidget);
        final id = type == 'assignment' ? 901 : 902;
        expect(
          requests,
          contains(
            '/api/v1/dev/teachers/$mockTeacherId/courses/42/${type == 'assignment' ? 'assignments' : 'quizzes'}/$id/students',
          ),
        );
        expect(
          find.widgetWithText(
            SectionHeader,
            type == 'assignment' ? 'Chưa nộp (2)' : 'Chưa bắt đầu (1)',
          ),
          findsOneWidget,
        );
        await t.pageBack();
        await t.pumpAndSettle();
        expect(
          DefaultTabController.of(t.element(find.byType(TabBar))).index,
          type == 'assignment' ? 2 : 3,
        );
      },
    );
    testWidgets('$type roster shows meaningful empty unfinished group', (
      t,
    ) async {
      viewport(t);
      roster = [
        {
          ...high,
          'done': true,
          'source_status': type == 'assignment' ? 'submitted' : null,
          'quiz_state': type == 'quiz' ? 'finished' : null,
        },
      ];
      await t.pumpWidget(
        app(
          ActivityStudentsScreen(
            api: service(),
            courseId: 42,
            activity: MonitoredActivity.fromJson(activity(type)),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text(
          type == 'assignment'
              ? 'Tất cả sinh viên đã nộp'
              : 'Tất cả sinh viên đã hoàn tất',
        ),
        findsOneWidget,
      );
    });
  }
  testWidgets('Continue fallback opens Content tab of matching course', (
    t,
  ) async {
    viewport(t);
    await t.pumpWidget(app(StudentMainScreen(apiService: service())));
    await t.pumpAndSettle();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();
    expect(
      t
          .widget<StudentCourseDetailScreen>(
            find.byType(StudentCourseDetailScreen),
          )
          .course
          .courseId,
      42,
    );
    expect(DefaultTabController.of(t.element(find.byType(TabBar))).index, 1);
    expect(
      requests,
      contains('/api/v1/dev/students/$mockStudentId/courses/42/learning-items'),
    );
    await t.pageBack();
    await t.pumpAndSettle();
    expect(
      t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
  testWidgets(
    'Continue full URL launches directly; missing context stays safe',
    (t) async {
      viewport(t);
      suggestionPath = {
        'courseid': 42,
        'coursemoduleid': 2903,
        'moodle_path': 'https://lms.dlu.edu.vn/mod/resource/view.php?id=2903',
      };
      await t.pumpWidget(app(StudentMainScreen(apiService: service())));
      await t.pumpAndSettle();
      await t.tap(find.text('Tiếp tục'));
      await t.pumpAndSettle();
      expect(launches.single.arguments['url'], suggestionPath['moodle_path']);
      await t.pumpWidget(const SizedBox());
      suggestionPath = {
        'courseid': null,
        'coursemoduleid': null,
        'source_id': null,
        'moodle_path': null,
      };
      await t.pumpWidget(app(StudentMainScreen(apiService: service())));
      await t.pumpAndSettle();
      expect(find.text('Chưa có liên kết LMS khả dụng'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Notification fallback reuses Task Center; invalid URL never launches',
    (t) async {
      viewport(t);
      notificationData = [
        {
          'title': 'Nhắc bài',
          'course_id': 42,
          'source_kind': 'reminder',
          'moodle_path': 'https://example.com/mod/quiz/view.php?id=2902',
          'coursemoduleid': 2902,
        },
      ];
      await t.pumpWidget(app(StudentMainScreen(apiService: service())));
      await t.pumpAndSettle();
      await t.tap(find.byType(NavigationDestination).at(3));
      await t.pumpAndSettle();
      expect(find.text('Mở trên LMS'), findsNothing);
      await t.tap(find.text('Kiểm tra việc cần làm'));
      await t.pumpAndSettle();
      expect(
        t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.byType(StudentTaskCenterScreen), findsOneWidget);
      expect(launches, isEmpty);
    },
  );
  test(
    'Moodle accepts same-origin full or relative URL and rejects wrong module IDs',
    () {
      const path = '/mod/quiz/view.php?id=2902';
      expect(
        moodleActivityUri('https://lms.dlu.edu.vn$path', 2902).toString(),
        'https://lms.dlu.edu.vn$path',
      );
      expect(
        moodleActivityUri(path, 2902).toString(),
        'https://lms.dlu.edu.vn$path',
      );
      for (final url in [
        'https://example.com$path',
        'http://lms.dlu.edu.vn$path',
        'https://x@lms.dlu.edu.vn$path',
        '//$path',
        '/mod/quiz/view.php?id=902',
      ]) {
        expect(moodleActivityUri(url, 2902), isNull);
      }
    },
  );
  testWidgets('Notification valid full URL opens Moodle without navigation', (
    t,
  ) async {
    viewport(t);
    notificationData = [
      {
        'title': 'Nhắc quiz',
        'source_kind': 'reminder',
        'course_id': 42,
        'coursemoduleid': 2902,
        'moodle_path': 'https://lms.dlu.edu.vn/mod/quiz/view.php?id=2902',
      },
    ];
    await t.pumpWidget(app(StudentMainScreen(apiService: service())));
    await t.pumpAndSettle();
    await t.tap(find.byType(NavigationDestination).at(3));
    await t.pumpAndSettle();
    await t.tap(find.text('Mở trên LMS'));
    await t.pumpAndSettle();
    expect(
      launches.single.arguments['url'],
      notificationData.single['moodle_path'],
    );
    expect(
      t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });
  testWidgets('Unknown roster statuses do not claim every student submitted', (
    t,
  ) async {
    viewport(t);
    roster = [
      {...high, 'done': null, 'source_status': null},
    ];
    await t.pumpWidget(
      app(
        ActivityStudentsScreen(
          api: service(),
          courseId: 42,
          activity: MonitoredActivity.fromJson(activity('assignment')),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Tất cả sinh viên đã nộp'), findsNothing);
    expect(
      find.widgetWithText(SectionHeader, 'Chưa có trạng thái (1)'),
      findsOneWidget,
    );
  });
  testWidgets('Teacher API failure is friendly and retry restores roster', (
    t,
  ) async {
    viewport(t);
    failStudents = true;
    await t.pumpWidget(
      app(Scaffold(body: TeacherStudentsTab(api: service(), courseId: 42))),
    );
    await t.pumpAndSettle();
    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
    failStudents = false;
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.byType(StudentMonitoringCard), findsNWidgets(3));
  });
}
