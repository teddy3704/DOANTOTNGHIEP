import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../domain/learning_reminder.dart';
import '../domain/reminder_exception.dart';
import '../domain/reminder_scheduler.dart';

/// Narrow boundary around the notification plugin so reminder scheduling is
/// testable without pretending a device notification was delivered.
abstract interface class LocalNotificationGateway {
  Future<bool> requestPermission();

  Future<void> schedule({
    required int notificationId,
    required DateTime scheduledAt,
    required String title,
    required String body,
  });

  Future<void> cancel(int notificationId);
}

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'student_support_learning_reminders';
  static const _channelName = 'Nhắc việc học tập';
  static const _channelDescription =
      'Nhắc việc cục bộ do ứng dụng tạo theo lựa chọn của người học';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  @override
  Future<void> cancel(int notificationId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> schedule({
    required int notificationId,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: timezone.TZDateTime.from(scheduledAt, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'student-support-reminder',
    );
  }

  Future<void> _ensureInitialized() =>
      _initialization ??= _initializeNotificationPlatform();

  Future<void> _initializeNotificationPlatform() async {
    timezone_data.initializeTimeZones();
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(
        timezone.getLocation(deviceTimezone.identifier),
      );
    } catch (_) {
      // The timezone database defaults safely when a platform cannot report a
      // device zone. Scheduling still uses a concrete instant from DateTime.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_dlu_lms'),
      ),
    );
  }
}

/// Schedules user-approved reminders as local device notifications.
///
/// Notification text deliberately remains generic: academic information stays
/// in the LMS data source and is not copied into the device notification.
class FlutterLocalReminderScheduler implements ReminderScheduler {
  FlutterLocalReminderScheduler({LocalNotificationGateway? gateway})
    : _gateway = gateway ?? FlutterLocalNotificationGateway();

  final LocalNotificationGateway _gateway;

  @override
  Future<void> cancel(String reminderId) async {
    try {
      await _gateway.cancel(_notificationIdFor(reminderId));
    } on ReminderException {
      rethrow;
    } catch (_) {
      throw const ReminderSchedulingException(
        'Không thể hủy nhắc việc trên thiết bị.',
        code: 'REMINDER_NOTIFICATION_CANCEL_FAILED',
      );
    }
  }

  @override
  Future<void> schedule(LearningReminder reminder) async {
    final bool isAllowed;
    try {
      isAllowed = await _gateway.requestPermission();
    } on ReminderException {
      rethrow;
    } catch (_) {
      throw const ReminderSchedulingException(
        'Không thể yêu cầu quyền thông báo trên thiết bị.',
        code: 'REMINDER_NOTIFICATION_PERMISSION_REQUEST_FAILED',
      );
    }
    if (!isAllowed) {
      throw const ReminderSchedulingException(
        'Bạn cần cho phép thông báo để bật nhắc việc học tập.',
        code: 'REMINDER_NOTIFICATION_PERMISSION_DENIED',
      );
    }

    try {
      await _gateway.schedule(
        notificationId: _notificationIdFor(reminder.id),
        scheduledAt: reminder.remindAt,
        title: reminder.assignmentId.startsWith('study-plan:')
            ? 'Đến giờ học theo kế hoạch'
            : 'Nhắc việc học tập',
        body: reminder.assignmentId.startsWith('study-plan:')
            ? 'Mở kế hoạch để bắt đầu buổi học của bạn.'
            : 'Bạn có một hạn nộp cần xem lại.',
      );
    } on ReminderException {
      rethrow;
    } catch (_) {
      throw const ReminderSchedulingException(
        'Không thể lên lịch nhắc việc trên thiết bị.',
        code: 'REMINDER_NOTIFICATION_SCHEDULE_FAILED',
      );
    }
  }

  static int _notificationIdFor(String reminderId) {
    var hash = 0;
    for (final unit in reminderId.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + unit);
    }
    return hash;
  }
}
