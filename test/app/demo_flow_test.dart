import 'dart:io';

import 'package:dlu_lms_mobile/app/app.dart';
import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/dev/fixtures/dev_repositories.dart';
import 'package:dlu_lms_mobile/dev/fixtures/synthetic_fixture_data_source.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/calendar/domain/calendar_repository.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_content_repository.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/courses/presentation/widgets/course_card.dart';
import 'package:dlu_lms_mobile/features/grades/domain/grade_repository.dart';
import 'package:dlu_lms_mobile/features/profile/domain/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('production login fails closed with student-friendly copy', (
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

    // Android can briefly report a viewport below the screen's outer padding
    // during cold launch. Resize after Splash has left the tree so this
    // specifically exercises LoginScreen's constraint guard.
    tester.view.physicalSize = const Size(390, 40);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();

    expect(find.text('Dịch vụ đăng nhập đang được chuẩn bị'), findsOneWidget);
    expect(find.textContaining('vui lòng quay lại sau'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Tiếp tục'), findsNothing);
    expect(find.textContaining('Xin chào'), findsNothing);
    _expectNoTechnicalCopy(tester);
  });

  testWidgets('student flow reaches all available learning screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixtureJson = File(
      SyntheticFixtureDataSource.assetPath,
    ).readAsStringSync();
    final fixtures = SyntheticFixtureDataSource(
      loadAsset: (_) async => fixtureJson,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(AppConfig.development()),
          authRepositoryProvider.overrideWithValue(DevAuthRepository(fixtures)),
          courseRepositoryProvider.overrideWithValue(
            DevCourseRepository(fixtures),
          ),
          courseContentRepositoryProvider.overrideWithValue(
            DevCourseContentRepository(fixtures),
          ),
          assignmentRepositoryProvider.overrideWithValue(
            DevAssignmentRepository(fixtures),
          ),
          gradeRepositoryProvider.overrideWithValue(
            DevGradeRepository(fixtures),
          ),
          calendarRepositoryProvider.overrideWithValue(
            DevCalendarRepository(fixtures),
          ),
          userRepositoryProvider.overrideWithValue(DevUserRepository(fixtures)),
        ],
        child: const DluLmsApp(),
      ),
    );
    expect(find.text('Đang chuẩn bị không gian học tập…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsOneWidget);
    _expectNoTechnicalCopy(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên đăng nhập'),
      'synthetic-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      'synthetic-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' | ');
    expect(
      find.textContaining('Xin chào'),
      findsOneWidget,
      reason: 'Visible text after DEV sign-in: $visibleText',
    );
    expect(find.text('Việc cần ưu tiên'), findsOneWidget);
    _expectNoTechnicalCopy(tester);

    await tester.ensureVisible(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Bài tập'), findsOneWidget);
    expect(find.text('Kết quả'), findsOneWidget);
    _expectNoTechnicalCopy(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khóa học').last);
    await tester.pumpAndSettle();
    expect(find.text('Khóa học của tôi'), findsOneWidget);
    expect(find.byType(CourseCard), findsWidgets);
    _expectNoTechnicalCopy(tester);

    await tester.tap(find.byType(CourseCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết khóa học'), findsOneWidget);
    expect(find.text('Nội dung khóa học'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
    _expectNoTechnicalCopy(tester);

    await tester.tap(find.byTooltip('Xem điểm khóa học'));
    await tester.pumpAndSettle();
    expect(find.text('Kết quả học tập'), findsOneWidget);
    expect(find.text('Các mục đánh giá'), findsOneWidget);
    _expectNoTechnicalCopy(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch').last);
    await tester.pumpAndSettle();
    expect(find.text('Lịch học tập'), findsOneWidget);
    _expectNoTechnicalCopy(tester);

    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ').first, findsOneWidget);
    expect(find.text('Sinh viên'), findsOneWidget);
    expect(find.text('Tùy chọn ứng dụng'), findsOneWidget);
    final initialsFinder = find.text('NA');
    final initials = tester.widget<Text>(initialsFinder);
    expect(
      initials.style?.color,
      Theme.of(tester.element(initialsFinder)).colorScheme.onPrimaryContainer,
    );
    _expectNoTechnicalCopy(tester);
  });
}

void _expectNoTechnicalCopy(WidgetTester tester) {
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  final forbidden = RegExp(
    r'(^|[^a-z])(dev|fixture|mock|synthetic|debug|api|token|endpoint|repository|schema|metadata|placeholder|production)([^a-z]|$)|mẫu|kiểm thử|demo',
    caseSensitive: false,
  );
  expect(forbidden.hasMatch(visibleText), isFalse, reason: visibleText);
}
