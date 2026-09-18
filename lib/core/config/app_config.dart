import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  AppConfig({
    required this.environment,
    required Uri moodleBaseUri,
    required this.enableDevFixtures,
    this.appName = 'DLU LMS Mobile',
  }) : moodleBaseUri = _normalizeMoodleOrigin(moodleBaseUri) {
    if (environment != AppEnvironment.development && enableDevFixtures) {
      throw ArgumentError(
        'DEV fixtures can only be enabled in a development configuration.',
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

  /// A clearly separated build mode for the development Student Support API.
  ///
  /// The staging API configuration and identity live in the development layer;
  /// production remains fail-closed and never selects that adapter implicitly.
  factory AppConfig.staging() => AppConfig(
    environment: AppEnvironment.staging,
    moodleBaseUri: Uri.parse('https://lms.dlu.edu.vn'),
    enableDevFixtures: false,
  );

  final AppEnvironment environment;
  final Uri moodleBaseUri;
  final bool enableDevFixtures;
  final String appName;

  bool get isProduction => environment == AppEnvironment.production;

  bool get isStaging => environment == AppEnvironment.staging;

  static Uri _normalizeMoodleOrigin(Uri uri) {
    if (!uri.hasScheme || uri.scheme.toLowerCase() != 'https') {
      throw ArgumentError.value(
        uri,
        'moodleBaseUri',
        'Production-capable LMS configuration must use HTTPS.',
      );
    }
    if (!uri.hasAuthority || uri.host.isEmpty) {
      throw ArgumentError.value(
        uri,
        'moodleBaseUri',
        'The LMS origin must include a host.',
      );
    }
    if (uri.userInfo.isNotEmpty || uri.authority.contains('@')) {
      throw ArgumentError.value(
        uri,
        'moodleBaseUri',
        'The LMS origin cannot contain user information.',
      );
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw ArgumentError.value(
        uri,
        'moodleBaseUri',
        'The LMS origin cannot contain a query or fragment.',
      );
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      throw ArgumentError.value(
        uri,
        'moodleBaseUri',
        'The LMS base URI must be an origin without a path.',
      );
    }

    return Uri(
      scheme: 'https',
      host: uri.host.toLowerCase(),
      port: uri.hasPort && uri.port != 443 ? uri.port : null,
    );
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('AppConfig must be provided at bootstrap.'),
);
