import 'package:dlu_lms_mobile/app/router/app_routes.dart';
import 'package:dlu_lms_mobile/features/dashboard/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('compact shell exposes four student destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.destinations, hasLength(4));
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Khóa học'), findsOneWidget);
    expect(find.text('Lịch'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('Tổng quan'), findsNothing);
    expect(find.text('Cá nhân'), findsNothing);

    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();

    expect(find.text('calendar-page'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('profile-page'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets('wide shell renders the same destinations in a rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _testRouter(initialLocation: AppRoutes.calendar);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(4));
    expect(rail.selectedIndex, 2);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Khóa học'), findsOneWidget);
    expect(find.text('Lịch'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });
}

GoRouter _testRouter({String initialLocation = AppRoutes.dashboard}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        _shellRoute(AppRoutes.dashboard, 'dashboard-page'),
        _shellRoute(AppRoutes.courses, 'courses-page'),
        _shellRoute(AppRoutes.calendar, 'calendar-page'),
        _shellRoute(AppRoutes.profile, 'profile-page'),
      ],
    );

GoRoute _shellRoute(String path, String pageLabel) => GoRoute(
  path: path,
  builder: (context, state) => AppShell(
    currentLocation: state.uri.path,
    child: Center(child: Text(pageLabel)),
  ),
);
