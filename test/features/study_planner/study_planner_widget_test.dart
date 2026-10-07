import 'dart:async';
import 'package:dlu_lms_mobile/app/theme/app_theme.dart';

import 'package:dlu_lms_mobile/app/router/app_routes.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/core/widgets/content_skeleton.dart';
import 'package:dlu_lms_mobile/features/reminders/presentation/reminder_providers.dart';
import 'package:dlu_lms_mobile/features/study_planner/application/study_plan_coordinator.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_plan.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_planner_repository.dart';
import 'package:dlu_lms_mobile/features/study_planner/presentation/screens/student_today_screen.dart';
import 'package:dlu_lms_mobile/features/study_planner/presentation/screens/study_plan_screen.dart';
import 'package:dlu_lms_mobile/features/study_planner/presentation/study_planner_providers.dart';
import 'package:dlu_lms_mobile/features/study_planner/presentation/widgets/study_plan_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'study_planner_fakes.dart';

void viewport(WidgetTester tester, double width, {double keyboard = 0}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> mount(
  WidgetTester tester,
  MemoryStudyRepository repository, {
  MemoryStudyReminders? reminders,
  String location = AppRoutes.dashboard,
}) async {
  final localReminders = reminders ?? MemoryStudyReminders();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, _) => const Scaffold(body: StudentTodayScreen()),
      ),
      GoRoute(
        path: AppRoutes.studyPlan,
        builder: (_, _) => const Scaffold(body: StudyPlanScreen()),
      ),
      GoRoute(
        path: AppRoutes.courses,
        builder: (_, _) => const Scaffold(body: Text('Khóa học')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studyPlannerOwnerProvider.overrideWithValue('student-1'),
        studyPlannerClockProvider.overrideWithValue(() => testNow),
        studyPlannerRepositoryProvider.overrideWithValue(repository),
        reminderRepositoryProvider.overrideWithValue(localReminders),
        studyPlanCoordinatorProvider.overrideWith(
          (ref) => StudyPlanCoordinator(
            repository: repository,
            reminders: localReminders,
            ownerId: 'student-1',
            currentOwnerId: () => 'student-1',
            clock: () => testNow,
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
      ),
    ),
  );
}

Future<void> press(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('today reasons and plan card fit $width with text scale 1.3', (
      tester,
    ) async {
      viewport(tester, width);
      final repository = MemoryStudyRepository();
      await mount(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay nên học gì?'), findsOneWidget);
      await press(tester, 'Vì sao việc này được đề xuất?');
      expect(find.text('Chưa có bài nộp được ghi nhận.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await press(tester, 'Lên kế hoạch');
      expect(find.byType(StudyPlanEditor), findsOneWidget);
      final notes = tester.widget<TextField>(
        find.descendant(
          of: field('Mục tiêu cho buổi học'),
          matching: find.byType(TextField),
        ),
      );
      expect(notes.maxLength, 500);
      await press(tester, 'Lưu kế hoạch');
      expect(repository.creates, 1);
      expect(repository.items.single.status, StudyPlanStatus.planned);
      await press(tester, 'Mở kế hoạch học tập');
      expect(find.text('Kế hoạch của bạn'), findsOneWidget);
      await press(tester, 'Vì sao việc này được đề xuất?');
      expect(find.text('Bài tập sắp đến hạn.'), findsOneWidget);
      await tester.ensureVisible(find.text('Xóa khỏi kế hoạch'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('editor validation stays scrollable above keyboard at $width', (
      tester,
    ) async {
      viewport(tester, width, keyboard: 300);
      await mount(tester, MemoryStudyRepository());
      await tester.pumpAndSettle();
      await press(tester, 'Lên kế hoạch');
      await tester.ensureVisible(field('Thời lượng (phút)'));
      await tester.enterText(field('Thời lượng (phút)'), '4');
      await press(tester, 'Lưu kế hoạch');
      expect(find.text('Nhập số phút từ 5 đến 480.'), findsOneWidget);
      expect(find.byType(StudyPlanEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'create edit postpone handle and confirmed delete persist through screens',
    (tester) async {
      viewport(tester, 390);
      final repository = MemoryStudyRepository();
      final reminders = MemoryStudyReminders();
      await mount(tester, repository, reminders: reminders);
      await tester.pumpAndSettle();
      await press(tester, 'Lên kế hoạch');
      await tester.ensureVisible(field('Mục tiêu cho buổi học'));
      await tester.enterText(
        field('Mục tiêu cho buổi học'),
        'Đọc đề, lập dàn ý',
      );
      await press(tester, 'Lưu kế hoạch');
      expect(repository.items.single.notes, 'Đọc đề, lập dàn ý');
      expect(reminders.entries.single.assignmentId, 'study-plan:plan-1');
      await press(tester, 'Mở kế hoạch học tập');
      await press(tester, 'Điều chỉnh / nhắc giờ học');
      await tester.ensureVisible(field('Thời lượng (phút)'));
      await tester.enterText(field('Thời lượng (phút)'), '60');
      await press(tester, 'Lưu kế hoạch');
      expect(repository.items.single.estimatedMinutes, 60);
      expect(reminders.entries, hasLength(1));
      await press(tester, 'Dời sang ngày mai');
      await press(tester, 'Lưu kế hoạch');
      expect(
        repository.items.single.scheduledStartAt,
        DateTime(2030, 6, 4, 10),
      );
      expect(find.text('Lịch học còn trống'), findsOneWidget);
      await press(tester, 'Ngày mai');
      expect(find.text('Đọc đề, lập dàn ý'), findsOneWidget);
      await press(tester, 'Đánh dấu đã xử lý');
      expect(repository.items.single.status, StudyPlanStatus.handled);
      expect(reminders.entries, isEmpty);
      expect(find.text('Đã xử lý'), findsOneWidget);
      expect(find.text('Đánh dấu đã xử lý'), findsNothing);
      expect(
        find.textContaining('Trạng thái nộp bài và điểm vẫn do LMS'),
        findsOneWidget,
      );
      await press(tester, 'Xóa khỏi kế hoạch');
      await press(tester, 'Giữ lại');
      expect(repository.items, hasLength(1));
      await press(tester, 'Xóa khỏi kế hoạch');
      await press(tester, 'Xóa buổi học');
      expect(repository.items, isEmpty);
      expect(find.text('Lịch học còn trống'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reminder failure reports saved plan without losing authoritative write',
    (tester) async {
      final repository = MemoryStudyRepository();
      final reminders = MemoryStudyReminders()..failCreate = true;
      await mount(tester, repository, reminders: reminders);
      await tester.pumpAndSettle();
      await press(tester, 'Lên kế hoạch');
      await press(tester, 'Lưu kế hoạch');
      expect(repository.items, hasLength(1));
      expect(find.byType(StudyPlanEditor), findsNothing);
      expect(find.textContaining('Chưa bật được nhắc giờ học'), findsOneWidget);
    },
  );

  testWidgets(
    'loading empty and retry states are meaningful, without fallback recommendations',
    (tester) async {
      final repository = MemoryStudyRepository();
      final response = Completer<List<StudyRecommendation>>();
      repository.onRecommendations = () => response.future;
      await mount(tester, repository);
      await tester.pump();
      expect(find.byType(ContentSkeleton), findsWidgets);
      expect(find.text('Lên kế hoạch'), findsNothing);
      response.completeError(const NetworkFailure('unreachable'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Lên kế hoạch'), findsNothing);
      repository.onRecommendations = () async => [];
      await press(tester, 'Thử lại');
      expect(find.text('Bạn đã có khoảng trống để chủ động'), findsOneWidget);
      expect(find.text('Lên kế hoạch'), findsNothing);
      await press(tester, 'Mở kế hoạch học tập');
      expect(find.text('Lịch học còn trống'), findsOneWidget);
    },
  );

  testWidgets(
    'failed save keeps editor and entered values available for retry',
    (tester) async {
      final repository = MemoryStudyRepository()
        ..afterWrite = () async => throw const NetworkFailure('unreachable');
      await mount(tester, repository);
      await tester.pumpAndSettle();
      await press(tester, 'Lên kế hoạch');
      await tester.enterText(
        field('Mục tiêu cho buổi học'),
        'Mục tiêu cần giữ lại',
      );
      await press(tester, 'Lưu kế hoạch');
      expect(find.byType(StudyPlanEditor), findsOneWidget);
      expect(
        find.text('Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Mục tiêu cần giữ lại'), findsOneWidget);
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Lưu kế hoạch'),
      );
      expect(saveButton.onPressed, isNotNull);
    },
  );

  testWidgets('processing save prevents duplicate writes', (tester) async {
    final gate = Completer<void>();
    final repository = MemoryStudyRepository()..afterWrite = () => gate.future;
    await mount(tester, repository);
    await tester.pumpAndSettle();
    await press(tester, 'Lên kế hoạch');
    await press(tester, 'Lưu kế hoạch');
    expect(repository.creates, 1);
    final button = find.widgetWithText(FilledButton, 'Đang lưu…');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(button);
    await tester.pump();
    expect(repository.creates, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(StudyPlanEditor), findsNothing);
    expect(repository.items, hasLength(1));
  });
}
