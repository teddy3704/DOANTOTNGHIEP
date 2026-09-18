import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
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
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bản xem trước dữ liệu mẫu'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Mật khẩu'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _NoSessionAuth implements AuthRepository {
  const _NoSessionAuth();

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
