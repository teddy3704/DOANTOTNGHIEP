import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'course.dart';

abstract interface class CourseRepository {
  Future<List<Course>> getMyCourses();
  Future<Course> getCourse(String courseId);
}

class UnconfiguredCourseRepository implements CourseRepository {
  const UnconfiguredCourseRepository();

  @override
  Future<List<Course>> getMyCourses() {
    throw const ConfigurationFailure(
      'Danh sách Moodle Web Services của DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_STATUS_REQUIRED',
    );
  }

  @override
  Future<Course> getCourse(String courseId) {
    throw const ConfigurationFailure(
      'API chi tiết khóa học DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_STATUS_REQUIRED',
    );
  }
}

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => const UnconfiguredCourseRepository(),
);

final myCoursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(courseRepositoryProvider).getMyCourses(),
);

final courseDetailProvider = FutureProvider.family<Course, String>(
  (ref, courseId) => ref.watch(courseRepositoryProvider).getCourse(courseId),
);
