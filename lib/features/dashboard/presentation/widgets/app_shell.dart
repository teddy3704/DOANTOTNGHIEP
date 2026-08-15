import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get _selectedIndex {
    if (currentLocation.startsWith(AppRoutes.courses)) return 1;
    if (currentLocation.startsWith(AppRoutes.calendar)) return 2;
    if (currentLocation.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.courses);
      case 2:
        context.go(AppRoutes.calendar);
      case 3:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
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
                  destinations: const [
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
                      icon: Icon(Icons.calendar_today_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: Text('Lịch'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Hồ sơ'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => _navigate(context, index),
          destinations: const [
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
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Lịch',
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
