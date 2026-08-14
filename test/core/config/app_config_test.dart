import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('production configuration is HTTPS and disables DEV fixtures', () {
      final config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.production);
      expect(config.moodleBaseUri, Uri.parse('https://lms.dlu.edu.vn'));
      expect(config.enableDevFixtures, isFalse);
    });

    test('rejects non-HTTPS Moodle URLs', () {
      expect(
        () => AppConfig(
          environment: AppEnvironment.production,
          moodleBaseUri: Uri.parse('http://lms.example.test'),
          enableDevFixtures: false,
        ),
        throwsArgumentError,
      );
    });

    test('rejects values that are not a credential-free HTTPS origin', () {
      final invalidOrigins = <Uri>[
        Uri(scheme: 'https'),
        Uri.parse('https://user:password@lms.example.test'),
        Uri.parse('https://lms.example.test/moodle'),
        Uri.parse('https://lms.example.test?service=mobile'),
        Uri.parse('https://lms.example.test#private'),
      ];

      for (final origin in invalidOrigins) {
        expect(
          () => AppConfig(
            environment: AppEnvironment.production,
            moodleBaseUri: origin,
            enableDevFixtures: false,
          ),
          throwsArgumentError,
          reason: '$origin must not be accepted as an LMS origin.',
        );
      }
    });

    test('normalizes the root slash, host case, and default HTTPS port', () {
      final config = AppConfig(
        environment: AppEnvironment.production,
        moodleBaseUri: Uri.parse('https://LMS.Example.Test:443/'),
        enableDevFixtures: false,
      );

      expect(config.moodleBaseUri, Uri.parse('https://lms.example.test'));
    });

    test('rejects DEV fixtures in production', () {
      expect(
        () => AppConfig(
          environment: AppEnvironment.production,
          moodleBaseUri: Uri.parse('https://lms.example.test'),
          enableDevFixtures: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
