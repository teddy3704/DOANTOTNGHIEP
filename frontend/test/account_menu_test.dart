import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/app_settings.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_main_screen.dart';
import 'package:lms_mobile_app/services/reminder_service.dart';

import 'reminder_test.dart' show FakeGateway, MemoryStore;
import 'support/mock_api.dart';

/// POLISH-2: light / dark / follow-the-phone from inside the app, on both home screens.
void main() {
  Widget home(bool teacher, {double scale = 1}) {
    final api = testApi(
      client: MockClient((r) async => http.Response('', 404)),
    );
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: teacher
            ? TeacherMainScreen(apiService: api)
            : StudentMainScreen(
                apiService: api,
                reminders: ReminderService(
                  gateway: FakeGateway(),
                  store: MemoryStore(),
                ),
              ),
      ),
    );
  }

  for (final teacher in [false, true]) {
    final who = teacher ? 'teacher' : 'student';

    testWidgets('$who home: account menu switches dark and back to light', (
      tester,
    ) async {
      AppSettings.themeMode.value = ThemeMode.light;
      addTearDown(() => AppSettings.themeMode.value = ThemeMode.system);
      await tester.pumpWidget(home(teacher));
      await tester.pumpAndSettle();
      final menu = find.byKey(const Key('account-menu'));
      expect(
        tester.widget<PopupMenuButton<dynamic>>(menu).tooltip,
        'Tài khoản và giao diện',
      );

      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text('Giao diện'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      expect(AppSettings.themeMode.value, ThemeMode.dark);
      expect(Theme.of(tester.element(menu)).brightness, Brightness.dark);

      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pumpAndSettle();
      expect(AppSettings.themeMode.value, ThemeMode.light);
      expect(Theme.of(tester.element(menu)).brightness, Brightness.light);
    });

    testWidgets('$who home app bar fits 320 dp at text scale 1.3, menu open', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(960, 2000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(home(teacher, scale: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('account-menu')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
