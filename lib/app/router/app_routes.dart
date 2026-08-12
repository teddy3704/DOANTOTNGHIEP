abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const courses = '/courses';
  static const courseDetail = '/courses/:courseId';
  static const profile = '/profile';

  static String course(String courseId) => '/courses/$courseId';
}
