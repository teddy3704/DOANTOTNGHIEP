import 'dart:async';

import 'package:lms_mobile_app/core/app_settings.dart';

/// Applies to every test file: the first-run introduction would otherwise sit in front of
/// every role-selection flow. The onboarding test turns it back on for itself.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppSettings.onboardingEnabled = false;
  await testMain();
}
