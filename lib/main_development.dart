import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'dev/fixtures/dev_repositories.dart';
import 'dev/fixtures/synthetic_fixture_data_source.dart';
import 'features/assignments/domain/assignment_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/calendar/domain/calendar_repository.dart';
import 'features/courses/domain/course_content_repository.dart';
import 'features/courses/domain/course_repository.dart';
import 'features/grades/domain/grade_repository.dart';
import 'features/profile/domain/user_repository.dart';

void main() {
  final fixtures = SyntheticFixtureDataSource();
  runDluLmsApp(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(AppConfig.development()),
      authRepositoryProvider.overrideWithValue(DevAuthRepository(fixtures)),
      courseRepositoryProvider.overrideWithValue(DevCourseRepository(fixtures)),
      courseContentRepositoryProvider.overrideWithValue(
        DevCourseContentRepository(fixtures),
      ),
      assignmentRepositoryProvider.overrideWithValue(
        DevAssignmentRepository(fixtures),
      ),
      gradeRepositoryProvider.overrideWithValue(DevGradeRepository(fixtures)),
      calendarRepositoryProvider.overrideWithValue(
        DevCalendarRepository(fixtures),
      ),
      userRepositoryProvider.overrideWithValue(DevUserRepository(fixtures)),
    ],
  );
}
