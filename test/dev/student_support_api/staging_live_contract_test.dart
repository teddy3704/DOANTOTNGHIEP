import 'package:flutter_test/flutter_test.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_api_client.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_repositories.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/staging_student_identity_provider.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/teacher_support_api_repository.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/study_planner_api_repository.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/intervention_api_repository.dart';

class _Storage implements StagingIdentityStorage {
  String? value;
  @override
  Future<String?> readStudentCode() async => value;
  @override
  Future<void> writeStudentCode(String code) async {
    value = code;
  }

  @override
  Future<void> deleteStudentCode() async {
    value = null;
  }
}

void main() {
  test(
    'opt-in public staging payloads map to every Student/Teacher domain',
    () async {
      final identity = StagingStudentIdentityProvider(
        storage: _Storage(),
        includeTeacher: true,
      );
      final client = StudentSupportApiClient(
        config: StudentSupportStagingConfig.fromEnvironment(),
        identityProvider: identity,
      );
      for (final code in ['SV001', 'SV002']) {
        await identity.select(code);
        final profile = await StagingUserRepository(
          client,
          identityProvider: identity,
        ).getCurrentUser();
        expect(profile.id, code);
        expect(profile.displayName, isNotEmpty);
        expect(
          (await StagingPreviewAuthRepository(
            client,
            identity,
          ).restoreSession())?.userId,
          code,
        );
        expect(await client.getOverview(), isNotEmpty);
        final courses = await StagingCourseRepository(client).getMyCourses();
        expect(courses, hasLength(3));
        expect(
          await StagingAssignmentRepository(client).getAssignments(),
          hasLength(10),
        );
        await StagingCalendarRepository(client).getUpcomingEvents();
        final planner = StudyPlannerApiRepository(client);
        final suggestions = await planner.getRecommendations();
        expect(suggestions, isNotEmpty);
        expect(suggestions.every((r) => r.reasons.isNotEmpty), isTrue);
        await planner.getPlan();
        for (final course in courses) {
          expect(
            await StagingCourseContentRepository(client).getSections(course.id),
            isNotEmpty,
          );
          await StagingGradeRepository(client).getGrades(course.id);
        }
      }
      await identity.select('GV001');
      final teacher = TeacherSupportApiRepository(client);
      final overview = await teacher.getOverview();
      final support = InterventionApiRepository(client);
      expect(await support.getAttention(), isNotEmpty);
      await support.getInterventions();
      expect(overview.courses, hasLength(2));
      for (final course in overview.courses) {
        expect(await teacher.getStudents(course.id), isNotEmpty);
      }
    },
    skip: !const bool.fromEnvironment('RUN_STAGING_LIVE'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
