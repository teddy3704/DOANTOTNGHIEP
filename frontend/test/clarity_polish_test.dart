import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/date_time_text.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_home_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_course_detail_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

import 'product_polish_test.dart' as fixtures;

ApiService api(Object Function(Uri) response) {
  final value = testApi(
    client: MockClient(
      (r) async => http.Response(
        jsonEncode(response(r.url)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
  addTearDown(value.dispose);
  return value;
}

void viewport(WidgetTester t, double width) {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void expectPaddedLabel(WidgetTester t, String label) {
  final bar = t.getRect(find.byType(TabBar));
  final text = find.descendant(
    of: find.byType(TabBar),
    matching: find.text(label),
  );
  final rect = t.getRect(text);
  expect(rect.left, greaterThanOrEqualTo(bar.left + 12));
  expect(rect.right, lessThanOrEqualTo(bar.right - 12));
  expect(rect.top, greaterThanOrEqualTo(bar.top));
  expect(rect.bottom, lessThanOrEqualTo(bar.bottom));
  expect(text.hitTestable(), findsOneWidget);
}

void main() {
  test(
    'Relative deadlines use elapsed time and local calendar without losing absolute dates',
    () {
      final now = DateTime(2026, 9, 22, 8);
      expect(formatDeadline(DateTime(2026, 9, 15, 23, 59)), '15/09/2026 23:59');
      expect(relativeDeadline(null, now: now), 'Không có hạn');
      expect(
        relativeDeadline(now.subtract(const Duration(days: 8)), now: now),
        'Quá hạn 8 ngày',
      );
      expect(
        relativeDeadline(now.subtract(const Duration(hours: 8)), now: now),
        'Quá hạn 8 giờ',
      );
      expect(
        relativeDeadline(now.subtract(const Duration(minutes: 1)), now: now),
        'Quá hạn dưới 1 giờ',
      );
      expect(
        relativeDeadline(now.add(const Duration(hours: 6)), now: now),
        'Còn 6 giờ',
      );
      expect(
        relativeDeadline(
          now.add(const Duration(hours: 6, minutes: 1)),
          now: now,
        ),
        'Còn 7 giờ',
      );
      expect(
        relativeDeadline(now.add(const Duration(days: 2)), now: now),
        'Còn 2 ngày',
      );
      expect(
        relativeDeadline(now.add(const Duration(minutes: 30)), now: now),
        'Hôm nay',
      );
      expect(
        relativeDeadline(now.add(const Duration(days: 1)), now: now),
        'Ngày mai',
      );
      expect(
        relativeDeadline(
          DateTime(2026, 9, 23, 0, 10),
          now: DateTime(2026, 9, 22, 23, 50),
        ),
        'Ngày mai',
      );
    },
  );

  test(
    'Activity deadline state handles 48 hours, null and past close independently of submissions',
    () {
      final now = DateTime(2026, 9, 22, 8);
      expect(
        activityDeadlineState(
          now.subtract(const Duration(seconds: 1)),
          quiz: false,
          now: now,
        ),
        'Đã hết hạn',
      );
      expect(
        activityDeadlineState(
          now.subtract(const Duration(seconds: 1)),
          quiz: true,
          now: now,
        ),
        'Đã đóng',
      );
      expect(
        activityDeadlineState(
          now.add(const Duration(hours: 48)),
          quiz: false,
          now: now,
        ),
        'Sắp đến hạn',
      );
      expect(
        activityDeadlineState(
          now.add(const Duration(hours: 48, seconds: 1)),
          quiz: false,
          now: now,
        ),
        isNull,
      );
      expect(
        activityDeadlineState(null, quiz: true, now: now),
        'Không đặt hạn đóng',
      );
    },
  );

  testWidgets(
    'Pending relative deadline retains timestamp; completed never becomes overdue',
    (t) async {
      final due = DateTime.now().subtract(const Duration(days: 8));
      for (final completed in [false, true]) {
        final task = StudentTask.fromJson({
          'title': 'Bài tập',
          'task_type': 'assignment',
          'task_status': completed ? 'completed' : 'pending',
          'due_time': due.millisecondsSinceEpoch ~/ 1000,
        });
        await fixtures.show(t, Scaffold(body: TaskCard(task)), 1.5);
        expect(
          find.text('Hạn: ${formatDeadline(task.deadline)}'),
          findsOneWidget,
        );
        expect(
          find.text('Quá hạn 8 ngày'),
          completed ? findsNothing : findsOneWidget,
        );
        expect(
          find.widgetWithText(StatusChip, 'Quá hạn 8 ngày'),
          completed ? findsNothing : findsOneWidget,
        );
        expect(
          find.widgetWithText(StatusChip, 'Đã hoàn thành'),
          completed ? findsOneWidget : findsNothing,
        );
      }
    },
  );

  for (final type in ['assignment', 'quiz']) {
    testWidgets('$type displays true deadline state and null date', (t) async {
      for (final (due, label) in [
        (
          DateTime.now().subtract(const Duration(days: 2)),
          type == 'quiz' ? 'Đã đóng' : 'Đã hết hạn',
        ),
        (DateTime.now().add(const Duration(hours: 6)), 'Sắp đến hạn'),
        (null, 'Không có hạn'),
      ]) {
        final service = api(
          (_) => [
            {
              ...fixtures.activity(type),
              'due_time': due == null
                  ? null
                  : due.millisecondsSinceEpoch ~/ 1000,
            },
          ],
        );
        await fixtures.show(
          t,
          Scaffold(
            body: TeacherActivitiesTab(api: service, courseId: 42, type: type),
          ),
          1.5,
        );
        if (due == null) {
          expect(
            find.text(
              type == 'quiz'
                  ? 'Đóng lúc: Không đặt hạn đóng'
                  : 'Hạn nộp: Không có hạn',
            ),
            findsOneWidget,
          );
        } else {
          expect(find.widgetWithText(StatusChip, label), findsOneWidget);
        }
      }
    });
  }

  testWidgets(
    'Support explanation uses API risk only when observable reasons are absent',
    (t) async {
      final row = {
        ...fixtures.student,
        'risk_level': 'MEDIUM',
        'progress': 95,
        'overdue_tasks': 0,
        'days_since_last_activity': 1,
        'attendance': null,
        'pending_tasks': 0,
      };
      final s = MonitoredStudent.fromJson(row);
      expect(s.riskReasons, isEmpty);
      expect(s.supportBasisLabel, contains('nguy cơ trung bình'));
      final service = api(
        (uri) => uri.path.endsWith('/students') ? [row] : {...row, 'tasks': []},
      );
      await fixtures.show(
        t,
        Scaffold(
          body: TeacherStudentsTab(
            api: service,
            courseId: 42,
            initialFilter: 'support',
          ),
        ),
        1.5,
      );
      expect(find.text(s.supportBasisLabel!), findsOneWidget);
      expect(find.textContaining('chuyên cần thấp'), findsNothing);
      await t.tap(find.byType(StudentMonitoringCard));
      await t.pumpAndSettle();
      expect(find.text(s.supportBasisLabel!), findsOneWidget);
      expect(find.textContaining('Chưa đủ dữ liệu'), findsOneWidget);
      expect(find.text('0,0%'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Reason icons preserve evidence and never use manual text bullets',
    (t) async {
      final service = fixtures.service();
      addTearDown(service.dispose);
      await fixtures.show(
        t,
        StudentMonitoringDetailScreen(
          api: service,
          courseId: 42,
          userId: 501,
          name: 'Sinh viên',
        ),
        1.5,
      );
      expect(find.byType(MonitoringReasonRow), findsNWidgets(3));
      expect(find.text('3 bài đã quá hạn'), findsOneWidget);
      expect(find.text('30 ngày chưa hoạt động'), findsOneWidget);
      expect(find.textContaining('•'), findsNothing);
    },
  );

  testWidgets(
    'Teacher zero counts are actionable and aggregate explicitly counts course occurrences',
    (t) async {
      viewport(t, 360);
      final service = api(
        (uri) => uri.path.endsWith('/courses')
            ? [
                {...fixtures.course, 'needs_grading_count': 0},
              ]
            : [],
      );
      await fixtures.show(t, TeacherHomeScreen(apiService: service), 1);
      expect(find.text('4 trường hợp cần theo dõi'), findsOneWidget);
      expect(find.text('Được tổng hợp từ các khóa học'), findsOneWidget);
      final summary = find.ancestor(
        of: find.text('4 trường hợp cần theo dõi'),
        matching: find.byType(Card),
      );
      expect(t.getSize(summary).height, lessThan(260));
      expect(
        find.descendant(of: summary, matching: find.byType(InkWell)),
        findsNWidgets(3),
      );
      await t.tap(find.text('Không có bài nào đang chờ chấm'));
      await t.pumpAndSettle();
      expect(find.byType(TeacherCourseDetailScreen), findsOneWidget);
      expect(DefaultTabController.of(t.element(find.byType(TabBar))).index, 2);
      expect(find.text('Khóa học chưa có bài tập'), findsOneWidget);
    },
  );

  testWidgets(
    'Quiz in progress, abandoned or unknown cannot claim all completed',
    (t) async {
      for (final state in ['inprogress', 'abandoned', 'unknown', 'finished']) {
        final service = api(
          (_) => [
            {
              ...fixtures.student,
              'quiz_state': state,
              'done': state == 'finished',
            },
          ],
        );
        await fixtures.show(
          t,
          ActivityStudentsScreen(
            api: service,
            courseId: 42,
            activity: MonitoredActivity.fromJson(fixtures.activity('quiz')),
          ),
          1,
        );
        expect(
          find.text('Tất cả sinh viên đã hoàn tất'),
          state == 'finished' ? findsOneWidget : findsNothing,
        );
      }
    },
  );

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.5, 1.8]) {
      testWidgets(
        'Student Home order and relative deadline remain usable $width/$scale',
        (t) async {
          viewport(t, width);
          final service = api(
            (uri) => switch (uri.pathSegments.last) {
              'dashboard' => {
                'fullname': 'Nguyễn Thị Minh Anh',
                'average_progress': 62.3,
                'total_courses': 1,
              },
              'tasks' => [
                {
                  ...fixtures.activity('assignment'),
                  'task_status': 'pending',
                  'course_name': 'Khóa học phát triển ứng dụng di động',
                  'due_time':
                      DateTime.now()
                          .subtract(const Duration(days: 8))
                          .millisecondsSinceEpoch ~/
                      1000,
                },
              ],
              'courses' => [fixtures.course],
              'continue-learning' => [
                {
                  'activity_name': '0. Giới thiệu học phần',
                  'activity_type': 'resource',
                  'section_name': 'Bài giảng',
                },
              ],
              _ => [],
            },
          );
          await fixtures.show(t, StudentMainScreen(apiService: service), scale);
          final scrollable = find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first;
          await t.scrollUntilVisible(
            find.text('Quá hạn 8 ngày'),
            200,
            scrollable: scrollable,
          );
          await t.pumpAndSettle();
          expect(find.text('Quá hạn 8 ngày'), findsOneWidget);
          final priorityOffset = t
              .state<ScrollableState>(scrollable)
              .position
              .pixels;
          await t.scrollUntilVisible(
            find.widgetWithText(SectionHeader, 'Tiếp tục học'),
            200,
            scrollable: scrollable,
          );
          await t.pumpAndSettle();
          expect(
            t.state<ScrollableState>(scrollable).position.pixels,
            greaterThanOrEqualTo(priorityOffset),
          );
          await fixtures.scrollAll(t);
          expect(t.takeException(), isNull);
        },
      );
      for (final teacher in [true, false]) {
        testWidgets(
          'Selected native tab stays padded and accessible $width/$scale/teacher=$teacher',
          (t) async {
            viewport(t, width);
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
            await fixtures.show(
              t,
              DefaultTabController(
                length: 5,
                child: Builder(
                  builder: (context) {
                    controller = DefaultTabController.of(context);
                    return Scaffold(
                      appBar: AppBar(
                        bottom: CourseTabBar(labels: labels, textScale: scale),
                      ),
                      body: TabBarView(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Center(child: Text('Nội dung $i')),
                        ],
                      ),
                    );
                  },
                ),
              ),
              scale,
            );
            expectPaddedLabel(t, labels.first);
            for (final index in [4, 0, 2, 4]) {
              controller.animateTo(index);
              await t.pumpAndSettle();
              expectPaddedLabel(t, labels[index]);
              final label = find.descendant(
                of: find.byType(TabBar),
                matching: find.text(labels[index]),
              );
              expect(
                t.getSemantics(label),
                matchesSemantics(
                  label: '${labels[index]}\nTab ${index + 1} of 5',
                  isSelected: true,
                  hasSelectedState: true,
                  isFocusable: true,
                  hasTapAction: true,
                  hasFocusAction: true,
                ),
              );
              await t.tap(label);
              await t.pumpAndSettle();
              expect(controller.index, index);
            }
            // Content swipes must also reveal the selected tab.
            await t.drag(find.byType(TabBarView), Offset(width - 40, 0));
            await t.pumpAndSettle();
            expect(controller.index, 3);
            expectPaddedLabel(t, labels[3]);
            t.view.physicalSize = Size(width == 320 ? 360 : 320, 900);
            await t.pumpAndSettle();
            expectPaddedLabel(t, labels[3]);
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}
