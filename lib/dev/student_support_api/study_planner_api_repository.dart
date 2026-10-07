import '../../core/errors/app_failure.dart';
import '../../features/study_planner/domain/study_plan.dart';
import '../../features/study_planner/domain/study_planner_repository.dart';
import 'student_support_api_client.dart';

/// Staging app-owned planning. Never alters academic records or falls back.
class StudyPlannerApiRepository implements StudyPlannerRepository {
  const StudyPlannerApiRepository(this.client);
  final StudentSupportApiClient client;
  static const _items = '/api/v1/me/study-plan/items';

  @override
  Future<List<StudyRecommendation>> getRecommendations() async =>
      (await client.getWorkflowList(
        '/api/v1/me/recommendations',
      )).map(parseRecommendation).toList(growable: false);
  @override
  Future<List<StudyPlanItem>> getPlan() async => (await client.getWorkflowList(
    '/api/v1/me/study-plan',
  )).map(parsePlanItem).toList(growable: false);
  @override
  Future<StudyPlanItem> createItem({
    required String assignmentId,
    required DateTime scheduledStartAt,
    required int estimatedMinutes,
    required String notes,
  }) async => parsePlanItem(
    await client.mutateWorkflow(
      'POST',
      _items,
      data: {
        'assignmentId': assignmentId,
        'scheduledStartAt': scheduledStartAt.toUtc().toIso8601String(),
        'estimatedMinutes': estimatedMinutes,
        'notes': notes,
      },
    ),
  );
  @override
  Future<StudyPlanItem> updateItem(
    String id, {
    DateTime? scheduledStartAt,
    int? estimatedMinutes,
    String? notes,
    StudyPlanStatus? status,
  }) async => parsePlanItem(
    await client.mutateWorkflow(
      'PATCH',
      '$_items/$id',
      data: {
        if (scheduledStartAt != null)
          'scheduledStartAt': scheduledStartAt.toUtc().toIso8601String(),
        'estimatedMinutes': ?estimatedMinutes,
        'notes': ?notes,
        if (status != null) 'status': status.name,
      },
    ),
  );
  @override
  Future<void> deleteItem(String id) async {
    final result = await client.mutateWorkflow('DELETE', '$_items/$id');
    if (result['deleted'] != true) _invalid();
  }
}

StudyRecommendation parseRecommendation(StudentSupportJson json) =>
    StudyRecommendation(
      assignmentId: _text(json, 'assignmentId'),
      assignmentCode: _text(json, 'assignmentCode'),
      assignmentName: _text(json, 'assignmentName'),
      courseId: _text(json, 'courseId'),
      courseCode: _text(json, 'courseCode'),
      courseName: _text(json, 'courseName'),
      dueAt: _date(json, 'dueAt', optional: true),
      submissionStatus: _text(json, 'submissionStatus'),
      priority: _priority(json),
      reasons: _reasons(json),
      planned: json['planned'] is bool ? json['planned']! as bool : _invalid(),
      recommendedDurationMinutes: _minutes(json, 'recommendedDurationMinutes'),
    );

StudyPlanItem parsePlanItem(StudentSupportJson json) => StudyPlanItem(
  id: _text(json, 'id'),
  assignmentId: _text(json, 'assignmentId'),
  assignmentCode: _text(json, 'assignmentCode'),
  courseId: _text(json, 'courseId'),
  courseName: _text(json, 'courseName'),
  title: _text(json, 'title'),
  dueAt: _date(json, 'dueAt', optional: true),
  priority: _priority(json),
  reasons: _reasons(json),
  scheduledStartAt: _date(json, 'scheduledStartAt')!,
  estimatedMinutes: _minutes(json, 'estimatedMinutes'),
  notes: _text(json, 'notes', allowEmpty: true),
  status: switch (json['status']) {
    'planned' => StudyPlanStatus.planned,
    'handled' => StudyPlanStatus.handled,
    _ => _invalid(),
  },
  createdAt: _date(json, 'createdAt')!,
  updatedAt: _date(json, 'updatedAt')!,
);

Never _invalid() => throw const ParsingFailure(
  'Dữ liệu kế hoạch chưa hợp lệ. Vui lòng thử lại.',
  code: 'STUDY_PLAN_PAYLOAD_INVALID',
);
String _text(StudentSupportJson json, String key, {bool allowEmpty = false}) {
  final value = json[key];
  return value is String && (allowEmpty || value.trim().isNotEmpty)
      ? value
      : _invalid();
}

DateTime? _date(StudentSupportJson json, String key, {bool optional = false}) {
  if (optional && json[key] == null) return null;
  return DateTime.tryParse(_text(json, key)) ?? _invalid();
}

int _minutes(StudentSupportJson json, String key) {
  final value = json[key];
  return value is int && value >= 5 && value <= 480 ? value : _invalid();
}

StudyPriority _priority(StudentSupportJson json) => switch (json['priority']) {
  'high' => StudyPriority.high,
  'medium' => StudyPriority.medium,
  'low' => StudyPriority.low,
  _ => _invalid(),
};
List<String> _reasons(StudentSupportJson json) {
  final value = json['reasons'];
  if (value is! List || value.any((v) => v is! String || v.trim().isEmpty)) {
    _invalid();
  }
  return List<String>.unmodifiable(value.cast<String>());
}
