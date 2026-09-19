import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/staging_read_only_notice.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    this.teacher = false,
    super.key,
  });

  final String currentLocation;
  final Widget child;
  final bool teacher;

  int get _selectedIndex {
    if (teacher) {
      return switch (currentLocation) {
        '/teacher/courses' => 1,
        '/teacher/work' => 2,
        '/teacher/calendar' => 3,
        '/teacher/profile' => 4,
        _ => 0,
      };
    }
    if (currentLocation.startsWith(AppRoutes.courses)) return 1;
    if (currentLocation.startsWith(AppRoutes.assignments)) return 2;
    if (currentLocation.startsWith(AppRoutes.progress)) return 3;
    if (currentLocation.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    if (teacher) {
      context.go(
        [
          '/teacher',
          '/teacher/courses',
          '/teacher/work',
          '/teacher/calendar',
          '/teacher/profile',
        ][index],
      );
      return;
    }
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.courses);
      case 2:
        context.go(AppRoutes.assignments);
      case 3:
        context.go(AppRoutes.progress);
      case 4:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagingNotice = ref.watch(appConfigProvider).isStaging
        ? const StagingReadOnlyNotice()
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final extended = constraints.maxWidth >= 980;
        final useRail = constraints.maxWidth >= 720;
        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    extended: extended,
                    minExtendedWidth: 220,
                    onDestinationSelected: (index) => _navigate(context, index),
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: _RailBrand(extended: extended),
                    ),
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.space_dashboard_outlined),
                        selectedIcon: Icon(Icons.space_dashboard_rounded),
                        label: Text('Trang chủ'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: Text('Khóa học'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment_rounded),
                        label: Text(teacher ? 'Công việc' : 'Bài tập'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          teacher
                              ? Icons.event_outlined
                              : Icons.auto_graph_outlined,
                        ),
                        selectedIcon: Icon(
                          teacher ? Icons.event : Icons.auto_graph_rounded,
                        ),
                        label: Text(teacher ? 'Lịch' : 'Tiến độ'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: Text('Hồ sơ'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _ShellBody(notice: stagingNotice, child: child),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: _ShellBody(notice: stagingNotice, child: child),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => _navigate(context, index),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Khóa học',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: teacher ? 'Công việc' : 'Bài tập',
              ),
              NavigationDestination(
                icon: Icon(
                  teacher ? Icons.event_outlined : Icons.auto_graph_outlined,
                ),
                selectedIcon: Icon(
                  teacher ? Icons.event : Icons.auto_graph_rounded,
                ),
                label: teacher ? 'Lịch' : 'Tiến độ',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Hồ sơ',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.child, required this.notice});

  final Widget child;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final banner = notice;
    if (banner == null) return child;
    return Column(
      children: [
        banner,
        Expanded(child: child),
      ],
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: const Icon(Icons.school_rounded),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            const Text(
              'DLU LMS',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }
}
