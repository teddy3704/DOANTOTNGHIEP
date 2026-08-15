import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'grade_entry.dart';

abstract interface class GradeRepository {
  Future<List<GradeEntry>> getGrades(String courseId);
}

class UnconfiguredGradeRepository implements GradeRepository {
  const UnconfiguredGradeRepository();

  @override
  Future<List<GradeEntry>> getGrades(String courseId) {
    throw const ConfigurationFailure(
      'API điểm DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
    );
  }
}

final gradeRepositoryProvider = Provider<GradeRepository>(
  (ref) => const UnconfiguredGradeRepository(),
);

final courseGradesProvider = FutureProvider.autoDispose
    .family<List<GradeEntry>, String>(
      (ref, courseId) => ref.watch(gradeRepositoryProvider).getGrades(courseId),
    );
