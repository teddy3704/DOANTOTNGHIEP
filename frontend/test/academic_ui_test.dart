import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/student_dashboard.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_monitoring_screens.dart';
import 'package:lms_mobile_app/screens/student/student_dashboard_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';

import 'product_polish_test.dart' as fixtures;

const khanh = <String, dynamic>{
  'userid': 207,
  'fullname': 'Bui Khanh',
  'student_code': '2412007',
  'email': 'student07@example.edu.vn',
  'cohort_code': 'K48',
  'class_code': 'CTK48A',
  'major_name': 'Công nghệ thông tin',
  'progress': 28.57,
  'pending_tasks': 4,
  'overdue_tasks': 3,
  'days_since_last_activity': 32,
  'risk_level': 'HIGH',
  'needs_attention': true,
  'attendance': null,
  'average_grade': 0,
};
const giang = <String, dynamic>{
  'userid': 205,
  'fullname': 'Hoang Giang',
  'student_code': '2312005',
  'email': 'student05@example.edu.vn',
  'cohort_code': 'K47',
  'class_code': 'CTK47A',
  'major_name': 'Công nghệ thông tin',
  'progress': 100,
  'pending_tasks': 0,
  'overdue_tasks': 0,
  'risk_level': 'MEDIUM',
  'needs_attention': true,
};
ApiService service() {
  final api = testApi(
    client: MockClient((r) async {
      final path = r.url.path;
      final Object data = path.endsWith('/students')
          ? [khanh, giang]
          : path.endsWith('/207')
          ? {...khanh, 'tasks': []}
          : path.endsWith('/dashboard')
          ? giang
          : [];
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

Future<void> reveal(WidgetTester t, Finder finder) async {
  await t.scrollUntilVisible(
    finder,
    180,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await t.pumpAndSettle();
}

void main() {
  test(
    'Academic fields parse without changing identities; null and partial profiles stay clean',
    () {
      final s = MonitoredStudent.fromJson(khanh);
      expect(s.studentCode, '2412007');
      expect(s.code, '2412007');
      expect(s.cohortCode, 'K48');
      expect(s.classCode, 'CTK48A');
      expect(s.majorName, 'Công nghệ thông tin');
      expect(s.id, 207);
      expect(s.academicLabel, 'K48 • CTK48A');
      expect(s.identityLabel, 'MSSV: 2412007');
      final d = StudentDashboard.fromJson(giang);
      expect(d.identityLabel, 'MSSV: 2312005');
      expect(d.academicLabel, 'K47 • CTK47A');
      expect(d.majorName, 'Công nghệ thông tin');
      final missing = MonitoredStudent.fromJson({
        'userid': 999,
        'email': 'fallback@example.edu.vn',
        'cohort_code': ' ',
        'class_code': null,
      });
      expect(missing.studentCode, isNull);
      expect(missing.academicLabel, isNull);
      expect(missing.identityLabel, 'fallback@example.edu.vn');
      expect(
        MonitoredStudent.fromJson({
          'userid': 999,
          'class_code': 'CTK48A',
        }).academicLabel,
        'CTK48A',
      );
      expect(StudentDashboard.fromJson({}).academicLabel, isNull);
      expect(StudentDashboard.fromJson({}).studentCode, isNull);
    },
  );
  testWidgets(
    'Search MSSV/name and dynamic cohort filter compose without clearing search',
    (t) async {
      await fixtures.show(
        t,
        Scaffold(body: TeacherStudentsTab(api: service(), courseId: 13)),
        1,
      );
      expect(find.widgetWithText(ChoiceChip, 'K47'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'K48'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'K46'), findsNothing);
      await t.enterText(find.byType(TextField), '2412007');
      await t.pumpAndSettle();
      expect(find.byType(StudentMonitoringCard), findsOneWidget);
      expect(find.text('Bui Khanh'), findsOneWidget);
      await t.tap(find.widgetWithText(ChoiceChip, 'K47'));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        '2412007',
      );
      expect(find.byType(StudentMonitoringCard), findsNothing);
      await t.tap(find.widgetWithText(ChoiceChip, 'K48'));
      await t.enterText(find.byType(TextField), 'kHaNh');
      await t.pumpAndSettle();
      expect(find.byType(StudentMonitoringCard), findsOneWidget);
      await t.tap(find.widgetWithText(ChoiceChip, 'Quá hạn'));
      await t.pumpAndSettle();
      expect(find.byType(StudentMonitoringCard), findsOneWidget);
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'kHaNh',
      );
      expect(find.textContaining('null'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Missing student code falls back to email and no fabricated academic text',
    (t) async {
      await fixtures.show(
        t,
        Scaffold(
          body: StudentMonitoringCard(
            student: MonitoredStudent.fromJson({
              'userid': 999,
              'fullname': 'Sinh viên',
              'email': 'fallback@example.edu.vn',
            }),
            onOpen: () {},
          ),
        ),
        1.5,
      );
      expect(find.text('fallback@example.edu.vn'), findsOneWidget);
      expect(find.textContaining('MSSV:'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(find.text('K48'), findsNothing);
    },
  );
  testWidgets(
    'Student dashboard header uses academic API fields instead of repeated email',
    (t) async {
      await fixtures.show(
        t,
        StudentDashboardScreen(apiService: service()),
        1.5,
      );
      expect(find.text('Xin chào, Hoang Giang'), findsOneWidget);
      expect(find.text('MSSV: 2312005'), findsOneWidget);
      expect(find.text('K47 • CTK47A'), findsOneWidget);
      expect(find.text('student05@example.edu.vn'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Academic roster/detail fits $width at text scale $scale', (
        t,
      ) async {
        t.view.physicalSize = Size(width, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final api = service();
        await fixtures.show(
          t,
          Scaffold(body: TeacherStudentsTab(api: api, courseId: 13)),
          scale,
        );
        final cohort = find.widgetWithText(ChoiceChip, 'K48');
        await reveal(t, cohort);
        await t.tap(cohort);
        await t.pumpAndSettle();
        final card = find.widgetWithText(StudentMonitoringCard, 'Bui Khanh');
        await reveal(t, card);
        expect(find.text('MSSV: 2412007'), findsOneWidget);
        expect(find.text('K48 • CTK48A'), findsOneWidget);
        expect(find.text('Công nghệ thông tin'), findsOneWidget);
        expect(find.text('Hoang Giang'), findsNothing);
        expect(find.textContaining('null'), findsNothing);
        await t.tap(find.text('Bui Khanh'));
        await t.pumpAndSettle();
        await reveal(t, find.text('Ngành: Công nghệ thông tin'));
        expect(find.text('Khóa tuyển: K48'), findsOneWidget);
        expect(find.text('Lớp: CTK48A'), findsOneWidget);
        expect(find.text('Email: student07@example.edu.vn'), findsOneWidget);
        expect(find.text('student07@example.edu.vn'), findsNothing);
        await reveal(t, find.text('Chuyên cần'));
        // Missing attendance is said in words under its own label, never as "null".
        final attendance = find.ancestor(
          of: find.text('Chuyên cần'),
          matching: find.byType(Card),
        );
        expect(
          find.descendant(
            of: attendance,
            matching: find.text('Chưa có dữ liệu'),
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      });
    }
  }
}
