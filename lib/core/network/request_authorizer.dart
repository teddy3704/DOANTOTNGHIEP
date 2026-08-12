import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';

abstract interface class RequestAuthorizer {
  Future<void> authorize(RequestOptions request);
}

class UnconfiguredRequestAuthorizer implements RequestAuthorizer {
  const UnconfiguredRequestAuthorizer();

  @override
  Future<void> authorize(RequestOptions request) {
    throw const ConfigurationFailure(
      'Cơ chế xác thực của DLU chưa được xác nhận.',
      code: 'AUTHENTICATION_METHOD_UNCONFIRMED',
    );
  }
}

final requestAuthorizerProvider = Provider<RequestAuthorizer>(
  (ref) => const UnconfiguredRequestAuthorizer(),
);
