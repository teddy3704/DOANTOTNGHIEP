import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/reminder_schedule.dart';
import 'package:lms_mobile_app/screens/student/reminder_settings_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/services/reminder_service.dart';

import 'support/mock_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class FakeGateway implements NotificationGateway {
  final scheduled = <PlannedReminder>[];
  final shown = <String>[];
  int cancels = 0;
  bool permit;
  int asked = 0, settingsOpened = 0;
  FakeGateway({this.permit = true});

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async {
    asked++;
    return permit;
  }

  @override
  Future<bool> isPermitted() async => permit;
  @override
  Future<void> openSettings() async => settingsOpened++;
  @override
  Future<void> cancelAll() async {
    cancels++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(PlannedReminder r) async => scheduled.add(r);
  @override
  Future<void> showNow(String title, String body) async => shown.add(title);
}

class MemoryStore implements ReminderDeviceStore {
  int? minute;
  @override
  Future<int?> dailyMinute() async => minute;
  @override
  Future<void> setDailyMinute(int m) async => minute = m;
}

final _now = DateTime(2026, 11, 16, 10, 0);

int _epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

void main() {
  group('planReminders', () {
    final future = DeadlineInput(
      title: 'Bài tập 2',
      courseName: 'Software Testing',
      due: DateTime(2026, 11, 18, 23, 59),
    );
    final past = DeadlineInput(
      title: 'Bài cũ',
      due: DateTime(2026, 11, 10, 23, 59),
    );

    test('past deadlines are skipped; reminder fires N hours before', () {
      final plan = planReminders(
        now: _now,
        prefs: const ReminderPrefs(learningReminder: false),
        deadlines: [past, future],
      );
      expect(plan.upcomingDeadlines, 1);
      expect(plan.reminders, hasLength(1));
      expect(plan.reminders.single.when, DateTime(2026, 11, 17, 23, 59));
      expect(plan.reminders.single.title, contains('còn 24 giờ: Bài tập 2'));
      expect(plan.reminders.single.body, contains('Software Testing'));
    });

    test(
      'changing hours before moves the reminder; passed time is skipped',
      () {
        ReminderPlan at(int h) => planReminders(
          now: _now,
          prefs: ReminderPrefs(learningReminder: false, reminderBeforeHours: h),
          deadlines: [future],
        );
        expect(at(6).reminders.single.when, DateTime(2026, 11, 18, 17, 59));
        expect(at(72).reminders, isEmpty);
        expect(at(72).upcomingDeadlines, 1);
      },
    );

    test('only past deadlines: nothing scheduled, no upcoming', () {
      final plan = planReminders(
        now: _now,
        prefs: const ReminderPrefs(learningReminder: false),
        deadlines: [past],
      );
      expect(plan.reminders, isEmpty);
      expect(plan.upcomingDeadlines, 0);
    });

    test('quiz and assignment switches and the master switch', () {
      final quiz = DeadlineInput(
        title: 'Quiz 3',
        due: DateTime(2026, 11, 19, 8),
        isQuiz: true,
      );
      final noQuiz = planReminders(
        now: _now,
        prefs: const ReminderPrefs(
          learningReminder: false,
          quizReminder: false,
        ),
        deadlines: [future, quiz],
      );
      expect(noQuiz.reminders.map((r) => r.title).join(), isNot('Quiz 3'));
      expect(noQuiz.reminders, hasLength(1));
      final off = planReminders(
        now: _now,
        prefs: const ReminderPrefs(pushEnabled: false),
        deadlines: [future, quiz],
        dueCards: 5,
      );
      expect(off.reminders, isEmpty);
    });

    test('daily reminder: first carries cards, each day its plan', () {
      final plan = planReminders(
        now: _now,
        prefs: const ReminderPrefs(
          assignmentReminder: false,
          dailyMinute: 19 * 60,
        ),
        deadlines: [future],
        dueCards: 4,
        planDays: [
          PlanDayInput(DateTime(2026, 11, 16), 2, 51),
          PlanDayInput(DateTime(2026, 11, 18), 1, 45),
        ],
      );
      final daily = plan.daily;
      expect(daily, hasLength(2));
      expect(daily[0].when, DateTime(2026, 11, 16, 19));
      expect(daily[0].body, 'Cần ôn 4 thẻ · 2 việc trong kế hoạch (51 phút)');
      expect(daily[1].when, DateTime(2026, 11, 18, 19));
      expect(daily[1].body, '1 việc trong kế hoạch (45 phút)');
    });

    test('daily time already passed today starts tomorrow; ids unique', () {
      final plan = planReminders(
        now: _now,
        prefs: const ReminderPrefs(dailyMinute: 8 * 60),
        deadlines: [future],
        dueCards: 3,
      );
      expect(plan.daily.single.when, DateTime(2026, 11, 17, 8));
      final ids = plan.reminders.map((r) => r.id).toSet();
      expect(ids.length, plan.reminders.length);
    });

    test('deadline reminders are capped', () {
      final many = [
        for (var i = 0; i < 60; i++)
          DeadlineInput(title: 'B$i', due: DateTime(2026, 11, 20, 0, i)),
      ];
      final plan = planReminders(
        now: _now,
        prefs: const ReminderPrefs(learningReminder: false),
        deadlines: many,
      );
      expect(plan.reminders, hasLength(maxDeadlineReminders));
    });
  });

  group('ReminderService', () {
    late List<String> calls;
    Map<String, dynamic> prefs = {};

    http.Client client({bool tasksFail = false}) => MockClient((r) async {
      calls.add('${r.method} ${r.url.path} ${r.body}');
      final p = r.url.path;
      if (p.endsWith('/notification-preferences')) {
        if (r.method == 'PUT') {
          prefs = {...prefs, ...jsonDecode(r.body) as Map<String, dynamic>};
        }
        return _json(prefs);
      }
      if (p.endsWith('/tasks')) {
        if (tasksFail) return http.Response('', 500);
        return _json([
          {
            'courseid': 13,
            'course_name': 'Software Testing',
            'title': 'Bài tập 2',
            'task_type': 'assignment',
            'task_status': 'pending',
            'due_time': _epoch(DateTime(2026, 11, 18, 23, 59)),
          },
          {
            'title': 'Đã nộp',
            'task_type': 'assignment',
            'task_status': 'pending',
            'source_status': 'submitted',
            'due_time': _epoch(DateTime(2026, 11, 19)),
          },
        ]);
      }
      if (p.endsWith('/flashcards/due')) {
        return _json({'total': 2, 'cards': []});
      }
      if (p.endsWith('/study-plan')) {
        return _json({
          'today': '2026-11-16',
          'dailyMinutes': 60,
          'days': [
            {
              'date': '2026-11-16',
              'items': [
                {
                  'id': 1,
                  'date': '2026-11-16',
                  'sourceType': 'quiz',
                  'title': 'Quiz 3',
                  'minutes': 45,
                  'status': 'planned',
                },
              ],
            },
          ],
        });
      }
      return http.Response('', 404);
    });

    setUp(() {
      calls = [];
      prefs = {
        'pushEnabled': true,
        'assignmentReminder': true,
        'quizReminder': true,
        'learningReminder': true,
        'reminderBeforeHours': 24,
      };
    });

    test('reschedule cancels then schedules deadlines and daily', () async {
      final gw = FakeGateway();
      final svc = ReminderService(
        gateway: gw,
        store: MemoryStore(),
        clock: () => _now,
      );
      final status = await svc.reschedule(testApi(client: client()));
      expect(gw.cancels, 1);
      expect(gw.scheduled.where((r) => r.kind == ReminderKind.deadline), [
        isA<PlannedReminder>().having(
          (r) => r.title,
          't',
          contains('Bài tập 2'),
        ),
      ]);
      expect(
        gw.scheduled.firstWhere((r) => r.kind == ReminderKind.daily).body,
        'Cần ôn 2 thẻ · 1 việc trong kế hoạch (45 phút)',
      );
      expect(status.permitted, isTrue);
    });

    test('no permission: cancels, schedules nothing', () async {
      final gw = FakeGateway(permit: false);
      final svc = ReminderService(
        gateway: gw,
        store: MemoryStore(),
        clock: () => _now,
      );
      final status = await svc.reschedule(testApi(client: client()));
      expect(status.permitted, isFalse);
      expect(gw.cancels, 1);
      expect(gw.scheduled, isEmpty);
    });

    test('a failing source does not block the others', () async {
      final gw = FakeGateway();
      final svc = ReminderService(
        gateway: gw,
        store: MemoryStore(),
        clock: () => _now,
      );
      await svc.reschedule(testApi(client: client(tasksFail: true)));
      expect(gw.scheduled.map((r) => r.kind).toSet(), {ReminderKind.daily});
    });

    test(
      'save sends server fields only and keeps daily time on device',
      () async {
        final store = MemoryStore();
        final svc = ReminderService(
          gateway: FakeGateway(),
          store: store,
          clock: () => _now,
        );
        await svc.save(
          testApi(client: client()),
          const ReminderPrefs(reminderBeforeHours: 6, dailyMinute: 7 * 60 + 30),
        );
        final put = calls.firstWhere((c) => c.startsWith('PUT'));
        expect(
          put,
          contains('/api/v1/dev/students/205/notification-preferences'),
        );
        expect(put, contains('"reminderBeforeHours":6'));
        expect(put, isNot(contains('daily')));
        expect(store.minute, 7 * 60 + 30);
      },
    );
  });

  testWidgets('settings screen: toggles save, upcoming list, test button', (
    tester,
  ) async {
    final calls = <String>[];
    var prefs = <String, dynamic>{
      'pushEnabled': true,
      'assignmentReminder': true,
      'quizReminder': true,
      'learningReminder': false,
      'reminderBeforeHours': 24,
    };
    final api = testApi(
      client: MockClient((r) async {
        calls.add('${r.method} ${r.url.path}');
        if (r.url.path.endsWith('/notification-preferences')) {
          if (r.method == 'PUT') {
            prefs = {...prefs, ...jsonDecode(r.body) as Map<String, dynamic>};
          }
          return _json(prefs);
        }
        if (r.url.path.endsWith('/tasks')) return _json([]);
        return http.Response('', 404);
      }),
    );
    final gw = FakeGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderSettingsScreen(
          api: api,
          reminders: ReminderService(
            gateway: gw,
            store: MemoryStore(),
            clock: () => _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-no-deadline')), findsOneWidget);
    expect(find.text('Không có hạn nộp sắp tới'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pref-quiz')));
    await tester.pumpAndSettle();
    expect(prefs['quizReminder'], isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('pref-quiz'))).value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('pref-push')));
    await tester.pumpAndSettle();
    expect(prefs['pushEnabled'], isFalse);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('pref-assign')))
          .onChanged,
      isNull,
    );
    expect(find.text('Đã tắt thông báo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pref-test')));
    await tester.pumpAndSettle();
    expect(gw.shown, ['Thông báo thử']);
    expect(find.text('Đã gửi thông báo thử'), findsOneWidget);
    expect(calls.where((c) => c.startsWith('PUT')), hasLength(2));
  });

  testWidgets('settings screen: failed save reverts the switch', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient((r) async {
        if (r.method == 'PUT') return http.Response('', 500);
        if (r.url.path.endsWith('/notification-preferences')) {
          return _json({'pushEnabled': true, 'learningReminder': false});
        }
        return _json([]);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderSettingsScreen(
          api: api,
          reminders: ReminderService(
            gateway: FakeGateway(),
            store: MemoryStore(),
            clock: () => _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pref-assign')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('pref-assign'))).value,
      isTrue,
    );
    expect(find.byType(SnackBar), findsOneWidget);
  });

  group('Android 13 permission', () {
    ApiService prefsApi() => testApi(
      client: MockClient((r) async {
        if (r.url.path.endsWith('/notification-preferences')) {
          return _json({'pushEnabled': true, 'learningReminder': false});
        }
        return _json([]);
      }),
    );

    Widget screen(FakeGateway gw) => MaterialApp(
      home: ReminderSettingsScreen(
        api: prefsApi(),
        reminders: ReminderService(
          gateway: gw,
          store: MemoryStore(),
          clock: () => _now,
        ),
      ),
    );

    test('app start never shows the permission dialog', () async {
      final gw = FakeGateway(permit: false);
      await ReminderService(
        gateway: gw,
        store: MemoryStore(),
        clock: () => _now,
      ).refreshQuietly(prefsApi());
      expect(gw.asked, 0);
      expect(gw.scheduled, isEmpty);
    });

    testWidgets('opening the screen does not ask; turning a reminder on does', (
      tester,
    ) async {
      final gw = FakeGateway();
      await tester.pumpWidget(screen(gw));
      await tester.pumpAndSettle();
      expect(gw.asked, 0);
      await tester.tap(find.byKey(const Key('pref-assign')));
      await tester.pumpAndSettle();
      expect(gw.asked, 1);
    });

    testWidgets('refused: test sends nothing and points to the settings', (
      tester,
    ) async {
      final gw = FakeGateway(permit: false);
      await tester.pumpWidget(screen(gw));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder-no-permission')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pref-test')));
      await tester.pumpAndSettle();
      expect(gw.asked, 1);
      expect(gw.shown, isEmpty);
      expect(
        find.text('Ứng dụng chưa được phép gửi thông báo'),
        findsOneWidget,
      );
      expect(find.text('Đã gửi thông báo thử'), findsNothing);
      await tester.tap(find.text('Mở cài đặt'));
      await tester.pumpAndSettle();
      expect(gw.settingsOpened, 1);

      await tester.ensureVisible(
        find.byKey(const Key('reminder-open-settings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-open-settings')));
      expect(gw.settingsOpened, 2);

      // Allowed in the system settings, then back to the app.
      gw.permit = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder-no-permission')), findsNothing);
      expect(find.text('Ứng dụng chưa được phép gửi thông báo'), findsNothing);
    });
  });
}
