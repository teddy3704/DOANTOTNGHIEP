import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, production }

class AppConfig {
  AppConfig({
    required this.environment,
    required this.moodleBaseUri,
    required this.enableDevFixtures,
    this.appName = 'DLU LMS Mobile',
  }) {
    if (!moodleBaseUri.hasScheme || moodleBaseUri.scheme != 'https') {
      throw ArgumentError.value(
        moodleBaseUri,
        'moodleBaseUri',
        'Production-capable LMS configuration must use HTTPS.',
      );
    }
    if (environment == AppEnvironment.production && enableDevFixtures) {
      throw ArgumentError(
        'DEV fixtures cannot be enabled in a production configuration.',
      );
    }
  }

  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'MOODLE_BASE_URL',
      defaultValue: 'https://lms.dlu.edu.vn',
    );
    return AppConfig(
      environment: AppEnvironment.production,
      moodleBaseUri: Uri.parse(baseUrl),
      enableDevFixtures: false,
    );
  }

  factory AppConfig.development() => AppConfig(
    environment: AppEnvironment.development,
    moodleBaseUri: Uri.parse('https://lms.dlu.edu.vn'),
    enableDevFixtures: true,
  );

  final AppEnvironment environment;
  final Uri moodleBaseUri;
  final bool enableDevFixtures;
  final String appName;

  bool get isProduction => environment == AppEnvironment.production;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('AppConfig must be provided at bootstrap.'),
);
