import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment.dart';
import 'package:dlu_lms_mobile/features/assignments/domain/assignment_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/learning_reminder.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/reminder_repository.dart';
import 'package:dlu_lms_mobile/features/reminders/presentation/reminder_providers.dart';
import 'package:dlu_lms_mobile/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a loading skeleton while reminders are loading', (
    tester,
  ) async {
    final completer = Completer<List<LearningReminder>>();
    await tester.pumpWidget(
      _app(
        reminderRepository: _MemoryReminderRepository(
          onList: (_) => completer.future,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Nhắc việc học tập'), findsOneWidget);
    expect(find.bySemanticsLabel('Đang tải nhắc việc học tập'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(const <LearningReminder>[]);
  });

  testWidgets('resolves a safe assignment name and changes enabled state', (
    tester,
  ) async {
    final reminder = _reminder();
    final repository = _MemoryReminderRepository(
      onList: (_) async => <LearningReminder>[reminder],
    );
    await tester.pumpWidget(
      _app(
        reminderRepository: repository,
        assignmentRepository: _MemoryAssignmentRepository([_assignment]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhắc việc học tập'), findsWidgets);
    expect(find.text('Phân tích thiết kế hệ thống'), findsOneWidget);
    expect(find.textContaining('course-private'), findsNothing);
    expect(find.textContaining('assignment-private'), findsNothing);

    final reminderSwitch = find.byType(Switch);
    expect(reminderSwitch, findsOneWidget);
    expect(tester.widget<Switch>(reminderSwitch).value, isTrue);

    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    expect(repository.setEnabledCalls, <_SetEnabledCall>[
      const _SetEnabledCall('learner-1', 'reminder-1', false),
    ]);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('confirms then deletes only the active learner reminder', (
    tester,
  ) async {
    final repository = _MemoryReminderRepository(
      onList: (_) async => <LearningReminder>[_reminder()],
    );
    await tester.pumpWidget(_app(reminderRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa nhắc việc'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa nhắc việc?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, <_DeleteCall>[
      const _DeleteCall('learner-1', 'reminder-1'),
    ]);
    expect(find.text('Chưa có nhắc việc'), findsOneWidget);
  });

  testWidgets('maps a reminder failure safely and retries the owner query', (
    tester,
  ) async {
    var requestCount = 0;
    final repository = _MemoryReminderRepository(
      onList: (_) async {
        if (requestCount == 0) {
          requestCount += 1;
          throw const NetworkFailure('diagnostic detail must stay internal');
        }
        requestCount += 1;
        return const <LearningReminder>[];
      },
    );
    await tester.pumpWidget(_app(reminderRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(
      find.text('Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.'),
      findsOneWidget,
    );
    expect(find.textContaining('diagnostic'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(requestCount, 2);
    expect(find.text('Chưa có nhắc việc'), findsOneWidget);
  });

  testWidgets('does not query local reminders without an active learner', (
    tester,
  ) async {
    final repository = _MemoryReminderRepository(
      onList: (_) async => <LearningReminder>[_reminder()],
    );
    await tester.pumpWidget(
      _app(
        authRepository: const _FakeAuthRepository(null),
        reminderRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có người học'), findsOneWidget);
    expect(repository.listOwners, isEmpty);
  });

  testWidgets('shows a back affordance for a contextual reminders route', (
    tester,
  ) async {
    await tester.pumpWidget(_app(showBackButton: true));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Quay lại'), findsOneWidget);
  });
}

Widget _app({
  AuthRepository authRepository = const _FakeAuthRepository(
    AuthSession(userId: 'learner-1', displayName: 'Người học mẫu'),
  ),
  ReminderRepository? reminderRepository,
  AssignmentRepository? assignmentRepository,
  bool showBackButton = false,
}) => ProviderScope(
  overrides: <Override>[
    authRepositoryProvider.overrideWithValue(authRepository),
    reminderRepositoryProvider.overrideWithValue(
      reminderRepository ??
          _MemoryReminderRepository(onList: (_) async => <LearningReminder>[]),
    ),
    assignmentRepositoryProvider.overrideWithValue(
      assignmentRepository ??
          const _MemoryAssignmentRepository(<AssignmentDetail>[]),
    ),
  ],
  child: MaterialApp(
    theme: ThemeData(useMaterial3: false),
    home: Scaffold(body: RemindersScreen(showBackButton: showBackButton)),
  ),
);

final _assignment = AssignmentDetail(
  id: 'assignment-private-1',
  courseId: 'course-private-1',
  name: 'Phân tích thiết kế hệ thống',
  description: 'Nội dung chỉ dùng trong dữ liệu kiểm thử.',
  dueAt: DateTime.utc(2030, 8, 22, 10),
  allowsSubmissionsFrom: DateTime.utc(2030, 8, 10),
  cutoffAt: null,
  timing: AssignmentTiming.soon,
  submissionState: SubmissionState.notSubmitted,
);

LearningReminder _reminder() => LearningReminder(
  id: 'reminder-1',
  ownerId: 'learner-1',
  courseId: 'course-private-1',
  assignmentId: 'assignment-private-1',
  dueAt: DateTime.utc(2030, 8, 22, 10),
  remindAt: DateTime.utc(2030, 8, 22, 8),
  isEnabled: true,
  createdAt: DateTime.utc(2030, 8, 1),
  updatedAt: DateTime.utc(2030, 8, 1),
);

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this.session);

  final AuthSession? session;

  @override
  Stream<void> get sessionInvalidations => const Stream<void>.empty();

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _MemoryReminderRepository implements ReminderRepository {
  _MemoryReminderRepository({required this.onList});

  Future<List<LearningReminder>> Function(String ownerId) onList;
  final List<String> listOwners = <String>[];
  final List<_SetEnabledCall> setEnabledCalls = <_SetEnabledCall>[];
  final List<_DeleteCall> deleteCalls = <_DeleteCall>[];
  List<LearningReminder> _stored = <LearningReminder>[];
  var _hasLoaded = false;

  @override
  Future<List<LearningReminder>> listForOwner(String ownerId) async {
    listOwners.add(ownerId);
    if (_hasLoaded) {
      return _stored
          .where((reminder) => reminder.ownerId == ownerId)
          .toList(growable: false);
    }
    final listed = await onList(ownerId);
    _hasLoaded = true;
    _stored = List<LearningReminder>.from(listed);
    return _stored
        .where((reminder) => reminder.ownerId == ownerId)
        .toList(growable: false);
  }

  @override
  Future<LearningReminder> create({
    required String ownerId,
    required LearningReminderDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<void> delete({
    required String ownerId,
    required String reminderId,
  }) async {
    deleteCalls.add(_DeleteCall(ownerId, reminderId));
    _stored = _stored
        .where(
          (reminder) =>
              reminder.id != reminderId || reminder.ownerId != ownerId,
        )
        .toList(growable: false);
  }

  @override
  Future<LearningReminder> setEnabled({
    required String ownerId,
    required String reminderId,
    required bool isEnabled,
  }) async {
    setEnabledCalls.add(_SetEnabledCall(ownerId, reminderId, isEnabled));
    final index = _stored.indexWhere(
      (reminder) => reminder.id == reminderId && reminder.ownerId == ownerId,
    );
    final next = _stored[index].withUserSettings(
      isEnabled: isEnabled,
      updatedAt: DateTime.utc(2030, 8, 2),
    );
    _stored[index] = next;
    return next;
  }

  @override
  Future<LearningReminder> update({
    required String ownerId,
    required LearningReminder reminder,
  }) => throw UnimplementedError();
}

class _MemoryAssignmentRepository implements AssignmentRepository {
  const _MemoryAssignmentRepository(this.assignments);

  final List<AssignmentDetail> assignments;

  @override
  Future<AssignmentDetail> getAssignment(
    String assignmentId, {
    String? courseId,
  }) async => assignments.firstWhere((item) => item.id == assignmentId);

  @override
  Future<List<AssignmentDetail>> getAssignments({String? courseId}) async =>
      assignments;
}

class _SetEnabledCall {
  const _SetEnabledCall(this.ownerId, this.reminderId, this.isEnabled);

  final String ownerId;
  final String reminderId;
  final bool isEnabled;

  @override
  bool operator ==(Object other) =>
      other is _SetEnabledCall &&
      other.ownerId == ownerId &&
      other.reminderId == reminderId &&
      other.isEnabled == isEnabled;

  @override
  int get hashCode => Object.hash(ownerId, reminderId, isEnabled);
}

class _DeleteCall {
  const _DeleteCall(this.ownerId, this.reminderId);

  final String ownerId;
  final String reminderId;

  @override
  bool operator ==(Object other) =>
      other is _DeleteCall &&
      other.ownerId == ownerId &&
      other.reminderId == reminderId;

  @override
  int get hashCode => Object.hash(ownerId, reminderId);
}
