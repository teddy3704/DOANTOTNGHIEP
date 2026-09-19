import 'dart:async';

import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/auth/domain/student_identity_provider.dart';
import 'package:dlu_lms_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('staging login never renders password controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.staging()),
          authRepositoryProvider.overrideWithValue(const _NoSessionAuth()),
          studentIdentityProvider.overrideWithValue(const _StagingIdentity()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dữ liệu mô phỏng phục vụ phát triển'), findsOneWidget);
    expect(find.text('Sinh viên mẫu 01'), findsOneWidget);
    expect(find.text('Sinh viên mẫu 02'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Mật khẩu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('development login also uses selectable sample identities', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.development()),
          authRepositoryProvider.overrideWithValue(const _NoSessionAuth()),
          studentIdentityProvider.overrideWithValue(const _StagingIdentity()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dữ liệu mô phỏng phục vụ phát triển'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Mật khẩu'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _NoSessionAuth implements AuthRepository {
  const _NoSessionAuth();

  @override
  Stream<void> get sessionInvalidations => const Stream<void>.empty();

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _StagingIdentity implements StudentIdentityProvider {
  const _StagingIdentity();

  @override
  List<StudentIdentity> get availableIdentities => const <StudentIdentity>[
    StudentIdentity(studentCode: 'SV001', label: 'Sinh viên mẫu 01'),
    StudentIdentity(studentCode: 'SV002', label: 'Sinh viên mẫu 02'),
  ];

  @override
  Future<void> clear() async {}

  @override
  Future<void> invalidate() async {}

  @override
  Stream<void> get invalidations => const Stream<void>.empty();

  @override
  Future<StudentIdentity?> restore() async => null;

  @override
  Future<void> select(String studentCode) async {}
}
