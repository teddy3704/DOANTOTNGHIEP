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
