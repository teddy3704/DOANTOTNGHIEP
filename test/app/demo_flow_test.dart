import 'dart:io';

import 'package:dlu_lms_mobile/app/app.dart';
import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/dev/fixtures/dev_repositories.dart';
import 'package:dlu_lms_mobile/dev/fixtures/synthetic_fixture_data_source.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/auth/domain/student_identity_provider.dart';
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
    final identity = _FixtureIdentityProvider();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(AppConfig.development()),
          authRepositoryProvider.overrideWithValue(_FixtureAuth(identity)),
          studentIdentityProvider.overrideWithValue(identity),
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

    expect(find.text('Dữ liệu mô phỏng phục vụ phát triển'), findsOneWidget);
    expect(find.text('Sinh viên mẫu 01'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.ensureVisible(find.text('Sinh viên mẫu 01'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sinh viên mẫu 01'));
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
    await tester.tap(find.text('Bài tập').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Theo dõi hạn nộp và kết quả đã được công bố.'),
      findsOneWidget,
    );
    _expectNoTechnicalCopy(tester);

    await tester.tap(find.text('Tiến độ').last);
    await tester.pumpAndSettle();
    expect(find.text('Tiến độ học tập'), findsOneWidget);
    _expectNoTechnicalCopy(tester);

    await tester.tap(find.text('Trang chủ').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Xem lịch'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Xem lịch'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch học tập'), findsOneWidget);
    _expectNoTechnicalCopy(tester);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

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

class _FixtureIdentityProvider implements StudentIdentityProvider {
  String? selectedCode;

  @override
  List<StudentIdentity> get availableIdentities => const <StudentIdentity>[
    StudentIdentity(studentCode: 'SV001', label: 'Sinh viên mẫu 01'),
    StudentIdentity(studentCode: 'SV002', label: 'Sinh viên mẫu 02'),
  ];

  @override
  Future<void> clear() async => selectedCode = null;

  @override
  Future<void> invalidate() async => selectedCode = null;

  @override
  Stream<void> get invalidations => const Stream<void>.empty();

  @override
  Future<StudentIdentity?> restore() async {
    final code = selectedCode;
    if (code == null) return null;
    return availableIdentities.firstWhere(
      (identity) => identity.studentCode == code,
    );
  }

  @override
  Future<void> select(String studentCode) async {
    selectedCode = availableIdentities
        .firstWhere((identity) => identity.studentCode == studentCode)
        .studentCode;
  }
}

class _FixtureAuth implements AuthRepository {
  _FixtureAuth(this.identity);

  final _FixtureIdentityProvider identity;

  @override
  Stream<void> get sessionInvalidations => const Stream<void>.empty();

  @override
  Future<AuthSession?> restoreSession() async {
    final selected = await identity.restore();
    if (selected == null) return null;
    return AuthSession(
      userId: selected.studentCode,
      displayName: 'Nguyễn Minh Anh',
    );
  }

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) => throw UnsupportedError('Sample identity selection is required.');

  @override
  Future<void> signOut() => identity.clear();
}
