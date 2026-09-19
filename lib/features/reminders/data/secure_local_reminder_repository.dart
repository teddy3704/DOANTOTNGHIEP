import 'dart:convert';
import 'dart:math';

import '../domain/learning_reminder.dart';
import '../domain/reminder_exception.dart';
import '../domain/reminder_repository.dart';
import '../domain/reminder_scheduler.dart';
import 'reminder_local_storage.dart';

typedef ReminderIdGenerator = String Function();
typedef ReminderClock = DateTime Function();

/// Locally persists learner-controlled reminder settings and coordinates the
/// platform scheduler. Moodle remains the authority for all academic data.
class SecureLocalReminderRepository implements ReminderRepository {
  SecureLocalReminderRepository({
    required this.storage,
    required this.scheduler,
    ReminderIdGenerator? idGenerator,
    ReminderClock? clock,
  }) : _idGenerator = idGenerator ?? _defaultId,
       _clock = clock ?? DateTime.now;

  static const _schemaVersion = 1;

  final ReminderLocalStorage storage;
  final ReminderScheduler scheduler;
  final ReminderIdGenerator _idGenerator;
  final ReminderClock _clock;
  Future<void> _pendingOperation = Future<void>.value();

  @override
  Future<LearningReminder> create({
    required String ownerId,
    required LearningReminderDraft draft,
  }) {
    return _runExclusive(() async {
      final normalizedOwnerId = _requiredOwnerId(ownerId);
      final reminders = await _readAll();
      final duplicate = reminders.any(
        (reminder) =>
            reminder.ownerId == normalizedOwnerId &&
            reminder.courseId == draft.courseId &&
            reminder.assignmentId == draft.assignmentId,
      );
      if (duplicate) {
        throw const ReminderConflictException(
          'Đã có nhắc việc cho bài học này.',
          code: 'REMINDER_ALREADY_EXISTS',
        );
      }

      final now = _clock().toUtc();
      _validateFutureSchedule(
        remindAt: draft.remindAt,
        isEnabled: draft.isEnabled,
        now: now,
      );
      final reminder = LearningReminder(
        id: _newId(reminders),
        ownerId: normalizedOwnerId,
        courseId: draft.courseId,
        assignmentId: draft.assignmentId,
        dueAt: draft.dueAt,
        remindAt: draft.remindAt,
        isEnabled: draft.isEnabled,
        createdAt: now,
        updatedAt: now,
      );
      await _applyMutation(
        previous: null,
        next: reminder,
        nextCollection: <LearningReminder>[...reminders, reminder],
      );
      return reminder;
    });
  }

  @override
  Future<void> delete({required String ownerId, required String reminderId}) {
    return _runExclusive(() async {
      final normalizedOwnerId = _requiredOwnerId(ownerId);
      final normalizedReminderId = _requiredReminderId(reminderId);
      final reminders = await _readAll();
      final existing = _findOwnedReminder(
        reminders,
        ownerId: normalizedOwnerId,
        reminderId: normalizedReminderId,
      );
      await _applyMutation(
        previous: existing,
        next: null,
        nextCollection: reminders
            .where((reminder) => reminder.id != existing.id)
            .toList(growable: false),
      );
    });
  }

  @override
  Future<List<LearningReminder>> listForOwner(String ownerId) {
    return _runExclusive(() async {
      final normalizedOwnerId = _requiredOwnerId(ownerId);
      final reminders = await _readAll();
      final owned =
          reminders
              .where((reminder) => reminder.ownerId == normalizedOwnerId)
              .toList(growable: false)
            ..sort((left, right) => left.remindAt.compareTo(right.remindAt));
      return List<LearningReminder>.unmodifiable(owned);
    });
  }

  @override
  Future<LearningReminder> setEnabled({
    required String ownerId,
    required String reminderId,
    required bool isEnabled,
  }) {
    return _runExclusive(() async {
      final normalizedOwnerId = _requiredOwnerId(ownerId);
      final normalizedReminderId = _requiredReminderId(reminderId);
      final reminders = await _readAll();
      final existing = _findOwnedReminder(
        reminders,
        ownerId: normalizedOwnerId,
        reminderId: normalizedReminderId,
      );
      final now = _clock().toUtc();
      final updated = existing.withUserSettings(
        isEnabled: isEnabled,
        updatedAt: now,
      );
      _validateFutureSchedule(
        remindAt: updated.remindAt,
        isEnabled: updated.isEnabled,
        now: now,
      );
      await _replaceReminder(reminders, previous: existing, next: updated);
      return updated;
    });
  }

  @override
  Future<LearningReminder> update({
    required String ownerId,
    required LearningReminder reminder,
  }) {
    return _runExclusive(() async {
      final normalizedOwnerId = _requiredOwnerId(ownerId);
      final reminders = await _readAll();
      final existing = _findOwnedReminder(
        reminders,
        ownerId: normalizedOwnerId,
        reminderId: reminder.id,
      );
      _validateUserOwnedUpdate(existing: existing, proposed: reminder);
      final now = _clock().toUtc();
      final updated = existing.withUserSettings(
        remindAt: reminder.remindAt,
        isEnabled: reminder.isEnabled,
        updatedAt: now,
      );
      _validateFutureSchedule(
        remindAt: updated.remindAt,
        isEnabled: updated.isEnabled,
        now: now,
      );
      await _replaceReminder(reminders, previous: existing, next: updated);
      return updated;
    });
  }

  Future<void> _replaceReminder(
    List<LearningReminder> reminders, {
    required LearningReminder previous,
    required LearningReminder next,
  }) {
    final nextCollection = reminders
        .map((reminder) => reminder.id == previous.id ? next : reminder)
        .toList(growable: false);
    return _applyMutation(
      previous: previous,
      next: next,
      nextCollection: nextCollection,
    );
  }

  Future<void> _applyMutation({
    required LearningReminder? previous,
    required LearningReminder? next,
    required List<LearningReminder> nextCollection,
  }) async {
    await _applySchedulerState(previous: previous, next: next);
    try {
      await _writeAll(nextCollection);
    } on ReminderPersistenceException {
      await _restoreSchedulerState(previous: previous, next: next);
      rethrow;
    }
  }

  Future<void> _applySchedulerState({
    required LearningReminder? previous,
    required LearningReminder? next,
  }) async {
    try {
      if (next?.isEnabled == true) {
        await scheduler.schedule(next!);
      } else if (previous?.isEnabled == true) {
        await scheduler.cancel(previous!.id);
      }
    } on ReminderException {
      rethrow;
    } catch (_) {
      throw const ReminderSchedulingException(
        'Không thể cập nhật lịch nhắc trên thiết bị.',
        code: 'REMINDER_SCHEDULER_FAILED',
      );
    }
  }

  Future<void> _restoreSchedulerState({
    required LearningReminder? previous,
    required LearningReminder? next,
  }) async {
    try {
      if (previous?.isEnabled == true) {
        await scheduler.schedule(previous!);
      } else if (next?.isEnabled == true) {
        await scheduler.cancel(next!.id);
      }
    } on ReminderException {
      rethrow;
    } catch (_) {
      throw const ReminderSchedulingException(
        'Không thể khôi phục lịch nhắc trên thiết bị.',
        code: 'REMINDER_SCHEDULER_ROLLBACK_FAILED',
      );
    }
  }

  Future<List<LearningReminder>> _readAll() async {
    final encoded = await _readEncoded();
    if (encoded == null || encoded.trim().isEmpty) {
      return <LearningReminder>[];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic> ||
          decoded['schemaVersion'] != _schemaVersion ||
          decoded['reminders'] is! List<dynamic>) {
        throw const ReminderPersistenceException(
          'Dữ liệu nhắc việc trên thiết bị không hợp lệ.',
          code: 'REMINDER_STORAGE_SCHEMA_INVALID',
        );
      }

      final reminders = <LearningReminder>[];
      final ids = <String>{};
      for (final rawReminder in decoded['reminders'] as List<dynamic>) {
        if (rawReminder is! Map<String, dynamic>) {
          throw const ReminderPersistenceException(
            'Dữ liệu nhắc việc trên thiết bị không hợp lệ.',
            code: 'REMINDER_STORAGE_RECORD_INVALID',
          );
        }
        final reminder = LearningReminder.fromJson(rawReminder);
        if (!ids.add(reminder.id)) {
          throw const ReminderPersistenceException(
            'Dữ liệu nhắc việc trên thiết bị không hợp lệ.',
            code: 'REMINDER_STORAGE_DUPLICATE_ID',
          );
        }
        reminders.add(reminder);
      }
      return reminders;
    } on ReminderPersistenceException {
      rethrow;
    } on ReminderException {
      throw const ReminderPersistenceException(
        'Dữ liệu nhắc việc trên thiết bị không hợp lệ.',
        code: 'REMINDER_STORAGE_RECORD_INVALID',
      );
    } on FormatException {
      throw const ReminderPersistenceException(
        'Dữ liệu nhắc việc trên thiết bị không hợp lệ.',
        code: 'REMINDER_STORAGE_JSON_INVALID',
      );
    }
  }

  Future<String?> _readEncoded() async {
    try {
      return await storage.read();
    } catch (_) {
      throw const ReminderPersistenceException(
        'Không thể đọc nhắc việc trên thiết bị.',
        code: 'REMINDER_STORAGE_READ_FAILED',
      );
    }
  }

  Future<void> _writeAll(List<LearningReminder> reminders) async {
    try {
      if (reminders.isEmpty) {
        await storage.delete();
        return;
      }
      final encoded = jsonEncode(<String, Object?>{
        'schemaVersion': _schemaVersion,
        'reminders': reminders.map((reminder) => reminder.toJson()).toList(),
      });
      await storage.write(encoded);
    } catch (_) {
      throw const ReminderPersistenceException(
        'Không thể lưu nhắc việc trên thiết bị.',
        code: 'REMINDER_STORAGE_WRITE_FAILED',
      );
    }
  }

  LearningReminder _findOwnedReminder(
    List<LearningReminder> reminders, {
    required String ownerId,
    required String reminderId,
  }) {
    LearningReminder? existing;
    for (final reminder in reminders) {
      if (reminder.id == reminderId) {
        existing = reminder;
        break;
      }
    }
    if (existing == null) {
      throw const ReminderNotFoundException(
        'Không tìm thấy nhắc việc.',
        code: 'REMINDER_NOT_FOUND',
      );
    }
    if (existing.ownerId != ownerId) {
      throw const ReminderAccessException(
        'Bạn không có quyền thay đổi nhắc việc này.',
        code: 'REMINDER_OWNER_MISMATCH',
      );
    }
    return existing;
  }

  void _validateUserOwnedUpdate({
    required LearningReminder existing,
    required LearningReminder proposed,
  }) {
    if (proposed.ownerId != existing.ownerId) {
      throw const ReminderAccessException(
        'Bạn không có quyền thay đổi nhắc việc này.',
        code: 'REMINDER_OWNER_MISMATCH',
      );
    }
    if (proposed.courseId != existing.courseId ||
        proposed.assignmentId != existing.assignmentId ||
        !proposed.dueAt.isAtSameMomentAs(existing.dueAt)) {
      throw const ReminderValidationException(
        'Liên kết học vụ của nhắc việc không thể thay đổi.',
        code: 'REMINDER_ACADEMIC_REFERENCE_IMMUTABLE',
      );
    }
  }

  void _validateFutureSchedule({
    required DateTime remindAt,
    required bool isEnabled,
    required DateTime now,
  }) {
    if (isEnabled && !remindAt.isAfter(now)) {
      throw const ReminderValidationException(
        'Thời điểm nhắc phải ở trong tương lai.',
        code: 'REMINDER_TIME_NOT_FUTURE',
      );
    }
  }

  String _newId(List<LearningReminder> reminders) {
    final id = _requiredReminderId(_idGenerator());
    if (reminders.any((reminder) => reminder.id == id)) {
      throw const ReminderConflictException(
        'Không thể tạo mã nhắc việc duy nhất.',
        code: 'REMINDER_ID_CONFLICT',
      );
    }
    return id;
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final operation = _pendingOperation.then((_) => action());
    _pendingOperation = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  static String _requiredOwnerId(String ownerId) {
    final normalized = ownerId.trim();
    if (normalized.isEmpty) {
      throw const ReminderValidationException(
        'Người dùng nhắc việc không hợp lệ.',
        code: 'REMINDER_OWNER_INVALID',
      );
    }
    return normalized;
  }

  static String _requiredReminderId(String reminderId) {
    final normalized = reminderId.trim();
    if (normalized.isEmpty) {
      throw const ReminderValidationException(
        'Mã nhắc việc không hợp lệ.',
        code: 'REMINDER_ID_INVALID',
      );
    }
    return normalized;
  }

  static String _defaultId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = Random.secure().nextInt(1 << 32).toRadixString(36);
    return 'reminder-$timestamp-$random';
  }
}
