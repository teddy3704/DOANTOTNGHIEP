import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/grades/domain/grade_entry.dart';
import 'package:dlu_lms_mobile/features/grades/domain/grade_repository.dart';
import 'package:dlu_lms_mobile/features/grades/presentation/screens/grades_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grades screen renders loading state', (tester) async {
    final completer = Completer<List<GradeEntry>>();
    final repository = _MemoryGradeRepository(
      onGetGrades: (_) => completer.future,
    );

    await tester.pumpWidget(_gradesApp(repository));
    await tester.pump();

    expect(find.text('Đang tải điểm…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('grades screen renders populated grade book', (tester) async {
    final repository = _MemoryGradeRepository(
      onGetGrades: (_) async => _grades,
    );

    await tester.pumpWidget(_gradesApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Phát triển ứng dụng di động'), findsOneWidget);
    expect(find.text('Trung bình các mục đã chấm: 80.0%'), findsOneWidget);
    expect(find.text('Bài tập phân tích yêu cầu'), findsOneWidget);
    expect(find.text('8 / 10'), findsOneWidget);
    expect(find.text('Bài tập chưa chấm'), findsOneWidget);
    expect(find.text('Chưa chấm'), findsOneWidget);

    final courseNameFinder = find.text('Phát triển ứng dụng di động');
    final courseName = tester.widget<Text>(courseNameFinder);
    expect(
      courseName.style?.color,
      Theme.of(tester.element(courseNameFinder)).colorScheme.onPrimaryContainer,
    );
  });

  testWidgets('grades screen renders empty state', (tester) async {
    final repository = _MemoryGradeRepository(
      onGetGrades: (_) async => const <GradeEntry>[],
    );

    await tester.pumpWidget(_gradesApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có mục điểm'), findsOneWidget);
    expect(
      find.text('Các mục điểm được phép hiển thị sẽ xuất hiện tại đây.'),
      findsOneWidget,
    );
  });

  testWidgets('grades screen retries after a classified failure', (
    tester,
  ) async {
    final repository = _MemoryGradeRepository(
      onGetGrades: (_) async {
        throw const NetworkFailure('Synthetic network failure.');
      },
    );

    await tester.pumpWidget(_gradesApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(repository.requestCount, 1);

    repository.onGetGrades = (_) async => const <GradeEntry>[];
    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 2);
    expect(find.text('Chưa có mục điểm'), findsOneWidget);
  });
}

Widget _gradesApp(GradeRepository gradeRepository) => ProviderScope(
  overrides: <Override>[
    gradeRepositoryProvider.overrideWithValue(gradeRepository),
    courseRepositoryProvider.overrideWithValue(const _MemoryCourseRepository()),
  ],
  child: const MaterialApp(home: GradesScreen(courseId: 'course-1')),
);

const _course = Course(
  id: 'course-1',
  shortName: 'MOB101',
  fullName: 'Phát triển ứng dụng di động',
  category: 'Công nghệ thông tin',
  accentIndex: 1,
);

const _grades = <GradeEntry>[
  GradeEntry(
    id: 'grade-1',
    courseId: 'course-1',
    itemName: 'Bài tập phân tích yêu cầu',
    minimum: 0,
    maximum: 10,
    hidden: false,
    finalGrade: 8,
    feedback: 'Đạt yêu cầu.',
  ),
  GradeEntry(
    id: 'grade-2',
    courseId: 'course-1',
    itemName: 'Bài tập chưa chấm',
    minimum: 0,
    maximum: 10,
    hidden: false,
  ),
];

class _MemoryGradeRepository implements GradeRepository {
  _MemoryGradeRepository({required this.onGetGrades});

  Future<List<GradeEntry>> Function(String courseId) onGetGrades;
  int requestCount = 0;

  @override
  Future<List<GradeEntry>> getGrades(String courseId) {
    requestCount += 1;
    return onGetGrades(courseId);
  }
}

class _MemoryCourseRepository implements CourseRepository {
  const _MemoryCourseRepository();

  @override
  Future<Course> getCourse(String courseId) async => _course;

  @override
  Future<List<Course>> getMyCourses() async => const <Course>[_course];
}
