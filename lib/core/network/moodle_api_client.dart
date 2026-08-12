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
  }) : _dio =
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

    if (requiresAuthentication) {
      await authorizer.authorize(requestOptions);
    }

    try {
      return await _dio.fetch<T>(requestOptions);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on TimeoutException catch (error) {
      throw TimeoutFailure(
        'Kết nối tới LMS đã hết thời gian chờ.',
        cause: error,
      );
    }
  }

  AppFailure _mapDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutFailure(
        'Kết nối tới LMS đã hết thời gian chờ.',
        cause: error,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        'Không thể kết nối tới LMS.',
        cause: error,
      ),
      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        AuthenticationFailure(
          'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
          cause: error,
        ),
      DioExceptionType.badResponse when error.response?.statusCode == 403 =>
        PermissionFailure('Moodle từ chối quyền truy cập.', cause: error),
      DioExceptionType.badResponse
          when (error.response?.statusCode ?? 0) >= 500 =>
        ServerFailure('Máy chủ LMS đang gặp sự cố.', cause: error),
      DioExceptionType.cancel => NetworkFailure(
        'Yêu cầu đã được hủy.',
        code: 'REQUEST_CANCELLED',
        cause: error,
      ),
      _ => MoodleApiFailure(
        'Moodle trả về phản hồi không hợp lệ.',
        cause: error,
      ),
    };
  }
}

final moodleApiClientProvider = Provider<MoodleApiClient>(
  (ref) => MoodleApiClient(
    config: ref.watch(appConfigProvider),
    authorizer: ref.watch(requestAuthorizerProvider),
  ),
);
