import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'dev/student_support_api/student_support_api_client.dart';
import 'dev/student_support_api/student_support_repositories.dart';
import 'dev/student_support_api/student_support_staging_config.dart';
import 'features/assignments/domain/assignment_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/calendar/domain/calendar_repository.dart';
import 'features/courses/domain/course_content_repository.dart';
import 'features/courses/domain/course_repository.dart';
import 'features/grades/domain/grade_repository.dart';
import 'features/profile/domain/user_repository.dart';

/// Explicit, read-only entrypoint for the verified Student Support staging API.
///
/// It is not selected by `main.dart`, does not implement DLU password login, and
/// never falls back from a production API request to development data.
void main() {
  final stagingConfig = StudentSupportStagingConfig.fromEnvironment();
  final client = StudentSupportApiClient(config: stagingConfig);

  runDluLmsApp(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(AppConfig.staging()),
      authRepositoryProvider.overrideWithValue(
        StagingPreviewAuthRepository(client),
      ),
      userRepositoryProvider.overrideWithValue(StagingUserRepository(client)),
      courseRepositoryProvider.overrideWithValue(
        StagingCourseRepository(client),
      ),
      courseContentRepositoryProvider.overrideWithValue(
        StagingCourseContentRepository(client),
      ),
      assignmentRepositoryProvider.overrideWithValue(
        StagingAssignmentRepository(client),
      ),
      gradeRepositoryProvider.overrideWithValue(StagingGradeRepository(client)),
      calendarRepositoryProvider.overrideWithValue(
        StagingCalendarRepository(client),
      ),
    ],
  );
}
