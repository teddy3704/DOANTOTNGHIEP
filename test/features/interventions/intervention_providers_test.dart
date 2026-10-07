import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dlu_lms_mobile/features/interventions/presentation/intervention_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support_test_fixtures.dart';

void main() {
  test('student context is rejected before repository access', () async {
    final repo = RecordingInterventions();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockSupportAuth(role: DluRole.student),
        ),
        interventionRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();
    await expectLater(
      container.read(teacherAttentionProvider.future),
      throwsA(isA<PermissionFailure>()),
    );
    await expectLater(
      container.read(teacherInterventionsProvider.future),
      throwsA(isA<PermissionFailure>()),
    );
    expect(repo.attentionCalls + repo.recordCalls, 0);
  });
  test(
    'teacher context switch refreshes data and logout drops authorization',
    () async {
      final auth = MockSupportAuth();
      final repo = RecordingInterventions();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          interventionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();
      final subscription = container.listen(
        teacherSupportDataProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(teacherSupportDataProvider.future);
      expect(repo.attentionCalls, 1);
      auth.userId = 'teacher-other';
      await container.read(authControllerProvider.notifier).restoreSession();
      await container.read(teacherSupportDataProvider.future);
      expect(repo.attentionCalls, 2);
      expect(repo.recordCalls, 2);
      await container.read(authControllerProvider.notifier).signOut();
      await expectLater(
        container.read(teacherSupportDataProvider.future),
        throwsA(isA<PermissionFailure>()),
      );
      expect(repo.attentionCalls, 2);
    },
  );
}
