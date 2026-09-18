import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'assignment.dart';

abstract interface class AssignmentRepository {
  Future<List<AssignmentDetail>> getAssignments({String? courseId});
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  });
}

class UnconfiguredAssignmentRepository implements AssignmentRepository {
  const UnconfiguredAssignmentRepository();

  @override
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  }) {
    throw const ConfigurationFailure(
      'API bài tập DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
    );
  }

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) {
    throw const ConfigurationFailure(
      'API danh sách bài tập DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
    );
  }
}

final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => const UnconfiguredAssignmentRepository(),
);

final upcomingAssignmentsProvider =
    FutureProvider.autoDispose<List<AssignmentDetail>>(
      (ref) => ref.watch(assignmentRepositoryProvider).getAssignments(),
    );

class AssignmentReference {
  const AssignmentReference({
    required this.courseId,
    required this.assignmentId,
  });

  final String courseId;
  final String assignmentId;

  @override
  bool operator ==(Object other) =>
      other is AssignmentReference &&
      other.courseId == courseId &&
      other.assignmentId == assignmentId;

  @override
  int get hashCode => Object.hash(courseId, assignmentId);
}

final assignmentDetailProvider = FutureProvider.autoDispose
    .family<AssignmentDetail, AssignmentReference>(
      (ref, reference) => ref
          .watch(assignmentRepositoryProvider)
          .getAssignment(reference.assignmentId, courseId: reference.courseId),
    );
