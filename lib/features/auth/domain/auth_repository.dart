import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();
  Future<AuthSession> signIn({
    required String username,
    required String password,
  });
  Future<void> signOut();
}

class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) {
    throw const ConfigurationFailure(
      'DLU chưa xác nhận cơ chế đăng nhập dành cho ứng dụng bên thứ ba.',
      code: 'AUTHENTICATION_METHOD_UNCONFIRMED',
    );
  }

  @override
  Future<void> signOut() async {}
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const UnconfiguredAuthRepository(),
);
