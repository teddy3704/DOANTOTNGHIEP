/// Typed failures for the app-owned reminder boundary.
///
/// These failures deliberately contain no academic content, credentials, or
/// storage payloads. Presentation code can map them to a concise local error
/// message without exposing implementation details.
sealed class ReminderException implements Exception {
  const ReminderException(this.message, {required this.code});

  final String message;
  final String code;

  @override
  String toString() => '$runtimeType(code: $code)';
}

final class ReminderValidationException extends ReminderException {
  const ReminderValidationException(super.message, {required super.code});
}

final class ReminderAccessException extends ReminderException {
  const ReminderAccessException(super.message, {required super.code});
}

final class ReminderNotFoundException extends ReminderException {
  const ReminderNotFoundException(super.message, {required super.code});
}

final class ReminderConflictException extends ReminderException {
  const ReminderConflictException(super.message, {required super.code});
}

final class ReminderPersistenceException extends ReminderException {
  const ReminderPersistenceException(super.message, {required super.code});
}

final class ReminderSchedulingException extends ReminderException {
  const ReminderSchedulingException(super.message, {required super.code});
}
