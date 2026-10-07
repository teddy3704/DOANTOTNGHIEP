import '../../../core/errors/app_failure.dart';
import '../../reminders/domain/learning_reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../domain/study_plan.dart';
import '../domain/study_planner_repository.dart';

class StudyPlanResult {
  const StudyPlanResult({this.item, this.reminderWarning});
  final StudyPlanItem? item;
  final String? reminderWarning;
}

/// Coordinates an authoritative plan write with an optional device reminder.
/// Notification failure never claims the persisted plan itself was not saved.
class StudyPlanCoordinator {
  StudyPlanCoordinator({
    required this.repository,
    required this.reminders,
    required this.ownerId,
    required this.currentOwnerId,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final StudyPlannerRepository repository;
  final ReminderRepository reminders;
  final String ownerId;
  final String? Function() currentOwnerId;
  final DateTime Function() clock;

  void _requireOwner() {
    if (ownerId.isEmpty || currentOwnerId() != ownerId) {
      throw const AuthenticationFailure(
        'Phiên làm việc đã thay đổi. Vui lòng mở lại kế hoạch.',
        code: 'STUDY_PLAN_SESSION_CHANGED',
      );
    }
  }

  static String? validateSchedule(DateTime start, int minutes, DateTime now) {
    if (!start.isAfter(now)) return 'Hãy chọn giờ học trong tương lai.';
    if (minutes < 5 || minutes > 480) {
      return 'Thời lượng cần từ 5 đến 480 phút.';
    }
    return null;
  }

  Future<StudyPlanResult> save({
    required String assignmentId,
    required DateTime scheduledStartAt,
    required int estimatedMinutes,
    required String notes,
    required bool remind,
    StudyPlanItem? existing,
  }) async {
    _requireOwner();
    final error = validateSchedule(scheduledStartAt, estimatedMinutes, clock());
    if (error != null) throw ValidationFailure(error);
    final item = existing == null
        ? await repository.createItem(
            assignmentId: assignmentId,
            scheduledStartAt: scheduledStartAt,
            estimatedMinutes: estimatedMinutes,
            notes: notes,
          )
        : await repository.updateItem(
            existing.id,
            scheduledStartAt: scheduledStartAt,
            estimatedMinutes: estimatedMinutes,
            notes: notes,
          );
    _requireOwner();
    return StudyPlanResult(
      item: item,
      reminderWarning: await _syncReminder(item, enabled: remind),
    );
  }

  Future<StudyPlanResult> markHandled(StudyPlanItem item) async {
    _requireOwner();
    final updated = await repository.updateItem(
      item.id,
      status: StudyPlanStatus.handled,
    );
    _requireOwner();
    return StudyPlanResult(
      item: updated,
      reminderWarning: await _syncReminder(updated, enabled: false),
    );
  }

  Future<StudyPlanResult> remove(StudyPlanItem item) async {
    _requireOwner();
    await repository.deleteItem(item.id);
    _requireOwner();
    return StudyPlanResult(reminderWarning: await _cancelReminder(item));
  }

  Future<bool> reminderEnabled(StudyPlanItem item) async {
    _requireOwner();
    final entries = await reminders.listForOwner(ownerId);
    _requireOwner();
    return entries.any(
      (entry) => entry.assignmentId == _reference(item) && entry.isEnabled,
    );
  }

  // This opaque local reference is deliberately not a Moodle assignment id.
  // It prevents a study session from overwriting an assignment deadline alert.
  String _reference(StudyPlanItem item) => 'study-plan:${item.id}';

  Future<String?> _cancelReminder(StudyPlanItem item) async {
    try {
      final entries = await reminders.listForOwner(ownerId);
      _requireOwner();
      for (final entry in entries.where(
        (entry) => entry.assignmentId == _reference(item),
      )) {
        _requireOwner();
        await reminders.delete(ownerId: ownerId, reminderId: entry.id);
        _requireOwner();
      }
      return null;
    } on AuthenticationFailure {
      rethrow;
    } on Object {
      return 'Kế hoạch đã cập nhật nhưng chưa hủy được nhắc giờ học. Hãy kiểm tra mục Nhắc việc.';
    }
  }

  Future<String?> _syncReminder(
    StudyPlanItem item, {
    required bool enabled,
  }) async {
    final cancellationWarning = await _cancelReminder(item);
    if (cancellationWarning != null) return cancellationWarning;
    if (!enabled || item.status == StudyPlanStatus.handled) return null;
    try {
      _requireOwner();
      await reminders.create(
        ownerId: ownerId,
        draft: LearningReminderDraft(
          courseId: item.courseId,
          assignmentId: _reference(item),
          dueAt: item.scheduledEndAt,
          remindAt: item.scheduledStartAt,
        ),
      );
      _requireOwner();
      return null;
    } on AuthenticationFailure {
      rethrow;
    } on Object {
      return 'Đã lưu kế hoạch. Chưa bật được nhắc giờ học trên thiết bị; hãy kiểm tra quyền thông báo và thử lại.';
    }
  }
}
