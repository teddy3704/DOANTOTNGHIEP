import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/display_text.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/core/vietnamese_localizations.dart';
import 'package:lms_mobile_app/main.dart';
import 'package:lms_mobile_app/models/student_course.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

void main() {
  test(
    'Demo aliases are exact, opt-in and never translate other source names',
    () {
      const courses = {
        'Software Testing': 'Kiểm thử phần mềm',
        'Mobile Application Development': 'Phát triển ứng dụng di động',
      };
      const activities = {
        'Boundary Value Assignment': 'Bài tập Phân tích giá trị biên',
        'Android API Assignment': 'Bài tập API Android',
        'Decision Table Assignment': 'Bài tập Bảng quyết định',
        'Software Testing Quiz': 'Bài kiểm tra Kiểm thử phần mềm',
        'MVP3 - Bài tập 2.3': 'Bài tập 2.3',
        'MVP3 - Quiz 4.5': 'Bài kiểm tra 4.5',
      };
      for (final e in courses.entries) {
        expect(DemoDisplayNames.course(e.key, demo: true), e.value);
        expect(DemoDisplayNames.course(e.key, demo: false), e.key);
      }
      for (final e in activities.entries) {
        expect(DemoDisplayNames.activity(e.key, demo: true), e.value);
        expect(DemoDisplayNames.activity(e.key, demo: false), e.key);
      }
      expect(
        DemoDisplayNames.activity('Production Quiz 1', demo: true),
        'Production Quiz 1',
      );
      expect(
        DemoDisplayNames.activity('MVP3 - Quiz 1.2 extra', demo: true),
        'MVP3 - Quiz 1.2 extra',
      );
      expect(
        DemoDisplayNames.section('Course Activities', demo: true),
        'Hoạt động khóa học',
      );
      expect(
        DemoDisplayNames.section('Course Activities', demo: false),
        'Course Activities',
      );
    },
  );
  test(
    'Zero, missing and decimal grades have Vietnamese score and grading state',
    () {
      for (final j in [
        {'finalgrade': 0, 'grade_percentage': 0},
        {'finalgrade': 0},
      ]) {
        final grade = StudentGrade.fromJson(j);
        expect(grade.scoreLabel, '0,0%');
        expect(grade.gradingStatus, 'Đã chấm');
      }
      final missing = StudentGrade.fromJson({
        'finalgrade': null,
        'grade_percentage': null,
      });
      expect(missing.scoreLabel, 'Chưa có điểm');
      expect(missing.gradingStatus, 'Chưa chấm');
      expect(
        StudentGrade.fromJson({'finalgrade': 8.75, 'grademax': 10}).scoreLabel,
        '87,5%',
      );
      expect(StudentGrade.fromJson({'finalgrade': 8.75}).scoreLabel, '8,8');
      expect(gradeCategoryLabel('Điểm quá trình'), 'Điểm hoạt động trong kỳ');
      expect(gradeCategoryLabel('Điểm cuối kỳ'), 'Điểm cuối kỳ');
      expect(gradeCategoryLabel('Production category'), 'Production category');
    },
  );
  test('Fixed activity/action/risk wording stays Vietnamese', () {
    expect(activityLabel('quiz'), 'Bài kiểm tra');
    expect(
      StudentTask.fromJson({
        'task_type': 'quiz',
        'task_status': 'completed',
      }).actionLabel,
      'Xem bài kiểm tra trên LMS',
    );
    expect(
      MonitoredStudent.fromJson({
        'userid': 1,
        'days_since_last_activity': 30,
      }).activityLabel,
      'Hoạt động gần nhất: 30 ngày trước',
    );
    for (final (risk, label) in [
      ('HIGH', 'Nguy cơ cao'),
      ('MEDIUM', 'Nguy cơ trung bình'),
      ('LOW', 'Nguy cơ thấp'),
    ]) {
      expect(
        MonitoredStudent.fromJson({'userid': 1, 'risk_level': risk}).riskLabel,
        label,
      );
    }
  });
  testWidgets(
    'App and framework labels use Vietnamese without external localization package',
    (t) async {
      await t.pumpWidget(const LMSApp());
      await t.pumpAndSettle();
      expect(find.text('Hỗ trợ học tập LMS'), findsOneWidget);
      expect(find.text('Sinh viên'), findsNothing);
      final context = t.element(find.text('Hỗ trợ học tập LMS'));
      expect(Localizations.localeOf(context).languageCode, 'vi');
      expect(MaterialLocalizations.of(context).backButtonTooltip, 'Quay lại');
      expect(
        MaterialLocalizations.of(context).tabLabel(tabIndex: 1, tabCount: 5),
        'Thẻ 1 trong 5',
      );
      expect(WidgetsLocalizations.of(context).copyButtonLabel, 'Sao chép');
      expect(t.takeException(), isNull);
    },
  );
  for (final width in [360.0, 384.0, 412.0]) {
    testWidgets(
      'Grade screen zero/null/status/category at $width and text 1.5',
      (t) async {
        t.view.physicalSize = Size(width, 1600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final api = testApi(
          client: MockClient((r) async {
            final Object data = switch (r.url.pathSegments.last) {
              'grades' => [
                {
                  'activity_name': 'Boundary Value Assignment',
                  'finalgrade': 0,
                  'grade_percentage': 0,
                  'category_id': 1,
                },
                {
                  'activity_name': 'Decision Table Assignment',
                  'finalgrade': null,
                  'grade_percentage': null,
                  'category_id': 1,
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
        final rawCourse = StudentCourse(
          courseId: 42,
          courseName: 'Software Testing',
        );
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('vi', 'VN'),
            supportedLocales: const [Locale('vi', 'VN')],
            localizationsDelegates: const [
              VietnameseMaterialDelegate(),
              VietnameseWidgetsDelegate(),
              VietnameseCupertinoDelegate(),
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: StudentCourseDetailScreen(
              course: rawCourse,
              apiService: api,
              initialTab: 3,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('0,0%'), findsNWidgets(2));
        expect(find.widgetWithText(StatusChip, 'Đã chấm'), findsOneWidget);
        expect(find.widgetWithText(StatusChip, 'Chưa chấm'), findsOneWidget);
        expect(find.text('Chưa có điểm'), findsOneWidget);
        expect(find.text('Hoạt động đã chấm: 1 / 2'), findsNWidgets(2));
        expect(find.text('Trung bình các hoạt động đã chấm'), findsOneWidget);
        expect(find.text('Điểm hoạt động trong kỳ'), findsOneWidget);
        expect(
          find.text(DemoDisplayNames.activity('Boundary Value Assignment')),
          findsOneWidget,
        );
        expect(rawCourse.courseName, 'Software Testing');
        expect(rawCourse.courseId, 42);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('Task demo display leaves API title and IDs intact', (t) async {
    final task = StudentTask.fromJson({
      'source_id': 42,
      'coursemoduleid': 142,
      'title': 'MVP3 - Quiz 2.3',
      'task_type': 'quiz',
      'task_status': 'pending',
      'moodle_path': '/mod/quiz/view.php?id=142',
    });
    await t.pumpWidget(MaterialApp(home: Scaffold(body: TaskCard(task))));
    expect(
      find.text(
        DemoDisplayNames.enabled ? 'Bài kiểm tra 2.3' : 'MVP3 - Quiz 2.3',
      ),
      findsOneWidget,
    );
    expect(task.title, 'MVP3 - Quiz 2.3');
    expect(task.sourceId, 42);
    expect(task.courseModuleId, 142);
    expect(task.moodlePath, '/mod/quiz/view.php?id=142');
  });
}
