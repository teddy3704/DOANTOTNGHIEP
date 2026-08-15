import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/courses/presentation/screens/courses_screen.dart';
import 'package:dlu_lms_mobile/features/courses/presentation/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('courses screen renders loading then empty state', (
    tester,
  ) async {
    final completer = Completer<List<Course>>();

    await tester.pumpWidget(_coursesApp(_CompleterCourseRepository(completer)));
    await tester.pump();

    expect(find.text('Đang tải khóa học…'), findsOneWidget);

    completer.complete(const <Course>[]);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có khóa học'), findsOneWidget);
  });

  testWidgets('courses screen retries after a classified failure', (
    tester,
  ) async {
    final repository = _RetryCourseRepository();

    await tester.pumpWidget(_coursesApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(repository.requestCount, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 2);
    expect(find.text('Chưa có khóa học'), findsOneWidget);
  });

  testWidgets('courses screen filters by course name and code', (tester) async {
    const courses = <Course>[
      Course(
        id: 'course-1',
        shortName: 'MOB301',
        fullName: 'Phát triển ứng dụng di động',
        category: 'Công nghệ thông tin',
        accentIndex: 0,
        progress: 0.65,
      ),
      Course(
        id: 'course-2',
        shortName: 'WEB204',
        fullName: 'Thiết kế trải nghiệm web',
        category: 'Công nghệ thông tin',
        accentIndex: 1,
        progress: 0.4,
      ),
    ];

    await tester.pumpWidget(
      _coursesApp(const _MemoryCourseRepository(courses)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourseCard), findsNWidgets(2));
    expect(find.text('Tiến độ 65%'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'web204');
    await tester.pumpAndSettle();

    expect(find.text('Thiết kế trải nghiệm web'), findsOneWidget);
    expect(find.text('Phát triển ứng dụng di động'), findsNothing);

    await tester.enterText(find.byType(TextField), 'không tồn tại');
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy khóa học'), findsOneWidget);
    expect(find.text('Thử một tên hoặc mã khóa học khác.'), findsOneWidget);
  });

  testWidgets('course cards remain layout-safe on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _coursesApp(
        const _MemoryCourseRepository(<Course>[
          Course(
            id: 'course-compact',
            shortName: 'MOB301',
            fullName: 'Phát triển ứng dụng di động đa nền tảng',
            category: 'Khoa Công nghệ thông tin',
            accentIndex: 2,
            progress: 0.82,
            nextActivity: 'Bài tập thiết kế giao diện · 20/09',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourseCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _coursesApp(CourseRepository repository) => ProviderScope(
  overrides: <Override>[courseRepositoryProvider.overrideWithValue(repository)],
  child: const MaterialApp(home: Scaffold(body: CoursesScreen())),
);

class _CompleterCourseRepository implements CourseRepository {
  _CompleterCourseRepository(this.completer);

  final Completer<List<Course>> completer;

  @override
  Future<List<Course>> getMyCourses() => completer.future;

  @override
  Future<Course> getCourse(String courseId) => throw UnimplementedError();
}

class _RetryCourseRepository implements CourseRepository {
  int requestCount = 0;

  @override
  Future<List<Course>> getMyCourses() async {
    requestCount += 1;
    if (requestCount == 1) {
      throw const NetworkFailure('Synthetic network failure for widget test.');
    }
    return const <Course>[];
  }

  @override
  Future<Course> getCourse(String courseId) => throw UnimplementedError();
}

class _MemoryCourseRepository implements CourseRepository {
  const _MemoryCourseRepository(this.courses);

  final List<Course> courses;

  @override
  Future<Course> getCourse(String courseId) async =>
      courses.firstWhere((course) => course.id == courseId);

  @override
  Future<List<Course>> getMyCourses() async => courses;
}
