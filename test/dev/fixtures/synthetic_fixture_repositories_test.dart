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

    test(
      'keeps presentation data natural while preserving fixture safety',
      () async {
        final user = await DevUserRepository(source).getCurrentUser();
        expect(user.displayName, 'Nguyễn Minh Anh');
        expect(user.email, 'nguyen.minh.anh@example.test');
        expect(user.roleLabel, 'Sinh viên');
        expect(user.faculty, 'Khoa Công nghệ Thông tin');
        _expectCleanDisplayCopy(<String?>[
          user.displayName,
          user.roleLabel,
          user.faculty,
        ]);

        final courses = await DevCourseRepository(source).getMyCourses();
        for (final course in courses) {
          _expectCleanDisplayCopy(<String?>[
            course.shortName,
            course.fullName,
            course.category,
            course.summary,
            course.nextActivity,
          ]);
          final sections = await DevCourseContentRepository(
            source,
          ).getSections(course.id);
          for (final section in sections) {
            _expectCleanDisplayCopy(<String?>[section.name, section.summary]);
            for (final activity in section.activities) {
              _expectCleanDisplayCopy(<String?>[
                activity.name,
                activity.description,
                activity.fileName,
                activity.statusLabel,
              ]);
            }
          }

          final grades = await DevGradeRepository(source).getGrades(course.id);
          for (final grade in grades) {
            _expectCleanDisplayCopy(<String?>[grade.itemName, grade.feedback]);
          }
        }

        final assignments = await DevAssignmentRepository(
          source,
        ).getAssignments();
        for (final assignment in assignments) {
          _expectCleanDisplayCopy(<String?>[
            assignment.name,
            assignment.description,
            assignment.feedback,
          ]);
        }

        final events = await DevCalendarRepository(source).getUpcomingEvents();
        for (final event in events) {
          _expectCleanDisplayCopy(<String?>[event.name]);
        }
      },
    );

    test('rejects a fixture without the SYNTHETIC_DATA marker', () async {
      final invalid = SyntheticFixtureDataSource(
        loadAsset: (_) async =>
            '{"metadata":{"seed":202608,"reference_time_epoch":1,"source_classification":"DLU_LIVE_EVIDENCE"},"tables":{}}',
      );

      await expectLater(invalid.load(), throwsFormatException);
    });
  });
}

void _expectCleanDisplayCopy(Iterable<String?> values) {
  final technicalMarker = RegExp(
    r'(^|[^a-z])(dev|fixture|mock|synthetic|debug|demo)([^a-z]|$)',
    caseSensitive: false,
  );
  for (final value in values.whereType<String>()) {
    expect(technicalMarker.hasMatch(value), isFalse, reason: value);
    expect(value.toLowerCase().contains('mẫu'), isFalse, reason: value);
    expect(value.toLowerCase().contains('kiểm thử'), isFalse, reason: value);
  }
}
