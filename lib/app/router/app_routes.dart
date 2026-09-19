abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const courses = '/courses';
  static const assignments = '/assignments';
  static const progress = '/progress';
  static const calendar = '/calendar';
  static const reminders = '/reminders';
  static const courseDetail = '/courses/:courseId';
  static const assignmentDetail =
      '/courses/:courseId/assignments/:assignmentId';
  static const courseGrades = '/courses/:courseId/grades';
  static const profile = '/profile';

  static String course(String courseId) =>
      '/courses/${Uri.encodeComponent(courseId)}';
  static String assignment(String courseId, String assignmentId) =>
      '/courses/${Uri.encodeComponent(courseId)}/assignments/${Uri.encodeComponent(assignmentId)}';
  static String grades(String courseId) =>
      '/courses/${Uri.encodeComponent(courseId)}/grades';
}
