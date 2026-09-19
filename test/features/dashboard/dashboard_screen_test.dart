import 'dart:async';

import 'package:dlu_lms_mobile/features/assignments/domain/assignment.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/calendar/domain/calendar_repository.dart';
import 'package:dlu_lms_mobile/features/calendar/domain/learning_event.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders student priorities without technical labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          courseRepositoryProvider.overrideWithValue(_CourseRepository()),
          assignmentRepositoryProvider.overrideWithValue(
            _AssignmentRepository(),
          ),
          calendarRepositoryProvider.overrideWithValue(_CalendarRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Việc cần ưu tiên'), findsOneWidget);
    expect(find.text('Báo cáo chuyên đề'), findsOneWidget);
    expect(find.textContaining('Còn'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Khóa học hiện tại'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Khóa học hiện tại'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .join(' ')
        .toLowerCase();
    for (final forbidden in <String>[
      'dev',
      'fixture',
      'mock',
      'synthetic',
      'debug',
      'token',
      'endpoint',
    ]) {
      expect(visibleText, isNot(contains(forbidden)));
    }
  });

  testWidgets(
    'keeps a meaningful greeting when a preview name ends in digits',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authRepositoryProvider.overrideWithValue(const _SessionAuth()),
            courseRepositoryProvider.overrideWithValue(_CourseRepository()),
            assignmentRepositoryProvider.overrideWithValue(
              _AssignmentRepository(),
            ),
            calendarRepositoryProvider.overrideWithValue(_CalendarRepository()),
          ],
          child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Sinh viên mẫu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _CourseRepository implements CourseRepository {
  static const course = Course(
    id: 'course-1',
    shortName: 'CNTT201',
    fullName: 'Cơ sở dữ liệu ứng dụng',
    category: 'Công nghệ thông tin',
    accentIndex: 0,
    progress: 0.65,
  );

  @override
  Future<Course> getCourse(String courseId) async => course;

  @override
  Future<List<Course>> getMyCourses() async => const <Course>[course];
}

class _AssignmentRepository implements AssignmentRepository {
  @override
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  }) async => (await getAssignments()).first;

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) async =>
      <AssignmentDetail>[
        AssignmentDetail(
          id: 'assignment-1',
          courseId: 'course-1',
          name: 'Báo cáo chuyên đề',
          description: 'Hoàn thiện báo cáo theo yêu cầu.',
          dueAt: DateTime.now().add(const Duration(days: 2)),
          allowsSubmissionsFrom: DateTime.now(),
          cutoffAt: DateTime.now().add(const Duration(days: 5)),
          timing: AssignmentTiming.soon,
          submissionState: SubmissionState.notSubmitted,
        ),
      ];
}

class _CalendarRepository implements CalendarRepository {
  @override
  Future<List<LearningEvent>> getUpcomingEvents() async => <LearningEvent>[
    LearningEvent(
      id: 'event-1',
      courseId: 'course-1',
      name: 'Thảo luận chương 2',
      startsAt: DateTime.now().add(const Duration(days: 3)),
      eventType: 'course',
    ),
  ];
}

class _SessionAuth implements AuthRepository {
  const _SessionAuth();

  @override
  Stream<void> get sessionInvalidations => const Stream<void>.empty();

  @override
  Future<AuthSession?> restoreSession() async =>
      const AuthSession(userId: 'SV001', displayName: 'Sinh viên mẫu 01');

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}
