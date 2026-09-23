import '../../core/errors/app_failure.dart';
import '../../features/profile/domain/app_user.dart';
import '../../features/teacher/domain/teacher_support_repository.dart';
import 'student_support_api_client.dart';

/// GET-only adapter for the verified GROUP_39_20 staging contract. No fallback.
class TeacherSupportApiRepository implements TeacherSupportRepository {
  TeacherSupportApiRepository(this.client);
  final StudentSupportApiClient client;

  @override
  Future<TeacherOverview> getOverview() async {
    final data = await client.getTeacherOverview();
    final profile = _object(data['profile']);
    if (_string(profile, 'role') != 'teacher') _invalid();
    return TeacherOverview(
      profile: AppUser(
        id: _string(profile, 'teacherCode'),
        displayName: _string(profile, 'fullName'),
        email: _string(profile, 'email'),
        roleLabel: 'Giảng viên',
        faculty: _string(profile, 'department'),
      ),
      courses: List.unmodifiable(
        _list(data['courses']).map((c) {
          final count = _count(c, 'studentCount');
          return TeachingCourse(
            id: _id(c, 'id'),
            name: _string(c, 'name'),
            code: _string(c, 'code'),
            summary: _string(c, 'summary'),
            studentCount: count,
            work: List.unmodifiable(
              _list(c['work']).map((w) {
                final total = _count(w, 'studentCount');
                final submitted = _count(w, 'submitted');
                final dueAt = DateTime.tryParse(_string(w, 'dueAt'));
                if (submitted > total || total != count || dueAt == null) {
                  _invalid();
                }
                return TeachingWork(
                  title: _string(w, 'title'),
                  description: _string(w, 'description'),
                  dueAt: dueAt.toLocal(),
                  submitted: submitted,
                  studentCount: total,
                );
              }),
            ),
            sections: List.unmodifiable(
              _list(c['sections']).map((s) {
                final resources = s['resources'];
                if (resources is! List || resources.any((r) => r is! String)) {
                  _invalid();
                }
                return TeachingSection(
                  title: _string(s, 'title'),
                  resources: List<String>.unmodifiable(resources),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  @override
  Future<List<StudentMonitoring>> getStudents(String courseId) async {
    final rows = await client.getTeacherStudents(courseId);
    final seen = <String>{};
    return List.unmodifiable(
      rows.map((r) {
        final id = _id(r, 'studentId');
        final progress = r['progressPercent'];
        if (_id(r, 'courseId') != courseId ||
            !seen.add(id) ||
            progress is! num ||
            !progress.isFinite ||
            progress < 0 ||
            progress > 100) {
          _invalid();
        }
        final level = switch (_string(r, 'riskLevel')) {
          'LOW' => LearningSupportLevel.low,
          'MEDIUM' => LearningSupportLevel.medium,
          'HIGH' => LearningSupportLevel.high,
          _ => _invalid(),
        };
        return StudentMonitoring(
          studentId: id,
          courseId: courseId,
          name: _string(r, 'studentName'),
          progressPercent: progress.toDouble(),
          pendingTasks: _count(r, 'pendingTasks'),
          overdueTasks: _count(r, 'overdueTasks'),
          supportLevel: level,
        );
      }),
    );
  }
}

Never _invalid() => throw const ParsingFailure(
  'Dữ liệu giảng dạy tạm thời chưa thể hiển thị.',
  code: 'TEACHER_CONTRACT_INVALID',
);
Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) _invalid();
  return value;
}

Iterable<Map<String, Object?>> _list(Object? value) {
  if (value is! List) _invalid();
  return value.map(_object);
}

String _string(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! String) _invalid();
  return value;
}

String _id(Map<String, Object?> row, String key) {
  final value = _string(row, key);
  if (!RegExp(r'^[1-9][0-9]{0,14}$').hasMatch(value)) _invalid();
  return value;
}

int _count(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! int || value < 0) _invalid();
  return value;
}
