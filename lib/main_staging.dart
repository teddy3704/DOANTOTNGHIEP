import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'dev/student_support_api/student_support_api_client.dart';
import 'dev/student_support_api/student_support_repositories.dart';
import 'dev/student_support_api/student_support_staging_config.dart';
import 'dev/student_support_api/staging_student_identity_provider.dart';
import 'features/assignments/domain/assignment_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/domain/student_identity_provider.dart';
import 'features/calendar/domain/calendar_repository.dart';
import 'features/courses/domain/course_content_repository.dart';
import 'features/courses/domain/course_repository.dart';
import 'features/grades/domain/grade_repository.dart';
import 'features/profile/domain/user_repository.dart';
import 'dev/student_support_api/teacher_support_api_repository.dart';
import 'features/teacher/domain/teacher_support_repository.dart';
import 'dev/student_support_api/study_planner_api_repository.dart';
import 'dev/student_support_api/intervention_api_repository.dart';
import 'features/study_planner/domain/study_planner_repository.dart';
import 'features/interventions/presentation/intervention_providers.dart';

/// Explicit staging entrypoint: academic reads and app-owned learning support.
///
/// It is not selected by `main.dart`, does not implement DLU password login, and
/// never falls back from a production API request to development data.
void main() {
  final stagingConfig = StudentSupportStagingConfig.fromEnvironment();
  final identityProvider = StagingStudentIdentityProvider(includeTeacher: true);
  final client = StudentSupportApiClient(
    config: stagingConfig,
    identityProvider: identityProvider,
  );
  final teacherRepository = TeacherSupportApiRepository(client);

  runDluLmsApp(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(AppConfig.staging()),
      studentIdentityProvider.overrideWithValue(identityProvider),
      authRepositoryProvider.overrideWithValue(
        StagingPreviewAuthRepository(
          client,
          identityProvider,
          teacherRepository: teacherRepository,
        ),
      ),
      userRepositoryProvider.overrideWithValue(
        StagingUserRepository(
          client,
          identityProvider: identityProvider,
          teacherRepository: teacherRepository,
        ),
      ),
      teacherSupportRepositoryProvider.overrideWithValue(teacherRepository),
      studyPlannerRepositoryProvider.overrideWithValue(
        StudyPlannerApiRepository(client),
      ),
      interventionRepositoryProvider.overrideWithValue(
        InterventionApiRepository(client),
      ),
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
