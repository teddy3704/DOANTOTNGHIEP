import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/profile/domain/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production course repository never returns mock data', () async {
    const repository = UnconfiguredCourseRepository();

    expect(
      repository.getMyCourses,
      throwsA(
        isA<ConfigurationFailure>().having(
          (failure) => failure.code,
          'code',
          'MOODLE_WEB_SERVICES_NOT_ENABLED',
        ),
      ),
    );
  });

  test('production user repository never returns mock data', () async {
    const repository = UnconfiguredUserRepository();

    expect(
      repository.getCurrentUser,
      throwsA(
        isA<ConfigurationFailure>().having(
          (failure) => failure.code,
          'code',
          'MOODLE_WEB_SERVICES_NOT_ENABLED',
        ),
      ),
    );
  });
}
