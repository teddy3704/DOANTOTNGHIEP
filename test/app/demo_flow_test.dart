import 'package:dlu_lms_mobile/app/app.dart';
import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/dev/fixtures/dev_repositories.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/profile/domain/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('production login fails closed without exposing DEV fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
        ],
        child: const DluLmsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.textContaining('DEV FIXTURE'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên đăng nhập'),
      'synthetic-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      'synthetic-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('DLU chưa xác nhận cơ chế đăng nhập'),
      findsOneWidget,
    );
    expect(find.textContaining('Xin chào'), findsNothing);
  });

  testWidgets(
    'DEV demo reaches dashboard, courses, course detail and profile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            appConfigProvider.overrideWithValue(AppConfig.development()),
            authRepositoryProvider.overrideWithValue(DevAuthRepository()),
            courseRepositoryProvider.overrideWithValue(DevCourseRepository()),
            userRepositoryProvider.overrideWithValue(DevUserRepository()),
          ],
          child: const DluLmsApp(),
        ),
      );
      expect(find.text('Đang chuẩn bị không gian học tập…'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.textContaining('DEV FIXTURE'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập'),
        'synthetic-user',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'synthetic-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Xin chào'), findsOneWidget);
      expect(find.text('Khóa học gần đây'), findsOneWidget);

      await tester.tap(find.text('Khóa học').last);
      await tester.pumpAndSettle();
      expect(find.text('Khóa học của tôi'), findsOneWidget);
      expect(find.text('Phát triển ứng dụng di động'), findsOneWidget);

      await tester.tap(find.text('Phát triển ứng dụng di động'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết khóa học'), findsOneWidget);
      expect(find.text('Nội dung khóa học'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cá nhân').last);
      await tester.pumpAndSettle();
      expect(find.text('Thông tin cá nhân'), findsOneWidget);
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    },
  );
}
