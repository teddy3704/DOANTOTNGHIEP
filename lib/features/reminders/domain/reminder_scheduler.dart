import 'learning_reminder.dart';

/// Platform boundary for a user-approved local notification scheduler.
///
/// A concrete Android/iOS implementation belongs in a later platform layer.
/// Calling [schedule] for an existing reminder id must replace its prior local
/// schedule. This interface intentionally does not simulate scheduling.
abstract interface class ReminderScheduler {
  Future<void> schedule(LearningReminder reminder);

  Future<void> cancel(String reminderId);
}
