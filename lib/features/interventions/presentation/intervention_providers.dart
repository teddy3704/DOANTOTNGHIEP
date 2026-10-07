import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/intervention_models.dart';
import '../domain/intervention_repository.dart';

final interventionRepositoryProvider = Provider<InterventionRepository>(
  (ref) => const UnconfiguredInterventionRepository(),
);

final teacherAttentionProvider =
    FutureProvider.autoDispose<List<AttentionStudent>>((ref) {
      final auth = ref.watch(authControllerProvider);
      if (auth.status != AuthStatus.authenticated ||
          auth.session?.role != DluRole.teacher) {
        throw const PermissionFailure('Teacher context required');
      }
      return ref.watch(interventionRepositoryProvider).getAttention();
    });

final teacherInterventionsProvider =
    FutureProvider.autoDispose<List<TeacherIntervention>>((ref) {
      final auth = ref.watch(authControllerProvider);
      if (auth.status != AuthStatus.authenticated ||
          auth.session?.role != DluRole.teacher) {
        throw const PermissionFailure('Teacher context required');
      }
      return ref.watch(interventionRepositoryProvider).getInterventions();
    });

typedef TeacherSupportData = ({
  List<AttentionStudent> attention,
  List<TeacherIntervention> interventions,
});

final teacherSupportDataProvider =
    FutureProvider.autoDispose<TeacherSupportData>((ref) async {
      final attention = ref.watch(teacherAttentionProvider.future);
      final interventions = ref.watch(teacherInterventionsProvider.future);
      final results = await Future.wait<Object>([attention, interventions]);
      return (
        attention: results[0] as List<AttentionStudent>,
        interventions: results[1] as List<TeacherIntervention>,
      );
    });

void refreshInterventions(WidgetRef ref) {
  ref.invalidate(teacherAttentionProvider);
  ref.invalidate(teacherInterventionsProvider);
}
