import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/reminder_schedule.dart';
import '../models/study_plan.dart';
import 'api_service.dart';

/// Thin seam over the notification plugin so the scheduling logic can be tested without it.
abstract class NotificationGateway {
  Future<void> init();

  /// Android 13+ runtime permission; true when notifications may be shown.
  /// Shows the system dialog when it has not been answered yet.
  Future<bool> requestPermission();

  /// Current permission without asking.
  Future<bool> isPermitted();

  /// Opens this app's notification settings (after the user said no).
  Future<void> openSettings();
  Future<void> cancelAll();
  Future<void> schedule(PlannedReminder r);
  Future<void> showNow(String title, String body);
}

/// Device-only settings (the daily reminder time).
abstract class ReminderDeviceStore {
  Future<int?> dailyMinute();
  Future<void> setDailyMinute(int minute);
}

class SharedPrefsReminderStore implements ReminderDeviceStore {
  static const _key = 'reminder_daily_minute';
  @override
  Future<int?> dailyMinute() async =>
      (await SharedPreferences.getInstance()).getInt(_key);
  @override
  Future<void> setDailyMinute(int minute) async =>
      (await SharedPreferences.getInstance()).setInt(_key, minute);
}

/// flutter_local_notifications with inexact scheduling (no exact-alarm permission), Asia/Ho_Chi_Minh.
class LocalNotificationGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  tz.Location? _zone;
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'study_reminders',
      'Nhắc học',
      channelDescription: 'Nhắc hạn nộp, ôn thẻ và kế hoạch học',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _zone = tz.getLocation('Asia/Ho_Chi_Minh');
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android == null) return true;
    if (await android.areNotificationsEnabled() == true) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> isPermitted() async =>
      await _android?.areNotificationsEnabled() ?? true;

  static const _settings = MethodChannel('dlu.lms/settings');

  @override
  Future<void> openSettings() =>
      _settings.invokeMethod<void>('openNotificationSettings');

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(PlannedReminder r) => _plugin.zonedSchedule(
    id: r.id,
    scheduledDate: tz.TZDateTime.from(r.when, _zone!),
    notificationDetails: _details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: r.title,
    body: r.body,
  );

  @override
  Future<void> showNow(String title, String body) => _plugin.show(
    id: 1,
    title: title,
    body: body,
    notificationDetails: _details,
  );
}

/// Result of a (re)schedule; the settings screen lists it.
class ReminderStatus {
  final ReminderPrefs prefs;
  final ReminderPlan plan;
  final bool permitted;
  const ReminderStatus(this.prefs, this.plan, this.permitted);
}

class ReminderService {
  final NotificationGateway gateway;
  final ReminderDeviceStore store;
  final DateTime Function() clock;

  ReminderService({
    NotificationGateway? gateway,
    ReminderDeviceStore? store,
    DateTime Function()? clock,
  }) : gateway = gateway ?? LocalNotificationGateway(),
       store = store ?? SharedPrefsReminderStore(),
       clock = clock ?? DateTime.now;

  Future<ReminderPrefs> loadPrefs(ApiService api) async {
    final json = await api.getNotificationPreferences();
    final minute = await _dailyMinute();
    return ReminderPrefs.fromJson(json, dailyMinute: minute);
  }

  Future<int> _dailyMinute() async {
    try {
      return await store.dailyMinute() ?? ReminderPrefs.defaultDailyMinute;
    } catch (e) {
      debugPrint('Reminder store: $e');
      return ReminderPrefs.defaultDailyMinute;
    }
  }

  /// Saves server fields (PUT) and the device daily time, then reschedules.
  Future<ReminderStatus> save(ApiService api, ReminderPrefs prefs) async {
    final saved = ReminderPrefs.fromJson(
      await api.putNotificationPreferences(prefs.toJson()),
      dailyMinute: prefs.dailyMinute,
    );
    await store.setDailyMinute(prefs.dailyMinute);
    return reschedule(api, prefs: saved);
  }

  /// Cancels every pending reminder and schedules the current plan. Sources that fail to load are
  /// treated as empty so one failing endpoint never blocks the others.
  Future<ReminderStatus> reschedule(
    ApiService api, {
    ReminderPrefs? prefs,
    bool askPermission = true,
  }) async {
    await gateway.init();
    final p = prefs ?? await loadPrefs(api);
    final now = clock();
    final deadlines = <DeadlineInput>[];
    var cards = 0;
    final days = <PlanDayInput>[];
    if (p.pushEnabled) {
      try {
        for (final t in await api.getAllStudentTasks()) {
          final due = t.deadline;
          if (t.isDone || due == null) continue;
          deadlines.add(
            DeadlineInput(
              title: t.title,
              courseName: t.courseName,
              due: due,
              isQuiz: t.type == 'quiz',
            ),
          );
        }
      } catch (e) {
        debugPrint('Reminder tasks: $e');
      }
      if (p.learningReminder) {
        try {
          cards = (await api.getDueFlashcards()).total;
        } catch (e) {
          debugPrint('Reminder cards: $e');
        }
        try {
          for (final d in (await api.getStudyPlan()).days) {
            final open = d.items.where((i) => i.status == PlanStatus.planned);
            days.add(
              PlanDayInput(
                d.date,
                open.length,
                open.fold(0, (s, i) => s + i.minutes),
              ),
            );
          }
        } catch (e) {
          debugPrint('Reminder plan: $e');
        }
      }
    }
    final plan = planReminders(
      now: now,
      prefs: p,
      deadlines: deadlines,
      dueCards: cards,
      planDays: days,
    );
    final permitted =
        !p.pushEnabled ||
        (askPermission
            ? await gateway.requestPermission()
            : await gateway.isPermitted());
    await gateway.cancelAll();
    if (permitted) {
      for (final r in plan.reminders) {
        await gateway.schedule(r);
      }
    }
    return ReminderStatus(p, plan, permitted);
  }

  /// Asks for permission first; false (nothing shown) when the user refused.
  Future<bool> sendTest() async {
    await gateway.init();
    if (!await gateway.requestPermission()) return false;
    await gateway.showNow(
      'Thông báo thử',
      'Nhắc học trên điện thoại đang hoạt động.',
    );
    return true;
  }

  Future<void> openSettings() => gateway.openSettings();

  /// Sign-out: the phone must not keep reminding about the previous account. Never throws.
  Future<void> clearAll() async {
    try {
      await gateway.init();
      await gateway.cancelAll();
    } catch (e) {
      debugPrint('Reminder clear: $e');
    }
  }

  /// Best-effort background refresh (app start); never throws and never shows the permission
  /// dialog: that is only asked when the user turns reminders on or sends a test.
  Future<void> refreshQuietly(ApiService api) async {
    try {
      await reschedule(api, askPermission: false);
    } catch (e) {
      debugPrint('Reminder reschedule: $e');
    }
  }
}
