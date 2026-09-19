import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/assignments/presentation/screens/assignments_screen.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('assignment list renders loading state without a spinner', (
    tester,
  ) async {
    final assignments = Completer<List<AssignmentDetail>>();

    await tester.pumpWidget(
      _assignmentsApp(
        assignmentRepository: _MemoryAssignmentRepository(
          onGetAssignments: () => assignments.future,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Đang tải bài tập…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'assignment list filters cards and shows a grade only when present',
    (tester) async {
      await tester.pumpWidget(_assignmentsApp());
      await tester.pumpAndSettle();

      expect(find.text('Bài thực hành giao diện'), findsOneWidget);
      expect(find.text('Báo cáo kiến trúc ứng dụng'), findsOneWidget);
      expect(find.text('Thiết kế luồng người dùng'), findsOneWidget);
      expect(find.text('Điểm 8.5 / 10'), findsOneWidget);
      expect(find.text('Điểm 7.5 / 10'), findsNothing);

      await tester.tap(find.text('Đã nộp'));
      await tester.pumpAndSettle();
      expect(find.text('Bài thực hành giao diện'), findsOneWidget);
      expect(find.text('Báo cáo kiến trúc ứng dụng'), findsNothing);
      expect(find.text('Thiết kế luồng người dùng'), findsNothing);

      await tester.tap(find.text('Chưa nộp'));
      await tester.pumpAndSettle();
      expect(find.text('Bài thực hành giao diện'), findsNothing);
      expect(find.text('Báo cáo kiến trúc ứng dụng'), findsOneWidget);

      await tester.tap(find.text('Quá hạn'));
      await tester.pumpAndSettle();
      expect(find.text('Thiết kế luồng người dùng'), findsOneWidget);
      expect(find.text('Báo cáo kiến trúc ứng dụng'), findsNothing);
    },
  );

  testWidgets('assignment card opens the existing detail route', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_assignmentsApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bài thực hành giao diện'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chi tiết bài tập'), findsOneWidget);
    expect(find.textContaining('course-1/assignment-1'), findsOneWidget);
  });

  testWidgets('assignment list retries after a classified failure', (
    tester,
  ) async {
    final repository = _MemoryAssignmentRepository(
      onGetAssignments: () async {
        throw const NetworkFailure('Synthetic test failure.');
      },
    );
    await tester.pumpWidget(_assignmentsApp(assignmentRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(repository.requestCount, 1);

    repository.onGetAssignments = () async => _assignments;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 2);
    expect(find.text('Bài thực hành giao diện'), findsOneWidget);
  });

  testWidgets('assignment cards remain layout-safe on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_assignmentsApp());
    await tester.pumpAndSettle();

    expect(find.text('Bài thực hành giao diện'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _assignmentsApp({
  AssignmentRepository? assignmentRepository,
  GoRouter? router,
}) {
  final scope = ProviderScope(
    overrides: <Override>[
      assignmentRepositoryProvider.overrideWithValue(
        assignmentRepository ??
            _MemoryAssignmentRepository(
              onGetAssignments: () async => _assignments,
            ),
      ),
      courseRepositoryProvider.overrideWithValue(
        const _MemoryCourseRepository(),
      ),
    ],
    child: router == null
        ? const MaterialApp(home: Scaffold(body: AssignmentsScreen()))
        : MaterialApp.router(routerConfig: router),
  );
  return scope;
}

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: AssignmentsScreen()),
    ),
    GoRoute(
      path: '/courses/:courseId/assignments/:assignmentId',
      builder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Chi tiết bài tập\n${state.pathParameters['courseId']}/${state.pathParameters['assignmentId']}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  ],
);

final _assignments = <AssignmentDetail>[
  AssignmentDetail(
    id: 'assignment-1',
    courseId: 'course-1',
    name: 'Bài thực hành giao diện',
    description: 'Thiết kế giao diện ứng dụng di động.',
    dueAt: DateTime(2026, 9, 25, 16),
    allowsSubmissionsFrom: DateTime(2026, 9, 10),
    cutoffAt: null,
    timing: AssignmentTiming.soon,
    submissionState: SubmissionState.graded,
    grade: 8.5,
    gradeMax: 10,
  ),
  AssignmentDetail(
    id: 'assignment-2',
    courseId: 'course-2',
    name: 'Báo cáo kiến trúc ứng dụng',
    description: 'Trình bày kiến trúc hệ thống.',
    dueAt: DateTime(2026, 9, 28, 9),
    allowsSubmissionsFrom: DateTime(2026, 9, 14),
    cutoffAt: null,
    timing: AssignmentTiming.future,
    submissionState: SubmissionState.notSubmitted,
  ),
  AssignmentDetail(
    id: 'assignment-3',
    courseId: 'course-1',
    name: 'Thiết kế luồng người dùng',
    description: 'Phân tích luồng thao tác.',
    dueAt: DateTime(2026, 9, 12, 16),
    allowsSubmissionsFrom: DateTime(2026, 9, 1),
    cutoffAt: null,
    timing: AssignmentTiming.overdue,
    submissionState: SubmissionState.missing,
  ),
];

class _MemoryAssignmentRepository implements AssignmentRepository {
  _MemoryAssignmentRepository({required this.onGetAssignments});

  Future<List<AssignmentDetail>> Function() onGetAssignments;
  int requestCount = 0;

  @override
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  }) async =>
      _assignments.firstWhere((assignment) => assignment.id == assignmentId);

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) {
    requestCount += 1;
    return onGetAssignments();
  }
}

class _MemoryCourseRepository implements CourseRepository {
  const _MemoryCourseRepository();

  @override
  Future<Course> getCourse(String courseId) async =>
      (await getMyCourses()).firstWhere((course) => course.id == courseId);

  @override
  Future<List<Course>> getMyCourses() async => const <Course>[
    Course(
      id: 'course-1',
      shortName: 'MOB301',
      fullName: 'Phát triển ứng dụng di động',
      category: 'Công nghệ thông tin',
      accentIndex: 0,
    ),
    Course(
      id: 'course-2',
      shortName: 'WEB204',
      fullName: 'Thiết kế trải nghiệm web',
      category: 'Công nghệ thông tin',
      accentIndex: 1,
    ),
  ];
}
