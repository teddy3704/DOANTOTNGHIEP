import 'reminder_exception.dart';

/// A narrow, app-owned reminder record.
///
/// It keeps only opaque owner/course/assignment identifiers and the timestamps
/// needed to schedule a local alert. It intentionally does not duplicate
/// Moodle content, grades, submissions, names, or credentials.
class LearningReminder {
  LearningReminder({
    required String id,
    required String ownerId,
    required String courseId,
    required String assignmentId,
    required DateTime dueAt,
    required DateTime remindAt,
    required this.isEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : id = _requiredValue(id, 'id'),
       ownerId = _requiredValue(ownerId, 'ownerId'),
       courseId = _requiredValue(courseId, 'courseId'),
       assignmentId = _requiredValue(assignmentId, 'assignmentId'),
       dueAt = dueAt.toUtc(),
       remindAt = remindAt.toUtc(),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    _validateReminderTime(remindAt: this.remindAt, dueAt: this.dueAt);
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw const ReminderValidationException(
        'Thời điểm cập nhật không hợp lệ.',
        code: 'REMINDER_UPDATED_BEFORE_CREATED',
      );
    }
  }

  final String id;
  final String ownerId;
  final String courseId;
  final String assignmentId;
  final DateTime dueAt;
  final DateTime remindAt;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Produces a record with only the controls a learner is allowed to change.
  ///
  /// The owner and Moodle references deliberately remain immutable here.
  LearningReminder withUserSettings({
    DateTime? remindAt,
    bool? isEnabled,
    required DateTime updatedAt,
  }) {
    return LearningReminder(
      id: id,
      ownerId: ownerId,
      courseId: courseId,
      assignmentId: assignmentId,
      dueAt: dueAt,
      remindAt: remindAt ?? this.remindAt,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'ownerId': ownerId,
    'courseId': courseId,
    'assignmentId': assignmentId,
    'dueAt': dueAt.toIso8601String(),
    'remindAt': remindAt.toIso8601String(),
    'isEnabled': isEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LearningReminder.fromJson(Map<String, dynamic> json) {
    return LearningReminder(
      id: _requiredJsonString(json, 'id'),
      ownerId: _requiredJsonString(json, 'ownerId'),
      courseId: _requiredJsonString(json, 'courseId'),
      assignmentId: _requiredJsonString(json, 'assignmentId'),
      dueAt: _requiredJsonDateTime(json, 'dueAt'),
      remindAt: _requiredJsonDateTime(json, 'remindAt'),
      isEnabled: _requiredJsonBool(json, 'isEnabled'),
      createdAt: _requiredJsonDateTime(json, 'createdAt'),
      updatedAt: _requiredJsonDateTime(json, 'updatedAt'),
    );
  }

  static void validateReminderTime({
    required DateTime remindAt,
    required DateTime dueAt,
  }) {
    _validateReminderTime(remindAt: remindAt.toUtc(), dueAt: dueAt.toUtc());
  }

  static String _requiredValue(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ReminderValidationException(
        'Trường nhắc việc không hợp lệ.',
        code: 'REMINDER_$field'.toUpperCase(),
      );
    }
    return normalized;
  }

  static void _validateReminderTime({
    required DateTime remindAt,
    required DateTime dueAt,
  }) {
    if (!remindAt.isBefore(dueAt)) {
      throw const ReminderValidationException(
        'Thời điểm nhắc phải trước hạn nộp.',
        code: 'REMINDER_TIME_NOT_BEFORE_DUE',
      );
    }
  }

  static String _requiredJsonString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw const ReminderValidationException(
        'Dữ liệu nhắc việc không hợp lệ.',
        code: 'REMINDER_JSON_STRING_INVALID',
      );
    }
    return value;
  }

  static bool _requiredJsonBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw const ReminderValidationException(
        'Dữ liệu nhắc việc không hợp lệ.',
        code: 'REMINDER_JSON_BOOL_INVALID',
      );
    }
    return value;
  }

  static DateTime _requiredJsonDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw const ReminderValidationException(
        'Dữ liệu nhắc việc không hợp lệ.',
        code: 'REMINDER_JSON_DATE_INVALID',
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const ReminderValidationException(
        'Dữ liệu nhắc việc không hợp lệ.',
        code: 'REMINDER_JSON_DATE_INVALID',
      );
    }
    return parsed;
  }
}

/// Input used to create a local reminder from an already-read assignment.
///
/// A caller provides only opaque Moodle references plus scheduling times. No
/// authoritative learning content is copied into local reminder storage.
class LearningReminderDraft {
  LearningReminderDraft({
    required String courseId,
    required String assignmentId,
    required DateTime dueAt,
    required DateTime remindAt,
    this.isEnabled = true,
  }) : courseId = LearningReminder._requiredValue(courseId, 'courseId'),
       assignmentId = LearningReminder._requiredValue(
         assignmentId,
         'assignmentId',
       ),
       dueAt = dueAt.toUtc(),
       remindAt = remindAt.toUtc() {
    LearningReminder.validateReminderTime(
      remindAt: this.remindAt,
      dueAt: this.dueAt,
    );
  }

  final String courseId;
  final String assignmentId;
  final DateTime dueAt;
  final DateTime remindAt;
  final bool isEnabled;
}
