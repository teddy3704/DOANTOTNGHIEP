import 'package:dlu_lms_mobile/features/reminders/data/flutter_local_reminder_scheduler.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/learning_reminder.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/reminder_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reminder = LearningReminder(
    id: 'reminder-1',
    ownerId: 'student-1',
    courseId: 'course-1',
    assignmentId: 'assignment-1',
    dueAt: DateTime.utc(2026, 8, 22, 10),
    remindAt: DateTime.utc(2026, 8, 22, 8),
    isEnabled: true,
    createdAt: DateTime.utc(2026, 8, 18),
    updatedAt: DateTime.utc(2026, 8, 18),
  );

  test(
    'requests permission then schedules generic local reminder copy',
    () async {
      final gateway = _RecordingGateway();
      final scheduler = FlutterLocalReminderScheduler(gateway: gateway);

      await scheduler.schedule(reminder);

      expect(gateway.permissionRequests, 1);
      expect(gateway.scheduled, hasLength(1));
      final scheduled = gateway.scheduled.single;
      expect(scheduled.scheduledAt, reminder.remindAt);
      expect(scheduled.title, 'Nhắc việc học tập');
      expect(scheduled.body, 'Bạn có một hạn nộp cần xem lại.');
      expect(scheduled.body, isNot(contains(reminder.assignmentId)));
    },
  );

  test('denied notification permission does not schedule a reminder', () async {
    final gateway = _RecordingGateway(permissionAllowed: false);
    final scheduler = FlutterLocalReminderScheduler(gateway: gateway);

    await expectLater(
      scheduler.schedule(reminder),
      throwsA(
        isA<ReminderSchedulingException>().having(
          (failure) => failure.code,
          'code',
          'REMINDER_NOTIFICATION_PERMISSION_DENIED',
        ),
      ),
    );
    expect(gateway.scheduled, isEmpty);
  });

  test('cancels the same deterministic platform notification id', () async {
    final gateway = _RecordingGateway();
    final scheduler = FlutterLocalReminderScheduler(gateway: gateway);

    await scheduler.schedule(reminder);
    await scheduler.cancel(reminder.id);

    expect(gateway.cancelled, <int>[gateway.scheduled.single.notificationId]);
  });

  test('maps a device scheduling failure to a safe reminder failure', () async {
    final gateway = _RecordingGateway(scheduleError: StateError('device'));
    final scheduler = FlutterLocalReminderScheduler(gateway: gateway);

    await expectLater(
      scheduler.schedule(reminder),
      throwsA(
        isA<ReminderSchedulingException>().having(
          (failure) => failure.code,
          'code',
          'REMINDER_NOTIFICATION_SCHEDULE_FAILED',
        ),
      ),
    );
  });
}

class _RecordingGateway implements LocalNotificationGateway {
  _RecordingGateway({this.permissionAllowed = true, this.scheduleError});

  final bool permissionAllowed;
  final Object? scheduleError;
  int permissionRequests = 0;
  final List<_ScheduledNotification> scheduled = <_ScheduledNotification>[];
  final List<int> cancelled = <int>[];

  @override
  Future<void> cancel(int notificationId) async =>
      cancelled.add(notificationId);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionAllowed;
  }

  @override
  Future<void> schedule({
    required int notificationId,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    final error = scheduleError;
    if (error != null) throw error;
    scheduled.add(
      _ScheduledNotification(
        notificationId: notificationId,
        scheduledAt: scheduledAt,
        title: title,
        body: body,
      ),
    );
  }
}

class _ScheduledNotification {
  const _ScheduledNotification({
    required this.notificationId,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  final int notificationId;
  final DateTime scheduledAt;
  final String title;
  final String body;
}
