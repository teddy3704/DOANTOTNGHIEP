sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.diagnostic});

  final String message;
  final String? code;
  final AppFailureDiagnostic? diagnostic;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.diagnostic});
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure(super.message, {super.code, super.diagnostic});
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(super.message, {super.code, super.diagnostic});
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message, {super.code, super.diagnostic});
}

final class MoodleApiFailure extends AppFailure {
  const MoodleApiFailure(super.message, {super.code, super.diagnostic});
}

final class ParsingFailure extends AppFailure {
  const ParsingFailure(super.message, {super.code, super.diagnostic});
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.code, super.diagnostic});
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure(super.message, {super.code, super.diagnostic});
}

sealed class AppFailureDiagnostic {
  const AppFailureDiagnostic();
}

final class NetworkFailureDiagnostic extends AppFailureDiagnostic {
  const NetworkFailureDiagnostic({
    required this.method,
    required this.redactedPath,
    required this.transportType,
    this.statusCode,
  });

  final String method;
  final String redactedPath;
  final String transportType;
  final int? statusCode;

  @override
  String toString() {
    return 'NetworkFailureDiagnostic('
        'method: $method, '
        'path: $redactedPath, '
        'status: $statusCode, '
        'type: $transportType)';
  }
}
