import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../application/study_plan_coordinator.dart';
import '../domain/study_plan.dart';
import '../domain/study_planner_repository.dart';

final studyPlannerClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final studyPlannerOwnerProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider);
  final session = auth.session;
  if (auth.status != AuthStatus.authenticated || session == null) {
    throw const AuthenticationFailure('Vui lòng đăng nhập để mở kế hoạch.');
  }
  if (session.role != DluRole.student) {
    throw const PermissionFailure(
      'Kế hoạch học tập dành cho tài khoản sinh viên.',
    );
  }
  return session.userId;
});

final studyRecommendationsProvider =
    FutureProvider.autoDispose<List<StudyRecommendation>>((ref) {
      ref.watch(studyPlannerOwnerProvider);
      return ref.watch(studyPlannerRepositoryProvider).getRecommendations();
    });

final studyPlanProvider = FutureProvider.autoDispose<List<StudyPlanItem>>((
  ref,
) {
  ref.watch(studyPlannerOwnerProvider);
  return ref.watch(studyPlannerRepositoryProvider).getPlan();
});

final studyPlanCoordinatorProvider = Provider.autoDispose<StudyPlanCoordinator>(
  (ref) {
    final owner = ref.watch(studyPlannerOwnerProvider);
    var active = true;
    ref.onDispose(() => active = false);
    return StudyPlanCoordinator(
      repository: ref.watch(studyPlannerRepositoryProvider),
      reminders: ref.watch(reminderRepositoryProvider),
      ownerId: owner,
      currentOwnerId: () {
        if (!active) return null;
        final auth = ref.read(authControllerProvider);
        return auth.status == AuthStatus.authenticated &&
                auth.session?.role == DluRole.student
            ? auth.session?.userId
            : null;
      },
      clock: ref.watch(studyPlannerClockProvider),
    );
  },
);

void refreshStudyPlanner(WidgetRef ref) {
  ref.invalidate(studyPlanProvider);
  ref.invalidate(studyRecommendationsProvider);
  ref.invalidate(remindersForOwnerProvider);
}
