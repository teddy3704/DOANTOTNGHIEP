import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_analytics_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_analytics_sections.dart';
import 'package:lms_mobile_app/services/api_service.dart';

Map<String, Object?> student(
  int id,
  String name,
  String group, {
  List<Map<String, Object?>> signals = const [],
  int overdue = 0,
  int completed = 3,
  double progress = 80,
}) => {
  'userid': id,
  'fullname': name,
  'student_code': '22120$id',
  'group': group,
  'progress': progress,
  'marked_sessions': 18,
  'absent_sessions': 2,
  'days_since_last_activity': 1,
  'completed_tasks': completed,
  'total_tasks': 3,
  'overdue_tasks': overdue,
  'average_grade': 85.0,
  'graded_items': 3,
  'signals': signals,
};

final insights = {
  'generated_at': '2026-10-10T00:00:00Z',
  'summary': {'student_count': 3, 'watch_count': 2},
  'watch_groups': {'on_track': 1, 'watch': 1, 'needs_support': 1, 'unknown': 0},
  'signal_counts': {
    'ABSENCE': 1,
    'INACTIVE': 0,
    'OVERDUE': 1,
    'LOW_PROGRESS': 1,
    'LOW_GRADE': 0,
  },
  'progress_distribution': [
    {'label': '0–24%', 'students': 1},
    {'label': '25–49%', 'students': 0},
    {'label': '50–74%', 'students': 0},
    {'label': '75–100%', 'students': 2},
  ],
  'students': [
    {
      ...student(
        1,
        'Bùi Mai Oanh',
        'needs_support',
        overdue: 2,
        completed: 1,
        progress: 10,
        signals: [
          {'code': 'ABSENCE', 'label': 'Vắng 9/18 buổi (50%)', 'strong': true},
          {'code': 'OVERDUE', 'label': 'Quá hạn 2/3 bài', 'strong': false},
        ],
      ),
      'risk_score': 65,
      'average_grade': 40.0,
      'tasks': [
        {
          'title': 'Bài tập 1',
          'task_type': 'assignment',
          'status': 'completed',
        },
        {
          'title': 'Bài tập 2',
          'task_type': 'assignment',
          'status': 'overdue',
          'due_time': 1788000000,
        },
        {
          'title': 'Quiz 1',
          'task_type': 'quiz',
          'status': 'overdue',
          'due_time': 1788100000,
        },
      ],
      'completed_activities': 2,
      'total_tracked_activities': 20,
      'score_breakdown': [
        {'points': 40, 'label': '16 ngày không truy cập (≥14 ngày)'},
        {'points': 25, 'label': 'Tiến độ 10% (dưới 30%)'},
      ],
    },
    student(2, 'Phạm Trọng Duy', 'watch'),
    student(3, 'Trần Công Hải', 'on_track'),
  ],
  'task_status': {'total': 9, 'completed': 7, 'pending': 0, 'overdue': 2},
  'action_items': [
    {
      'code': 'DEADLINE_SOON',
      'priority': 1,
      'action': 'REMIND',
      'student_ids': [1, 2],
      'days': 2,
      'activity': {
        'source_id': 21,
        'task_type': 'assignment',
        'title': 'Bài tập nhóm',
        'due_time': 4102444800,
        'coursemoduleid': 70,
        'moodle_path': '/mod/assign/view.php?id=70',
      },
    },
    {
      'code': 'STOPPED_LEARNING',
      'priority': 3,
      'action': 'CONTACT',
      'student_ids': [1],
    },
  ],
  'weekly_change': {
    'as_of': '2026-10-03T00:00:00Z',
    'previous': {
      'needs_support': 0,
      'watch': 1,
      'on_track': 2,
      'average_progress': 50.0,
      'overdue_students': 0,
    },
    'current': {
      'needs_support': 1,
      'watch': 1,
      'on_track': 1,
      'average_progress': 56.7,
      'overdue_students': 1,
    },
    'worsened': [
      {
        'userid': 1,
        'fullname': 'Bùi Mai Oanh',
        'from': 'on_track',
        'to': 'needs_support',
      },
    ],
    'improved': [],
  },
  'activity_heatmap': {
    'weeks': ['2026-08-17', '2026-08-24', '2026-08-31', '2026-09-07'],
    'max_events': 9,
    'dropped_count': 1,
    'never_active_count': 1,
    'drop_off_weeks': 2,
    'rows': [
      {
        'userid': 1,
        'fullname': 'Bùi Mai Oanh',
        'group': 'needs_support',
        'weekly_events': [6, 0, 0, 0],
        'total_events': 6,
        'status': 'dropped',
        'dropped_since': '2026-08-24',
      },
      {
        'userid': 2,
        'fullname': 'Phạm Trọng Duy',
        'group': 'watch',
        'weekly_events': [0, 0, 0, 0],
        'total_events': 0,
        'status': 'never_active',
      },
      {
        'userid': 3,
        'fullname': 'Trần Công Hải',
        'group': 'on_track',
        'weekly_events': [2, 4, 9, 3],
        'total_events': 18,
        'status': 'active',
      },
    ],
  },
  'support_followups': {
    'window_days': 7,
    'total': 2,
    'returned': 1,
    'no_change': 1,
    'waiting': 0,
    'return_rate': 50.0,
    'average_days_to_return': 1.0,
    'average_events_before': 0.5,
    'average_events_after': 3.0,
    'items': [
      {
        'id': 2,
        'student_id': 2,
        'fullname': 'Phạm Trọng Duy',
        'note': 'Nhắn tin hỏi thăm',
        'noted_at': '2026-09-20T03:00:00Z',
        'days_since': 20,
        'events_before': 1,
        'events_after': 0,
        'outcome': 'NO_CHANGE',
      },
      {
        'id': 1,
        'student_id': 1,
        'fullname': 'Bùi Mai Oanh',
        'note': 'Gọi điện nhắc nộp bài',
        'noted_at': '2026-09-10T03:00:00Z',
        'days_since': 30,
        'events_before': 0,
        'events_after': 6,
        'outcome': 'RETURNED',
        'days_to_return': 1,
      },
    ],
  },
};

ApiService api() => testApi(
  client: MockClient(
    (_) async => http.Response(
      jsonEncode(insights),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  ),
);

void main() {
  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'To-do list sends a reminder about the right activity and reloads',
    (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final posts = <Map<String, dynamic>>[];
      var gets = 0;
      final client = MockClient((req) async {
        if (req.method == 'POST') {
          expect(req.url.path, endsWith('/teachers/102/courses/14/reminders'));
          posts.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({'sent': 2}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        // Count class-insights loads only; the V2-N4 forecast section loads separately.
        if (req.url.path.endsWith('class-insights')) gets++;
        return http.Response(
          jsonEncode(insights),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeacherAnalyticsTab(
              api: testApi(client: client),
              courseId: 14,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Việc cần làm tuần này'), findsWidgets);
      expect(
        find.text('1. Nhắc 2 sinh viên chưa nộp "Bài tập nhóm"'),
        findsOneWidget,
      );
      expect(
        find.text('2. Liên hệ 1 sinh viên đã ngừng vào học'),
        findsOneWidget,
      );

      // The composer shows who gets it and a prefilled, editable message.
      await tester.tap(find.text('Nhắc 2 sinh viên'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Gửi tới: Bùi Mai Oanh, Phạm Trọng Duy'),
        findsOneWidget,
      );
      expect(find.text('Nhắc nộp bài: Bài tập nhóm'), findsOneWidget);
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();

      expect(posts, hasLength(1));
      expect(posts.single['student_ids'], [1, 2]);
      expect(posts.single['source_type'], 'assignment');
      expect(posts.single['source_id'], 21);
      expect(find.text('Đã gửi nhắc nhở tới 2 sinh viên.'), findsOneWidget);
      expect(
        gets,
        2,
        reason: 'reloads so the to-do list reflects the reminder',
      );

      // A contact item opens the students, and that list can be reminded too.
      await tester.tap(find.text('Xem 1 sinh viên'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Bùi Mai Oanh'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Nhắc 1 sinh viên'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Weekly change shows what moved since last week', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TeacherAnalyticsTab(api: api(), courseId: 14)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thay đổi so với tuần trước'), findsOneWidget);
    expect(
      find.textContaining('1 sinh viên chuyển sang nhóm cần chú ý hơn'),
      findsOneWidget,
    );
    expect(
      find.text('Bùi Mai Oanh: Đúng tiến độ → Cần hỗ trợ'),
      findsOneWidget,
    );
    // Summary tiles carry the change too.
    expect(find.textContaining('▲ 1 so với tuần trước'), findsOneWidget);
    expect(find.text('▲ 6.7% so với tuần trước'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A failed reminder keeps the composer open with an error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient(
      (req) async => req.method == 'POST'
          ? http.Response('{"message":"x"}', 400)
          : http.Response(
              jsonEncode(insights),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeacherAnalyticsTab(api: testApi(client: client), courseId: 14),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhắc 2 sinh viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Không gửi được nhắc nhở. Vui lòng thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping a watch group opens a sheet listing exactly that group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TeacherAnalyticsTab(api: api(), courseId: 14)),
      ),
    );
    await tester.pumpAndSettle();

    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );

    // What the grouping is based on is stated on screen; no student list until a tap.
    expect(find.text('Mức độ cần hỗ trợ'), findsOneWidget);
    // Score rules live under "Cách tính" and are hidden until tapped.
    expect(find.textContaining('Có từ 3 bài quá hạn chưa nộp'), findsNothing);
    // No chart is titled as a question any more.
    expect(find.textContaining('?'), findsNothing);
    expect(find.text('Hỗ trợ sinh viên'), findsOneWidget);
    expect(find.text('Cần hỗ trợ (≥60 điểm)'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    // A group opens in a sheet, with each student's score explained.
    await tapVisible(tester, find.text('Cần hỗ trợ (≥60 điểm)'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(inSheet('Cần hỗ trợ · 1 sinh viên'), findsOneWidget);
    expect(inSheet('Bùi Mai Oanh'), findsOneWidget);
    expect(inSheet('+40'), findsOneWidget);
    expect(inSheet('16 ngày không truy cập (≥14 ngày)'), findsOneWidget);
    expect(inSheet('2/20 hoạt động (10%)'), findsOneWidget);
    expect(inSheet('1/3 bài đã xong, 2 quá hạn'), findsOneWidget);
    expect(inSheet('Phạm Trọng Duy'), findsNothing);
    await closeSheet(tester);
    expect(find.byType(BottomSheet), findsNothing);

    await tapVisible(tester, find.text('Cần theo dõi (30–59 điểm)'));
    await tester.pumpAndSettle();
    expect(inSheet('Cần theo dõi · 1 sinh viên'), findsOneWidget);
    expect(inSheet('Phạm Trọng Duy'), findsOneWidget);
    expect(inSheet('Bùi Mai Oanh'), findsNothing);
    await closeSheet(tester);

    // A signal chip opens every student with that signal, across groups.
    await tapVisible(tester, find.text('Có bài quá hạn · 1'));
    await tester.pumpAndSettle();
    expect(inSheet('Bùi Mai Oanh'), findsOneWidget);
    expect(inSheet('Trần Công Hải'), findsNothing);
    await closeSheet(tester);

    // Inside "Cần chú ý", quick filters narrow the list.
    await tapVisible(tester, find.text('Cần chú ý'));
    await tester.pumpAndSettle();
    expect(inSheet('Phạm Trọng Duy'), findsOneWidget);
    await tester.tap(inSheet('Có bài quá hạn (1)'));
    await tester.pumpAndSettle();
    expect(inSheet('Phạm Trọng Duy'), findsNothing);
    expect(inSheet('Bùi Mai Oanh'), findsOneWidget);
    await closeSheet(tester);

    // Summary cards explain where their number comes from.
    await tester.tap(find.text('Điểm TB').first);
    await tester.pumpAndSettle();
    // The formula stays folded until the teacher asks for it.
    expect(inSheet('Cách tính'), findsOneWidget);
    expect(find.textContaining('sổ điểm (gradebook)'), findsNothing);
    await tester.tap(inSheet('Cách tính'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sổ điểm (gradebook)'), findsOneWidget);
    await tester.tap(inSheet('Cách tính'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sổ điểm (gradebook)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Quadrants, drop-off heatmap and support follow-ups explain themselves',
    (tester) async {
      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TeacherAnalyticsTab(api: api(), courseId: 14)),
        ),
      );
      await tester.pumpAndSettle();

      // A. Effort × result quadrants, each with a count and a suggested kind of help.
      expect(find.text('Tiến độ và điểm số của sinh viên'), findsOneWidget);
      final weak = find.descendant(
        of: find.byType(ProgressGradeQuadrants),
        matching: find.text('1 SV (33%)'),
      );
      await tester.ensureVisible(weak);
      await tester.pumpAndSettle();
      await tester.tap(weak);
      await tester.pumpAndSettle();
      expect(find.text('Làm ít, điểm thấp · 1 sinh viên'), findsOneWidget);
      await closeSheet(tester);
      expect(
        find.textContaining('sinh viên không phải tự nhập gì'),
        findsOneWidget,
      );

      // B. Who stopped and since when.
      expect(find.text('Lịch sử vào học theo tuần'), findsOneWidget);
      expect(find.text('Ngừng từ 24/8'), findsOneWidget);
      expect(find.text('Chưa vào học'), findsOneWidget);
      expect(
        find.textContaining('1 sinh viên đã ngừng vào học ít nhất 2 tuần'),
        findsOneWidget,
      );

      // C. Did support help? Before/after activity per note.
      expect(find.text('Hiệu quả hỗ trợ sinh viên'), findsOneWidget);
      expect(find.text('Quay lại sau 1 ngày'), findsOneWidget);
      expect(find.text('Chưa quay lại sau 7 ngày'), findsOneWidget);
      expect(find.text('Hoạt động: 0 → 6 lượt'), findsOneWidget);
      expect(find.textContaining('1/2 lần hỗ trợ (50%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Task status slices list the students and the tasks in that state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TeacherAnalyticsTab(api: api(), courseId: 14)),
      ),
    );
    await tester.pumpAndSettle();
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );

    expect(find.text('Tình hình nộp bài tập và bài kiểm tra'), findsOneWidget);

    // "Đã nộp" lists who submitted and which work, not their overdue or watch score.
    final done = find.text('Đã nộp / đã làm');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(inSheet('Đã nộp / đã làm · 3 sinh viên'), findsOneWidget);
    expect(inSheet('Đã nộp / đã làm: 1/3 bài'), findsOneWidget);
    expect(inSheet('Bài tập 1'), findsOneWidget);
    expect(inSheet('+40'), findsNothing);
    await closeSheet(tester);

    // "Quá hạn" lists only students with overdue work, naming each task and its due date.
    final late = find.text('Quá hạn, chưa nộp');
    await tester.ensureVisible(late);
    await tester.pumpAndSettle();
    await tester.tap(late);
    await tester.pumpAndSettle();
    expect(inSheet('Quá hạn, chưa nộp · 1 sinh viên'), findsOneWidget);
    expect(inSheet('Quá hạn, chưa nộp: 2/3 bài'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining('Bài tập 2 · hạn'),
      ),
      findsOneWidget,
    );
    expect(inSheet('Phạm Trọng Duy'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A low-completion activity lists every student as on time, late or not submitted',
    (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const due = 1788000000;
      Map<String, Object?> task(
        String status, {
        int? submitted,
        bool late = false,
      }) => {
        'source_id': 21,
        'title': 'Bài tập nhóm',
        'task_type': 'assignment',
        'status': status,
        'due_time': due,
        'submitted_at': submitted,
        'late': late,
      };
      final students = (insights['students'] as List)
          .cast<Map<String, Object?>>();
      final withActivity = {
        ...insights,
        'students': [
          {
            ...students[0],
            'tasks': [
              task('completed', submitted: due + 3 * 86400, late: true),
            ],
          },
          {
            ...students[1],
            'tasks': [task('overdue')],
          },
          // Same id but a quiz: a different activity, so it must not be listed.
          {
            ...students[2],
            'tasks': [
              {
                ...task('completed', submitted: due - 3600),
                'graded': true,
                'grade_percentage': 80.0,
                'passed': true,
              },
              {...task('completed'), 'task_type': 'quiz'},
            ],
          },
        ],
        'low_completion_activities': [
          {
            'source_id': 21,
            'task_type': 'assignment',
            'title': 'Bài tập nhóm',
            'due_time': due,
            'due_passed': true,
            'student_count': 3,
            'done_count': 1,
            'completion_rate': 33.3,
          },
        ],
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeacherAnalyticsTab(
              courseId: 14,
              api: testApi(
                client: MockClient(
                  (_) async => http.Response(
                    jsonEncode(withActivity),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder inSheet(String text) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(text),
      );
      Finder inSheetContaining(String text) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining(text),
      );

      final row = find.text('1/3 sinh viên hoàn thành (33%)');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      // All three students, each in the right state, the late one with how late.
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(inSheet('Bùi Mai Oanh'), findsOneWidget);
      expect(inSheet('Phạm Trọng Duy'), findsOneWidget);
      expect(inSheet('Trần Công Hải'), findsOneWidget);
      expect(inSheet('Nộp trễ'), findsNWidgets(2)); // count box + Oanh's card
      expect(inSheetContaining('trễ 3 ngày'), findsOneWidget);
      expect(inSheetContaining('Đã quá hạn'), findsWidgets);

      // Journey: 3 assigned → 2 handed in → 1 graded → 1 passed; no view logs, so no "Đã mở đề".
      expect(inSheet('Hành trình làm bài'), findsOneWidget);
      expect(inSheet('Đã mở đề'), findsNothing);
      expect(inSheet('↓ 1 sinh viên dừng lại: chưa nộp bài'), findsOneWidget);
      expect(
        inSheet('↓ 1 sinh viên dừng lại: đã nộp nhưng chưa được chấm'),
        findsOneWidget,
      );
      expect(inSheet('Đã chấm: 80% · Đạt'), findsOneWidget);
      expect(inSheet('Chưa được chấm'), findsOneWidget);

      // A drop line lists exactly who stopped there.
      await tester.tap(
        inSheet('↓ 1 sinh viên dừng lại: đã nộp nhưng chưa được chấm'),
      );
      await tester.pumpAndSettle();
      expect(inSheet('Bùi Mai Oanh'), findsOneWidget);
      expect(inSheet('Phạm Trọng Duy'), findsNothing);
      expect(inSheet('Trần Công Hải'), findsNothing);

      // Tapping a count box narrows the list to that state.
      await tester.tap(inSheet('Chưa nộp').first);
      await tester.pumpAndSettle();
      expect(inSheet('Phạm Trọng Duy'), findsOneWidget);
      expect(inSheet('Bùi Mai Oanh'), findsNothing);
      expect(inSheet('Trần Công Hải'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Overlapping dots merge into one numbered dot, never across quadrants',
    (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final students = (insights['students'] as List)
          .cast<Map<String, Object?>>();
      final close = {
        ...insights,
        'students': [
          // 100% / 70.3% and 100% / 71.0%: under 2 px apart, as in the real class.
          {...students[0], 'progress': 100.0, 'average_grade': 70.3},
          {...students[1], 'progress': 100.0, 'average_grade': 71.0},
          // Just across the 50% line: close on screen but in another quadrant.
          {...students[2], 'progress': 100.0, 'average_grade': 49.9},
        ],
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeacherAnalyticsTab(
              courseId: 14,
              api: testApi(
                client: MockClient(
                  (_) async => http.Response(
                    jsonEncode(close),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder inPlot(Finder f) =>
          find.descendant(of: find.byType(ProgressGradeQuadrants), matching: f);

      // One "2" on the merged dot plus one in the legend sample.
      expect(inPlot(find.text('2')), findsNWidgets(2));
      expect(inPlot(find.text('2 SV (67%)')), findsOneWidget);
      expect(inPlot(find.text('1 SV (33%)')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Quadrants leave out students with fewer than 2 graded items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final students = (insights['students'] as List)
        .cast<Map<String, Object?>>();
    final oneGrade = {
      ...insights,
      'students': [
        ...students.take(2),
        {...students[2], 'graded_items': 1},
      ],
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeacherAnalyticsTab(
            courseId: 14,
            api: testApi(
              client: MockClient(
                (_) async => http.Response(
                  jsonEncode(oneGrade),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 sinh viên chưa đủ dữ liệu điểm'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ProgressGradeQuadrants),
        matching: find.text('1 SV (50%)'),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('All analytics sections fit 320 px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(body: TeacherAnalyticsTab(api: api(), courseId: 14)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProgressGradeQuadrants), findsOneWidget);
    expect(find.byType(ActivityHeatmapSection), findsOneWidget);
    expect(find.byType(SupportFollowUpSection), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Follow-up section explains how to start when there are no notes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final empty = {
        ...insights,
        'support_followups': {'window_days': 7, 'total': 0, 'items': []},
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeacherAnalyticsTab(
              courseId: 14,
              api: testApi(
                client: MockClient(
                  (_) async => http.Response(
                    jsonEncode(empty),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa có ghi chú hỗ trợ nào trong khóa học này.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
