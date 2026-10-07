import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/learning_reminder.dart';
import 'package:dlu_lms_mobile/features/study_planner/application/study_plan_coordinator.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_planner_fakes.dart';

void main() {
  late MemoryStudyRepository repository;
  late MemoryStudyReminders reminders;
  late StudyPlanCoordinator coordinator;
  String? currentOwner;
  setUp(() {
    currentOwner = 'student-1';
    repository = MemoryStudyRepository();
    reminders = MemoryStudyReminders();
    coordinator = StudyPlanCoordinator(
      repository: repository,
      reminders: reminders,
      ownerId: 'student-1',
      currentOwnerId: () => currentOwner,
      clock: () => testNow,
    );
  });

  Future<StudyPlanResult> save({
    bool remind = true,
    StudyPlanItem? existing,
    DateTime? start,
    int minutes = 45,
  }) => coordinator.save(
    assignmentId: 'assignment-1',
    scheduledStartAt: start ?? testNow.add(const Duration(hours: 1)),
    estimatedMinutes: minutes,
    notes: 'Đọc đề và lập dàn ý',
    remind: remind,
    existing: existing,
  );

  test(
    'create persists plan and schedules a namespaced owner reminder',
    () async {
      final result = await save();
      expect(repository.creates, 1);
      expect(repository.items.single.notes, 'Đọc đề và lập dàn ý');
      expect(result.reminderWarning, isNull);
      expect(reminders.entries.single.ownerId, 'student-1');
      expect(reminders.entries.single.assignmentId, 'study-plan:plan-1');
      expect(
        reminders.entries.single.remindAt,
        result.item!.scheduledStartAt.toUtc(),
      );
      expect(
        reminders.entries.single.dueAt,
        result.item!.scheduledEndAt.toUtc(),
      );
    },
  );

  test('postpone updates original item, replacing only its reminder', () async {
    final original = (await save()).item!;
    await reminders.create(
      ownerId: 'student-1',
      draft: LearningReminderDraft(
        courseId: 'course-1',
        assignmentId: 'assignment-1',
        dueAt: testNow.add(const Duration(days: 2)),
        remindAt: testNow.add(const Duration(days: 1)),
      ),
    );
    final postponed = testNow.add(const Duration(days: 1));
    await save(existing: original, start: postponed, minutes: 60);
    expect(repository.items.single.id, original.id);
    expect(repository.items.single.scheduledStartAt, postponed);
    expect(reminders.entries.length, 2);
    expect(
      reminders.entries
          .singleWhere((entry) => entry.assignmentId == 'assignment-1')
          .remindAt,
      testNow.add(const Duration(days: 1)).toUtc(),
    );
    expect(
      reminders.entries
          .singleWhere((entry) => entry.assignmentId == 'study-plan:plan-1')
          .remindAt,
      postponed.toUtc(),
    );
  });

  test(
    'handled and delete cancel plan reminders without academic writes',
    () async {
      final item = (await save()).item!;
      final handled = await coordinator.markHandled(item);
      expect(handled.item!.status, StudyPlanStatus.handled);
      expect(reminders.entries, isEmpty);
      await coordinator.remove(handled.item!);
      expect(repository.items, isEmpty);
      expect(repository.deletes, 1);
    },
  );

  test('turning reminder off cancels old scheduling', () async {
    final item = (await save()).item!;
    expect(await coordinator.reminderEnabled(item), isTrue);
    await save(existing: item, remind: false);
    expect(await coordinator.reminderEnabled(item), isFalse);
  });

  test(
    'notification failure reports saved plan, not failed persistence',
    () async {
      reminders.failCreate = true;
      final result = await save();
      expect(repository.items.length, 1);
      expect(result.item, isNotNull);
      expect(result.reminderWarning, contains('Đã lưu kế hoạch'));
    },
  );

  test(
    'failed cancellation is surfaced and does not add duplicate reminder',
    () async {
      final item = (await save()).item!;
      reminders.failDelete = true;
      final result = await save(
        existing: item,
        start: testNow.add(const Duration(days: 1)),
      );
      expect(result.reminderWarning, contains('chưa hủy được'));
      expect(reminders.creates, 1);
    },
  );

  test('past schedules and invalid duration do not write', () async {
    await expectLater(save(start: testNow), throwsA(isA<ValidationFailure>()));
    await expectLater(save(minutes: 481), throwsA(isA<ValidationFailure>()));
    await expectLater(save(minutes: 4), throwsA(isA<ValidationFailure>()));
    expect(repository.creates, 0);
  });

  test('changed session rejects all writes', () async {
    currentOwner = 'student-2';
    await expectLater(save(), throwsA(isA<AuthenticationFailure>()));
    await expectLater(
      coordinator.markHandled(planItem()),
      throwsA(isA<AuthenticationFailure>()),
    );
    await expectLater(
      coordinator.remove(planItem()),
      throwsA(isA<AuthenticationFailure>()),
    );
    expect(repository.creates + repository.updates + repository.deletes, 0);
  });

  test(
    'session switched during remote write never schedules old owner reminder',
    () async {
      repository.afterWrite = () async {
        currentOwner = 'student-2';
      };
      await expectLater(save(), throwsA(isA<AuthenticationFailure>()));
      expect(reminders.entries, isEmpty);
    },
  );

  test('period filters are calendar ranges and chronologically sorted', () {
    final morning = planItem(
      id: 'early',
      start: testNow.subtract(const Duration(hours: 1)),
    );
    final later = planItem(id: 'later');
    final tomorrow = planItem(
      id: 'tomorrow',
      start: testNow.add(const Duration(days: 1)),
    );
    final nextWeek = planItem(
      id: 'next-week',
      start: testNow.add(const Duration(days: 7)),
    );
    final items = [nextWeek, tomorrow, later, morning];
    expect(
      filterStudyPlan(
        items,
        StudyPlanPeriod.today,
        testNow,
      ).map((item) => item.id),
      ['early', 'later'],
    );
    expect(
      filterStudyPlan(
        items,
        StudyPlanPeriod.tomorrow,
        testNow,
      ).map((item) => item.id),
      ['tomorrow'],
    );
    expect(
      filterStudyPlan(
        items,
        StudyPlanPeriod.week,
        testNow,
      ).map((item) => item.id),
      ['early', 'later', 'tomorrow'],
    );
  });
}
