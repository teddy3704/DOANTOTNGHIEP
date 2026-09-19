import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/flutter_local_reminder_scheduler.dart';
import '../data/reminder_local_storage.dart';
import '../data/secure_local_reminder_repository.dart';
import '../domain/learning_reminder.dart';
import '../domain/reminder_repository.dart';
import '../domain/reminder_scheduler.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => FlutterLocalReminderScheduler(),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => SecureLocalReminderRepository(
    storage: FlutterSecureReminderLocalStorage(),
    scheduler: ref.watch(reminderSchedulerProvider),
  ),
);

final remindersForOwnerProvider = FutureProvider.autoDispose
    .family<List<LearningReminder>, String>(
      (ref, ownerId) =>
          ref.watch(reminderRepositoryProvider).listForOwner(ownerId),
    );
