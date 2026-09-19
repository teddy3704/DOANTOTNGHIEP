import 'dart:async';

import 'package:dlu_lms_mobile/app/theme/app_theme.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/progress/presentation/screens/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a clear and accessible course progress summary', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _progressApp(
          const _MemoryCourseRepository(<Course>[
            Course(
              id: 'mob-301',
              shortName: 'MOB301',
              fullName: 'Phát triển ứng dụng di động',
              category: 'Công nghệ thông tin',
              accentIndex: 0,
              progress: 0.65,
              nextActivity: 'Hoàn thiện giao diện tuần 4',
            ),
            Course(
              id: 'web-204',
              shortName: 'WEB204',
              fullName: 'Thiết kế trải nghiệm web',
              category: 'Công nghệ thông tin',
              accentIndex: 1,
              progress: 0.25,
            ),
            Course(
              id: 'eng-102',
              shortName: 'ENG102',
              fullName: 'Tiếng Anh chuyên ngành',
              category: 'Ngoại ngữ',
              accentIndex: 2,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiến độ học tập'), findsOneWidget);
      expect(find.text('Trung bình hoàn thành'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('2/3 khóa học đã có dữ liệu tiến độ'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .color,
        AppTheme.light().colorScheme.onPrimaryContainer,
      );
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Chưa có dữ liệu tiến độ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Chưa có dữ liệu tiến độ'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Tiến độ khóa học Phát triển ứng dụng di động'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('uses the shared loading and empty states', (tester) async {
    final completer = Completer<List<Course>>();

    await tester.pumpWidget(
      _progressApp(_CompleterCourseRepository(completer)),
    );
    await tester.pump();

    expect(find.text('Đang tải tiến độ học tập…'), findsOneWidget);

    completer.complete(const <Course>[]);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có khóa học'), findsOneWidget);
    expect(
      find.text('Tiến độ học tập sẽ xuất hiện khi bạn tham gia khóa học.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'keeps long course progress content layout-safe on a compact phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _progressApp(
          const _MemoryCourseRepository(<Course>[
            Course(
              id: 'compact-course',
              shortName: 'MOB301',
              fullName: 'Phát triển ứng dụng di động đa nền tảng',
              category: 'Khoa Công nghệ thông tin',
              accentIndex: 0,
              progress: 0.82,
              nextActivity: 'Hoàn thiện giao diện và kiểm thử tuần 4',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('82%'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('uses the shared error state and retries the course request', (
    tester,
  ) async {
    final repository = _RetryCourseRepository();

    await tester.pumpWidget(_progressApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(repository.requestCount, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 2);
    expect(find.text('Chưa có khóa học'), findsOneWidget);
  });
}

Widget _progressApp(CourseRepository repository) => ProviderScope(
  overrides: <Override>[courseRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(body: ProgressScreen()),
  ),
);

class _MemoryCourseRepository implements CourseRepository {
  const _MemoryCourseRepository(this.courses);

  final List<Course> courses;

  @override
  Future<Course> getCourse(String courseId) async =>
      courses.firstWhere((course) => course.id == courseId);

  @override
  Future<List<Course>> getMyCourses() async => courses;
}

class _CompleterCourseRepository implements CourseRepository {
  _CompleterCourseRepository(this.completer);

  final Completer<List<Course>> completer;

  @override
  Future<Course> getCourse(String courseId) => throw UnimplementedError();

  @override
  Future<List<Course>> getMyCourses() => completer.future;
}

class _RetryCourseRepository implements CourseRepository {
  int requestCount = 0;

  @override
  Future<Course> getCourse(String courseId) => throw UnimplementedError();

  @override
  Future<List<Course>> getMyCourses() async {
    requestCount += 1;
    if (requestCount == 1) {
      throw const NetworkFailure('Network failure for progress screen test.');
    }
    return const <Course>[];
  }
}
