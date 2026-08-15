import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'course_content.dart';

abstract interface class CourseContentRepository {
  Future<List<CourseSection>> getSections(String courseId);
}

class UnconfiguredCourseContentRepository implements CourseContentRepository {
  const UnconfiguredCourseContentRepository();

  @override
  Future<List<CourseSection>> getSections(String courseId) {
    throw const ConfigurationFailure(
      'API nội dung khóa học DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
    );
  }
}

final courseContentRepositoryProvider = Provider<CourseContentRepository>(
  (ref) => const UnconfiguredCourseContentRepository(),
);

final courseSectionsProvider = FutureProvider.autoDispose
    .family<List<CourseSection>, String>(
      (ref, courseId) =>
          ref.watch(courseContentRepositoryProvider).getSections(courseId),
    );
