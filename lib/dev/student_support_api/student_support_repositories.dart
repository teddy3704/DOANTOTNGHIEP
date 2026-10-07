import 'dart:async';

import '../../core/errors/app_failure.dart';
import '../../core/parsing/api_timestamp.dart';
import '../../features/assignments/domain/assignment.dart';
import '../../features/assignments/domain/assignment_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/domain/student_identity_provider.dart';
import '../../features/calendar/domain/calendar_repository.dart';
import '../../features/calendar/domain/learning_event.dart';
import '../../features/courses/domain/course.dart';
import '../../features/courses/domain/course_content.dart';
import '../../features/courses/domain/course_content_repository.dart';
import '../../features/courses/domain/course_repository.dart';
import '../../features/grades/domain/grade_entry.dart';
import '../../features/grades/domain/grade_repository.dart';
import '../../features/profile/domain/app_user.dart';
import '../../features/profile/domain/user_repository.dart';
import '../../features/teacher/domain/teacher_support_repository.dart';
import 'student_support_api_client.dart';

/// Read-only repository adapters for the explicitly selected staging API.
///
/// These adapters are injected only by `main_staging.dart`. Production uses the
/// unconfigured Moodle repositories and never falls back to these values.
class StagingPreviewAuthRepository implements AuthRepository {
  StagingPreviewAuthRepository(
    this._client,
    this._identityProvider, {
    this.teacherRepository,
  });

  final TeacherSupportRepository? teacherRepository;

  final StudentSupportApiClient _client;
  final StudentIdentityProvider _identityProvider;

  @override
  Stream<void> get sessionInvalidations => _identityProvider.invalidations;

  @override
  Future<AuthSession?> restoreSession() async {
    final identity = await _identityProvider.restore();
    if (identity == null) return null;
    if (identity.role == DluRole.teacher) {
      final repository = teacherRepository;
      if (repository == null) {
        throw const ConfigurationFailure(
          'Kết nối giảng dạy chưa được cấu hình.',
          code: 'TEACHER_SUPPORT_UNCONFIGURED',
        );
      }
      final overview = await repository.getOverview();
      return AuthSession(
        userId: overview.profile.id,
        displayName: overview.profile.displayName,
        role: DluRole.teacher,
      );
    }
    final profile = await _client.getProfile();
    return AuthSession(
      userId: _requiredString(profile, 'studentCode'),
      displayName: _requiredString(profile, 'fullName'),
    );
  }

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) {
    throw const ConfigurationFailure(
      'Môi trường này không hỗ trợ đăng nhập bằng mật khẩu.',
      code: 'STAGING_INTERACTIVE_AUTH_UNSUPPORTED',
    );
  }

  @override
  Future<void> signOut() => _identityProvider.clear();
}

class StagingUserRepository implements UserRepository {
  StagingUserRepository(
    this._client, {
    this.identityProvider,
    this.teacherRepository,
  });

  final StudentIdentityProvider? identityProvider;
  final TeacherSupportRepository? teacherRepository;

  final StudentSupportApiClient _client;

  @override
  Future<AppUser> getCurrentUser() async {
    if ((await identityProvider?.restore())?.role == DluRole.teacher) {
      final repository = teacherRepository;
      if (repository == null) {
        throw const ConfigurationFailure(
          'Kết nối giảng dạy chưa được cấu hình.',
          code: 'TEACHER_SUPPORT_UNCONFIGURED',
        );
      }
      return (await repository.getOverview()).profile;
    }
    final profile = await _client.getProfile();
    final role = _requiredString(profile, 'role');
    if (role != 'student') {
      throw const ParsingFailure(
        'Vai trò dữ liệu học tập không được hỗ trợ.',
        code: 'STAGING_ROLE_INVALID',
      );
    }
    return AppUser(
      id: _requiredString(profile, 'studentCode'),
      displayName: _requiredString(profile, 'fullName'),
      email: _requiredString(profile, 'email'),
      idNumber: _requiredString(profile, 'studentCode'),
      roleLabel: 'Sinh viên',
      faculty: _nullableNonEmptyString(profile, 'department'),
    );
  }
}

class StagingCourseRepository implements CourseRepository {
  StagingCourseRepository(this._client);

  final StudentSupportApiClient _client;

  @override
  Future<List<Course>> getMyCourses() async {
    final result = await Future.wait<Object>([
      _client.getCourses(),
      _client.getProgress(),
      _client.getDeadlines(),
    ]);
    final courses = result[0] as List<StudentSupportJson>;
    final progress = result[1] as List<StudentSupportJson>;
    final deadlines = result[2] as List<StudentSupportJson>;

    final progressByCourseCode = <String, double>{
      for (final item in progress)
        _requiredString(item, 'courseCode'):
            (_requiredNumber(item, 'progressPercent') / 100).clamp(0, 1),
    };
    final nextDeadlineByCourseCode = <String, _DeadlinePreview>{};
    final now = DateTime.now();
    for (final item in deadlines) {
      final courseCode = _requiredString(item, 'courseCode');
      final candidate = _DeadlinePreview(
        name: _requiredString(item, 'assignmentName'),
        dueAt: _requiredDate(item, 'dueAt'),
      );
      if (candidate.dueAt.isBefore(now)) continue;
      final current = nextDeadlineByCourseCode[courseCode];
      if (current == null || candidate.dueAt.isBefore(current.dueAt)) {
        nextDeadlineByCourseCode[courseCode] = candidate;
      }
    }

    final mapped =
        courses
            .map((item) {
              final id = _requiredPositiveId(item, 'courseId');
              final code = _requiredString(item, 'courseCode');
              final deadline = nextDeadlineByCourseCode[code];
              return Course(
                id: id,
                shortName: code,
                fullName: _requiredString(item, 'courseName'),
                category: _requiredString(item, 'categoryName'),
                accentIndex: int.parse(id) % 4,
                summary: _nullableNonEmptyString(item, 'summary'),
                progress: progressByCourseCode[code],
                nextActivity: deadline == null
                    ? null
                    : '${deadline.name} · ${_shortDate(deadline.dueAt)}',
              );
            })
            .toList(growable: false)
          ..sort(
            (first, second) => first.shortName.compareTo(second.shortName),
          );
    return List<Course>.unmodifiable(mapped);
  }

  @override
  Future<Course> getCourse(String courseId) async {
    _ensurePositiveId(courseId, 'courseId');
    final courses = await getMyCourses();
    for (final course in courses) {
      if (course.id == courseId) return course;
    }
    throw const MoodleApiFailure(
      'Không tìm thấy khóa học được yêu cầu.',
      code: 'STAGING_COURSE_NOT_FOUND',
    );
  }
}

class StagingCourseContentRepository implements CourseContentRepository {
  StagingCourseContentRepository(this._client);

  final StudentSupportApiClient _client;

  @override
  Future<List<CourseSection>> getSections(String courseId) async {
    _ensurePositiveId(courseId, 'courseId');
    final result = await Future.wait<Object>([
      _client.getCourseContent(courseId),
      _client.getResources(),
      _client.getAssignments(),
      _client.getAssignmentStatus(),
    ]);
    final content = result[0] as List<StudentSupportJson>;
    final resources = result[1] as List<StudentSupportJson>;
    final assignments = result[2] as List<StudentSupportJson>;
    final statuses = result[3] as List<StudentSupportJson>;

    final resourcesByName = <String, StudentSupportJson>{};
    for (final resource in resources) {
      if (_requiredPositiveId(resource, 'courseId') != courseId) continue;
      final key = _requiredString(resource, 'resourceName');
      if (resourcesByName.containsKey(key)) {
        throw const ParsingFailure(
          'Dữ liệu tài liệu học tập không nhất quán.',
          code: 'STAGING_RESOURCE_JOIN_AMBIGUOUS',
        );
      }
      resourcesByName[key] = resource;
    }
    final assignmentsByKey = <_AssignmentKey, StudentSupportJson>{
      for (final assignment in assignments)
        _AssignmentKey(
          courseCode: _requiredString(assignment, 'courseCode'),
          assignmentCode: _requiredString(assignment, 'assignmentCode'),
        ): assignment,
    };
    final statusByKey = <_AssignmentKey, StudentSupportJson>{
      for (final status in statuses)
        _AssignmentKey(
          courseCode: _requiredString(status, 'courseCode'),
          assignmentCode: _requiredString(status, 'assignmentCode'),
        ): status,
    };

    final activitiesBySection = <int, List<CourseActivity>>{};
    final sectionNameByNumber = <int, String>{};
    for (final item in content) {
      final sectionNumber = _requiredInt(item, 'sectionNumber');
      final sectionName = _requiredString(item, 'sectionName');
      final existingName = sectionNameByNumber[sectionNumber];
      if (existingName != null && existingName != sectionName) {
        throw const ParsingFailure(
          'Dữ liệu chủ đề khóa học không nhất quán.',
          code: 'STAGING_SECTION_NAME_CONFLICT',
        );
      }
      sectionNameByNumber[sectionNumber] = sectionName;
      activitiesBySection
          .putIfAbsent(sectionNumber, () => <CourseActivity>[])
          .add(
            _mapContentActivity(
              item: item,
              resourcesByName: resourcesByName,
              assignmentsByKey: assignmentsByKey,
              statusByKey: statusByKey,
            ),
          );
    }

    final sections =
        activitiesBySection.entries
            .map((entry) {
              final activities = entry.value
                ..sort((first, second) => first.id.compareTo(second.id));
              return CourseSection(
                id: '$courseId:${entry.key}',
                courseId: courseId,
                number: entry.key,
                name: sectionNameByNumber[entry.key]!,
                activities: List<CourseActivity>.unmodifiable(activities),
              );
            })
            .toList(growable: false)
          ..sort((first, second) => first.number.compareTo(second.number));
    return List<CourseSection>.unmodifiable(sections);
  }

  CourseActivity _mapContentActivity({
    required StudentSupportJson item,
    required Map<String, StudentSupportJson> resourcesByName,
    required Map<_AssignmentKey, StudentSupportJson> assignmentsByKey,
    required Map<_AssignmentKey, StudentSupportJson> statusByKey,
  }) {
    final activityType = _requiredString(item, 'activityType').toLowerCase();
    final courseCode = _requiredString(item, 'courseCode');
    final name = _requiredString(item, 'activityName');
    if (activityType == 'assign' || activityType == 'assignment') {
      final assignmentCode = _requiredString(item, 'assignmentCode');
      final key = _AssignmentKey(
        courseCode: courseCode,
        assignmentCode: assignmentCode,
      );
      if (!assignmentsByKey.containsKey(key)) {
        throw const ParsingFailure(
          'Không thể liên kết bài tập với khóa học.',
          code: 'STAGING_ASSIGNMENT_JOIN_MISSING',
        );
      }
      final status = statusByKey[key];
      return CourseActivity(
        id: _requiredPositiveId(item, 'courseModuleId'),
        instanceId: assignmentCode,
        kind: CourseActivityKind.assignment,
        name: name,
        description: _nullableNonEmptyString(item, 'description'),
        dueAt: _nullableDate(item, 'dueAt'),
        statusLabel: status == null
            ? null
            : _submissionStateFromStatus(
                _requiredString(status, 'submissionStatus'),
              ).label,
        visible: true,
      );
    }
    final otherKind = switch (activityType) {
      'resource' => CourseActivityKind.resource,
      'quiz' => CourseActivityKind.quiz,
      'folder' => CourseActivityKind.folder,
      'forum' => CourseActivityKind.forum,
      'attendance' => CourseActivityKind.attendance,
      _ => null,
    };
    if (otherKind == null) {
      throw const ParsingFailure(
        'Loại nội dung khóa học chưa được hỗ trợ.',
        code: 'STAGING_ACTIVITY_TYPE_UNSUPPORTED',
      );
    }
    final resource = resourcesByName[name];
    return CourseActivity(
      id: _requiredPositiveId(item, 'courseModuleId'),
      instanceId: _requiredPositiveId(item, 'courseModuleId'),
      kind: otherKind,
      name: name,
      description: _nullableNonEmptyString(item, 'description'),
      visible: true,
      fileName: resource == null
          ? _nullableNonEmptyString(item, 'filenames')
          : _nullableNonEmptyString(resource, 'filename'),
      mimeType: resource == null
          ? null
          : _nullableNonEmptyString(resource, 'mimeType'),
      fileSize: resource == null
          ? _nullableInt(item, 'totalSizeBytes')
          : _nullableInt(resource, 'fileSizeBytes'),
    );
  }
}

class StagingAssignmentRepository implements AssignmentRepository {
  StagingAssignmentRepository(this._client);

  final StudentSupportApiClient _client;

  @override
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  }) async {
    final assignments = await getAssignments(courseId: courseId);
    final matches = assignments
        .where((item) => item.id == assignmentId)
        .toList(growable: false);
    if (matches.length == 1) return matches.single;
    if (matches.length > 1) {
      throw const ParsingFailure(
        'Dữ liệu bài tập không xác định duy nhất.',
        code: 'STAGING_ASSIGNMENT_LOOKUP_AMBIGUOUS',
      );
    }
    throw const MoodleApiFailure(
      'Không tìm thấy bài tập được yêu cầu.',
      code: 'STAGING_ASSIGNMENT_NOT_FOUND',
    );
  }

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) async {
    if (courseId != null) _ensurePositiveId(courseId, 'courseId');
    final result = await Future.wait<Object>([
      _client.getAssignments(),
      _client.getAssignmentStatus(),
      _client.getGrades(),
    ]);
    final assignments = result[0] as List<StudentSupportJson>;
    final statuses = result[1] as List<StudentSupportJson>;
    final grades = result[2] as List<StudentSupportJson>;
    final statusByKey = <_AssignmentKey, StudentSupportJson>{
      for (final status in statuses)
        _AssignmentKey(
          courseCode: _requiredString(status, 'courseCode'),
          assignmentCode: _requiredString(status, 'assignmentCode'),
        ): status,
    };
    final gradeByKey = <_AssignmentKey, StudentSupportJson>{
      for (final grade in grades)
        _AssignmentKey(
          courseCode: _requiredString(grade, 'courseCode'),
          assignmentCode: _requiredString(grade, 'assignmentCode'),
        ): grade,
    };

    final mapped =
        assignments
            .map((item) {
              final itemCourseId = _requiredPositiveId(item, 'courseId');
              final key = _AssignmentKey(
                courseCode: _requiredString(item, 'courseCode'),
                assignmentCode: _requiredString(item, 'assignmentCode'),
              );
              final status = statusByKey[key];
              final grade = gradeByKey[key];
              return AssignmentDetail(
                // Content is keyed by assignmentCode; keep this UI reference scoped by
                // courseId at the provider boundary rather than exposing a database ID.
                id: key.assignmentCode,
                courseId: itemCourseId,
                name: _requiredString(item, 'assignmentName'),
                description: _nullableNonEmptyString(item, 'description') ?? '',
                dueAt: _nullableDate(item, 'dueAt'),
                allowsSubmissionsFrom: _requiredDate(item, 'opensAt'),
                cutoffAt: null,
                timing: _assignmentTiming(_nullableDate(item, 'dueAt')),
                submissionState: status == null
                    ? SubmissionState.notSubmitted
                    : _submissionStateFromStatus(
                        _requiredString(status, 'submissionStatus'),
                      ),
                submittedAt: status == null
                    ? null
                    : _nullableDate(status, 'submittedAt'),
                grade: grade == null ? null : _requiredNumber(grade, 'score'),
                gradeMax: grade == null
                    ? _requiredNumber(item, 'maxGrade')
                    : _requiredNumber(grade, 'maxGrade'),
                feedback: grade == null
                    ? null
                    : _nullableNonEmptyString(grade, 'feedback'),
              );
            })
            .where((item) => courseId == null || item.courseId == courseId)
            .toList(growable: false)
          ..sort(compareAssignmentDeadlines);
    return List<AssignmentDetail>.unmodifiable(mapped);
  }
}

class StagingGradeRepository implements GradeRepository {
  StagingGradeRepository(this._client);

  final StudentSupportApiClient _client;

  @override
  Future<List<GradeEntry>> getGrades(String courseId) async {
    _ensurePositiveId(courseId, 'courseId');
    final result = await Future.wait<Object>([
      _client.getCourses(),
      _client.getGrades(),
    ]);
    final courses = result[0] as List<StudentSupportJson>;
    final grades = result[1] as List<StudentSupportJson>;
    final course = courses.where(
      (item) => _requiredPositiveId(item, 'courseId') == courseId,
    );
    if (course.length != 1) {
      throw const MoodleApiFailure(
        'Không tìm thấy khóa học được yêu cầu.',
        code: 'STAGING_COURSE_NOT_FOUND',
      );
    }
    final courseCode = _requiredString(course.single, 'courseCode');
    final mapped = grades
        .where((item) => _requiredString(item, 'courseCode') == courseCode)
        .map(
          (item) => GradeEntry(
            id: '$courseId:${_requiredString(item, 'assignmentCode')}',
            courseId: courseId,
            itemName: _requiredString(item, 'gradeItem'),
            maximum: _requiredNumber(item, 'maxGrade'),
            hidden: false,
            finalGrade: _requiredNumber(item, 'score'),
            feedback: _nullableNonEmptyString(item, 'feedback'),
          ),
        )
        .toList(growable: false);
    return List<GradeEntry>.unmodifiable(mapped);
  }
}

class StagingCalendarRepository implements CalendarRepository {
  StagingCalendarRepository(this._client);

  final StudentSupportApiClient _client;

  @override
  Future<List<LearningEvent>> getUpcomingEvents() async {
    final result = await Future.wait<Object>([
      _client.getCourses(),
      _client.getDeadlines(),
    ]);
    final courses = result[0] as List<StudentSupportJson>;
    final deadlines = result[1] as List<StudentSupportJson>;
    final courseIdByCode = <String, String>{
      for (final course in courses)
        _requiredString(course, 'courseCode'): _requiredPositiveId(
          course,
          'courseId',
        ),
    };
    final events = <LearningEvent>[];
    final now = DateTime.now();
    for (final deadline in deadlines) {
      final courseCode = _requiredString(deadline, 'courseCode');
      final courseId = courseIdByCode[courseCode];
      if (courseId == null) {
        throw const ParsingFailure(
          'Không thể liên kết hạn nộp với khóa học.',
          code: 'STAGING_DEADLINE_COURSE_JOIN_MISSING',
        );
      }
      final assignmentCode = _requiredString(deadline, 'assignmentCode');
      final dueAt = _requiredDate(deadline, 'dueAt');
      if (dueAt.isBefore(now)) continue;
      events.add(
        LearningEvent(
          id: '$courseId:$assignmentCode',
          courseId: courseId,
          name: _requiredString(deadline, 'assignmentName'),
          startsAt: dueAt,
          eventType: 'assignment',
        ),
      );
    }
    events.sort((first, second) => first.startsAt.compareTo(second.startsAt));
    return List<LearningEvent>.unmodifiable(events);
  }
}

class _AssignmentKey {
  const _AssignmentKey({
    required this.courseCode,
    required this.assignmentCode,
  });

  final String courseCode;
  final String assignmentCode;

  @override
  bool operator ==(Object other) =>
      other is _AssignmentKey &&
      other.courseCode == courseCode &&
      other.assignmentCode == assignmentCode;

  @override
  int get hashCode => Object.hash(courseCode, assignmentCode);
}

class _DeadlinePreview {
  const _DeadlinePreview({required this.name, required this.dueAt});

  final String name;
  final DateTime dueAt;
}

String _requiredString(StudentSupportJson json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ParsingFailure(
    'Trường dữ liệu "$key" không hợp lệ.',
    code: 'STAGING_REQUIRED_STRING_INVALID',
  );
}

String? _nullableNonEmptyString(StudentSupportJson json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
  throw ParsingFailure(
    'Trường dữ liệu "$key" không hợp lệ.',
    code: 'STAGING_OPTIONAL_STRING_INVALID',
  );
}

int _requiredInt(StudentSupportJson json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw ParsingFailure(
    'Trường dữ liệu "$key" không hợp lệ.',
    code: 'STAGING_REQUIRED_INTEGER_INVALID',
  );
}

int? _nullableInt(StudentSupportJson json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int && value >= 0) return value;
  throw ParsingFailure(
    'Trường dữ liệu "$key" không hợp lệ.',
    code: 'STAGING_OPTIONAL_INTEGER_INVALID',
  );
}

double _requiredNumber(StudentSupportJson json, String key) {
  final value = json[key];
  if (value is num && value.isFinite) return value.toDouble();
  throw ParsingFailure(
    'Trường dữ liệu "$key" không hợp lệ.',
    code: 'STAGING_REQUIRED_NUMBER_INVALID',
  );
}

DateTime _requiredDate(StudentSupportJson json, String key) {
  final value = _requiredString(json, key);
  final parsed = tryParseApiTimestamp(value);
  if (parsed != null) return parsed.toLocal();
  throw ParsingFailure(
    'Trường thời gian "$key" không hợp lệ.',
    code: 'STAGING_REQUIRED_DATE_INVALID',
  );
}

DateTime? _nullableDate(StudentSupportJson json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) {
    final parsed = tryParseApiTimestamp(value);
    if (parsed != null) return parsed.toLocal();
  }
  throw ParsingFailure(
    'Trường thời gian "$key" không hợp lệ.',
    code: 'STAGING_OPTIONAL_DATE_INVALID',
  );
}

String _requiredPositiveId(StudentSupportJson json, String key) {
  final value = _requiredString(json, key);
  _ensurePositiveId(value, key);
  return value;
}

void _ensurePositiveId(String value, String label) {
  if (!RegExp(r'^[1-9][0-9]{0,14}$').hasMatch(value)) {
    throw ParsingFailure(
      'Trường dữ liệu "$label" không hợp lệ.',
      code: 'STAGING_ID_INVALID',
    );
  }
}

SubmissionState _submissionStateFromStatus(String status) => switch (status) {
  'graded' => SubmissionState.graded,
  'returned_for_resubmission' => SubmissionState.returnedForResubmission,
  'draft' => SubmissionState.draft,
  'late' => SubmissionState.late,
  'submitted' => SubmissionState.submitted,
  'missing' => SubmissionState.missing,
  'not_submitted' => SubmissionState.notSubmitted,
  _ => throw const ParsingFailure(
    'Trạng thái bài tập không được hỗ trợ.',
    code: 'STAGING_SUBMISSION_STATUS_INVALID',
  ),
};

AssignmentTiming _assignmentTiming(DateTime? dueAt) {
  if (dueAt == null) return AssignmentTiming.noDeadline;
  final remaining = dueAt.difference(DateTime.now());
  if (remaining.isNegative) return AssignmentTiming.overdue;
  if (remaining <= const Duration(days: 3)) return AssignmentTiming.soon;
  return AssignmentTiming.future;
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
