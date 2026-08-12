import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores an authenticated session', () async {
    final controller = AuthController(
      _FakeAuthRepository(
        restoredSession: const AuthSession(
          userId: 'student-1',
          displayName: 'Student One',
        ),
      ),
    );

    await controller.restoreSession();

    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.session?.userId, 'student-1');
  });

  test(
    'keeps user unauthenticated when repository is not configured',
    () async {
      final controller = AuthController(const UnconfiguredAuthRepository());
      await controller.restoreSession();

      final success = await controller.signIn(
        username: 'synthetic',
        password: 'not-a-real-password',
      );

      expect(success, isFalse);
      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.error, isA<ConfigurationFailure>());
    },
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoredSession});

  final AuthSession? restoredSession;

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async =>
      const AuthSession(userId: 'student-1', displayName: 'Student One');

  @override
  Future<void> signOut() async {}
}
