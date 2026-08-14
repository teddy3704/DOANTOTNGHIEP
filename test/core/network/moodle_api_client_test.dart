import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/core/network/moodle_api_client.dart';
import 'package:dlu_lms_mobile/core/network/request_authorizer.dart';
import 'package:dio/dio.dart';
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

  test(
    'mismatched injected Dio origin is blocked before auth and network',
    () async {
      const secret = 'PRE_AUTH_ORIGIN_SECRET';
      var networkAttempts = 0;
      final config = AppConfig.development();
      final authorizer = _RecordingAuthorizer();
      final dio = Dio(BaseOptions(baseUrl: 'https://evil.example/$secret'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            networkAttempts += 1;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
      final unsafeClient = MoodleApiClient(
        config: config,
        authorizer: authorizer,
        dio: dio,
      );

      Object? thrown;
      try {
        await unsafeClient.request<void>(
          verifiedPath: '/token/$secret',
          method: 'POST',
          data: <String, Object?>{'secret': secret},
          queryParameters: <String, Object?>{'token': secret},
        );
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isA<ConfigurationFailure>());
      final failure = thrown! as ConfigurationFailure;
      expect(failure.code, 'LMS_ORIGIN_MISMATCH');
      expect('$failure', isNot(contains(secret)));
      expect(failure.diagnostic, isNull);
      expect(authorizer.callCount, 0);
      expect(networkAttempts, 0);
    },
  );

  test('origin changed by authorizer is blocked before network', () async {
    const secret = 'POST_AUTH_ORIGIN_SECRET';
    var networkAttempts = 0;
    final config = AppConfig.development();
    final authorizer = _OriginChangingAuthorizer(
      crossOriginBaseUrl: 'https://evil.example/$secret',
      secret: secret,
    );
    final dio = Dio(BaseOptions(baseUrl: config.moodleBaseUri.toString()));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          networkAttempts += 1;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );
    final protectedClient = MoodleApiClient(
      config: config,
      authorizer: authorizer,
      dio: dio,
    );

    Object? thrown;
    try {
      await protectedClient.request<void>(
        verifiedPath: '/webservice/rest/server.php',
        method: 'POST',
      );
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<ConfigurationFailure>());
    final failure = thrown! as ConfigurationFailure;
    expect(failure.code, 'LMS_ORIGIN_MISMATCH');
    expect('$failure', isNot(contains(secret)));
    expect(failure.diagnostic, isNull);
    expect(authorizer.callCount, 1);
    expect(networkAttempts, 0);
  });

  test('Dio failures retain only a sanitized network diagnostic', () async {
    const secret = 'TOP_SECRET_SENTINEL_DO_NOT_LEAK_1234567890';
    final config = AppConfig.development();
    final dio = Dio(BaseOptions(baseUrl: config.moodleBaseUri.toString()));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $secret';
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 503,
                data: <String, Object?>{'token': secret},
                headers: Headers.fromMap(<String, List<String>>{
                  'x-private-debug': <String>[secret],
                }),
              ),
              error: StateError(secret),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    final sanitizedClient = MoodleApiClient(
      config: config,
      authorizer: const UnconfiguredRequestAuthorizer(),
      dio: dio,
    );

    try {
      await sanitizedClient.request<void>(
        verifiedPath: '/webservice/secret/$secret/server.php?token=$secret',
        method: 'POST',
        data: <String, Object?>{'password': secret},
        queryParameters: <String, Object?>{'sesskey': secret},
        requiresAuthentication: false,
      );
      fail('The intercepted request must fail.');
    } on AppFailure catch (failure) {
      expect(failure, isA<ServerFailure>());
      final diagnostic = failure.diagnostic;
      expect(diagnostic, isA<NetworkFailureDiagnostic>());
      final networkDiagnostic = diagnostic! as NetworkFailureDiagnostic;
      expect(networkDiagnostic.method, 'POST');
      expect(networkDiagnostic.redactedPath, startsWith('/webservice/'));
      expect(networkDiagnostic.redactedPath, isNot(contains('?')));
      expect(networkDiagnostic.statusCode, 503);
      expect(networkDiagnostic.transportType, 'badResponse');

      final safeFailureText = '$failure $networkDiagnostic';
      expect(safeFailureText, isNot(contains(secret)));
      expect(safeFailureText, isNot(contains('Authorization')));
      expect(safeFailureText, isNot(contains('password')));
      expect(safeFailureText, isNot(contains('sesskey')));
    }
  });

  test('diagnostics never expose a cross-origin request path', () async {
    const secret = 'CROSS_ORIGIN_SECRET_SENTINEL';
    final config = AppConfig.development();
    final dio = Dio(BaseOptions(baseUrl: config.moodleBaseUri.toString()));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: RequestOptions(
                path: 'https://evil.example/$secret',
                method: 'GET',
              ),
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );
    final sanitizedClient = MoodleApiClient(
      config: config,
      authorizer: const UnconfiguredRequestAuthorizer(),
      dio: dio,
    );

    try {
      await sanitizedClient.request<void>(
        verifiedPath: '/safe-path',
        method: 'GET',
        requiresAuthentication: false,
      );
      fail('The intercepted request must fail.');
    } on AppFailure catch (failure) {
      final diagnostic = failure.diagnostic! as NetworkFailureDiagnostic;
      expect(diagnostic.redactedPath, '<cross-origin>');
      expect('$failure $diagnostic', isNot(contains(secret)));
    }
  });

  test('same-origin diagnostics redact short unrecognized PII slugs', () async {
    const privateSlug = 'student-a';
    final config = AppConfig.development();
    final dio = Dio(BaseOptions(baseUrl: config.moodleBaseUri.toString()));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );
    final sanitizedClient = MoodleApiClient(
      config: config,
      authorizer: const UnconfiguredRequestAuthorizer(),
      dio: dio,
    );

    try {
      await sanitizedClient.request<void>(
        verifiedPath: '/user/$privateSlug/profile.php',
        method: 'GET',
        requiresAuthentication: false,
      );
      fail('The intercepted request must fail.');
    } on AppFailure catch (failure) {
      final diagnostic = failure.diagnostic! as NetworkFailureDiagnostic;
      expect(diagnostic.redactedPath, '/user/<redacted>/profile.php');
      expect('$failure $diagnostic', isNot(contains(privateSlug)));
    }
  });
}

final class _RecordingAuthorizer implements RequestAuthorizer {
  int callCount = 0;

  @override
  Future<void> authorize(RequestOptions request) async {
    callCount += 1;
  }
}

final class _OriginChangingAuthorizer implements RequestAuthorizer {
  _OriginChangingAuthorizer({
    required this.crossOriginBaseUrl,
    required this.secret,
  });

  final String crossOriginBaseUrl;
  final String secret;
  int callCount = 0;

  @override
  Future<void> authorize(RequestOptions request) async {
    callCount += 1;
    request.baseUrl = crossOriginBaseUrl;
    request.headers['Authorization'] = 'Bearer $secret';
  }
}
