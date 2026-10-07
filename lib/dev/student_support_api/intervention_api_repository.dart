import '../../core/errors/app_failure.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/interventions/domain/intervention_models.dart';
import '../../features/interventions/domain/intervention_repository.dart';
import 'student_support_api_client.dart';

/// Only app-owned support notes/followups are writable, never official grading.
class InterventionApiRepository implements InterventionRepository {
  const InterventionApiRepository(this.client);
  final StudentSupportApiClient client;
  static const _path = '/api/v1/me/teacher/interventions';
  static const _role = DluRole.teacher;

  @override
  Future<List<AttentionStudent>> getAttention() async =>
      (await client.getWorkflowList(
            '/api/v1/me/teacher/attention',
            role: _role,
          ))
          .map((json) => _parse(() => AttentionStudent.fromJson(json)))
          .toList(growable: false);
  @override
  Future<List<TeacherIntervention>> getInterventions() async =>
      (await client.getWorkflowList(
        _path,
        role: _role,
      )).map(_intervention).toList(growable: false);
  @override
  Future<TeacherIntervention> createIntervention(
    InterventionDraft draft,
  ) async => _intervention(
    await client.mutateWorkflow(
      'POST',
      _path,
      role: _role,
      data: draft.toJson(),
    ),
  );
  @override
  Future<TeacherIntervention> addFollowup(
    String id,
    FollowupDraft draft,
  ) async => _intervention(
    await client.mutateWorkflow(
      'POST',
      '$_path/$id/followups',
      role: _role,
      data: draft.toJson(),
    ),
  );
}

TeacherIntervention _intervention(StudentSupportJson json) =>
    _parse(() => TeacherIntervention.fromJson(json));
T _parse<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    throw const ParsingFailure('Dữ liệu theo dõi chưa hợp lệ.');
  } on TypeError {
    throw const ParsingFailure('Dữ liệu theo dõi chưa hợp lệ.');
  } on ArgumentError {
    throw const ParsingFailure('Dữ liệu theo dõi chưa hợp lệ.');
  }
}
