sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.cause});
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure(super.message, {super.code, super.cause});
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(super.message, {super.code, super.cause});
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message, {super.code, super.cause});
}

final class MoodleApiFailure extends AppFailure {
  const MoodleApiFailure(super.message, {super.code, super.cause});
}

final class ParsingFailure extends AppFailure {
  const ParsingFailure(super.message, {super.code, super.cause});
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.code, super.cause});
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure(super.message, {super.code, super.cause});
}
