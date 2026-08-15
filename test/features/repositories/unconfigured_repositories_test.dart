import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/calendar/domain/calendar_repository.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_content_repository.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/grades/domain/grade_repository.dart';
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

  test('new student repositories also fail closed in production', () async {
    const content = UnconfiguredCourseContentRepository();
    const assignments = UnconfiguredAssignmentRepository();
    const grades = UnconfiguredGradeRepository();
    const calendar = UnconfiguredCalendarRepository();

    for (final call in <Future<Object?> Function()>[
      () => content.getSections('2001'),
      () => assignments.getAssignments(),
      () => assignments.getAssignment('5001'),
      () => grades.getGrades('2001'),
      calendar.getUpcomingEvents,
    ]) {
      expect(
        call,
        throwsA(
          isA<ConfigurationFailure>().having(
            (failure) => failure.code,
            'code',
            'MOODLE_WEB_SERVICES_NOT_ENABLED',
          ),
        ),
      );
    }
  });
}
