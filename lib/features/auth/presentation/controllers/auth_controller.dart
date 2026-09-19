import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_repository.dart';
import '../../domain/auth_session.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.error,
    this.isSubmitting = false,
  });

  const AuthState.checking() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final AuthSession? session;
  final Object? error;
  final bool isSubmitting;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    Object? error,
    bool clearError = false,
    bool? isSubmitting,
  }) => AuthState(
    status: status ?? this.status,
    session: session ?? this.session,
    error: clearError ? null : error ?? this.error,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.checking()) {
    _invalidations = _repository.sessionInvalidations.listen((_) {
      if (!mounted) return;
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
    restoreSession();
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _invalidations;

  @override
  void dispose() {
    _invalidations.cancel();
    super.dispose();
  }

  Future<void> restoreSession() async {
    try {
      final session = await _repository.restoreSession();
      if (!mounted) return;
      state = session == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, session: session);
    } on Object catch (error) {
      if (!mounted) return;
      state = AuthState(status: AuthStatus.unauthenticated, error: error);
    }
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final session = await _repository.signIn(
        username: username,
        password: password,
      );
      if (!mounted) return false;
      state = AuthState(status: AuthStatus.authenticated, session: session);
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error,
        isSubmitting: false,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } finally {
      if (mounted) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
