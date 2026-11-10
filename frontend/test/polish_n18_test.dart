import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/app_settings.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/main.dart';
import 'package:lms_mobile_app/screens/onboarding_screen.dart';
import 'package:lms_mobile_app/screens/student/achievements_screen.dart';
import 'package:lms_mobile_app/screens/student/calendar_screen.dart';
import 'package:lms_mobile_app/screens/student/focus_timer_screen.dart';
import 'package:lms_mobile_app/screens/student/reminder_settings_screen.dart';
import 'package:lms_mobile_app/screens/student/study_plan_screen.dart';
import 'package:lms_mobile_app/services/reminder_service.dart';

import 'reminder_test.dart' show FakeGateway, MemoryStore;
import 'support/mock_api.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// One mock backend answering every screen tested here.
http.Response _answer(http.Request r) {
  final p = r.url.path;
  if (p.endsWith('/study-plan')) {
    return _json({
      'today': '2026-11-16',
      'dailyMinutes': 60,
      'days': [
        for (var d = 16; d <= 22; d++)
          {
            'date': '2026-11-$d',
            'items': d == 16
                ? [
                    {
                      'id': 1,
                      'date': '2026-11-16',
                      'courseId': 13,
                      'sourceType': 'assign',
                      'title':
                          'Bài tập rất dài về kiểm thử phần mềm (phần 1/2)',
                      'minutes': 45,
                      'status': 'planned',
                    },
                  ]
                : [],
          },
      ],
      'overloaded': [
        {
          'title': 'Quiz chương 5 kiểm thử hộp đen',
          'due': '2026-11-17',
          'minutes': 45,
        },
      ],
    });
  }
  if (p.endsWith('/notification-preferences')) {
    return _json({
      'pushEnabled': true,
      'learningReminder': true,
      'reminderBeforeHours': 24,
    });
  }
  if (p.endsWith('/calendar')) {
    return _json({
      'events': [
        {
          'uid': 'deadline-assign-1@x',
          'type': 'deadline',
          'title': 'Bài tập 5.1 kiểm thử phần mềm nâng cao',
          'courseName': 'Kiểm thử phần mềm',
          'start': '2026-11-16T16:59:00Z',
          'allDay': false,
        },
      ],
    });
  }
  if (p.endsWith('/achievements')) {
    return _json({
      'badges': [
        {
          'key': 'on_time',
          'title': 'Đúng hạn 3 lần liền',
          'description': 'Nộp 3 bài tập liên tiếp trước hạn',
          'achieved': false,
          'progress': 2,
          'target': 3,
        },
        {
          'key': 'minutes_300',
          'title': '300 phút tập trung',
          'description': 'Tích lũy 300 phút học tập trung',
          'achieved': true,
          'achievedOn': '2026-11-12',
          'progress': 300,
          'target': 300,
        },
      ],
    });
  }
  if (p.endsWith('/courses')) {
    return _json([
      {'courseid': 13, 'course_name': 'Kiểm thử phần mềm'},
    ]);
  }
  if (p.endsWith('/tasks')) return _json([]);
  return http.Response('', 404);
}

void main() {
  testWidgets(
    '1.3 text scale at 320/360/390 dp: new screens render without overflow',
    (tester) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = testApi(client: MockClient((r) async => _answer(r)));
      final screens = <String, Widget>{
        'plan': StudyPlanScreen(api: api),
        'focus': FocusTimerScreen(
          api: api,
          now: () => DateTime(2026, 11, 16, 9),
        ),
        'reminders': ReminderSettingsScreen(
          api: api,
          reminders: ReminderService(
            gateway: FakeGateway(),
            store: MemoryStore(),
            clock: () => DateTime(2026, 11, 16, 9),
          ),
        ),
        'calendar': CalendarScreen(
          api: api,
          now: () => DateTime(2026, 11, 16, 9),
        ),
        'achievements': AchievementsScreen(api: api),
      };
      for (final width in [320.0, 360.0, 390.0]) {
        tester.view.physicalSize = Size(width * 3, 2340);
        for (final dark in [false, true]) {
          for (final e in screens.entries) {
            await tester.pumpWidget(
              MaterialApp(
                key: UniqueKey(),
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: e.value,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${e.key} width=$width dark=$dark',
            );
          }
        }
      }
    },
  );

  testWidgets('dark theme is a real dark scheme', (tester) async {
    expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
  });

  testWidgets('theme menu switches the whole app', (tester) async {
    AppSettings.themeMode.value = ThemeMode.light;
    addTearDown(() => AppSettings.themeMode.value = ThemeMode.system);
    await tester.pumpWidget(const LMSApp());
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(const Key('theme-menu')))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byKey(const Key('theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(AppSettings.themeMode.value, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byKey(const Key('theme-menu')))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('onboarding: 3 steps, then marked as seen', (tester) async {
    AppSettings.onboardingSeen = false;
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('Mô phỏng điểm'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Kế hoạch tuần'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Ôn thẻ thông minh'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pump();
    expect(AppSettings.onboardingSeen, isTrue);
  });

  testWidgets('time picker speaks Vietnamese', (tester) async {
    await tester.pumpWidget(const LMSApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(const Key('theme-menu')));
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chọn giờ'), findsOneWidget);
    expect(find.text('Select time'), findsNothing);
  });
}
