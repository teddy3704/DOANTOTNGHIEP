import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlu_lms_mobile/app/theme/app_theme.dart';
import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/features/profile/domain/app_user.dart';
import 'package:dlu_lms_mobile/features/profile/domain/user_repository.dart';
import 'package:dlu_lms_mobile/features/profile/presentation/screens/profile_screen.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('profile renders absent optional metadata at $width/1.3', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.staging()),
            currentUserProvider.overrideWith(
              (ref) async => const AppUser(
                id: 'SV001',
                displayName: 'Sinh viên mẫu',
                roleLabel: 'Sinh viên',
                idNumber: 'SV001',
                email: 'sv001@example.test',
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: const TextScaler.linear(1.3),
              ),
              child: const Scaffold(body: ProfileScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sinh viên mẫu'), findsOneWidget);
      expect(find.text('sv001@example.test'), findsOneWidget);
      expect(find.text('SV001'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
