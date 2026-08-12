import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/courses/presentation/screens/courses_screen.dart';
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
