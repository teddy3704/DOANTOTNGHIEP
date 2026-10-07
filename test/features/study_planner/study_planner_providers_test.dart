import 'dart:async';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_planner_repository.dart';
import 'package:dlu_lms_mobile/features/study_planner/presentation/study_planner_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'study_planner_fakes.dart';

void main() {
  test(
    'teacher context never reaches student plan or recommendations repository',
    () async {
      final repository = MemoryStudyRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MemoryStudyAuth(role: DluRole.teacher),
          ),
          studyPlannerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();
      await expectLater(
        container.read(studyPlanProvider.future),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        container.read(studyRecommendationsProvider.future),
        throwsA(isA<PermissionFailure>()),
      );
      expect(repository.planReads + repository.recommendationReads, 0);
    },
  );

  test('checking session never permits student requests', () async {
    final auth = MemoryStudyAuth()..pending = Completer<AuthSession?>();
    final repository = MemoryStudyRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        studyPlannerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(studyPlanProvider.future),
      throwsA(isA<AuthenticationFailure>()),
    );
    expect(repository.planReads, 0);
    auth.pending!.complete(null);
  });

  test(
    'student identity changes reload both sources and logout rejects reads',
    () async {
      final auth = MemoryStudyAuth();
      final repository = MemoryStudyRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          studyPlannerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();
      final plans = container.listen(studyPlanProvider, (_, _) {});
      final recommendations = container.listen(
        studyRecommendationsProvider,
        (_, _) {},
      );
      addTearDown(plans.close);
      addTearDown(recommendations.close);
      await container.read(studyPlanProvider.future);
      await container.read(studyRecommendationsProvider.future);
      expect(repository.planReads, 1);
      expect(repository.recommendationReads, 1);
      auth.userId = 'student-2';
      await container.read(authControllerProvider.notifier).restoreSession();
      await container.read(studyPlanProvider.future);
      await container.read(studyRecommendationsProvider.future);
      expect(repository.planReads, 2);
      expect(repository.recommendationReads, 2);
      await container.read(authControllerProvider.notifier).signOut();
      await expectLater(
        container.read(studyPlanProvider.future),
        throwsA(isA<AuthenticationFailure>()),
      );
      await expectLater(
        container.read(studyRecommendationsProvider.future),
        throwsA(isA<AuthenticationFailure>()),
      );
      expect(repository.planReads + repository.recommendationReads, 4);
    },
  );
}
