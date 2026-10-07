import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../../features/assignments/domain/assignment.dart';
import '../../features/assignments/domain/assignment_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_session.dart';
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
import 'synthetic_fixture_data_source.dart';

const _fixtureStudentId = 1001;

/// TEST FIXTURE ONLY. No application entrypoint injects this repository.
class DevAuthRepository implements AuthRepository {
  DevAuthRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;
  AuthSession? _session;

  @override
  Stream<void> get sessionInvalidations => const Stream<void>.empty();

  @override
  Future<AuthSession?> restoreSession() async {
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return _session;
  }

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    final snapshot = await _dataSource.load();
    final user = _rowById(snapshot.table('user'), _fixtureStudentId);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _session = AuthSession(
      userId: _fixtureStudentId.toString(),
      displayName: _displayName(user),
    );
    return _session!;
  }

  @override
  Future<void> signOut() async => _session = null;
}

/// DEV FIXTURE ONLY. All records come from the generated canonical dataset.
class DevCourseRepository implements CourseRepository {
  DevCourseRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;

  @override
  Future<List<Course>> getMyCourses() async {
    final snapshot = await _dataSource.load();
    return _coursesForStudent(snapshot, _fixtureStudentId);
  }

  @override
  Future<Course> getCourse(String courseId) async {
    final snapshot = await _dataSource.load();
    return _coursesForStudent(
      snapshot,
      _fixtureStudentId,
    ).firstWhere((course) => course.id == courseId);
  }
}

class DevCourseContentRepository implements CourseContentRepository {
  DevCourseContentRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;

  @override
  Future<List<CourseSection>> getSections(String courseId) async {
    final snapshot = await _dataSource.load();
    final numericCourseId = int.parse(courseId);
    _requireEnrolledCourse(snapshot, numericCourseId);
    final moduleTypes = {
      for (final row in snapshot.table('modules'))
        fixtureInt(row, 'id'): fixtureString(row, 'name'),
    };
    final assignments = {
      for (final row in snapshot.table('assign')) fixtureInt(row, 'id'): row,
    };
    final resources = {
      for (final row in snapshot.table('resource')) fixtureInt(row, 'id'): row,
    };
    final files = snapshot.table('files');
    final courseModules = snapshot
        .table('course_modules')
        .where(
          (row) =>
              fixtureInt(row, 'course') == numericCourseId &&
              fixtureBool(row, 'visible'),
        )
        .toList(growable: false);

    final sections =
        snapshot
            .table('course_sections')
            .where((row) => fixtureInt(row, 'course') == numericCourseId)
            .map((section) {
              final sectionId = fixtureInt(section, 'id');
              final activities = <CourseActivity>[];
              for (final module in courseModules.where(
                (row) => fixtureInt(row, 'section') == sectionId,
              )) {
                final type = moduleTypes[fixtureInt(module, 'module')];
                final instanceId = fixtureInt(module, 'instance');
                if (type == 'assign') {
                  final assignment = assignments[instanceId];
                  if (assignment == null) continue;
                  final detail = _assignmentFrom(
                    snapshot,
                    assignment,
                    _fixtureStudentId,
                  );
                  activities.add(
                    CourseActivity(
                      id: fixtureInt(module, 'id').toString(),
                      instanceId: instanceId.toString(),
                      kind: CourseActivityKind.assignment,
                      name: detail.name,
                      description: detail.description,
                      dueAt: detail.dueAt,
                      statusLabel: detail.submissionState.label,
                      visible: true,
                    ),
                  );
                } else if (type == 'resource') {
                  final resource = resources[instanceId];
                  if (resource == null) continue;
                  final file = _firstWhereOrNull(
                    files,
                    (row) =>
                        fixtureString(row, 'component') == 'mod_resource' &&
                        fixtureString(row, 'filearea') == 'content' &&
                        fixtureInt(row, 'itemid') == instanceId,
                  );
                  activities.add(
                    CourseActivity(
                      id: fixtureInt(module, 'id').toString(),
                      instanceId: instanceId.toString(),
                      kind: CourseActivityKind.resource,
                      name: fixtureString(resource, 'name'),
                      description: fixtureNullableString(resource, 'intro'),
                      visible: true,
                      fileName: file == null
                          ? null
                          : fixtureString(file, 'filename'),
                      mimeType: file == null
                          ? null
                          : fixtureNullableString(file, 'mimetype'),
                      fileSize: file == null
                          ? null
                          : fixtureInt(file, 'filesize'),
                    ),
                  );
                }
              }
              activities.sort(
                (a, b) => int.parse(a.id).compareTo(int.parse(b.id)),
              );
              final sectionNumber = fixtureInt(section, 'section');
              return CourseSection(
                id: sectionId.toString(),
                courseId: courseId,
                number: sectionNumber,
                name:
                    fixtureNullableString(section, 'name') ??
                    (sectionNumber == 0
                        ? 'Tổng quan'
                        : 'Chủ đề $sectionNumber'),
                summary: fixtureNullableString(section, 'summary'),
                activities: List.unmodifiable(activities),
              );
            })
            .toList(growable: false)
          ..sort((a, b) => a.number.compareTo(b.number));
    return sections;
  }
}

class DevAssignmentRepository implements AssignmentRepository {
  DevAssignmentRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;

  @override
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  }) async {
    final snapshot = await _dataSource.load();
    final row = _rowById(snapshot.table('assign'), int.parse(assignmentId));
    final rowCourseId = fixtureInt(row, 'course');
    _requireEnrolledCourse(snapshot, rowCourseId);
    if (courseId != null && courseId != rowCourseId.toString()) {
      throw StateError('Assignment is outside the requested course.');
    }
    return _assignmentFrom(snapshot, row, _fixtureStudentId);
  }

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) async {
    final snapshot = await _dataSource.load();
    final enrolledCourseIds = _enrolledCourseIds(snapshot, _fixtureStudentId);
    final rows = snapshot
        .table('assign')
        .where(
          (row) =>
              enrolledCourseIds.contains(fixtureInt(row, 'course')) &&
              (courseId == null ||
                  fixtureInt(row, 'course') == int.parse(courseId)),
        );
    final assignments =
        rows
            .map((row) => _assignmentFrom(snapshot, row, _fixtureStudentId))
            .toList(growable: false)
          ..sort(compareAssignmentDeadlines);
    return assignments;
  }
}

class DevGradeRepository implements GradeRepository {
  DevGradeRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;

  @override
  Future<List<GradeEntry>> getGrades(String courseId) async {
    final snapshot = await _dataSource.load();
    _requireEnrolledCourse(snapshot, int.parse(courseId));
    final gradeRows = {
      for (final row
          in snapshot
              .table('grade_grades')
              .where((row) => fixtureInt(row, 'userid') == _fixtureStudentId))
        fixtureInt(row, 'itemid'): row,
    };
    final entries = snapshot
        .table('grade_items')
        .where((row) => fixtureInt(row, 'courseid') == int.parse(courseId))
        .map((item) {
          final id = fixtureInt(item, 'id');
          final grade = gradeRows[id];
          return GradeEntry(
            id: id.toString(),
            courseId: courseId,
            itemName: fixtureNullableString(item, 'itemname') ?? 'Mục điểm $id',
            minimum: fixtureNullableDouble(item, 'grademin') ?? 0,
            maximum: fixtureNullableDouble(item, 'grademax') ?? 100,
            hidden: fixtureInt(item, 'hidden') != 0,
            finalGrade: grade == null
                ? null
                : fixtureNullableDouble(grade, 'finalgrade'),
            feedback: grade == null
                ? null
                : fixtureNullableString(grade, 'feedback'),
          );
        })
        .where((entry) => !entry.hidden)
        .toList(growable: false);
    return entries;
  }
}

class DevCalendarRepository implements CalendarRepository {
  DevCalendarRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;

  @override
  Future<List<LearningEvent>> getUpcomingEvents() async {
    final snapshot = await _dataSource.load();
    final enrolledCourseIds = _enrolledCourseIds(snapshot, _fixtureStudentId);
    final events =
        snapshot
            .table('event')
            .where(
              (row) =>
                  enrolledCourseIds.contains(fixtureInt(row, 'courseid')) &&
                  fixtureBool(row, 'visible') &&
                  fixtureInt(row, 'timestart') >=
                      snapshot.referenceTime.millisecondsSinceEpoch ~/ 1000,
            )
            .map(
              (row) => LearningEvent(
                id: fixtureInt(row, 'id').toString(),
                courseId: fixtureInt(row, 'courseid').toString(),
                name: fixtureString(row, 'name'),
                startsAt: _dateFromEpoch(fixtureInt(row, 'timestart')),
                eventType: fixtureString(row, 'eventtype'),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return events;
  }
}

/// DEV FIXTURE ONLY. The selected identity is fictional and uses example.test.
class DevUserRepository implements UserRepository {
  DevUserRepository([SyntheticFixtureDataSource? dataSource])
    : _dataSource = dataSource ?? SyntheticFixtureDataSource();

  final SyntheticFixtureDataSource _dataSource;

  @override
  Future<AppUser> getCurrentUser() async {
    final snapshot = await _dataSource.load();
    final user = _rowById(snapshot.table('user'), _fixtureStudentId);
    return AppUser(
      id: _fixtureStudentId.toString(),
      displayName: _displayName(user),
      email: fixtureString(user, 'email'),
      idNumber: fixtureString(user, 'idnumber'),
      roleLabel: 'Sinh viên',
      faculty: fixtureString(user, 'department'),
    );
  }
}

List<Course> _coursesForStudent(SyntheticFixtureSnapshot snapshot, int userId) {
  final enrolledCourseIds = _enrolledCourseIds(snapshot, userId);
  final categories = {
    for (final row in snapshot.table('course_categories'))
      fixtureInt(row, 'id'): fixtureString(row, 'name'),
  };
  final modules = snapshot.table('course_modules');
  final completion = snapshot.table('course_modules_completion');
  final assignments = snapshot.table('assign');

  final courses =
      snapshot
          .table('course')
          .where(
            (row) =>
                enrolledCourseIds.contains(fixtureInt(row, 'id')) &&
                fixtureBool(row, 'visible'),
          )
          .map((row) {
            final courseId = fixtureInt(row, 'id');
            final courseModules = modules
                .where(
                  (module) =>
                      fixtureInt(module, 'course') == courseId &&
                      fixtureBool(module, 'visible'),
                )
                .toList(growable: false);
            final courseModuleIds = courseModules
                .map((module) => fixtureInt(module, 'id'))
                .toSet();
            final completedCount = completion
                .where(
                  (item) =>
                      fixtureInt(item, 'userid') == userId &&
                      courseModuleIds.contains(
                        fixtureInt(item, 'coursemoduleid'),
                      ) &&
                      fixtureInt(item, 'completionstate') != 0,
                )
                .length;
            final upcoming =
                assignments
                    .where(
                      (item) =>
                          fixtureInt(item, 'course') == courseId &&
                          fixtureInt(item, 'duedate') >=
                              snapshot.referenceTime.millisecondsSinceEpoch ~/
                                  1000,
                    )
                    .toList(growable: false)
                  ..sort(
                    (a, b) => fixtureInt(
                      a,
                      'duedate',
                    ).compareTo(fixtureInt(b, 'duedate')),
                  );
            final next = upcoming.isEmpty ? null : upcoming.first;
            return Course(
              id: courseId.toString(),
              shortName: fixtureString(row, 'shortname'),
              fullName: fixtureString(row, 'fullname'),
              category:
                  categories[fixtureInt(row, 'category')] ?? 'Chưa phân loại',
              accentIndex: courseId % 4,
              summary: fixtureNullableString(row, 'summary'),
              progress: courseModules.isEmpty
                  ? null
                  : completedCount / courseModules.length,
              nextActivity: next == null
                  ? null
                  : '${fixtureString(next, 'name')} · ${_shortDate(_dateFromEpoch(fixtureInt(next, 'duedate')))}',
            );
          })
          .toList(growable: false)
        ..sort((a, b) => a.shortName.compareTo(b.shortName));
  return courses;
}

Set<int> _enrolledCourseIds(SyntheticFixtureSnapshot snapshot, int userId) {
  final enrolIds = snapshot
      .table('user_enrolments')
      .where(
        (row) =>
            fixtureInt(row, 'userid') == userId &&
            fixtureInt(row, 'status') == 0,
      )
      .map((row) => fixtureInt(row, 'enrolid'))
      .toSet();
  return snapshot
      .table('enrol')
      .where(
        (row) =>
            enrolIds.contains(fixtureInt(row, 'id')) &&
            fixtureInt(row, 'status') == 0,
      )
      .map((row) => fixtureInt(row, 'courseid'))
      .toSet();
}

void _requireEnrolledCourse(SyntheticFixtureSnapshot snapshot, int courseId) {
  if (!_enrolledCourseIds(snapshot, _fixtureStudentId).contains(courseId)) {
    throw StateError('Course is outside the fixture enrollment scope.');
  }
}

AssignmentDetail _assignmentFrom(
  SyntheticFixtureSnapshot snapshot,
  Map<String, Object?> assignment,
  int userId,
) {
  final assignmentId = fixtureInt(assignment, 'id');
  final submission = _firstWhereOrNull(
    snapshot.table('assign_submission'),
    (row) =>
        fixtureInt(row, 'assignment') == assignmentId &&
        fixtureInt(row, 'userid') == userId &&
        fixtureInt(row, 'latest') == 1,
  );
  final assignGrade = _firstWhereOrNull(
    snapshot.table('assign_grades'),
    (row) =>
        fixtureInt(row, 'assignment') == assignmentId &&
        fixtureInt(row, 'userid') == userId,
  );
  final gradeItem = _firstWhereOrNull(
    snapshot.table('grade_items'),
    (row) =>
        fixtureNullableString(row, 'itemmodule') == 'assign' &&
        fixtureInt(row, 'iteminstance') == assignmentId,
  );
  final grade = gradeItem == null
      ? null
      : _firstWhereOrNull(
          snapshot.table('grade_grades'),
          (row) =>
              fixtureInt(row, 'itemid') == fixtureInt(gradeItem, 'id') &&
              fixtureInt(row, 'userid') == userId,
        );
  final finalGrade = grade == null
      ? null
      : fixtureNullableDouble(grade, 'finalgrade');
  final assignmentGrade = assignGrade == null
      ? null
      : fixtureNullableDouble(assignGrade, 'grade');
  final submissionStatus = submission == null
      ? null
      : fixtureNullableString(submission, 'status');
  final state = finalGrade != null || assignmentGrade != null
      ? SubmissionState.graded
      : submissionStatus == 'submitted'
      ? SubmissionState.submitted
      : submissionStatus == 'draft'
      ? SubmissionState.draft
      : SubmissionState.notSubmitted;

  final dueAt = _dateFromEpoch(fixtureInt(assignment, 'duedate'));
  final difference = dueAt.difference(snapshot.referenceTime);
  final timing = difference.isNegative
      ? AssignmentTiming.overdue
      : difference <= const Duration(days: 3)
      ? AssignmentTiming.soon
      : AssignmentTiming.future;

  return AssignmentDetail(
    id: assignmentId.toString(),
    courseId: fixtureInt(assignment, 'course').toString(),
    name: fixtureString(assignment, 'name'),
    description: fixtureString(assignment, 'intro'),
    dueAt: dueAt,
    allowsSubmissionsFrom: _dateFromEpoch(
      fixtureInt(assignment, 'allowsubmissionsfromdate'),
    ),
    cutoffAt: _dateFromEpoch(fixtureInt(assignment, 'cutoffdate')),
    timing: timing,
    submissionState: state,
    submittedAt: submission == null
        ? null
        : _dateFromEpoch(fixtureInt(submission, 'timemodified')),
    grade: finalGrade ?? assignmentGrade,
    gradeMax: gradeItem == null
        ? fixtureInt(assignment, 'grade').toDouble()
        : fixtureNullableDouble(gradeItem, 'grademax'),
    feedback: grade == null ? null : fixtureNullableString(grade, 'feedback'),
  );
}

Map<String, Object?> _rowById(List<Map<String, Object?>> rows, int id) =>
    rows.firstWhere((row) => fixtureInt(row, 'id') == id);

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) return value;
  }
  return null;
}

String _displayName(Map<String, Object?> user) =>
    '${fixtureString(user, 'lastname')} ${fixtureString(user, 'firstname')}'
        .trim();

DateTime _dateFromEpoch(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
