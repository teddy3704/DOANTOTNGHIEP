import 'package:dlu_lms_mobile/dev/fixtures/dev_repositories.dart';
import 'package:dlu_lms_mobile/dev/fixtures/synthetic_fixture_data_source.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('canonical synthetic fixture', () {
    late SyntheticFixtureDataSource source;

    setUp(() => source = SyntheticFixtureDataSource());

    test('loads the fixed-seed 20-table dataset', () async {
      final snapshot = await source.load();

      expect(snapshot.seed, 202608);
      expect(snapshot.tables, hasLength(20));
      expect(snapshot.table('user'), hasLength(23));
      expect(snapshot.table('course_categories'), hasLength(4));
      expect(snapshot.table('course'), hasLength(6));
      expect(
        snapshot
            .table('user')
            .every(
              (row) => fixtureString(row, 'email').endsWith('@example.test'),
            ),
        isTrue,
      );
      expect(
        snapshot.table('user').any((row) => row.containsKey('password')),
        isFalse,
      );
    });

    test('maps enrolment, content, submission states and grades', () async {
      final courses = await DevCourseRepository(source).getMyCourses();
      expect(courses, hasLength(6));
      expect(courses.every((course) => course.progress != null), isTrue);

      final sections = await DevCourseContentRepository(
        source,
      ).getSections(courses.first.id);
      expect(sections.length, inInclusiveRange(3, 8));
      final activities = sections.expand((section) => section.activities);
      expect(
        activities.any(
          (activity) => activity.kind == CourseActivityKind.assignment,
        ),
        isTrue,
      );
      expect(
        activities.any(
          (activity) => activity.kind == CourseActivityKind.resource,
        ),
        isTrue,
      );

      final assignments = await DevAssignmentRepository(
        source,
      ).getAssignments();
      expect(assignments, isNotEmpty);
      expect(
        assignments.map((item) => item.submissionState).toSet(),
        containsAll(<SubmissionState>{
          SubmissionState.notSubmitted,
          SubmissionState.draft,
          SubmissionState.submitted,
          SubmissionState.graded,
        }),
      );
      expect(
        assignments.map((item) => item.timing).toSet(),
        containsAll(<AssignmentTiming>{
          AssignmentTiming.future,
          AssignmentTiming.soon,
          AssignmentTiming.overdue,
        }),
      );

      var gradeCount = 0;
      var hasGradedItem = false;
      for (final course in courses) {
        final grades = await DevGradeRepository(source).getGrades(course.id);
        gradeCount += grades.length;
        hasGradedItem =
            hasGradedItem || grades.any((grade) => grade.finalGrade != null);
      }
      expect(gradeCount, greaterThan(0));
      expect(hasGradedItem, isTrue);
    });

    test('rejects a fixture without the SYNTHETIC_DATA marker', () async {
      final invalid = SyntheticFixtureDataSource(
        loadAsset: (_) async =>
            '{"metadata":{"seed":202608,"reference_time_epoch":1,"source_classification":"DLU_LIVE_EVIDENCE"},"tables":{}}',
      );

      await expectLater(invalid.load(), throwsFormatException);
    });
  });
}
