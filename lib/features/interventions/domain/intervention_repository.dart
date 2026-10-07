import '../../../core/errors/app_failure.dart';
import 'intervention_models.dart';

/// App-owned support records only. Authorization and source snapshots are
/// resolved by the backend, never by client-provided user/teacher identity.
abstract interface class InterventionRepository {
  Future<List<AttentionStudent>> getAttention();
  Future<List<TeacherIntervention>> getInterventions();
  Future<TeacherIntervention> createIntervention(InterventionDraft draft);
  Future<TeacherIntervention> addFollowup(String id, FollowupDraft draft);
}

class UnconfiguredInterventionRepository implements InterventionRepository {
  const UnconfiguredInterventionRepository();
  Never _unavailable() => throw const ConfigurationFailure(
    'Dịch vụ hỗ trợ học tập chưa được cấu hình.',
    code: 'INTERVENTION_UNCONFIGURED',
  );
  @override
  Future<List<AttentionStudent>> getAttention() async => _unavailable();
  @override
  Future<List<TeacherIntervention>> getInterventions() async => _unavailable();
  @override
  Future<TeacherIntervention> createIntervention(
    InterventionDraft draft,
  ) async => _unavailable();
  @override
  Future<TeacherIntervention> addFollowup(
    String id,
    FollowupDraft draft,
  ) async => _unavailable();
}
