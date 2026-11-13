import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_mobile_app/core/data_profile.dart';
import 'package:lms_mobile_app/core/date_time_text.dart';
import 'package:lms_mobile_app/core/gpa_simulator.dart';
import 'package:lms_mobile_app/models/portal.dart';
import 'package:lms_mobile_app/models/student_dashboard.dart';
import 'package:lms_mobile_app/services/api_session.dart';
import 'package:lms_mobile_app/widgets/course_card.dart';
import 'package:lms_mobile_app/widgets/learning_widgets.dart';

/// REAL-DATA-1: labels follow how the real export is computed; missing data shows an
/// explicit empty state, never a made-up number.
void main() {
  tearDown(DataProfile.reset);

  test('the login response decides the profile; sign-out returns to demo', () {
    final session = ApiSession();
    session.accept({
      'token': 'abc.def.ghi',
      'userId': '7',
      'role': 'STUDENT',
      'dataProfile': 'real',
    }, requestedRole: 'student');
    expect(DataProfile.isReal, isTrue);
    session.clear();
    expect(DataProfile.isReal, isFalse);
    session.accept({
      'token': 'abc.def.ghi',
      'userId': '7',
      'role': 'STUDENT',
    }, requestedRole: 'student');
    expect(DataProfile.current, 'demo');
  });

  test('real labels say hand-ins and graded activities, never access', () {
    DataProfile.set('real');
    expect(DataProfile.progress, 'Tiến độ (theo hoạt động có chấm điểm)');
    expect(DataProfile.attendance, 'Điểm chuyên cần (theo điểm danh trên LMS)');
    expect(
      DataProfile.activityChartTitle,
      'Số lượt nộp bài và làm bài kiểm tra theo ngày',
    );
    expect(DataProfile.portalNotLinked, 'Chưa có dữ liệu Portal cho MSSV này');
    expect(DataProfile.noAttendance, startsWith('Không có dữ liệu'));
    for (final label in [
      DataProfile.learningHealthIntro,
      DataProfile.activityChartHelp,
      DataProfile.activityCount(3),
    ]) {
      expect(label.contains('truy cập'), isFalse, reason: label);
    }
  });

  test('demo labels are unchanged', () {
    expect(DataProfile.progress, 'Tiến độ');
    expect(DataProfile.attendance, 'Chuyên cần');
    expect(DataProfile.activityChartTitle, 'Biểu đồ hoạt động');
    expect(DataProfile.activityCount(2), '2 hoạt động');
  });

  test('a user without a name shows the student code, no invented name', () {
    final codeOnly = StudentDashboard.fromJson({
      'userid': 7,
      'firstname': '1234567',
      'lastname': '',
      'email': '',
      'student_code': '1234567',
    });
    expect(codeOnly.fullName, '1234567');
    expect(codeOnly.email, isNull);
    final nothing = StudentDashboard.fromJson({
      'userid': 8,
      'firstname': '',
      'lastname': '',
    });
    expect(nothing.fullName, isNull);
  });

  testWidgets(
    'course card on real data: graded-activity progress, empty attendance stated',
    (tester) async {
      DataProfile.set('real');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              courseName: 'Môn A',
              progressPercentage: 40,
              completedTasks: 2,
              totalTasks: 5,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(
        find.text('Tiến độ (theo hoạt động có chấm điểm):'),
        findsOneWidget,
      );
      expect(find.text('Không có dữ liệu điểm danh trên LMS'), findsOneWidget);
      expect(find.textContaining('Chuyên cần:'), findsNothing);
    },
  );

  testWidgets('a code-only name gets a person icon, not the first digit', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UserAvatar('1234567'))),
    );
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  test('teacher texts say hand-ins on real and stay unchanged on demo', () {
    expect(DataProfile.tt('Không truy cập ≥7 ngày'), 'Không truy cập ≥7 ngày');
    DataProfile.set('real');
    for (final t in [
      'Không truy cập ≥7 ngày',
      'Không truy cập khóa học 7–13 ngày',
      'Chưa ghi nhận lượt truy cập nào trong 4 tuần qua.',
      '3/9 sinh viên có truy cập (33%)',
      'Chưa truy cập',
      'Chào SV 01, đã 9 ngày em chưa truy cập Môn A. ',
    ]) {
      expect(DataProfile.tt(t).contains('truy cập'), isFalse, reason: t);
    }
  });

  test('a quiz without a Moodle close time says so', () {
    expect(formatDeadline(null, quiz: true), 'Không đặt hạn đóng');
    expect(formatDeadline(null), 'Không có hạn');
    expect(activityDeadlineState(null, quiz: true), 'Không đặt hạn đóng');
  });

  test('an improvement retake replaces the old score and adds no credits', () {
    const sim = GpaSimulation(
      gpa4: 2.5,
      credits: 8,
      remainingCredits: 10,
      bands: [GradeBand('Khá', 2.5)],
      conversion: [
        LetterGrade('A', 8.5, 4),
        LetterGrade('B', 7.0, 3),
        LetterGrade('C', 5.5, 2),
        LetterGrade('D', 4.0, 1),
      ],
      courses: [],
    );
    final r = GpaSimulator.of(
      sim,
    ).simulate([(10, 'C')], improvements: [(4, 'B', 1.0)]);
    // (2.5×8 + (3−1)×4 + 2×10) / 18
    expect(r.projectedGpa!, closeTo((20 + 8 + 20) / 18, 1e-9));
    expect(r.countedCredits, 18);
    final lower = GpaSimulator.of(
      sim,
    ).simulate([], improvements: [(4, 'D', 2.0)]);
    expect(lower.projectedGpa!, closeTo(2.5, 1e-9));
  });
}
