// MOCK test state only. No LMS records or credentials are used.
import 'dart:async';
import 'package:dlu_lms_mobile/app/theme/app_theme.dart';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/core/widgets/content_skeleton.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dlu_lms_mobile/features/interventions/domain/intervention_models.dart';
import 'package:dlu_lms_mobile/features/interventions/presentation/intervention_inbox_screen.dart';
import 'package:dlu_lms_mobile/features/interventions/presentation/intervention_providers.dart';
import 'package:dlu_lms_mobile/features/interventions/presentation/student_attention_detail_screen.dart';
import 'package:dlu_lms_mobile/features/interventions/presentation/teacher_today_screen.dart';
import 'package:dlu_lms_mobile/features/interventions/presentation/widgets/intervention_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support_test_fixtures.dart';

Future<ProviderContainer> mount(
  WidgetTester tester,
  Widget screen, {
  RecordingInterventions? repository,
  MockSupportAuth? auth,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth ?? MockSupportAuth()),
      interventionRepositoryProvider.overrideWithValue(
        repository ?? RecordingInterventions(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).restoreSession();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => screen is InterventionEditorSheet
            ? Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: TextButton(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => screen,
                      ),
                      child: const Text('Mở ghi nhận'),
                    ),
                  ),
                ),
              )
            : Scaffold(body: screen),
      ),
      GoRoute(
        path: '/teacher/interventions',
        builder: (context, _) => InterventionInboxScreen(clock: () => now),
      ),
      GoRoute(
        path: '/teacher/attention/:courseId/:studentId',
        builder: (context, state) => StudentAttentionDetailScreen(
          courseId: state.pathParameters['courseId']!,
          studentId: state.pathParameters['studentId']!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.3)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  if (screen is InterventionEditorSheet) {
    await tester.tap(find.text('Mở ghi nhận'));
    await tester.pumpAndSettle();
  }
  return container;
}

Future<void> reach(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0]) {
    for (final entry in <String, Widget>{
      'today': TeacherTodayScreen(clock: () => now),
      'inbox': InterventionInboxScreen(clock: () => now),
      'detail': const StudentAttentionDetailScreen(
        courseId: 'course-test',
        studentId: 'student-test',
      ),
    }.entries) {
      testWidgets('${entry.key} fits ${width.toInt()}px at text scale 1.3', (
        tester,
      ) async {
        await mount(tester, entry.value, width: width);
        await tester.pumpAndSettle();
        if (entry.key == 'today') {
          final scheme = AppTheme.light().colorScheme;
          final title = tester.widget<Text>(
            find.textContaining('lượt cần chú ý'),
          );
          expect(title.style?.color, scheme.onPrimaryContainer);
          final a = scheme.onPrimaryContainer.computeLuminance();
          final b = scheme.primaryContainer.computeLuminance();
          final ratio = ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
        for (var i = 0; i < 8; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -350));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('inbox filters zero risk, preserves low signal and searches', (
    tester,
  ) async {
    final repo = RecordingInterventions()
      ..attentionRows = [
        AttentionStudent.fromJson({
          ...attentionJson(),
          'studentName': 'Có việc cần làm',
          'priority': 'low',
          'priorityScore': 5,
        }),
        AttentionStudent.fromJson({
          ...attentionJson(),
          'studentName': 'Không cần ưu tiên',
          'studentId': 'healthy',
          'priority': 'low',
          'priorityScore': 0,
        }),
      ];
    await mount(
      tester,
      InterventionInboxScreen(clock: () => now),
      repository: repo,
    );
    await tester.pumpAndSettle();
    expect(find.text('Có việc cần làm'), findsOneWidget);
    expect(find.text('Không cần ưu tiên'), findsNothing);
    await tester.enterText(find.byType(TextField), 'không có');
    await tester.pumpAndSettle();
    expect(find.text('Có việc cần làm'), findsNothing);
    expect(find.text('Không có sinh viên phù hợp'), findsOneWidget);
  });

  testWidgets('today links to details and reuses the active support record', (
    tester,
  ) async {
    await mount(tester, TeacherTodayScreen(clock: () => now));
    await tester.pumpAndSettle();
    await reach(tester, find.text('Xem chi tiết'));
    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('Quá trình hỗ trợ'), findsOneWidget);
    expect(find.text('Ghi nhận hỗ trợ'), findsNothing);
    await reach(tester, find.widgetWithText(FilledButton, 'Cập nhật theo dõi'));
    await tester.tap(find.widgetWithText(FilledButton, 'Cập nhật theo dõi'));
    await tester.pumpAndSettle();
    expect(find.byType(InterventionEditorSheet), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('resolved filter displays history without a follow-up action', (
    tester,
  ) async {
    final repo = RecordingInterventions()
      ..records = [record(status: InterventionStatus.resolved)];
    await mount(
      tester,
      InterventionInboxScreen(clock: () => now),
      repository: repo,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Đã khép lại'));
    await tester.pumpAndSettle();
    expect(find.text('Đã kiểm tra kế hoạch cùng sinh viên.'), findsOneWidget);
    expect(find.text('Cập nhật theo dõi'), findsNothing);
  });

  testWidgets('loading, failure retry and empty states are meaningful', (
    tester,
  ) async {
    final repo = RecordingInterventions()..attentionPending = Completer();
    await mount(tester, TeacherTodayScreen(clock: () => now), repository: repo);
    expect(find.byType(ContentSkeleton), findsOneWidget);
    repo.readError = const NetworkFailure('Internal network detail');
    repo.attentionPending!.completeError(repo.readError!);
    await tester.pumpAndSettle();
    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(find.textContaining('Internal network detail'), findsNothing);
    repo.readError = null;
    repo.attentionPending = null;
    repo.attentionRows = [];
    repo.records = [];
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repo.attentionCalls, greaterThan(1));
    expect(repo.recordCalls, greaterThan(1));
    await reach(tester, find.text('Chưa có lịch đến hạn'));
    expect(find.text('Chưa có lịch đến hạn'), findsOneWidget);
    await reach(tester, find.text('Chưa có lượt cần ưu tiên'));
    expect(find.text('Chưa có lượt cần ưu tiên'), findsOneWidget);
  });

  testWidgets(
    'new action validates note and prevents duplicate pending saves',
    (tester) async {
      final repo = RecordingInterventions()..pending = Completer();
      await mount(
        tester,
        InterventionEditorSheet(student: attention, clock: () => now),
        repository: repo,
        width: 320,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 500);
      await reach(tester, find.text('Lưu ghi nhận'));
      await tester.tap(find.text('Lưu ghi nhận'));
      await tester.pumpAndSettle();
      expect(repo.creates, 0);
      expect(find.text('Nhập ghi chú trước khi lưu.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Đã hướng dẫn lập kế hoạch học tập.',
      );
      await reach(tester, find.text('Lưu ghi nhận'));
      await tester.tap(find.text('Lưu ghi nhận'));
      await tester.pump();
      expect(repo.creates, 1);
      expect(repo.lastDraft!.studentId, attention.studentId);
      expect(repo.lastDraft!.followUpAt, DateTime(2030, 6, 4, 9));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      repo.pending!.complete(record());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('required note error clears while typing before the next save', (
    tester,
  ) async {
    final repo = RecordingInterventions();
    await mount(
      tester,
      InterventionEditorSheet(student: attention, clock: () => now),
      repository: repo,
    );
    await tester.pumpAndSettle();
    await reach(tester, find.text('Lưu ghi nhận'));
    await tester.tap(find.text('Lưu ghi nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập ghi chú trước khi lưu.'), findsOneWidget);
    expect(repo.creates, 0);

    await tester.enterText(
      find.byType(TextFormField),
      'Đã trao đổi về kế hoạch học tập tiếp theo.',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhập ghi chú trước khi lưu.'), findsNothing);
    expect(repo.creates, 0);

    await reach(tester, find.text('Lưu ghi nhận'));
    await tester.tap(find.text('Lưu ghi nhận'));
    await tester.pumpAndSettle();
    expect(repo.creates, 1);
    expect(repo.lastDraft!.note, 'Đã trao đổi về kế hoạch học tập tiếp theo.');
    expect(find.byType(InterventionEditorSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follow-up records resolution without another due date', (
    tester,
  ) async {
    final repo = RecordingInterventions();
    await mount(
      tester,
      InterventionEditorSheet(existing: record(), clock: () => now),
      repository: repo,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Đã trao đổi và kết thúc lượt hỗ trợ.',
    );
    await reach(tester, find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Theo dõi lại'), findsNothing);
    await reach(tester, find.text('Lưu ghi nhận'));
    await tester.tap(find.text('Lưu ghi nhận'));
    await tester.pumpAndSettle();
    expect(repo.followups, 1);
    expect(repo.lastId, 'support-test');
    expect(repo.lastFollowup!.outcomeStatus, InterventionStatus.resolved);
    expect(repo.lastFollowup!.nextFollowUpAt, isNull);
  });

  testWidgets('editor rejects a changed teacher owner before writes', (
    tester,
  ) async {
    final repo = RecordingInterventions();
    final auth = MockSupportAuth();
    final container = await mount(
      tester,
      InterventionEditorSheet(student: attention, clock: () => now),
      repository: repo,
      auth: auth,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ghi nhận thử nghiệm.');
    auth.userId = 'teacher-other';
    await container.read(authControllerProvider.notifier).restoreSession();
    await reach(tester, find.text('Lưu ghi nhận'));
    await tester.tap(find.text('Lưu ghi nhận'));
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(
      find.text('Phiên làm việc đã thay đổi. Vui lòng mở lại màn hình.'),
      findsOneWidget,
    );
  });
}
