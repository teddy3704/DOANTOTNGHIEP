import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import 'request_authorizer.dart';

class MoodleApiClient {
  MoodleApiClient({
    required AppConfig config,
    required this.authorizer,
    Dio? dio,
  }) : _moodleOrigin = config.moodleBaseUri,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.moodleBaseUri.toString(),
               connectTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 25),
               responseType: ResponseType.json,
               headers: const <String, Object>{'Accept': 'application/json'},
             ),
           );

  final Dio _dio;
  final Uri _moodleOrigin;
  final RequestAuthorizer authorizer;

  Future<Response<T>> request<T>({
    required String verifiedPath,
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuthentication = true,
    CancelToken? cancelToken,
  }) async {
    if (!verifiedPath.startsWith('/') || verifiedPath.startsWith('//')) {
      throw ArgumentError.value(
        verifiedPath,
        'verifiedPath',
        'A verified same-origin relative path is required.',
      );
    }

    final options = Options(method: method);
    final requestOptions = options.compose(
      _dio.options,
      verifiedPath,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    _ensureSameOrigin(requestOptions.uri);

    if (requiresAuthentication) {
      await authorizer.authorize(requestOptions);
    }

    _ensureSameOrigin(requestOptions.uri);

    try {
      return await _dio.fetch<T>(requestOptions);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on TimeoutException {
      throw const TimeoutFailure('Kết nối tới LMS đã hết thời gian chờ.');
    }
  }

  AppFailure _mapDioException(DioException error) {
    final diagnostic = _buildDiagnostic(error);
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutFailure(
        'Kết nối tới LMS đã hết thời gian chờ.',
        diagnostic: diagnostic,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        'Không thể kết nối tới LMS.',
        diagnostic: diagnostic,
      ),
      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        AuthenticationFailure(
          'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
          diagnostic: diagnostic,
        ),
      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        PermissionFailure(
          'Moodle từ chối quyền truy cập.',
          diagnostic: diagnostic,
        ),
      DioExceptionType.badResponse
          when (error.response?.statusCode ?? 0) >= 500 =>
        ServerFailure('Máy chủ LMS đang gặp sự cố.', diagnostic: diagnostic),
      DioExceptionType.cancel => NetworkFailure(
        'Yêu cầu đã được hủy.',
        code: 'REQUEST_CANCELLED',
        diagnostic: diagnostic,
      ),
      _ => MoodleApiFailure(
        'Moodle trả về phản hồi không hợp lệ.',
        diagnostic: diagnostic,
      ),
    };
  }

  void _ensureSameOrigin(Uri requestUri) {
    if (_isSameOrigin(requestUri)) {
      return;
    }
    throw const ConfigurationFailure(
      'Yêu cầu LMS bị chặn vì origin không khớp cấu hình.',
      code: 'LMS_ORIGIN_MISMATCH',
    );
  }

  NetworkFailureDiagnostic _buildDiagnostic(DioException error) {
    final request = error.requestOptions;
    return NetworkFailureDiagnostic(
      method: _sanitizeMethod(request.method),
      redactedPath: _redactSameOriginPath(request.uri),
      statusCode: error.response?.statusCode,
      transportType: error.type.name,
    );
  }

  String _sanitizeMethod(String method) {
    final normalized = method.trim().toUpperCase();
    const supportedMethods = <String>{
      'DELETE',
      'GET',
      'HEAD',
      'OPTIONS',
      'PATCH',
      'POST',
      'PUT',
    };
    return supportedMethods.contains(normalized) ? normalized : 'UNKNOWN';
  }

  String _redactSameOriginPath(Uri requestUri) {
    if (!_isSameOrigin(requestUri)) {
      return '<cross-origin>';
    }

    if (requestUri.pathSegments.isEmpty) {
      return '/';
    }

    var redactNextSegment = false;
    final safeSegments = requestUri.pathSegments.map((segment) {
      if (redactNextSegment) {
        redactNextSegment = false;
        return '<redacted>';
      }

      final normalized = segment.toLowerCase();
      if (_isSensitivePathKey(normalized)) {
        redactNextSegment = true;
        return '<redacted>';
      }
      return _canonicalSafeStaticPathSegment(segment) ?? '<redacted>';
    });
    return '/${safeSegments.join('/')}';
  }

  bool _isSameOrigin(Uri uri) {
    return uri.scheme.toLowerCase() == _moodleOrigin.scheme &&
        uri.host.toLowerCase() == _moodleOrigin.host &&
        _effectivePort(uri) == _effectivePort(_moodleOrigin);
  }

  int? _effectivePort(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }
    return switch (uri.scheme.toLowerCase()) {
      'https' => 443,
      'http' => 80,
      _ => null,
    };
  }

  bool _isSensitivePathKey(String segment) {
    const sensitiveMarkers = <String>{
      'apikey',
      'api_key',
      'bearer',
      'credential',
      'password',
      'secret',
      'sesskey',
      'token',
    };
    return sensitiveMarkers.any(segment.contains);
  }

  String? _canonicalSafeStaticPathSegment(String segment) {
    const safeMoodlePathSegments = <String>{
      'course',
      'index.php',
      'lib',
      'login',
      'mod',
      'my',
      'profile.php',
      'rest',
      'server.php',
      'service.php',
      'user',
      'view.php',
      'webservice',
    };
    final normalized = segment.toLowerCase();
    return safeMoodlePathSegments.contains(normalized) ? normalized : null;
  }
}

final moodleApiClientProvider = Provider<MoodleApiClient>(
  (ref) => MoodleApiClient(
    config: ref.watch(appConfigProvider),
    authorizer: ref.watch(requestAuthorizerProvider),
  ),
);
