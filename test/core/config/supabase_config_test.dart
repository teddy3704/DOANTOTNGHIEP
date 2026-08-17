import 'dart:convert';

import 'package:dlu_lms_mobile/core/config/supabase_config.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseConfig', () {
    test('accepts only a credential-free HTTPS project origin', () {
      final config = SupabaseConfig(
        projectUri: Uri.parse('https://Project-Ref.Supabase.Co:443/'),
        publishableKey: 'sb_publishable_unit_test_value',
      );

      expect(config.projectUri, Uri.parse('https://project-ref.supabase.co'));
    });

    test('rejects unsafe project URLs', () {
      final invalidOrigins = <Uri>[
        Uri.parse('http://project-ref.supabase.co'),
        Uri.parse('https://user:password@project-ref.supabase.co'),
        Uri.parse('https://project-ref.supabase.co/rest/v1'),
        Uri.parse('https://project-ref.supabase.co?key=value'),
        Uri.parse('https://project-ref.supabase.co#fragment'),
      ];

      for (final origin in invalidOrigins) {
        expect(
          () => SupabaseConfig(
            projectUri: origin,
            publishableKey: 'sb_publishable_unit_test_value',
          ),
          throwsArgumentError,
          reason: '$origin must not be accepted as a project origin.',
        );
      }
    });

    test('rejects modern and legacy server-side keys', () {
      final legacyHeader = _base64Json(<String, Object?>{'alg': 'none'});
      final legacyPayload = _base64Json(<String, Object?>{
        'role': 'service_role',
      });

      for (final key in <String>[
        'sb_secret_unit_test_value',
        '$legacyHeader.$legacyPayload.signature',
      ]) {
        expect(
          () => SupabaseConfig(
            projectUri: Uri.parse('https://project-ref.supabase.co'),
            publishableKey: key,
          ),
          throwsArgumentError,
        );
      }
    });

    test('accepts legacy anon but rejects every other key class', () {
      final legacyHeader = _base64Json(<String, Object?>{'alg': 'HS256'});
      final legacyAnonPayload = _base64Json(<String, Object?>{'role': 'anon'});
      final legacyUserPayload = _base64Json(<String, Object?>{
        'role': 'authenticated',
      });

      expect(
        SupabaseConfig(
          projectUri: Uri.parse('https://project-ref.supabase.co'),
          publishableKey: '$legacyHeader.$legacyAnonPayload.signature',
        ).publishableKey,
        isNotEmpty,
      );

      for (final key in <String>[
        'opaque-unit-test-value',
        '$legacyHeader.$legacyUserPayload.signature',
      ]) {
        expect(
          () => SupabaseConfig(
            projectUri: Uri.parse('https://project-ref.supabase.co'),
            publishableKey: key,
          ),
          throwsArgumentError,
        );
      }
    });

    test('fails closed when project values are not supplied', () {
      expect(
        SupabaseConfig.fromEnvironment,
        throwsA(
          isA<ConfigurationFailure>().having(
            (failure) => failure.code,
            'code',
            'SUPABASE_PROJECT_CONNECTION_REQUIRED',
          ),
        ),
      );
    });
  });
}

String _base64Json(Map<String, Object?> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
