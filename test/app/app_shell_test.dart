import 'package:dlu_lms_mobile/app/router/app_routes.dart';
import 'package:dlu_lms_mobile/core/config/app_config.dart';
import 'package:dlu_lms_mobile/core/widgets/staging_read_only_notice.dart';
import 'package:dlu_lms_mobile/features/dashboard/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final teacher in [false, true]) {
    for (final width in [320.0, 390.0]) {
      testWidgets('assistant navigation role=$teacher width=$width scaled', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final paths = teacher
            ? [
                '/teacher',
                '/teacher/courses',
                '/teacher/interventions',
                '/teacher/calendar',
                '/teacher/profile',
              ]
            : [
                AppRoutes.dashboard,
                AppRoutes.studyPlan,
                AppRoutes.courses,
                AppRoutes.progress,
                AppRoutes.profile,
              ];
        final labels = teacher
            ? ['Hôm nay', 'Khóa học', 'Theo dõi', 'Lịch', 'Hồ sơ']
            : ['Hôm nay', 'Kế hoạch', 'Khóa học', 'Tiến độ', 'Hồ sơ'];
        final router = GoRouter(
          initialLocation: paths.first,
          routes: [
            for (final path in paths)
              GoRoute(
                path: path,
                builder: (context, state) => AppShell(
                  teacher: teacher,
                  currentLocation: state.uri.path,
                  child: Text('page:$path'),
                ),
              ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(AppConfig.staging()),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var index = 0; index < paths.length; index++) {
          await tester.tap(find.text(labels[index]));
          await tester.pumpAndSettle();
          expect(find.text('page:${paths[index]}'), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            index,
          );
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
  testWidgets('compact shell exposes five student destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.development()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.destinations, hasLength(5));
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Khóa học'), findsOneWidget);
    expect(find.text('Bài tập'), findsOneWidget);
    expect(find.text('Tiến độ'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('Tổng quan'), findsNothing);
    expect(find.text('Cá nhân'), findsNothing);

    await tester.tap(find.text('Bài tập'));
    await tester.pumpAndSettle();

    expect(find.text('assignments-page'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Tiến độ'));
    await tester.pumpAndSettle();

    expect(find.text('progress-page'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('profile-page'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
  });

  testWidgets('wide shell renders the same destinations in a rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _testRouter(initialLocation: AppRoutes.progress);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.development()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(5));
    expect(rail.selectedIndex, 3);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Khóa học'), findsOneWidget);
    expect(find.text('Bài tập'), findsOneWidget);
    expect(find.text('Tiến độ'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });

  testWidgets('staging shell makes the read-only data preview explicit', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(AppConfig.staging())],
        child: const MaterialApp(
          home: AppShell(
            currentLocation: AppRoutes.dashboard,
            child: Center(child: Text('dashboard-page')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Dữ liệu mô phỏng · Học tập chính thức trên LMS'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('root staging pages keep the notice compact on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(AppConfig.staging())],
        child: const MaterialApp(
          home: StagingReadOnlyFrame(
            child: Scaffold(body: Center(child: Text('detail-page'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(
      find.text('Dữ liệu mô phỏng · Học tập chính thức trên LMS'),
    );
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.style?.fontSize, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

GoRouter _testRouter({String initialLocation = AppRoutes.dashboard}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        _shellRoute(AppRoutes.dashboard, 'dashboard-page'),
        _shellRoute(AppRoutes.courses, 'courses-page'),
        _shellRoute(AppRoutes.assignments, 'assignments-page'),
        _shellRoute(AppRoutes.progress, 'progress-page'),
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
