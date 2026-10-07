import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/assignments/presentation/screens/assignment_screen.dart';
import '../../features/assignments/presentation/screens/assignments_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/widgets/app_shell.dart';
import '../../features/grades/presentation/screens/grades_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../core/widgets/staging_read_only_notice.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/teacher/presentation/teacher_support_screen.dart';
import '../../features/teacher/presentation/teacher_students_screen.dart';
import '../../core/config/app_config.dart';
import '../../features/study_planner/presentation/screens/student_today_screen.dart';
import '../../features/study_planner/presentation/screens/study_plan_screen.dart';
import '../../features/interventions/presentation/teacher_today_screen.dart';
import '../../features/interventions/presentation/intervention_inbox_screen.dart';
import '../../features/interventions/presentation/student_attention_detail_screen.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (_, _) => notifier.refresh());
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  final assistant = ref.watch(appConfigProvider).enableLearningAssistant;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onLogin = location == AppRoutes.login;

      if (auth.status == AuthStatus.checking) {
        return onSplash ? null : AppRoutes.splash;
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return onLogin ? null : AppRoutes.login;
      }
      final teacher = auth.session?.role == DluRole.teacher;
      if (onSplash || onLogin) {
        return teacher ? '/teacher' : AppRoutes.dashboard;
      }
      if (teacher && !location.startsWith('/teacher')) return '/teacher';
      if (!teacher && location.startsWith('/teacher')) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.uri.path,
          teacher: true,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/teacher',
            builder: (context, state) => assistant
                ? const TeacherTodayScreen()
                : const TeacherSupportScreen(),
          ),
          GoRoute(
            path: '/teacher/interventions',
            builder: (context, state) => const InterventionInboxScreen(),
          ),
          GoRoute(
            path: '/teacher/courses',
            builder: (context, state) =>
                const TeacherSupportScreen(view: TeacherView.courses),
          ),
          GoRoute(
            path: '/teacher/work',
            builder: (context, state) =>
                const TeacherSupportScreen(view: TeacherView.work),
          ),
          GoRoute(
            path: '/teacher/calendar',
            builder: (context, state) =>
                const TeacherSupportScreen(view: TeacherView.calendar),
          ),
          GoRoute(
            path: '/teacher/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/attention/:courseId/:studentId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StagingReadOnlyFrame(
          child: StudentAttentionDetailScreen(
            courseId: state.pathParameters['courseId']!,
            studentId: state.pathParameters['studentId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/teacher/course/:courseId/students',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StagingReadOnlyFrame(
          child: TeacherStudentsScreen(
            courseId: state.pathParameters['courseId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/teacher/course/:courseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StagingReadOnlyFrame(
          child: TeacherSupportScreen(
            courseId: state.pathParameters['courseId']!,
          ),
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            AppShell(currentLocation: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => NoTransitionPage(
              child: assistant
                  ? const StudentTodayScreen()
                  : const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.studyPlan,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StudyPlanScreen()),
          ),
          GoRoute(
            path: AppRoutes.courses,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CoursesScreen()),
          ),
          GoRoute(
            path: AppRoutes.assignments,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AssignmentsScreen()),
          ),
          GoRoute(
            path: AppRoutes.progress,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProgressScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.calendar,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StagingReadOnlyFrame(
          child: Scaffold(body: CalendarScreen(showBackButton: true)),
        ),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StagingReadOnlyFrame(
          child: Scaffold(body: RemindersScreen(showBackButton: true)),
        ),
      ),
      GoRoute(
        path: AppRoutes.assignmentDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StagingReadOnlyFrame(
          child: AssignmentScreen(
            courseId: state.pathParameters['courseId']!,
            assignmentId: state.pathParameters['assignmentId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.courseGrades,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StagingReadOnlyFrame(
          child: GradesScreen(courseId: state.pathParameters['courseId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.courseDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StagingReadOnlyFrame(
          child: CourseDetailScreen(
            courseId: state.pathParameters['courseId']!,
          ),
        ),
      ),
    ],
  );
});
