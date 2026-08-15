import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'assignment.dart';

abstract interface class AssignmentRepository {
  Future<List<AssignmentDetail>> getAssignments({String? courseId});
  Future<AssignmentDetail> getAssignment(String assignmentId);
}

class UnconfiguredAssignmentRepository implements AssignmentRepository {
  const UnconfiguredAssignmentRepository();

  @override
  Future<AssignmentDetail> getAssignment(String assignmentId) {
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

final assignmentDetailProvider = FutureProvider.autoDispose
    .family<AssignmentDetail, String>(
      (ref, assignmentId) =>
          ref.watch(assignmentRepositoryProvider).getAssignment(assignmentId),
    );
