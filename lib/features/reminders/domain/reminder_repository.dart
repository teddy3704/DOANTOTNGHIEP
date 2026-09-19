import 'learning_reminder.dart';

abstract interface class ReminderRepository {
  Future<List<LearningReminder>> listForOwner(String ownerId);

  Future<LearningReminder> create({
    required String ownerId,
    required LearningReminderDraft draft,
  });

  /// Updates only settings that belong to the learner, such as time/enabled.
  ///
  /// Implementations must reject any attempt to move a reminder to another
  /// owner or Moodle reference.
  Future<LearningReminder> update({
    required String ownerId,
    required LearningReminder reminder,
  });

  Future<LearningReminder> setEnabled({
    required String ownerId,
    required String reminderId,
    required bool isEnabled,
  });

  Future<void> delete({required String ownerId, required String reminderId});
}
