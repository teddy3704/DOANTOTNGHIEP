import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/core/network/moodle_api_client.dart';
import 'package:dlu_lms_mobile/core/network/request_authorizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MoodleApiClient client;

  setUp(() {
    client = MoodleApiClient(
      config: AppConfig.development(),
      authorizer: const UnconfiguredRequestAuthorizer(),
    );
  });

  test('rejects unverified absolute or same-origin-ambiguous paths', () async {
    expect(
      () => client.request<void>(
        verifiedPath: 'https://evil.example/path',
        method: 'GET',
      ),
      throwsArgumentError,
    );
    expect(
      () => client.request<void>(verifiedPath: '//evil.example', method: 'GET'),
      throwsArgumentError,
    );
  });

  test('blocks authenticated requests until DLU auth is confirmed', () async {
    expect(
      () => client.request<void>(
        verifiedPath: '/verified-only-after-discovery',
        method: 'GET',
      ),
      throwsA(
        isA<ConfigurationFailure>().having(
          (failure) => failure.code,
          'code',
          'AUTHENTICATION_METHOD_UNCONFIRMED',
        ),
      ),
    );
  });
}
