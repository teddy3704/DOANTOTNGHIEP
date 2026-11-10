import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/teacher/student_overview_details.dart';

// 2026-09-01 08:00 local, in epoch seconds, plus whole days.
final _t0 = DateTime(2026, 9, 1, 8).millisecondsSinceEpoch ~/ 1000;
int _day(int n) => _t0 + n * 86400;

Map<String, dynamic> student({bool marked = true}) => {
  'userid': 205,
  'fullname': 'Hoang Giang',
  'progress': 33.3,
  'completed_activities': 1,
  'total_tracked_activities': 3,
  'attendance': marked ? 62.5 : null,
  'marked_sessions': marked ? 4 : 0,
  'absent_sessions': marked ? 1 : 0,
  'average_grade': 52.5,
  'graded_items': 2,
  'pending_tasks': 2,
  'overdue_tasks': 1,
  'days_since_last_activity': 3,
  'progress_items': [
    {
      'activity_name': 'Bài giảng 1',
      'activity_type': 'resource',
      'completed': true,
      'completed_at': _day(2),
    },
    {
      'activity_name': 'Bài tập 1',
      'activity_type': 'assign',
      'completed': false,
      'due_time': _day(5),
    },
    {'activity_name': 'Quiz 1', 'activity_type': 'quiz', 'completed': false},
  ],
  'attendance_sessions': [
    for (final (i, a)
        in (marked ? ['P', 'P', 'L', 'A', null] : [null, null, null]).indexed)
      {
        'sessdate': _day(i * 7),
        'duration': 5400,
        'description': 'Buổi ${i + 1}',
        'acronym': a,
        'status_description': a,
        'status_grade': switch (a) {
          'P' => 2.0,
          'L' => 1.0,
          'A' => 0.0,
          _ => null,
        },
        'max_grade': 2.0,
      },
  ],
  'grade_items': [
    {
      'activity_name': 'Bài tập 0',
      'activity_type': 'assign',
      'finalgrade': 80,
      'grademax': 100,
      'gradepass': 50,
      'grade_percentage': 80,
      'passed': true,
    },
    {
      'activity_name': 'Quiz 0',
      'activity_type': 'quiz',
      'finalgrade': 2.5,
      'grademax': 10,
      'gradepass': 5,
      'grade_percentage': 25,
      'passed': false,
    },
    {
      'activity_name': 'Bài tập 1',
      'activity_type': 'assign',
      'grademax': 100,
      'gradepass': 50,
    },
  ],
};

Future<void> show(
  WidgetTester t,
  Map<String, dynamic> json, {
  double width = 400,
  double scale = 1,
}) async {
  t.view.physicalSize = Size(width, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StudentOverviewDetails(
            student: MonitoredStudent.fromJson(json),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  Finder inSheet(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));
  Finder inSheetContaining(String text) => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.textContaining(text),
  );
  Future<void> open(WidgetTester t, String tile) async {
    await t.tap(find.text(tile));
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  }

  Future<void> close(WidgetTester t) async {
    await t.tap(find.byTooltip('Đóng'));
    await t.pumpAndSettle();
  }

  testWidgets('Overview stays compact: four tiles, no lists until tapped', (
    t,
  ) async {
    await show(t, student());
    expect(find.byType(Card), findsNWidgets(4));
    expect(find.text('33,3%'), findsOneWidget);
    expect(find.text('1/3 hoạt động'), findsOneWidget);
    expect(find.text('62,5%'), findsOneWidget);
    expect(find.text('4 buổi đã điểm danh'), findsOneWidget);
    expect(find.text('52,5%'), findsOneWidget);
    expect(find.text('2 bài đã chấm'), findsOneWidget);
    expect(find.text('1 bài quá hạn'), findsOneWidget);
    expect(
      find.text('Hoạt động gần nhất trên Moodle: 3 ngày trước'),
      findsOneWidget,
    );
    // Explanations and lists live in the sheets, not on the page.
    expect(find.textContaining('÷'), findsNothing);
    expect(find.text('Chưa hoàn thành (2)'), findsNothing);
  });

  testWidgets(
    'Each tile opens a sheet with how it is computed and the rows behind it',
    (t) async {
      await show(t, student());

      await open(t, 'Tiến độ');
      expect(inSheet('Đã hoàn thành 1/3 hoạt động'), findsOneWidget);
      expect(inSheetContaining('(1 ÷ 3)'), findsOneWidget);
      expect(inSheet('Chưa hoàn thành (2)'), findsOneWidget);
      expect(
        inSheetContaining('Tài liệu · Hoàn thành 03/09/2026'),
        findsOneWidget,
      );
      await close(t);

      await open(t, 'Chuyên cần');
      expect(
        inSheet(
          'Có mặt 2 · Đi trễ 1 · Vắng 1 / 4 buổi đã điểm danh · 1 buổi chưa điểm danh',
        ),
        findsOneWidget,
      );
      expect(
        inSheetContaining('Có mặt 2 điểm, Đi trễ 1 điểm, Vắng 0 điểm'),
        findsOneWidget,
      );
      expect(inSheet('Các buổi học (5)'), findsOneWidget);
      expect(inSheet('Đi trễ'), findsOneWidget);
      expect(inSheet('Chưa điểm danh'), findsOneWidget);
      expect(inSheetContaining('Buổi 3 · 90 phút'), findsOneWidget);
      await close(t);

      await open(t, 'Điểm TB');
      expect(
        inSheet('Tính trên 2 bài đã chấm · Đạt 1 · Chưa đạt 1'),
        findsOneWidget,
      );
      expect(inSheetContaining('2,5/10 điểm · cần 5 để đạt'), findsOneWidget);
      expect(inSheet('25,0% · Chưa đạt'), findsOneWidget);
      expect(inSheet('Chưa chấm (1)'), findsOneWidget);
      await close(t);

      await open(t, 'Bài chưa hoàn thành');
      expect(inSheet('Trong đó 1 bài đã quá hạn'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Unmarked attendance is explained instead of shown as a dash', (
    t,
  ) async {
    await show(t, student(marked: false));
    expect(find.text('Chưa được điểm danh'), findsOneWidget);
    await open(t, 'Chuyên cần');
    expect(
      inSheetContaining(
        'Khóa học có 3 buổi điểm danh nhưng sinh viên chưa được điểm danh buổi nào',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tiles and sheets fit 320 px with large text', (t) async {
    await show(t, student(), width: 320, scale: 1.8);
    for (final tile in [
      'Tiến độ',
      'Chuyên cần',
      'Điểm TB',
      'Bài chưa hoàn thành',
    ]) {
      await t.ensureVisible(find.text(tile));
      await t.pumpAndSettle();
      await open(t, tile);
      await close(t);
    }
    expect(t.takeException(), isNull);
  });
}
