import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'study_plan.dart';

abstract interface class StudyPlannerRepository {
  Future<List<StudyRecommendation>> getRecommendations();
  Future<List<StudyPlanItem>> getPlan();
  Future<StudyPlanItem> createItem({
    required String assignmentId,
    required DateTime scheduledStartAt,
    required int estimatedMinutes,
    required String notes,
  });
  Future<StudyPlanItem> updateItem(
    String id, {
    DateTime? scheduledStartAt,
    int? estimatedMinutes,
    String? notes,
    StudyPlanStatus? status,
  });
  Future<void> deleteItem(String id);
}

class UnconfiguredStudyPlannerRepository implements StudyPlannerRepository {
  const UnconfiguredStudyPlannerRepository();

  Never _unavailable() => throw const ConfigurationFailure(
    'Kế hoạch học tập chưa khả dụng. Vui lòng thử lại sau.',
    code: 'STUDY_PLANNER_UNCONFIGURED',
  );

  @override
  Future<List<StudyRecommendation>> getRecommendations() async =>
      _unavailable();
  @override
  Future<List<StudyPlanItem>> getPlan() async => _unavailable();
  @override
  Future<StudyPlanItem> createItem({
    required String assignmentId,
    required DateTime scheduledStartAt,
    required int estimatedMinutes,
    required String notes,
  }) async => _unavailable();
  @override
  Future<StudyPlanItem> updateItem(
    String id, {
    DateTime? scheduledStartAt,
    int? estimatedMinutes,
    String? notes,
    StudyPlanStatus? status,
  }) async => _unavailable();
  @override
  Future<void> deleteItem(String id) async => _unavailable();
}

final studyPlannerRepositoryProvider = Provider<StudyPlannerRepository>(
  (ref) => const UnconfiguredStudyPlannerRepository(),
);
