import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/staging_student_identity_provider.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_api_client.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'c7ff8367-8643-434d-99ac-7e41b1bf64d3';
  late StagingStudentIdentityProvider identity;
  late Dio dio;
  late StudentSupportApiClient client;
  late List<RequestOptions> requests;
  setUp(() async {
    identity = StagingStudentIdentityProvider(
      storage: _Storage(),
      includeTeacher: true,
    );
    await identity.select('SV001');
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'https://staging.example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          requests.add(r);
          h.resolve(
            Response<Object?>(
              requestOptions: r,
              statusCode: 200,
              data: {
                'data': r.method == 'GET' ? [] : {'id': id},
                if (r.method == 'GET') 'meta': {'count': 0},
              },
            ),
          );
        },
      ),
    );
    client = StudentSupportApiClient(
      config: StudentSupportStagingConfig(
        baseUri: Uri.parse('https://staging.example.test'),
        studentCode: 'SV001',
      ),
      identityProvider: identity,
      dio: dio,
    );
  });

  test(
    'app-owned plan read/create/edit/delete use exact allowed methods',
    () async {
      await client.getWorkflowList('/api/v1/me/recommendations');
      await client.mutateWorkflow(
        'POST',
        '/api/v1/me/study-plan/items',
        data: {'assignmentId': '101'},
      );
      await client.mutateWorkflow(
        'PATCH',
        '/api/v1/me/study-plan/items/$id',
        data: {'status': 'handled'},
      );
      await client.mutateWorkflow('DELETE', '/api/v1/me/study-plan/items/$id');
      expect(requests.map((r) => r.method), ['GET', 'POST', 'PATCH', 'DELETE']);
      expect(
        requests.every((r) => r.headers['X-Demo-Student-Code'] == 'SV001'),
        isTrue,
      );
      expect(
        requests.every((r) => !r.followRedirects && r.queryParameters.isEmpty),
        isTrue,
      );
    },
  );

  test(
    'academic writes, cross-role paths and URL injection never reach network',
    () async {
      for (final path in [
        '/api/v1/me/assignments',
        '/api/v1/me/teacher/interventions',
        '/api/v1/me/study-plan/items?userid=202',
        'https://other.example.test/api/v1/me/study-plan/items',
      ]) {
        await expectLater(
          client.mutateWorkflow('POST', path),
          throwsA(isA<ConfigurationFailure>()),
        );
      }
      await expectLater(
        client.mutateWorkflow('DELETE', '/api/v1/me/study-plan/items/../201'),
        throwsA(isA<ConfigurationFailure>()),
      );
      expect(requests, isEmpty);
    },
  );

  test('teacher writes use only current teacher identity', () async {
    await identity.select('GV001');
    dio.options.headers['X-Demo-Student-Code'] = 'SV002';
    await client.mutateWorkflow(
      'POST',
      '/api/v1/me/teacher/interventions',
      role: DluRole.teacher,
      data: {'courseId': '11', 'studentId': '201'},
    );
    expect(requests.single.headers['X-Demo-Teacher-Code'], 'GV001');
    expect(
      requests.single.headers.keys.any(
        (k) => k.toLowerCase() == 'x-demo-student-code',
      ),
      isFalse,
    );
    await expectLater(
      client.getWorkflowList('/api/v1/me/study-plan'),
      throwsA(isA<ConfigurationFailure>()),
    );
    expect(requests, hasLength(1));
  });

  test(
    'late mutation response cannot populate another identity view',
    () async {
      final pending = Completer<RequestInterceptorHandler>();
      late RequestOptions captured;
      dio.interceptors.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            captured = r;
            pending.complete(h);
          },
        ),
      );
      final response = client.mutateWorkflow(
        'PATCH',
        '/api/v1/me/study-plan/items/$id',
        data: {'status': 'handled'},
      );
      final expectation = expectLater(
        response,
        throwsA(isA<AuthenticationFailure>()),
      );
      final handler = await pending.future;
      await identity.select('SV002');
      handler.resolve(
        Response<Object?>(
          requestOptions: captured,
          statusCode: 200,
          data: {
            'data': {'id': id},
          },
        ),
      );
      await expectation;
    },
  );

  test('invalid body response does not expose backend text', () async {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.reject(
          DioException(
            requestOptions: r,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: r,
              statusCode: 400,
              data: {'secret': 'SENTINEL_PRIVATE_VALUE'},
            ),
          ),
        ),
      ),
    );
    try {
      await client.mutateWorkflow(
        'POST',
        '/api/v1/me/study-plan/items',
        data: {},
      );
      fail('Expected safe validation failure');
    } on ValidationFailure catch (error) {
      expect(error.toString(), isNot(contains('SENTINEL_PRIVATE_VALUE')));
    }
  });
}

class _Storage implements StagingIdentityStorage {
  String? value;
  @override
  Future<void> deleteStudentCode() async {
    value = null;
  }

  @override
  Future<String?> readStudentCode() async => value;
  @override
  Future<void> writeStudentCode(String studentCode) async {
    value = studentCode;
  }
}
