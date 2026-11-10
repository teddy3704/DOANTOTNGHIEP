import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V2-N18 device settings: theme mode and whether the 3-step introduction was shown.
/// Not sensitive; stored with shared_preferences. Loading never blocks start-up for more than 2 s.
class AppSettings {
  AppSettings._();

  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'onboarding_seen';

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.system,
  );
  static bool onboardingSeen = false;

  /// Widget tests switch the introduction off globally (test/flutter_test_config.dart).
  static bool onboardingEnabled = true;

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_themeKey),
        orElse: () => ThemeMode.system,
      );
      onboardingSeen = p.getBool(_onboardingKey) ?? false;
    } catch (e) {
      debugPrint('App settings: $e');
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(
        _themeKey,
        mode.name,
      );
    } catch (e) {
      debugPrint('Theme save: $e');
    }
  }

  static Future<void> markOnboardingSeen() async {
    onboardingSeen = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(
        _onboardingKey,
        true,
      );
    } catch (e) {
      debugPrint('Onboarding save: $e');
    }
  }
}
