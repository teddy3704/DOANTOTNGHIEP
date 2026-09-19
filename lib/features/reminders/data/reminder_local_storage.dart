import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value boundary for app-owned reminder metadata.
///
/// The stored value is deliberately limited to local reminder IDs and timing
/// information; it never contains Moodle credentials or academic content.
abstract interface class ReminderLocalStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class FlutterSecureReminderLocalStorage implements ReminderLocalStorage {
  FlutterSecureReminderLocalStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'student_support_learning_reminders_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete() => _storage.delete(key: _storageKey);

  @override
  Future<String?> read() => _storage.read(key: _storageKey);

  @override
  Future<void> write(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Storage value cannot be empty.',
      );
    }
    return _storage.write(key: _storageKey, value: value);
  }
}
