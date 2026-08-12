import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/widgets/app_shell.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
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
      if (onSplash || onLogin) return AppRoutes.dashboard;
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
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            AppShell(currentLocation: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.courses,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CoursesScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.courseDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
    ],
  );
});
