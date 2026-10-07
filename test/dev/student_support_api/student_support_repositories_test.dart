import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_api_client.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_repositories.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/student_support_staging_config.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/staging_student_identity_provider.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FixtureClient client;

  setUp(() {
    client = _FixtureClient.standard();
  });

  test(
    'group profile maps identity with blank, null or absent department',
    () async {
      for (final value in ['', '   ', null]) {
        client.profile['department'] = value;
        final user = await StagingUserRepository(client).getCurrentUser();
        expect(user.id, 'SV001');
        expect(user.idNumber, 'SV001');
        expect(user.displayName, 'Nguyễn Minh Anh');
        expect(user.email, 'minh.anh@example.test');
        expect(user.roleLabel, 'Sinh viên');
        expect(user.faculty, isNull);
      }
      client.profile.remove('department');
      expect(
        (await StagingUserRepository(client).getCurrentUser()).faculty,
        isNull,
      );
      client.profile['department'] = ' Khoa mẫu ';
      expect(
        (await StagingUserRepository(client).getCurrentUser()).faculty,
        'Khoa mẫu',
      );
    },
  );

  test(
    'profile still rejects malformed metadata and missing identity',
    () async {
      client.profile['department'] = 42;
      await expectLater(
        StagingUserRepository(client).getCurrentUser(),
        throwsA(isA<ParsingFailure>()),
      );
      client.profile.remove('department');
      client.profile.remove('studentCode');
      await expectLater(
        StagingUserRepository(client).getCurrentUser(),
        throwsA(isA<ParsingFailure>()),
      );
    },
  );

  test('maps course progress and only future deadline previews', () async {
    final courses = await StagingCourseRepository(client).getMyCourses();

    final mobile = courses.singleWhere((course) => course.id == '101');
    expect(mobile.progress, 0.65);
    expect(mobile.nextActivity, contains('Bài tập ứng dụng'));
    expect(mobile.nextActivity, isNot(contains('Hạn cũ')));
  });

  test(
    'group model allows empty assignment description without hiding assignments',
    () async {
      client.assignments.first['description'] = '';
      final result = await StagingAssignmentRepository(client).getAssignments();
      expect(result, hasLength(client.assignments.length));
      expect(result.any((a) => a.description.isEmpty), isTrue);
    },
  );

  test(
    'group course activities preserve types and use read-only LMS handoff',
    () async {
      final content = client.contentByCourseId['101']!;
      for (final type in ['quiz', 'folder', 'forum', 'attendance']) {
        content.add({
          ...content.first,
          'courseModuleId': '${900 + content.length}',
          'activityType': type,
          'activityName': 'Nội dung $type',
          'assignmentCode': null,
        });
      }
      final sections = await StagingCourseContentRepository(
        client,
      ).getSections('101');
      expect(
        sections.single.activities.map((a) => a.kind.name),
        containsAll(['quiz', 'folder', 'forum', 'attendance']),
      );
    },
  );

  test(
    'assignment without a deadline stays null, unranked and sorted last',
    () async {
      client.assignments.first['dueAt'] = null;
      final result = await StagingAssignmentRepository(client).getAssignments();
      expect(result.last.dueAt, isNull);
      expect(result.last.timing, AssignmentTiming.noDeadline);
      expect(result.last.timing.label, 'Chưa đặt hạn');
      expect(result.first.dueAt, isNotNull);
    },
  );

  test('maps content joins without fabricating file or cutoff data', () async {
    final sections = await StagingCourseContentRepository(
      client,
    ).getSections('101');

    expect(sections, hasLength(1));
    expect(sections.single.activities, hasLength(2));
    final resource = sections.single.activities.firstWhere(
      (activity) => activity.name == 'Đề cương học phần',
    );
    expect(resource.fileName, 'de-cuong.pdf');
    expect(resource.fileSize, 2048);
    final assignment = sections.single.activities.firstWhere(
      (activity) => activity.kind.name == 'assignment',
    );
    expect(assignment.instanceId, 'SHARED-01');
    expect(assignment.statusLabel, startsWith('Đã nộp'));
  });

  test(
    'scopes repeated assignment codes by course and keeps absent fields null',
    () async {
      final repository = StagingAssignmentRepository(client);

      final mobile = await repository.getAssignment(
        'SHARED-01',
        courseId: '101',
      );
      final database = await repository.getAssignment(
        'SHARED-01',
        courseId: '102',
      );

      expect(mobile.name, 'Bài tập ứng dụng');
      expect(database.name, 'Bài tập cơ sở dữ liệu');
      expect(mobile.cutoffAt, isNull);
      expect(mobile.submissionState, SubmissionState.submitted);

      final grades = await StagingGradeRepository(client).getGrades('101');
      expect(grades.single.minimum, isNull);
      expect(grades.single.finalGrade, 8.5);
    },
  );

  test(
    'calendar only returns future deadlines from the explicitly scoped data',
    () async {
      final events = await StagingCalendarRepository(
        client,
      ).getUpcomingEvents();

      expect(events, isNotEmpty);
      expect(
        events.every((event) => !event.startsAt.isBefore(DateTime.now())),
        isTrue,
      );
      expect(events.map((event) => event.name), isNot(contains('Hạn cũ')));
    },
  );

  test(
    'rejects an invalid course reference before adapter data is used',
    () async {
      await expectLater(
        StagingCourseRepository(client).getCourse('invalid'),
        throwsA(
          isA<ParsingFailure>().having(
            (failure) => failure.code,
            'code',
            'STAGING_ID_INVALID',
          ),
        ),
      );
    },
  );

  test(
    'staging auth requires a selected identity and clears it on sign out',
    () async {
      final storage = _MemoryStagingIdentityStorage();
      final identity = StagingStudentIdentityProvider(storage: storage);
      final repository = StagingPreviewAuthRepository(
        _AuthProfileClient(identity),
        identity,
      );

      expect(await repository.restoreSession(), isNull);

      await identity.select('SV002');
      final session = await repository.restoreSession();
      expect(session?.userId, 'SV002');
      expect(session?.displayName, 'Sinh viên mẫu 02');

      await repository.signOut();
      expect(await repository.restoreSession(), isNull);
      expect(storage.value, isNull);
    },
  );
}

final class _FixtureClient extends StudentSupportApiClient {
  _FixtureClient({
    required this.profile,
    required this.courses,
    required this.progress,
    required this.deadlines,
    required this.resources,
    required this.assignments,
    required this.statuses,
    required this.grades,
    required this.contentByCourseId,
  }) : super(
         config: StudentSupportStagingConfig(
           baseUri: Uri.parse('https://staging.example.test'),
           studentCode: 'SV001',
         ),
       );

  factory _FixtureClient.standard() {
    final future = DateTime.now().add(const Duration(days: 7)).toUtc();
    final past = DateTime.now().subtract(const Duration(days: 2)).toUtc();
    return _FixtureClient(
      profile: <String, Object?>{
        'studentCode': 'SV001',
        'fullName': 'Nguyễn Minh Anh',
        'email': 'minh.anh@example.test',
        'role': 'student',
        'department': 'Công nghệ thông tin',
      },
      courses: const <StudentSupportJson>[
        <String, Object?>{
          'courseId': '101',
          'courseCode': 'MOB101',
          'courseName': 'Phát triển ứng dụng di động',
          'categoryName': 'Công nghệ thông tin',
          'summary': 'Học phần thực hành',
        },
        <String, Object?>{
          'courseId': '102',
          'courseCode': 'DB102',
          'courseName': 'Cơ sở dữ liệu',
          'categoryName': 'Công nghệ thông tin',
          'summary': null,
        },
      ],
      progress: const <StudentSupportJson>[
        <String, Object?>{'courseCode': 'MOB101', 'progressPercent': 65},
        <String, Object?>{'courseCode': 'DB102', 'progressPercent': 40},
      ],
      deadlines: <StudentSupportJson>[
        <String, Object?>{
          'courseCode': 'MOB101',
          'assignmentCode': 'SHARED-01',
          'assignmentName': 'Bài tập ứng dụng',
          'dueAt': future.toIso8601String(),
        },
        <String, Object?>{
          'courseCode': 'MOB101',
          'assignmentCode': 'OLD-01',
          'assignmentName': 'Hạn cũ',
          'dueAt': past.toIso8601String(),
        },
      ],
      resources: const <StudentSupportJson>[
        <String, Object?>{
          'courseId': '101',
          'resourceName': 'Đề cương học phần',
          'filename': 'de-cuong.pdf',
          'mimeType': 'application/pdf',
          'fileSizeBytes': 2048,
        },
      ],
      assignments: <StudentSupportJson>[
        <String, Object?>{
          'courseId': '101',
          'courseCode': 'MOB101',
          'assignmentCode': 'SHARED-01',
          'assignmentName': 'Bài tập ứng dụng',
          'description': 'Hoàn thiện một màn hình di động.',
          'opensAt': future.subtract(const Duration(days: 5)).toIso8601String(),
          'dueAt': future.toIso8601String(),
          'maxGrade': 10,
        },
        <String, Object?>{
          'courseId': '102',
          'courseCode': 'DB102',
          'assignmentCode': 'SHARED-01',
          'assignmentName': 'Bài tập cơ sở dữ liệu',
          'description': 'Thiết kế mô hình dữ liệu.',
          'opensAt': future.subtract(const Duration(days: 4)).toIso8601String(),
          'dueAt': future.add(const Duration(days: 2)).toIso8601String(),
          'maxGrade': 10,
        },
      ],
      statuses: <StudentSupportJson>[
        <String, Object?>{
          'courseCode': 'MOB101',
          'assignmentCode': 'SHARED-01',
          'submissionStatus': 'submitted',
          'submittedAt': future
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
        <String, Object?>{
          'courseCode': 'DB102',
          'assignmentCode': 'SHARED-01',
          'submissionStatus': 'not_submitted',
          'submittedAt': null,
        },
      ],
      grades: const <StudentSupportJson>[
        <String, Object?>{
          'courseCode': 'MOB101',
          'assignmentCode': 'SHARED-01',
          'gradeItem': 'Bài tập ứng dụng',
          'score': 8.5,
          'maxGrade': 10,
          'feedback': 'Trình bày rõ ràng.',
        },
      ],
      contentByCourseId: <String, List<StudentSupportJson>>{
        '101': <StudentSupportJson>[
          <String, Object?>{
            'courseModuleId': '1',
            'courseCode': 'MOB101',
            'sectionNumber': 1,
            'sectionName': 'Tuần 1',
            'activityType': 'resource',
            'activityName': 'Đề cương học phần',
            'description': 'Giới thiệu học phần.',
            'filenames': 'de-cuong.pdf',
            'totalSizeBytes': 2048,
          },
          <String, Object?>{
            'courseModuleId': '2',
            'courseCode': 'MOB101',
            'sectionNumber': 1,
            'sectionName': 'Tuần 1',
            'activityType': 'assign',
            'activityName': 'Bài tập ứng dụng',
            'assignmentCode': 'SHARED-01',
            'description': 'Nộp bài theo yêu cầu.',
            'dueAt': null,
          },
        ],
      },
    );
  }

  final StudentSupportJson profile;
  final List<StudentSupportJson> courses;
  final List<StudentSupportJson> progress;
  final List<StudentSupportJson> deadlines;
  final List<StudentSupportJson> resources;
  final List<StudentSupportJson> assignments;
  final List<StudentSupportJson> statuses;
  final List<StudentSupportJson> grades;
  final Map<String, List<StudentSupportJson>> contentByCourseId;

  @override
  Future<StudentSupportJson> getProfile() async => profile;

  @override
  Future<List<StudentSupportJson>> getCourses() async => courses;

  @override
  Future<List<StudentSupportJson>> getProgress() async => progress;

  @override
  Future<List<StudentSupportJson>> getDeadlines() async => deadlines;

  @override
  Future<List<StudentSupportJson>> getResources() async => resources;

  @override
  Future<List<StudentSupportJson>> getAssignments() async => assignments;

  @override
  Future<List<StudentSupportJson>> getAssignmentStatus() async => statuses;

  @override
  Future<List<StudentSupportJson>> getGrades() async => grades;

  @override
  Future<List<StudentSupportJson>> getCourseContent(String courseId) async =>
      contentByCourseId[courseId] ?? const <StudentSupportJson>[];
}

class _AuthProfileClient extends StudentSupportApiClient {
  _AuthProfileClient(StagingStudentIdentityProvider identity)
    : super(
        config: StudentSupportStagingConfig(
          baseUri: Uri.parse('https://staging.example.test'),
          studentCode: 'SV001',
        ),
        identityProvider: identity,
      );

  @override
  Future<StudentSupportJson> getProfile() async => const <String, Object?>{
    'studentCode': 'SV002',
    'fullName': 'Sinh viên mẫu 02',
    'email': 'sv002@example.test',
    'role': 'student',
    'department': 'Khoa mẫu',
  };
}

class _MemoryStagingIdentityStorage implements StagingIdentityStorage {
  String? value;

  @override
  Future<void> deleteStudentCode() async => value = null;

  @override
  Future<String?> readStudentCode() async => value;

  @override
  Future<void> writeStudentCode(String studentCode) async {
    value = studentCode;
  }
}
