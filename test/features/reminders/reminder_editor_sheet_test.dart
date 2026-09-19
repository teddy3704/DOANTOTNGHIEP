import 'dart:async';

import 'package:dlu_lms_mobile/features/reminders/domain/learning_reminder.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/reminder_repository.dart';
import 'package:dlu_lms_mobile/features/reminders/presentation/widgets/reminder_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _ownerId = 'student-sample-01';
const _courseId = 'course-sample-01';
const _assignmentId = 'assignment-sample-01';
const _assignmentName = 'Báo cáo học phần';

void main() {
  final clock = DateTime(2030, 6, 1, 9);
  final dueAt = DateTime(2030, 6, 20, 12);

  testWidgets('creates a reminder from a deterministic preset', (tester) async {
    final repository = _RecordingReminderRepository(clock: () => clock);

    await _pumpLauncher(
      tester,
      repository: repository,
      dueAt: dueAt,
      clock: () => clock,
    );
    await tester.tap(find.byKey(const Key('open-reminder-editor')));
    await tester.pumpAndSettle();

    expect(find.text('Tạo nhắc việc'), findsOneWidget);
    expect(find.text(_assignmentName), findsOneWidget);
    expect(find.text('3 ngày trước'), findsOneWidget);
    expect(find.text('1 ngày trước'), findsOneWidget);
    expect(find.text('1 giờ trước'), findsOneWidget);

    await tester.tap(find.text('1 ngày trước'));
    await tester.tap(find.text('Lưu nhắc việc'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.lastDraft?.courseId, _courseId);
    expect(repository.lastDraft?.assignmentId, _assignmentId);
    expect(repository.lastDraft?.remindAt, DateTime(2030, 6, 19, 12).toUtc());
    expect(repository.updateCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates only the selected reminder settings', (tester) async {
    final existing = _reminder(
      id: 'reminder-existing',
      dueAt: dueAt,
      remindAt: DateTime(2030, 6, 17, 12),
    );
    final repository = _RecordingReminderRepository(clock: () => clock);

    await _pumpLauncher(
      tester,
      repository: repository,
      dueAt: dueAt,
      existing: existing,
      clock: () => clock,
    );
    await tester.tap(find.byKey(const Key('open-reminder-editor')));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa nhắc việc'), findsOneWidget);
    await tester.tap(find.text('1 giờ trước'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 0);
    expect(repository.updateCalls, 1);
    expect(repository.lastUpdated?.id, existing.id);
    expect(repository.lastUpdated?.ownerId, _ownerId);
    expect(repository.lastUpdated?.courseId, _courseId);
    expect(repository.lastUpdated?.assignmentId, _assignmentId);
    expect(repository.lastUpdated?.dueAt, dueAt.toUtc());
    expect(repository.lastUpdated?.remindAt, DateTime(2030, 6, 20, 11).toUtc());
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects a reminder time that is no longer in the future', (
    tester,
  ) async {
    final existing = _reminder(
      id: 'reminder-stale',
      dueAt: dueAt,
      remindAt: DateTime(2030, 6, 2, 9),
    );
    final repository = _RecordingReminderRepository(
      clock: () => DateTime(2030, 6, 3, 9),
    );

    await _pumpLauncher(
      tester,
      repository: repository,
      dueAt: dueAt,
      existing: existing,
      clock: () => DateTime(2030, 6, 3, 9),
    );
    await tester.tap(find.byKey(const Key('open-reminder-editor')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();

    expect(find.text('Thời điểm nhắc cần ở trong tương lai.'), findsOneWidget);
    expect(repository.createCalls, 0);
    expect(repository.updateCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a real date picker for a custom reminder time', (
    tester,
  ) async {
    final repository = _RecordingReminderRepository(clock: () => clock);

    await _pumpLauncher(
      tester,
      repository: repository,
      dueAt: dueAt,
      clock: () => clock,
    );
    await tester.tap(find.byKey(const Key('open-reminder-editor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tùy chỉnh thời điểm'));
    await tester.pumpAndSettle();

    final picker = find.byType(DatePickerDialog);
    expect(picker, findsOneWidget);
    expect(find.text('Chọn ngày nhắc việc'), findsOneWidget);
    await tester.tap(find.descendant(of: picker, matching: find.text('Hủy')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prevents duplicate saves while a reminder is being stored', (
    tester,
  ) async {
    final pending = Completer<LearningReminder>();
    final repository = _RecordingReminderRepository(
      clock: () => clock,
      createCompleter: pending,
    );

    await _pumpLauncher(
      tester,
      repository: repository,
      dueAt: dueAt,
      clock: () => clock,
    );
    await tester.tap(find.byKey(const Key('open-reminder-editor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu nhắc việc'));
    await tester.pump();

    expect(find.text('Đang lưu…'), findsOneWidget);
    await tester.tap(find.text('Đang lưu…'), warnIfMissed: false);
    await tester.pump();
    expect(repository.createCalls, 1);

    pending.complete(
      _reminder(
        id: 'saved',
        dueAt: dueAt,
        remindAt: dueAt.subtract(const Duration(days: 3)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required ReminderRepository repository,
  required DateTime dueAt,
  required DateTime Function() clock,
  LearningReminder? existing,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => FilledButton(
                key: const Key('open-reminder-editor'),
                onPressed: () {
                  showReminderEditorSheet(
                    context,
                    repository: repository,
                    ownerId: _ownerId,
                    courseId: _courseId,
                    assignmentId: _assignmentId,
                    assignmentName: _assignmentName,
                    dueAt: dueAt,
                    existing: existing,
                    clock: clock,
                  );
                },
                child: const Text('Mở nhắc việc'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

LearningReminder _reminder({
  required String id,
  required DateTime dueAt,
  required DateTime remindAt,
}) {
  return LearningReminder(
    id: id,
    ownerId: _ownerId,
    courseId: _courseId,
    assignmentId: _assignmentId,
    dueAt: dueAt,
    remindAt: remindAt,
    isEnabled: true,
    createdAt: DateTime.utc(2030, 5, 1),
    updatedAt: DateTime.utc(2030, 5, 1),
  );
}

class _RecordingReminderRepository implements ReminderRepository {
  _RecordingReminderRepository({required this.clock, this.createCompleter});

  final DateTime Function() clock;
  final Completer<LearningReminder>? createCompleter;
  int createCalls = 0;
  int updateCalls = 0;
  LearningReminderDraft? lastDraft;
  LearningReminder? lastUpdated;

  @override
  Future<LearningReminder> create({
    required String ownerId,
    required LearningReminderDraft draft,
  }) async {
    createCalls += 1;
    lastDraft = draft;
    final pending = createCompleter;
    if (pending != null) return pending.future;
    return _reminder(
      id: 'created-$createCalls',
      dueAt: draft.dueAt,
      remindAt: draft.remindAt,
    );
  }

  @override
  Future<void> delete({
    required String ownerId,
    required String reminderId,
  }) async {}

  @override
  Future<List<LearningReminder>> listForOwner(String ownerId) async =>
      const <LearningReminder>[];

  @override
  Future<LearningReminder> setEnabled({
    required String ownerId,
    required String reminderId,
    required bool isEnabled,
  }) => throw UnimplementedError();

  @override
  Future<LearningReminder> update({
    required String ownerId,
    required LearningReminder reminder,
  }) async {
    updateCalls += 1;
    lastUpdated = reminder;
    return reminder;
  }
}
