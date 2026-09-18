import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_api_client.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = StudentSupportStagingConfig(
    baseUri: Uri.parse('https://staging.example.test'),
    studentCode: 'SV001',
  );

  test(
    'uses the verified GET route and minimal preview identity header',
    () async {
      final requests = <RequestOptions>[];
      final client = StudentSupportApiClient(
        config: config,
        dio: _dio((options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: <String, Object?>{
                'data': <Object?>[],
                'meta': <String, Object?>{'count': 0},
              },
            ),
          );
        }),
      );

      await client.getCourses();
      await client.getHealth();

      expect(requests, hasLength(2));
      expect(requests.first.method, 'GET');
      expect(requests.first.uri.path, '/api/v1/me/courses');
      expect(requests.first.headers['X-Demo-Student-Code'], 'SV001');
      expect(requests.first.headers.containsKey('Authorization'), isFalse);
      expect(requests.first.queryParameters, isEmpty);
      expect(requests.first.data, isNull);
      expect(requests.last.method, 'GET');
      expect(requests.last.uri.path, '/health');
      expect(requests.last.headers.containsKey('X-Demo-Student-Code'), isFalse);
    },
  );

  test('rejects an invalid course ID before any network request', () async {
    var networkAttempts = 0;
    final client = StudentSupportApiClient(
      config: config,
      dio: _dio((options, handler) {
        networkAttempts += 1;
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
      }),
    );

    expect(
      () => client.getCourseContent('0'),
      throwsA(
        isA<ParsingFailure>().having(
          (failure) => failure.code,
          'code',
          'STAGING_COURSE_ID_INVALID',
        ),
      ),
    );
    expect(networkAttempts, 0);
  });

  test('blocks a mismatched injected origin before network access', () async {
    const sentinel = 'STAGING_ORIGIN_SENTINEL_NOT_FOR_LOGS';
    var networkAttempts = 0;
    final unsafeDio = Dio(
      BaseOptions(baseUrl: 'https://evil.example/$sentinel'),
    );
    unsafeDio.interceptors.add(
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
    final client = StudentSupportApiClient(config: config, dio: unsafeDio);

    try {
      await client.getCourses();
      fail('The cross-origin request must be blocked.');
    } on ConfigurationFailure catch (failure) {
      expect(failure.code, 'STAGING_API_ORIGIN_MISMATCH');
      expect('$failure', isNot(contains(sentinel)));
      expect(failure.diagnostic, isNull);
    }
    expect(networkAttempts, 0);
  });

  test('rejects a malformed list envelope without inventing data', () async {
    final client = StudentSupportApiClient(
      config: config,
      dio: _dio((options, handler) {
        handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'courseId': '101'},
              ],
              'meta': <String, Object?>{'count': 2},
            },
          ),
        );
      }),
    );

    await expectLater(
      client.getCourses(),
      throwsA(
        isA<ParsingFailure>().having(
          (failure) => failure.code,
          'code',
          'STAGING_LIST_ENVELOPE_INVALID',
        ),
      ),
    );
  });

  test('sanitizes server failures without exposing response data', () async {
    const sentinel = 'STAGING_RESPONSE_SECRET_SENTINEL';
    final client = StudentSupportApiClient(
      config: config,
      dio: _dio((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 503,
              data: <String, Object?>{'private': sentinel},
            ),
            error: StateError(sentinel),
            type: DioExceptionType.badResponse,
          ),
        );
      }),
    );

    try {
      await client.getCourses();
      fail('The intercepted request must fail.');
    } on ServerFailure catch (failure) {
      expect(failure.diagnostic, isA<NetworkFailureDiagnostic>());
      final diagnostic = failure.diagnostic! as NetworkFailureDiagnostic;
      expect(diagnostic.method, 'GET');
      expect(diagnostic.redactedPath, '/api/v1/me/courses');
      expect(diagnostic.statusCode, 503);
      expect('$failure $diagnostic', isNot(contains(sentinel)));
    }
  });
}

Dio _dio(void Function(RequestOptions, RequestInterceptorHandler) onRequest) {
  final dio = Dio(BaseOptions(baseUrl: 'https://staging.example.test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
  return dio;
}
