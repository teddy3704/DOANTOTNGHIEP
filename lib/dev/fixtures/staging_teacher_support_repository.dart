import '../../core/errors/app_failure.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/domain/student_identity_provider.dart';
import '../../features/profile/domain/app_user.dart';
import '../../features/teacher/domain/teacher_support_repository.dart';
import 'synthetic_fixture_data_source.dart';

/// Explicit STAGING MOCK adapter over the existing canonical Moodle subset.
/// Not a Render endpoint; never a fallback after a failed Student API call.
class StagingTeacherSupportRepository implements TeacherSupportRepository {
  StagingTeacherSupportRepository(
    this.identity, {
    SyntheticFixtureDataSource? dataSource,
  }) : _data = dataSource ?? SyntheticFixtureDataSource();
  final StudentIdentityProvider identity;
  final SyntheticFixtureDataSource _data;

  @override
  Future<List<StudentMonitoring>> getStudents(String courseId) async =>
      throw const ConfigurationFailure(
        'Kết nối thông tin giảng dạy chưa được cấu hình.',
        code: 'TEACHER_MONITORING_FIXTURE_UNAVAILABLE',
      );

  @override
  Future<TeacherOverview> getOverview() async {
    final selected = await identity.restore();
    if (selected?.id != 'GV001' || selected?.role != DluRole.teacher) {
      throw const ConfigurationFailure(
        'Bạn không có quyền xem thông tin này.',
        code: 'TEACHER_CONTEXT_REQUIRED',
      );
    }
    final data = await _data.load();
    // Explicit mapping to an existing synthetic instructor, not a DLU account.
    const teacherId = 101;
    final user = data
        .table('user')
        .singleWhere((r) => fixtureInt(r, 'id') == teacherId);
    final teacherRoles = data
        .table('role')
        .where((r) => ['editingteacher', 'teacher'].contains(r['shortname']))
        .map((r) => fixtureInt(r, 'id'))
        .toSet();
    final contexts = data
        .table('role_assignments')
        .where(
          (r) =>
              fixtureInt(r, 'userid') == teacherId &&
              teacherRoles.contains(fixtureInt(r, 'roleid')),
        )
        .map((r) => fixtureInt(r, 'contextid'))
        .toSet();
    final courseContexts = data
        .table('context')
        .where(
          (r) =>
              contexts.contains(fixtureInt(r, 'id')) &&
              fixtureInt(r, 'contextlevel') == 50,
        )
        .toList();
    final courseIds = courseContexts
        .map((r) => fixtureInt(r, 'instanceid'))
        .toSet();
    final studentRoles = data
        .table('role')
        .where((r) => r['shortname'] == 'student')
        .map((r) => fixtureInt(r, 'id'))
        .toSet();
    final courses = <TeachingCourse>[];
    for (final course
        in data
            .table('course')
            .where(
              (r) =>
                  courseIds.contains(fixtureInt(r, 'id')) &&
                  fixtureBool(r, 'visible'),
            )) {
      final id = fixtureInt(course, 'id');
      final contextId = fixtureInt(
        courseContexts.singleWhere((r) => fixtureInt(r, 'instanceid') == id),
        'id',
      );
      final enrolIds = data
          .table('enrol')
          .where(
            (r) =>
                fixtureInt(r, 'courseid') == id && fixtureInt(r, 'status') == 0,
          )
          .map((r) => fixtureInt(r, 'id'))
          .toSet();
      final enrolled = data
          .table('user_enrolments')
          .where(
            (r) =>
                enrolIds.contains(fixtureInt(r, 'enrolid')) &&
                fixtureInt(r, 'status') == 0,
          )
          .map((r) => fixtureInt(r, 'userid'))
          .toSet();
      final students = data
          .table('role_assignments')
          .where(
            (r) =>
                fixtureInt(r, 'contextid') == contextId &&
                studentRoles.contains(fixtureInt(r, 'roleid')) &&
                enrolled.contains(fixtureInt(r, 'userid')),
          )
          .map((r) => fixtureInt(r, 'userid'))
          .toSet();
      final work = <TeachingWork>[];
      for (final a
          in data.table('assign').where((r) => fixtureInt(r, 'course') == id)) {
        final submitted = data
            .table('assign_submission')
            .where(
              (r) =>
                  fixtureInt(r, 'assignment') == fixtureInt(a, 'id') &&
                  fixtureInt(r, 'latest') == 1 &&
                  r['status'] == 'submitted' &&
                  students.contains(fixtureInt(r, 'userid')),
            )
            .map((r) => fixtureInt(r, 'userid'))
            .toSet()
            .length;
        work.add(
          TeachingWork(
            title: fixtureString(a, 'name'),
            description: fixtureString(a, 'intro'),
            dueAt: DateTime.fromMillisecondsSinceEpoch(
              fixtureInt(a, 'duedate') * 1000,
            ),
            submitted: submitted,
            studentCount: students.length,
          ),
        );
      }
      work.sort((a, b) => a.dueAt.compareTo(b.dueAt));
      final resourceTypes = data
          .table('modules')
          .where((r) => r['name'] == 'resource')
          .map((r) => fixtureInt(r, 'id'))
          .toSet();
      final sections = <TeachingSection>[];
      for (final s
          in data
              .table('course_sections')
              .where(
                (r) =>
                    fixtureInt(r, 'course') == id && fixtureBool(r, 'visible'),
              )) {
        final instances = data
            .table('course_modules')
            .where(
              (r) =>
                  fixtureInt(r, 'course') == id &&
                  fixtureInt(r, 'section') == fixtureInt(s, 'id') &&
                  fixtureBool(r, 'visible') &&
                  resourceTypes.contains(fixtureInt(r, 'module')),
            )
            .map((r) => fixtureInt(r, 'instance'))
            .toSet();
        sections.add(
          TeachingSection(
            title: fixtureNullableString(s, 'name') ?? 'Nội dung học phần',
            resources: List.unmodifiable(
              data
                  .table('resource')
                  .where(
                    (r) =>
                        fixtureInt(r, 'course') == id &&
                        instances.contains(fixtureInt(r, 'id')),
                  )
                  .map((r) => fixtureString(r, 'name')),
            ),
          ),
        );
      }
      courses.add(
        TeachingCourse(
          id: id.toString(),
          name: fixtureString(course, 'fullname'),
          code: fixtureString(course, 'shortname'),
          summary: fixtureString(course, 'summary'),
          studentCount: students.length,
          work: List.unmodifiable(work),
          sections: List.unmodifiable(sections),
        ),
      );
    }
    return TeacherOverview(
      profile: AppUser(
        id: selected!.id,
        displayName:
            '${fixtureString(user, 'lastname')} ${fixtureString(user, 'firstname')}',
        email: fixtureString(user, 'email'),
        idNumber: fixtureString(user, 'idnumber'),
        roleLabel: 'Giảng viên',
        faculty: fixtureString(user, 'department'),
      ),
      courses: List.unmodifiable(courses),
    );
  }
}
