import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/assignments/presentation/screens/assignment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('assignment screen renders loading state', (tester) async {
    final completer = Completer<AssignmentDetail>();
    final repository = _MemoryAssignmentRepository(
      onGetAssignment: (_) => completer.future,
    );

    await tester.pumpWidget(_assignmentApp(repository));
    await tester.pump();

    expect(find.text('Đang tải bài tập…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('assignment screen renders populated assignment', (tester) async {
    final repository = _MemoryAssignmentRepository(
      onGetAssignment: (_) async => _assignment,
    );

    await tester.pumpWidget(_assignmentApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Bài tập phân tích yêu cầu'), findsOneWidget);
    expect(find.text('Phân tích một tình huống học tập mẫu.'), findsOneWidget);
    expect(find.text('Đã chấm'), findsOneWidget);
    expect(find.text('Sắp đến hạn'), findsOneWidget);
    expect(find.text('8.5 / 10'), findsOneWidget);
    expect(find.text('Lập luận rõ ràng và có dẫn chứng.'), findsOneWidget);

    final titleFinder = find.text('Bài tập phân tích yêu cầu');
    final title = tester.widget<Text>(titleFinder);
    expect(
      title.style?.color,
      Theme.of(tester.element(titleFinder)).colorScheme.onPrimaryContainer,
    );
  });

  testWidgets('assignment screen retries after a classified failure', (
    tester,
  ) async {
    final repository = _MemoryAssignmentRepository(
      onGetAssignment: (_) async {
        throw const NetworkFailure('Synthetic network failure.');
      },
    );

    await tester.pumpWidget(_assignmentApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(repository.detailRequestCount, 1);

    repository.onGetAssignment = (_) async => _assignment;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.detailRequestCount, 2);
    expect(find.text('Bài tập phân tích yêu cầu'), findsOneWidget);
  });
}

Widget _assignmentApp(AssignmentRepository repository) => ProviderScope(
  overrides: <Override>[
    assignmentRepositoryProvider.overrideWithValue(repository),
  ],
  child: const MaterialApp(
    home: AssignmentScreen(courseId: 'course-1', assignmentId: 'assignment-1'),
  ),
);

final _assignment = AssignmentDetail(
  id: 'assignment-1',
  courseId: 'course-1',
  name: 'Bài tập phân tích yêu cầu',
  description: 'Phân tích một tình huống học tập mẫu.',
  dueAt: DateTime.utc(2026, 9, 20, 16),
  allowsSubmissionsFrom: DateTime.utc(2026, 9, 10, 1),
  cutoffAt: DateTime.utc(2026, 9, 21, 16),
  timing: AssignmentTiming.soon,
  submissionState: SubmissionState.graded,
  submittedAt: DateTime.utc(2026, 9, 18, 9, 30),
  grade: 8.5,
  gradeMax: 10,
  feedback: 'Lập luận rõ ràng và có dẫn chứng.',
);

class _MemoryAssignmentRepository implements AssignmentRepository {
  _MemoryAssignmentRepository({required this.onGetAssignment});

  Future<AssignmentDetail> Function(String assignmentId) onGetAssignment;
  int detailRequestCount = 0;

  @override
  Future<AssignmentDetail> getAssignment(String assignmentId) {
    detailRequestCount += 1;
    return onGetAssignment(assignmentId);
  }

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) async =>
      <AssignmentDetail>[_assignment];
}
