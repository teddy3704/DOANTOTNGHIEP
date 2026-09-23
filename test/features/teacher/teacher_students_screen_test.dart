import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlu_lms_mobile/app/theme/app_theme.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/teacher/domain/teacher_support_repository.dart';
import 'package:dlu_lms_mobile/features/teacher/presentation/teacher_students_screen.dart';

const student = StudentMonitoring(
  studentId: '201',
  courseId: '11',
  name: 'Sinh viên mẫu',
  progressPercent: 25,
  pendingTasks: 2,
  overdueTasks: 1,
  supportLevel: LearningSupportLevel.high,
);
Widget app(Future<List<StudentMonitoring>> Function() load, double width) =>
    ProviderScope(
      overrides: [teacherStudentsProvider('11').overrideWith((ref) => load())],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            textScaler: const TextScaler.linear(1.3),
          ),
          child: const TeacherStudentsScreen(courseId: '11'),
        ),
      ),
    );
void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('monitoring search, expand and empty state at $width/1.3', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(() async => [student], width));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sinh viên mẫu'));
      await tester.pumpAndSettle();
      expect(find.text('Tiến độ: 25%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('201'), findsNothing);
      await tester.enterText(find.byType(TextField), 'không khớp');
      await tester.pumpAndSettle();
      expect(find.text('Không có sinh viên phù hợp.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('loading, sanitized error and retry', (tester) async {
    final pending = Completer<List<StudentMonitoring>>();
    var attempts = 0;
    await tester.pumpWidget(
      app(() {
        attempts++;
        return attempts == 1 ? pending.future : Future.value([student]);
      }, 390),
    );
    await tester.pump();
    expect(find.text('Sinh viên mẫu'), findsNothing);
    pending.completeError(const ServerFailure('PRIVATE_SENTINEL'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PRIVATE_SENTINEL'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Sinh viên mẫu'), findsOneWidget);
    expect(attempts, 2);
  });
}
