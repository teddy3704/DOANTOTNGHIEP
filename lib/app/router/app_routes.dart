abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const courses = '/courses';
  static const calendar = '/calendar';
  static const courseDetail = '/courses/:courseId';
  static const assignmentDetail =
      '/courses/:courseId/assignments/:assignmentId';
  static const courseGrades = '/courses/:courseId/grades';
  static const profile = '/profile';

  static String course(String courseId) => '/courses/$courseId';
  static String assignment(String courseId, String assignmentId) =>
      '/courses/$courseId/assignments/$assignmentId';
  static String grades(String courseId) => '/courses/$courseId/grades';
}
