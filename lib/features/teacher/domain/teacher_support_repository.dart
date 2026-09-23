import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../profile/domain/app_user.dart';

class TeachingWork {
  const TeachingWork({
    required this.title,
    required this.description,
    required this.dueAt,
    required this.submitted,
    required this.studentCount,
  });
  final String title, description;
  final DateTime dueAt;
  final int submitted, studentCount;
  int get missing => studentCount - submitted;
}

class TeachingSection {
  const TeachingSection({required this.title, required this.resources});
  final String title;
  final List<String> resources;
}

class TeachingCourse {
  const TeachingCourse({
    required this.id,
    required this.name,
    required this.code,
    required this.summary,
    required this.studentCount,
    required this.work,
    required this.sections,
  });
  final String id, name, code, summary;
  final int studentCount;
  final List<TeachingWork> work;
  final List<TeachingSection> sections;
}

class TeacherOverview {
  const TeacherOverview({required this.profile, required this.courses});
  final AppUser profile;
  final List<TeachingCourse> courses;
}

enum LearningSupportLevel { low, medium, high }

class StudentMonitoring {
  const StudentMonitoring({
    required this.studentId,
    required this.courseId,
    required this.name,
    required this.progressPercent,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.supportLevel,
  });
  final String studentId, courseId, name;
  final double progressPercent;
  final int pendingTasks, overdueTasks;
  final LearningSupportLevel supportLevel;
}

/// Read-only support contract. No grading, feedback or course mutations.
abstract interface class TeacherSupportRepository {
  Future<TeacherOverview> getOverview();
  Future<List<StudentMonitoring>> getStudents(String courseId);
}

class UnconfiguredTeacherSupportRepository implements TeacherSupportRepository {
  const UnconfiguredTeacherSupportRepository();
  @override
  Future<List<StudentMonitoring>> getStudents(String courseId) async =>
      throw const ConfigurationFailure(
        'Kết nối thông tin giảng dạy chưa được cấu hình.',
        code: 'TEACHER_SUPPORT_UNCONFIGURED',
      );
  @override
  Future<TeacherOverview> getOverview() async =>
      throw const ConfigurationFailure(
        'Kết nối thông tin giảng dạy chưa được cấu hình.',
        code: 'TEACHER_SUPPORT_UNCONFIGURED',
      );
}

final teacherSupportRepositoryProvider = Provider<TeacherSupportRepository>(
  (ref) => const UnconfiguredTeacherSupportRepository(),
);
final teacherOverviewProvider = FutureProvider.autoDispose<TeacherOverview>((
  ref,
) {
  if (ref.watch(authControllerProvider).session?.role != DluRole.teacher) {
    throw const ConfigurationFailure(
      'Bạn không có quyền xem thông tin này.',
      code: 'TEACHER_CONTEXT_REQUIRED',
    );
  }
  return ref.watch(teacherSupportRepositoryProvider).getOverview();
});

final teacherStudentsProvider = FutureProvider.autoDispose
    .family<List<StudentMonitoring>, String>((ref, courseId) {
      if (ref.watch(authControllerProvider).session?.role != DluRole.teacher) {
        throw const ConfigurationFailure(
          'Bạn không có quyền xem thông tin này.',
          code: 'TEACHER_CONTEXT_REQUIRED',
        );
      }
      return ref.watch(teacherSupportRepositoryProvider).getStudents(courseId);
    });
