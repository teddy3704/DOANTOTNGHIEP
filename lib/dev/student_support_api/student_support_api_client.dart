import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/app_failure.dart';
import '../../features/auth/domain/student_identity_provider.dart';
import '../../features/auth/domain/auth_session.dart';
import 'staging_student_identity_provider.dart';
import 'student_support_staging_config.dart';

typedef StudentSupportJson = Map<String, Object?>;

/// HTTPS-only client for scoped staging reads and app-owned support workflows.
/// Academic resources remain GET-only; writes have a separate closed allowlist.
///
/// It deliberately lives in the development layer. It never participates in the
/// production composition root and does not model the development identity as a
/// credential or password.
class StudentSupportApiClient {
  StudentSupportApiClient({
    required StudentSupportStagingConfig config,
    StudentIdentityProvider? identityProvider,
    Dio? dio,
    Duration requestTimeout = const Duration(seconds: 60),
  }) : _origin = config.baseUri,
       // Keep the public named option while its backing field stays private.
       // ignore: prefer_initializing_formals
       _requestTimeout = requestTimeout,
       _identityProvider =
           identityProvider ??
           FixedStagingStudentIdentityProvider(config.studentCode),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.baseUri.toString(),
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 25),
               responseType: ResponseType.json,
               headers: const <String, Object>{'Accept': 'application/json'},
             ),
           );

  static const _staticPaths = <String>{
    '/health',
    '/api/v1/me',
    '/api/v1/me/courses',
    '/api/v1/me/resources',
    '/api/v1/me/assignments',
    '/api/v1/me/assignment-status',
    '/api/v1/me/grades',
    '/api/v1/me/progress',
    '/api/v1/me/deadlines',
    '/api/v1/me/overview',
    '/api/v1/me/teacher/overview',
  };
  static final _courseContentPath = RegExp(
    r'^/api/v1/me/courses/[1-9][0-9]{0,14}/content$',
  );
  static final _teacherStudentsPath = RegExp(
    r'^/api/v1/me/teacher/courses/[1-9][0-9]{0,14}/students$',
  );

  final Dio _dio;
  final Uri _origin;
  final StudentIdentityProvider _identityProvider;
  final Duration _requestTimeout;

  Future<void> getHealth() async {
    final response = await _get('/health', includeStudentCode: false);
    _expectObject(response.data);
  }

  Future<StudentSupportJson> getProfile() => _getObject('/api/v1/me');

  Future<List<StudentSupportJson>> getCourses() =>
      _getList('/api/v1/me/courses');

  Future<List<StudentSupportJson>> getCourseContent(String courseId) {
    _validateCourseId(courseId);
    return _getList('/api/v1/me/courses/$courseId/content');
  }

  Future<List<StudentSupportJson>> getResources() =>
      _getList('/api/v1/me/resources');

  Future<List<StudentSupportJson>> getAssignments() =>
      _getList('/api/v1/me/assignments');

  Future<List<StudentSupportJson>> getAssignmentStatus() =>
      _getList('/api/v1/me/assignment-status');

  Future<List<StudentSupportJson>> getGrades() => _getList('/api/v1/me/grades');

  Future<List<StudentSupportJson>> getProgress() =>
      _getList('/api/v1/me/progress');

  Future<List<StudentSupportJson>> getDeadlines() =>
      _getList('/api/v1/me/deadlines');

  Future<StudentSupportJson> getOverview() => _getObject('/api/v1/me/overview');

  /// Only explicitly reviewed app-owned endpoints may use these methods.
  Future<List<StudentSupportJson>> getWorkflowList(
    String path, {
    DluRole role = DluRole.student,
  }) async {
    _validateWorkflow('GET', path, role);
    final response = await _request(path, role: role);
    final envelope = _expectObject(response.data);
    final data = envelope['data'];
    final meta = _expectObject(envelope['meta']);
    if (data is! List ||
        meta['count'] is! int ||
        meta['count'] != data.length) {
      throw const ParsingFailure('Danh sách hỗ trợ học tập không hợp lệ.');
    }
    return List.unmodifiable(data.map(_expectObject));
  }

  Future<StudentSupportJson> mutateWorkflow(
    String method,
    String path, {
    StudentSupportJson? data,
    DluRole role = DluRole.student,
  }) async {
    _validateWorkflow(method, path, role);
    if (method == 'GET') throw ArgumentError('Use getWorkflowList for reads.');
    final response = await _request(
      path,
      role: role,
      method: method,
      data: data,
    );
    return _expectObject(_expectObject(response.data)['data']);
  }

  static final _planItemPath = RegExp(
    r'^/api/v1/me/study-plan/items/[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
  );
  static final _interventionPath = RegExp(
    r'^/api/v1/me/teacher/interventions/[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
  );
  static final _followupPath = RegExp(
    r'^/api/v1/me/teacher/interventions/[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}/followups$',
  );

  void _validateWorkflow(String method, String path, DluRole role) {
    final allowed = role == DluRole.student
        ? (method == 'GET' &&
                  const {
                    '/api/v1/me/recommendations',
                    '/api/v1/me/study-plan',
                  }.contains(path)) ||
              (method == 'POST' && path == '/api/v1/me/study-plan/items') ||
              (const {'PATCH', 'DELETE'}.contains(method) &&
                  _planItemPath.hasMatch(path))
        : (method == 'GET' &&
                  const {
                    '/api/v1/me/teacher/attention',
                    '/api/v1/me/teacher/interventions',
                  }.contains(path)) ||
              (method == 'POST' &&
                  path == '/api/v1/me/teacher/interventions') ||
              (method == 'PATCH' && _interventionPath.hasMatch(path)) ||
              (method == 'POST' && _followupPath.hasMatch(path));
    if (!allowed) {
      throw const ConfigurationFailure(
        'Chức năng này không thuộc phạm vi hỗ trợ học tập.',
        code: 'WORKFLOW_ROUTE_REJECTED',
      );
    }
  }

  Future<StudentSupportJson> getTeacherOverview() =>
      _getObject('/api/v1/me/teacher/overview', role: DluRole.teacher);

  Future<List<StudentSupportJson>> getTeacherStudents(String courseId) {
    _validateCourseId(courseId);
    return _getList(
      '/api/v1/me/teacher/courses/$courseId/students',
      role: DluRole.teacher,
    );
  }

  Future<StudentSupportJson> _getObject(
    String path, {
    DluRole role = DluRole.student,
  }) async {
    final response = await _get(path, role: role);
    final envelope = _expectObject(response.data);
    return _expectObject(envelope['data']);
  }

  Future<List<StudentSupportJson>> _getList(
    String path, {
    DluRole role = DluRole.student,
  }) async {
    final response = await _get(path, role: role);
    final envelope = _expectObject(response.data);
    final data = envelope['data'];
    final meta = _expectObject(envelope['meta']);
    final count = meta['count'];
    if (data is! List || count is! int || count != data.length) {
      throw const ParsingFailure(
        'Dữ liệu danh sách của môi trường thử nghiệm không hợp lệ.',
        code: 'STAGING_LIST_ENVELOPE_INVALID',
      );
    }
    return List<StudentSupportJson>.unmodifiable(
      data.map<StudentSupportJson>(_expectObject),
    );
  }

  Future<Response<Object?>> _get(
    String path, {
    bool includeStudentCode = true,
    DluRole role = DluRole.student,
  }) async {
    if (!_isAllowedPath(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'Only verified Student Support GET paths are allowed.',
      );
    }

    return _request(path, includeStudentCode: includeStudentCode, role: role);
  }

  Future<Response<Object?>> _request(
    String path, {
    bool includeStudentCode = true,
    DluRole role = DluRole.student,
    String method = 'GET',
    StudentSupportJson? data,
  }) async {
    final studentCode = includeStudentCode ? await _selectedCode(role) : null;
    final options = Options(
      method: method,
      followRedirects: false,
      headers: includeStudentCode
          ? <String, Object>{
              role == DluRole.teacher
                      ? 'X-Demo-Teacher-Code'
                      : 'X-Demo-Student-Code':
                  studentCode!,
            }
          : const <String, Object>{},
    );
    final request = options.compose(_dio.options, path, data: data);
    final cancelToken = CancelToken();
    request.cancelToken = cancelToken;
    // An injected transport must not attach query credentials or identity.
    request.queryParameters.clear();
    // Never inherit the other role's identity from an injected transport.
    request.headers.removeWhere(
      (key, _) => [
        'x-demo-student-code',
        'x-demo-teacher-code',
        'authorization',
        'proxy-authorization',
        'cookie',
        'x-api-key',
      ].contains(key.toLowerCase()),
    );
    if (studentCode != null) {
      request.headers[role == DluRole.teacher
              ? 'X-Demo-Teacher-Code'
              : 'X-Demo-Student-Code'] =
          studentCode;
    }
    _ensureSameOrigin(request.uri);

    try {
      // Socket timeouts do not bound a stalled interceptor or a slow overall
      // request. Give cold starts a finite window; never retry writes silently.
      final response = await _dio
          .fetch<Object?>(request)
          .timeout(
            _requestTimeout,
            onTimeout: () {
              cancelToken.cancel('request deadline');
              throw TimeoutException('request deadline');
            },
          );
      _ensureSameOrigin(response.requestOptions.uri);
      if (studentCode != null &&
          (await _identityProvider.restore())?.id != studentCode) {
        throw const AuthenticationFailure(
          'Ngữ cảnh xem dữ liệu đã thay đổi.',
          code: 'STAGING_IDENTITY_CHANGED',
        );
      }
      return response;
    } on DioException catch (error) {
      final failure = _mapDioException(error, path, method);
      if (failure is AuthenticationFailure &&
          (await _identityProvider.restore())?.id == studentCode) {
        await _identityProvider.invalidate();
      }
      throw failure;
    } on TimeoutException {
      throw const TimeoutFailure(
        'Không thể tải dữ liệu học tập trong thời gian chờ.',
      );
    }
  }

  Future<String> _selectedCode(DluRole role) async {
    final identity = await _identityProvider.restore();
    if (identity == null) {
      throw const AuthenticationFailure(
        'Chưa chọn dữ liệu người học cho môi trường thử nghiệm.',
        code: 'STAGING_IDENTITY_REQUIRED',
      );
    }
    if (identity.role != role) {
      throw ConfigurationFailure(
        'Dữ liệu này không thuộc ngữ cảnh đang chọn.',
        code: role == DluRole.student
            ? 'STUDENT_CONTEXT_REQUIRED'
            : 'TEACHER_CONTEXT_REQUIRED',
      );
    }
    return identity.studentCode;
  }

  bool _isAllowedPath(String path) =>
      _staticPaths.contains(path) ||
      _courseContentPath.hasMatch(path) ||
      _teacherStudentsPath.hasMatch(path);

  void _validateCourseId(String courseId) {
    if (!RegExp(r'^[1-9][0-9]{0,14}$').hasMatch(courseId)) {
      throw const ParsingFailure(
        'Mã khóa học không hợp lệ.',
        code: 'STAGING_COURSE_ID_INVALID',
      );
    }
  }

  void _ensureSameOrigin(Uri uri) {
    if (uri.scheme.toLowerCase() == _origin.scheme &&
        uri.host.toLowerCase() == _origin.host &&
        _effectivePort(uri) == _effectivePort(_origin)) {
      return;
    }
    throw const ConfigurationFailure(
      'Yêu cầu bị chặn vì máy chủ không khớp cấu hình thử nghiệm.',
      code: 'STAGING_API_ORIGIN_MISMATCH',
    );
  }

  int? _effectivePort(Uri uri) {
    if (uri.hasPort) return uri.port;
    return switch (uri.scheme.toLowerCase()) {
      'https' => 443,
      'http' => 80,
      _ => null,
    };
  }

  AppFailure _mapDioException(DioException error, String path, String method) {
    final statusCode = error.response?.statusCode;
    final diagnostic = NetworkFailureDiagnostic(
      method: method,
      redactedPath: _safePath(path),
      statusCode: statusCode,
      transportType: error.type.name,
    );
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutFailure(
        'Không thể tải dữ liệu học tập trong thời gian chờ.',
        diagnostic: diagnostic,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        'Không thể kết nối tới dữ liệu học tập.',
        diagnostic: diagnostic,
      ),
      DioExceptionType.badResponse when statusCode == 401 =>
        const AuthenticationFailure(
          'Phiên xem trước dữ liệu học tập không hợp lệ.',
          code: 'STAGING_IDENTITY_REJECTED',
        ),
      DioExceptionType.badResponse when statusCode == 403 => PermissionFailure(
        'Bạn không có quyền xem dữ liệu học tập này.',
        diagnostic: diagnostic,
      ),
      DioExceptionType.badResponse when statusCode == 429 =>
        const ValidationFailure(
          'Bạn thao tác quá nhanh. Vui lòng thử lại sau một phút.',
        ),
      DioExceptionType.badResponse
          when statusCode == 400 || statusCode == 409 =>
        const ValidationFailure(
          'Không thể lưu thay đổi. Kiểm tra thời gian, nội dung và thử lại.',
        ),
      DioExceptionType.badResponse when statusCode == 404 => MoodleApiFailure(
        'Dữ liệu học tập được yêu cầu không tồn tại.',
        diagnostic: diagnostic,
      ),
      DioExceptionType.badResponse when (statusCode ?? 0) >= 500 =>
        ServerFailure(
          'Dịch vụ dữ liệu học tập đang gặp sự cố.',
          diagnostic: diagnostic,
        ),
      DioExceptionType.cancel => NetworkFailure(
        'Yêu cầu tải dữ liệu đã được hủy.',
        code: 'REQUEST_CANCELLED',
        diagnostic: diagnostic,
      ),
      _ => MoodleApiFailure(
        'Phản hồi dữ liệu học tập không hợp lệ.',
        diagnostic: diagnostic,
      ),
    };
  }

  String _safePath(String path) {
    if (_planItemPath.hasMatch(path)) return '/api/v1/me/study-plan/items/<id>';
    if (_interventionPath.hasMatch(path)) {
      return '/api/v1/me/teacher/interventions/<id>';
    }
    if (_followupPath.hasMatch(path)) {
      return '/api/v1/me/teacher/interventions/<id>/followups';
    }
    if (_teacherStudentsPath.hasMatch(path)) {
      return '/api/v1/me/teacher/courses/<id>/students';
    }
    if (_courseContentPath.hasMatch(path)) {
      return '/api/v1/me/courses/<id>/content';
    }
    return _staticPaths.contains(path) ? path : '<unverified>';
  }
}

StudentSupportJson _expectObject(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      value.map<String, Object?>((key, item) => MapEntry('$key', item)),
    );
  }
  throw const ParsingFailure(
    'Dữ liệu của môi trường thử nghiệm không hợp lệ.',
    code: 'STAGING_OBJECT_INVALID',
  );
}
