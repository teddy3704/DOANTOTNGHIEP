import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/errors/app_failure.dart';
import 'student_support_staging_config.dart';

typedef StudentSupportJson = Map<String, Object?>;

/// HTTPS-only, GET-only client for the verified Student Support staging API.
///
/// It deliberately lives in the development layer. It never participates in the
/// production composition root and does not model the development identity as a
/// credential or password.
class StudentSupportApiClient {
  StudentSupportApiClient({
    required StudentSupportStagingConfig config,
    Dio? dio,
  }) : _origin = config.baseUri,
       _studentCode = config.studentCode,
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
  };
  static final _courseContentPath = RegExp(
    r'^/api/v1/me/courses/[1-9][0-9]{0,14}/content$',
  );

  final Dio _dio;
  final Uri _origin;
  final String _studentCode;

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

  Future<StudentSupportJson> _getObject(String path) async {
    final response = await _get(path);
    final envelope = _expectObject(response.data);
    return _expectObject(envelope['data']);
  }

  Future<List<StudentSupportJson>> _getList(String path) async {
    final response = await _get(path);
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
  }) async {
    if (!_isAllowedPath(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'Only verified Student Support GET paths are allowed.',
      );
    }

    final options = Options(
      method: 'GET',
      followRedirects: false,
      headers: includeStudentCode
          ? <String, Object>{'X-Demo-Student-Code': _studentCode}
          : const <String, Object>{},
    );
    final request = options.compose(_dio.options, path);
    _ensureSameOrigin(request.uri);

    try {
      final response = await _dio.fetch<Object?>(request);
      _ensureSameOrigin(response.requestOptions.uri);
      return response;
    } on DioException catch (error) {
      throw _mapDioException(error, path);
    } on TimeoutException {
      throw const TimeoutFailure(
        'Không thể tải dữ liệu học tập trong thời gian chờ.',
      );
    }
  }

  bool _isAllowedPath(String path) =>
      _staticPaths.contains(path) || _courseContentPath.hasMatch(path);

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

  AppFailure _mapDioException(DioException error, String path) {
    final statusCode = error.response?.statusCode;
    final diagnostic = NetworkFailureDiagnostic(
      method: 'GET',
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
