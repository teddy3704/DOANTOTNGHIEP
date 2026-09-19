import 'dart:io';
import 'package:dlu_lms_mobile/app/app.dart';
import 'package:dlu_lms_mobile/app/router/app_router.dart';
import 'package:dlu_lms_mobile/app/theme/app_theme.dart';
import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/fixtures/staging_teacher_support_repository.dart';
import 'package:dlu_lms_mobile/dev/fixtures/synthetic_fixture_data_source.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/staging_student_identity_provider.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_api_client.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_repositories.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/auth/domain/student_identity_provider.dart';
import 'package:dlu_lms_mobile/features/teacher/domain/teacher_support_repository.dart';
import 'package:dlu_lms_mobile/features/teacher/presentation/teacher_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Storage implements StagingIdentityStorage {
  String? value;
  @override
  Future<void> deleteStudentCode() async {
    value = null;
  }

  @override
  Future<String?> readStudentCode() async => value;
  @override
  Future<void> writeStudentCode(String code) async {
    value = code;
  }
}

void main() {
  final json = File(SyntheticFixtureDataSource.assetPath).readAsStringSync();
  late StagingStudentIdentityProvider identity;
  late StagingTeacherSupportRepository repository;
  setUp(() {
    identity = StagingStudentIdentityProvider(
      storage: _Storage(),
      includeTeacher: true,
    );
    repository = StagingTeacherSupportRepository(
      identity,
      dataSource: SyntheticFixtureDataSource(loadAsset: (_) async => json),
    );
  });
  test('role and persisted scope restore without any password', () async {
    final storage = _Storage();
    await StagingStudentIdentityProvider(
      storage: storage,
      includeTeacher: true,
    ).select('GV001');
    final restored = await StagingStudentIdentityProvider(
      storage: storage,
      includeTeacher: true,
    ).restore();
    expect(restored?.role, DluRole.teacher);
    expect(restored?.id, 'GV001');
    expect(
      await StagingStudentIdentityProvider(storage: storage).restore(),
      isNull,
    );
  });
  test(
    'teacher repository rejects student, missing identity and logged-out access',
    () async {
      await expectLater(
        repository.getOverview(),
        throwsA(isA<ConfigurationFailure>()),
      );
      await identity.select('SV001');
      await expectLater(
        repository.getOverview(),
        throwsA(isA<ConfigurationFailure>()),
      );
      await identity.select('GV001');
      final data = await repository.getOverview();
      expect(data.profile.email, endsWith('@example.test'));
      expect(data.courses.map((c) => c.id), ['201', '204']);
      for (final c in data.courses) {
        expect(c.studentCount, greaterThan(0));
        for (final w in c.work) {
          expect(w.submitted, inInclusiveRange(0, c.studentCount));
          expect(w.missing + w.submitted, c.studentCount);
        }
      }
      await identity.clear();
      await expectLater(
        repository.getOverview(),
        throwsA(isA<ConfigurationFailure>()),
      );
    },
  );
  test('teacher cannot use the student HTTP identity header', () async {
    await identity.select('GV001');
    final client = StudentSupportApiClient(
      config: StudentSupportStagingConfig.fromEnvironment(),
      identityProvider: identity,
    );
    await expectLater(
      client.getProfile(),
      throwsA(isA<ConfigurationFailure>()),
    );
  });
  for (final width in [320.0, 390.0]) {
    for (final view in TeacherView.values) {
      testWidgets('$view scales at $width with 1.3 text', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await identity.select('GV001');
        final data = await repository.getOverview();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              teacherOverviewProvider.overrideWith((ref) async => data),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 844),
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: Scaffold(body: TeacherSupportScreen(view: view)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextFormField), findsNothing);
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('teacher routes to own shell and cannot enter student routes', (
    tester,
  ) async {
    await identity.select('GV001');
    final client = StudentSupportApiClient(
      config: StudentSupportStagingConfig.fromEnvironment(),
      identityProvider: identity,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.staging()),
        studentIdentityProvider.overrideWithValue(identity),
        authRepositoryProvider.overrideWithValue(
          StagingPreviewAuthRepository(
            client,
            identity,
            teacherRepository: repository,
          ),
        ),
        teacherSupportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DluLmsApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Góc giảng dạy'), findsOneWidget);
    final router = container.read(appRouterProvider);
    router.go('/assignments');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/teacher');
    router.go('/teacher/course/999');
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tìm thấy học phần'), findsOneWidget);
  });
}
