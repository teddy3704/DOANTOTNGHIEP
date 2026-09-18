import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/features/profile/domain/app_user.dart';
import 'package:dlu_lms_mobile/features/profile/domain/user_repository.dart';
import 'package:dlu_lms_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows only useful profile and settings information', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(AppConfig.development()),
          userRepositoryProvider.overrideWithValue(
            const _UserRepository(
              AppUser(
                id: 'fictional-user',
                displayName: 'Nguyễn Minh Anh',
                email: 'minh.anh@example.test',
                roleLabel: 'Sinh viên',
                faculty: 'Khoa Công nghệ thông tin',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('minh.anh@example.test'), findsOneWidget);
    expect(find.text('Tùy chọn ứng dụng'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(find.textContaining('Token'), findsNothing);
    expect(find.textContaining('lms.dlu.edu.vn'), findsNothing);
    expect(find.textContaining('Mã người dùng'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank display name has a safe fallback', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(AppConfig.development()),
          userRepositoryProvider.overrideWithValue(
            const _UserRepository(
              AppUser(id: 'fictional-user', displayName: ''),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NH'), findsOneWidget);
    expect(find.text('Người học'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staging profile retains identity but hides logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(AppConfig.staging()),
          userRepositoryProvider.overrideWithValue(
            const _UserRepository(
              AppUser(
                id: 'SV001',
                displayName: 'Nguyễn Minh Anh',
                idNumber: 'SV001',
                roleLabel: 'Sinh viên',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mã sinh viên'), findsOneWidget);
    expect(find.text('SV001'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _UserRepository implements UserRepository {
  const _UserRepository(this.user);

  final AppUser user;

  @override
  Future<AppUser> getCurrentUser() async => user;
}
