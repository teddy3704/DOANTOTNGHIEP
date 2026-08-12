import 'package:flutter/scheduler.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/courses/domain/course.dart';
import '../../features/courses/domain/course_repository.dart';
import '../../features/profile/domain/app_user.dart';
import '../../features/profile/domain/user_repository.dart';

/// DEV FIXTURE ONLY. This class is injected exclusively by main_development.dart.
class DevAuthRepository implements AuthRepository {
  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    // Keep the development launch flow observable without changing production
    // session restoration or introducing a fixture fallback outside DEV.
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    return _session;
  }

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _session = const AuthSession(userId: 'dev-user', displayName: 'Minh Anh');
    return _session!;
  }

  @override
  Future<void> signOut() async => _session = null;
}

/// DEV FIXTURE ONLY. Synthetic courses contain no DLU production data.
class DevCourseRepository implements CourseRepository {
  static const courses = <Course>[
    Course(
      id: 'dev-mobile',
      shortName: 'CTK44',
      fullName: 'Phát triển ứng dụng di động',
      category: 'Học kỳ 1 · 2026–2027',
      accentIndex: 0,
      progress: 0.72,
      nextActivity: 'Bài tập kiến trúc ứng dụng · 18/08',
    ),
    Course(
      id: 'dev-security',
      shortName: 'ATTT',
      fullName: 'An toàn và bảo mật thông tin',
      category: 'Học kỳ 1 · 2026–2027',
      accentIndex: 1,
      progress: 0.48,
      nextActivity: 'Bài kiểm tra chương 3 · 20/08',
    ),
    Course(
      id: 'dev-project',
      shortName: 'DATN',
      fullName: 'Đồ án tốt nghiệp',
      category: 'Năm học 2026–2027',
      accentIndex: 2,
      progress: 0.35,
      nextActivity: 'Báo cáo tiến độ · 24/08',
    ),
  ];

  @override
  Future<List<Course>> getMyCourses() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return courses;
  }

  @override
  Future<Course> getCourse(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return courses.firstWhere((course) => course.id == courseId);
  }
}

/// DEV FIXTURE ONLY. The identity is fictional and not a DLU account.
class DevUserRepository implements UserRepository {
  @override
  Future<AppUser> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AppUser(
      id: 'dev-user',
      displayName: 'Nguyễn Minh Anh',
      email: 'minhanh.dev@example.test',
      roleLabel: 'Sinh viên · DEV FIXTURE',
      faculty: 'Khoa Công nghệ Thông tin',
    );
  }
}
