import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StudentSupportStagingConfig', () {
    test('normalizes a credential-free HTTPS origin and student code', () {
      final config = StudentSupportStagingConfig(
        baseUri: Uri.parse('https://STAGING.example.test:443/'),
        studentCode: ' sv001 ',
      );

      expect(config.baseUri, Uri.parse('https://staging.example.test'));
      expect(config.studentCode, 'SV001');
    });

    test('rejects non-origin, non-HTTPS, or credential-bearing API URLs', () {
      final invalidOrigins = <Uri>[
        Uri.parse('http://staging.example.test'),
        Uri.parse('https://user:password@staging.example.test'),
        Uri.parse('https://staging.example.test/path'),
        Uri.parse('https://staging.example.test?private=value'),
        Uri.parse('https://staging.example.test#fragment'),
      ];

      for (final origin in invalidOrigins) {
        expect(
          () => StudentSupportStagingConfig(
            baseUri: origin,
            studentCode: 'SV001',
          ),
          throwsA(
            isA<ConfigurationFailure>().having(
              (failure) => failure.code,
              'code',
              anyOf('STAGING_API_HTTPS_REQUIRED', 'STAGING_API_ORIGIN_INVALID'),
            ),
          ),
          reason: '$origin must not be accepted as a staging API origin.',
        );
      }
    });

    test('rejects a malformed preview student code', () {
      for (final code in <String>['', 'SV1', 'SV0001', 'ST001', 'SV 001']) {
        expect(
          () => StudentSupportStagingConfig(
            baseUri: Uri.parse('https://staging.example.test'),
            studentCode: code,
          ),
          throwsA(
            isA<ConfigurationFailure>().having(
              (failure) => failure.code,
              'code',
              'STAGING_STUDENT_CODE_INVALID',
            ),
          ),
        );
      }
    });
  });
}
