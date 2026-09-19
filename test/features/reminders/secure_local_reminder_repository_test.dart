import 'dart:convert';

import 'package:dlu_lms_mobile/features/reminders/data/reminder_local_storage.dart';
import 'package:dlu_lms_mobile/features/reminders/data/secure_local_reminder_repository.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/learning_reminder.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/reminder_exception.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ownerOne = 'student-one';
  const ownerTwo = 'student-two';
  final dueAt = DateTime.utc(2026, 8, 22, 10);
  final firstReminderAt = DateTime.utc(2026, 8, 22, 8);
  final secondReminderAt = DateTime.utc(2026, 8, 22, 9);

  test('creates, schedules, and securely persists a local reminder', () async {
    final storage = _MemoryReminderLocalStorage();
    final scheduler = _RecordingReminderScheduler();
    final repository = _repository(storage: storage, scheduler: scheduler);

    final created = await repository.create(
      ownerId: ownerOne,
      draft: LearningReminderDraft(
        courseId: 'course-a',
        assignmentId: 'assignment-a',
        dueAt: dueAt,
        remindAt: firstReminderAt,
      ),
    );

    expect(created.ownerId, ownerOne);
    expect(created.courseId, 'course-a');
    expect(created.assignmentId, 'assignment-a');
    expect(created.isEnabled, isTrue);
    expect(scheduler.scheduled[created.id]?.remindAt, firstReminderAt);

    final payload = jsonDecode(storage.value!) as Map<String, dynamic>;
    final storedReminder =
        (payload['reminders'] as List<dynamic>).single as Map<String, dynamic>;
    expect(
      storedReminder.keys,
      containsAll(<String>[
        'id',
        'ownerId',
        'courseId',
        'assignmentId',
        'dueAt',
        'remindAt',
        'isEnabled',
        'createdAt',
        'updatedAt',
      ]),
    );
    expect(storedReminder.containsKey('title'), isFalse);
    expect(storedReminder.containsKey('password'), isFalse);

    final restoredRepository = _repository(
      storage: storage,
      scheduler: _RecordingReminderScheduler(),
    );
    final restored = await restoredRepository.listForOwner(ownerOne);
    expect(restored, hasLength(1));
    expect(restored.single.id, created.id);
    expect(restored.single.remindAt, firstReminderAt);
  });

  test('updates only learner-controlled timing and enabled settings', () async {
    final storage = _MemoryReminderLocalStorage();
    final scheduler = _RecordingReminderScheduler();
    final repository = _repository(storage: storage, scheduler: scheduler);
    final created = await repository.create(
      ownerId: ownerOne,
      draft: LearningReminderDraft(
        courseId: 'course-a',
        assignmentId: 'assignment-a',
        dueAt: dueAt,
        remindAt: firstReminderAt,
      ),
    );

    final updated = await repository.update(
      ownerId: ownerOne,
      reminder: created.withUserSettings(
        remindAt: secondReminderAt,
        updatedAt: DateTime.utc(2026, 8, 20),
      ),
    );

    expect(updated.id, created.id);
    expect(updated.ownerId, ownerOne);
    expect(updated.courseId, created.courseId);
    expect(updated.assignmentId, created.assignmentId);
    expect(updated.dueAt, created.dueAt);
    expect(updated.remindAt, secondReminderAt);
    expect(scheduler.scheduleCalls, <String>[created.id, created.id]);

    final persisted = await _repository(
      storage: storage,
      scheduler: _RecordingReminderScheduler(),
    ).listForOwner(ownerOne);
    expect(persisted.single.remindAt, secondReminderAt);
  });

  test(
    'enables and disables a reminder while coordinating its scheduler',
    () async {
      final storage = _MemoryReminderLocalStorage();
      final scheduler = _RecordingReminderScheduler();
      final repository = _repository(storage: storage, scheduler: scheduler);
      final created = await repository.create(
        ownerId: ownerOne,
        draft: LearningReminderDraft(
          courseId: 'course-a',
          assignmentId: 'assignment-a',
          dueAt: dueAt,
          remindAt: firstReminderAt,
          isEnabled: false,
        ),
      );

      expect(scheduler.scheduleCalls, isEmpty);
      final enabled = await repository.setEnabled(
        ownerId: ownerOne,
        reminderId: created.id,
        isEnabled: true,
      );
      final disabled = await repository.setEnabled(
        ownerId: ownerOne,
        reminderId: created.id,
        isEnabled: false,
      );

      expect(enabled.isEnabled, isTrue);
      expect(disabled.isEnabled, isFalse);
      expect(scheduler.scheduleCalls, <String>[created.id]);
      expect(scheduler.cancelCalls, <String>[created.id]);
      expect(scheduler.scheduled, isEmpty);
    },
  );

  test(
    'deletes an owned reminder, cancels it, and removes stored state',
    () async {
      final storage = _MemoryReminderLocalStorage();
      final scheduler = _RecordingReminderScheduler();
      final repository = _repository(storage: storage, scheduler: scheduler);
      final created = await repository.create(
        ownerId: ownerOne,
        draft: LearningReminderDraft(
          courseId: 'course-a',
          assignmentId: 'assignment-a',
          dueAt: dueAt,
          remindAt: firstReminderAt,
        ),
      );

      await repository.delete(ownerId: ownerOne, reminderId: created.id);

      expect(scheduler.cancelCalls, <String>[created.id]);
      expect(scheduler.scheduled, isEmpty);
      expect(storage.value, isNull);
      expect(await repository.listForOwner(ownerOne), isEmpty);
    },
  );

  test('restores the scheduler state when local persistence fails', () async {
    final storage = _MemoryReminderLocalStorage();
    final scheduler = _RecordingReminderScheduler();
    final repository = _repository(storage: storage, scheduler: scheduler);
    final created = await repository.create(
      ownerId: ownerOne,
      draft: LearningReminderDraft(
        courseId: 'course-a',
        assignmentId: 'assignment-a',
        dueAt: dueAt,
        remindAt: firstReminderAt,
      ),
    );
    storage.failWrites = true;

    await expectLater(
      repository.setEnabled(
        ownerId: ownerOne,
        reminderId: created.id,
        isEnabled: false,
      ),
      throwsA(isA<ReminderPersistenceException>()),
    );

    expect(scheduler.cancelCalls, <String>[created.id]);
    expect(scheduler.scheduleCalls, <String>[created.id, created.id]);
    expect(scheduler.scheduled[created.id]?.isEnabled, isTrue);
  });

  test('isolates reminders by owner and rejects cross-owner changes', () async {
    final storage = _MemoryReminderLocalStorage();
    final scheduler = _RecordingReminderScheduler();
    final repository = _repository(storage: storage, scheduler: scheduler);
    final created = await repository.create(
      ownerId: ownerOne,
      draft: LearningReminderDraft(
        courseId: 'course-a',
        assignmentId: 'assignment-a',
        dueAt: dueAt,
        remindAt: firstReminderAt,
      ),
    );

    expect(await repository.listForOwner(ownerTwo), isEmpty);
    await expectLater(
      repository.setEnabled(
        ownerId: ownerTwo,
        reminderId: created.id,
        isEnabled: false,
      ),
      throwsA(
        isA<ReminderAccessException>().having(
          (failure) => failure.code,
          'code',
          'REMINDER_OWNER_MISMATCH',
        ),
      ),
    );
    await expectLater(
      repository.delete(ownerId: ownerTwo, reminderId: created.id),
      throwsA(isA<ReminderAccessException>()),
    );

    expect((await repository.listForOwner(ownerOne)).single.id, created.id);
    expect(scheduler.cancelCalls, isEmpty);
  });

  test('rejects a time that does not precede the assignment due time', () {
    expect(
      () => LearningReminderDraft(
        courseId: 'course-a',
        assignmentId: 'assignment-a',
        dueAt: dueAt,
        remindAt: dueAt,
      ),
      throwsA(
        isA<ReminderValidationException>().having(
          (failure) => failure.code,
          'code',
          'REMINDER_TIME_NOT_BEFORE_DUE',
        ),
      ),
    );
  });

  test('rejects enabled creates and updates scheduled in the past', () async {
    final repository = _repository(
      storage: _MemoryReminderLocalStorage(),
      scheduler: _RecordingReminderScheduler(),
    );

    await expectLater(
      repository.create(
        ownerId: ownerOne,
        draft: LearningReminderDraft(
          courseId: 'course-a',
          assignmentId: 'assignment-a',
          dueAt: dueAt,
          remindAt: DateTime.utc(2026, 8, 18, 8),
        ),
      ),
      throwsA(
        isA<ReminderValidationException>().having(
          (failure) => failure.code,
          'code',
          'REMINDER_TIME_NOT_FUTURE',
        ),
      ),
    );

    final created = await repository.create(
      ownerId: ownerOne,
      draft: LearningReminderDraft(
        courseId: 'course-a',
        assignmentId: 'assignment-a',
        dueAt: dueAt,
        remindAt: firstReminderAt,
      ),
    );
    final staleUpdate = created.withUserSettings(
      remindAt: DateTime.utc(2026, 8, 18, 9),
      updatedAt: DateTime.utc(2026, 8, 18, 9),
    );

    await expectLater(
      repository.update(ownerId: ownerOne, reminder: staleUpdate),
      throwsA(
        isA<ReminderValidationException>().having(
          (failure) => failure.code,
          'code',
          'REMINDER_TIME_NOT_FUTURE',
        ),
      ),
    );
  });

  test(
    'rejects changes to Moodle references from a learner-owned update',
    () async {
      final storage = _MemoryReminderLocalStorage();
      final repository = _repository(
        storage: storage,
        scheduler: _RecordingReminderScheduler(),
      );
      final created = await repository.create(
        ownerId: ownerOne,
        draft: LearningReminderDraft(
          courseId: 'course-a',
          assignmentId: 'assignment-a',
          dueAt: dueAt,
          remindAt: firstReminderAt,
        ),
      );
      final modifiedReference = LearningReminder(
        id: created.id,
        ownerId: created.ownerId,
        courseId: created.courseId,
        assignmentId: 'assignment-b',
        dueAt: created.dueAt,
        remindAt: secondReminderAt,
        isEnabled: created.isEnabled,
        createdAt: created.createdAt,
        updatedAt: DateTime.utc(2026, 8, 20),
      );

      await expectLater(
        repository.update(ownerId: ownerOne, reminder: modifiedReference),
        throwsA(
          isA<ReminderValidationException>().having(
            (failure) => failure.code,
            'code',
            'REMINDER_ACADEMIC_REFERENCE_IMMUTABLE',
          ),
        ),
      );
    },
  );
}

SecureLocalReminderRepository _repository({
  required ReminderLocalStorage storage,
  required ReminderScheduler scheduler,
}) {
  var nextId = 0;
  return SecureLocalReminderRepository(
    storage: storage,
    scheduler: scheduler,
    clock: () => DateTime.utc(2026, 8, 18, 9),
    idGenerator: () => 'reminder-${++nextId}',
  );
}

class _MemoryReminderLocalStorage implements ReminderLocalStorage {
  String? value;
  bool failWrites = false;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String nextValue) async {
    if (failWrites) throw StateError('write failed');
    value = nextValue;
  }
}

class _RecordingReminderScheduler implements ReminderScheduler {
  final Map<String, LearningReminder> scheduled = <String, LearningReminder>{};
  final List<String> scheduleCalls = <String>[];
  final List<String> cancelCalls = <String>[];

  @override
  Future<void> cancel(String reminderId) async {
    cancelCalls.add(reminderId);
    scheduled.remove(reminderId);
  }

  @override
  Future<void> schedule(LearningReminder reminder) async {
    scheduleCalls.add(reminder.id);
    scheduled[reminder.id] = reminder;
  }
}
