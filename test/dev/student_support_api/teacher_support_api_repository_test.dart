import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/staging_student_identity_provider.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_api_client.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/teacher_support_api_repository.dart';
import 'package:dlu_lms_mobile/features/teacher/domain/teacher_support_repository.dart';

class _Storage implements StagingIdentityStorage {
  String? value;
  @override
  Future<String?> readStudentCode() async => value;
  @override
  Future<void> writeStudentCode(String code) async {
    value = code;
  }

  @override
  Future<void> deleteStudentCode() async {
    value = null;
  }
}

Map<String, Object?> _overview() => {
  'profile': {
    'teacherCode': 'GV001',
    'role': 'teacher',
    'fullName': 'Giảng viên mẫu',
    'email': 'gv001@example.test',
    'department': 'Công nghệ thông tin',
  },
  'courses': [
    {
      'id': '11',
      'code': 'CS101',
      'name': 'Cơ sở dữ liệu',
      'summary': 'Học phần dữ liệu',
      'studentCount': 4,
      'work': [
        <String, Object?>{
          'title': 'Thiết kế dữ liệu',
          'description': 'Bài tập học phần',
          'dueAt': '2026-09-22T08:00:00Z',
          'submitted': 2,
          'studentCount': 4,
        },
      ],
      'sections': [
        {
          'title': 'Chủ đề 1',
          'resources': ['Tài liệu học phần'],
        },
      ],
    },
  ],
};
Map<String, Object?> _student({String course = '11', num progress = 25}) => {
  'studentId': '201',
  'courseId': course,
  'studentName': 'Sinh viên mẫu',
  'progressPercent': progress,
  'pendingTasks': 2,
  'overdueTasks': 1,
  'riskLevel': 'HIGH',
};
void main() {
  late StagingStudentIdentityProvider identity;
  late StudentSupportApiClient client;
  late TeacherSupportApiRepository repository;
  late List<RequestOptions> requests;
  late void Function(RequestOptions, RequestInterceptorHandler) respond;
  setUp(() async {
    identity = StagingStudentIdentityProvider(
      storage: _Storage(),
      includeTeacher: true,
    );
    await identity.select('GV001');
    requests = [];
    respond = (o, h) => h.resolve(
      Response<Object?>(
        requestOptions: o,
        statusCode: 200,
        data: o.path.endsWith('/students')
            ? {
                'data': [_student()],
                'meta': {'count': 1},
              }
            : {'data': _overview()},
      ),
    );
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://staging.example.test',
        headers: {'X-Demo-Student-Code': 'SV002'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          respond(o, h);
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
    repository = TeacherSupportApiRepository(client);
  });
  test(
    'maps verified Teacher overview and roster with exclusive GET identity',
    () async {
      final data = await repository.getOverview();
      expect(data.profile.id, 'GV001');
      expect(data.courses.single.work.single.missing, 2);
      expect(data.courses.single.sections.single.resources, [
        'Tài liệu học phần',
      ]);
      final roster = await repository.getStudents('11');
      expect(roster.single.supportLevel, LearningSupportLevel.high);
      expect(roster.single.progressPercent, 25);
      for (final r in requests) {
        expect(r.method, 'GET');
        expect(r.followRedirects, isFalse);
        expect(r.headers['X-Demo-Teacher-Code'], 'GV001');
        expect(r.headers.containsKey('X-Demo-Student-Code'), isFalse);
        expect(r.data, isNull);
        expect(r.queryParameters, isEmpty);
      }
    },
  );
  test('rejects Student scope and invalid course before network', () async {
    await expectLater(
      repository.getStudents('../12'),
      throwsA(isA<ParsingFailure>()),
    );
    await identity.select('SV001');
    await expectLater(
      repository.getOverview(),
      throwsA(isA<ConfigurationFailure>()),
    );
    expect(requests, isEmpty);
  });
  test(
    'rejects cross-course roster and invalid progress instead of displaying it',
    () async {
      for (final row in [_student(course: '12'), _student(progress: 101)]) {
        respond = (o, h) => h.resolve(
          Response<Object?>(
            requestOptions: o,
            statusCode: 200,
            data: {
              'data': [row],
              'meta': {'count': 1},
            },
          ),
        );
        await expectLater(
          repository.getStudents('11'),
          throwsA(isA<ParsingFailure>()),
        );
      }
    },
  );
  test('rejects inconsistent submission counts', () async {
    final data = _overview();
    final course = (data['courses']! as List).single as Map;
    ((course['work'] as List).single as Map)['submitted'] = 5;
    respond = (o, h) => h.resolve(
      Response<Object?>(
        requestOptions: o,
        statusCode: 200,
        data: {'data': data},
      ),
    );
    await expectLater(repository.getOverview(), throwsA(isA<ParsingFailure>()));
  });
  test(
    'teacher work retains absent deadline without a fake timestamp',
    () async {
      final data = _overview();
      final course = (data['courses']! as List).single as Map;
      ((course['work'] as List).single as Map)['dueAt'] = null;
      respond = (o, h) => h.resolve(
        Response<Object?>(
          requestOptions: o,
          statusCode: 200,
          data: {'data': data},
        ),
      );
      expect(
        (await repository.getOverview()).courses.single.work.single.dueAt,
        isNull,
      );
    },
  );
  test(
    'server error has no fixture fallback and 401 clears Teacher scope',
    () async {
      for (final status in [503, 401]) {
        respond = (o, h) => h.reject(
          DioException(
            requestOptions: o,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: o,
              statusCode: status,
              data: {'private': 'DO_NOT_DISPLAY'},
            ),
          ),
        );
        await expectLater(
          repository.getOverview(),
          throwsA(
            status == 503 ? isA<ServerFailure>() : isA<AuthenticationFailure>(),
          ),
        );
      }
      expect(await identity.restore(), isNull);
      expect(requests, hasLength(2));
    },
  );
  test('late Teacher response is discarded after scope changes', () async {
    final arrived = Completer<void>();
    late RequestOptions request;
    late RequestInterceptorHandler handler;
    respond = (o, h) {
      request = o;
      handler = h;
      arrived.complete();
    };
    final pending = repository.getOverview();
    final check = expectLater(pending, throwsA(isA<AuthenticationFailure>()));
    await arrived.future;
    await identity.select('SV002');
    handler.resolve(
      Response<Object?>(
        requestOptions: request,
        statusCode: 200,
        data: {'data': _overview()},
      ),
    );
    await check;
    expect((await identity.restore())?.id, 'SV002');
  });
  test('late 401 cannot clear a newly selected Student', () async {
    final arrived = Completer<void>();
    late RequestOptions request;
    late RequestInterceptorHandler handler;
    respond = (o, h) {
      request = o;
      handler = h;
      arrived.complete();
    };
    final check = expectLater(
      repository.getOverview(),
      throwsA(isA<AuthenticationFailure>()),
    );
    await arrived.future;
    await identity.select('SV001');
    handler.reject(
      DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(requestOptions: request, statusCode: 401),
      ),
    );
    await check;
    expect((await identity.restore())?.id, 'SV001');
  });
  test(
    'staging injects real Teacher adapter; production imports no staging adapter',
    () {
      final staging = File('lib/main_staging.dart').readAsStringSync();
      expect(staging, contains('TeacherSupportApiRepository(client)'));
      expect(staging, isNot(contains('dev/fixtures/')));
      final production = File('lib/main.dart').readAsStringSync();
      expect(production, isNot(contains('dev/')));
    },
  );
}
