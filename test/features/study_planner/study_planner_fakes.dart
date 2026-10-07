// Synthetic in-memory doubles used only by study planner tests.
import 'dart:async';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/learning_reminder.dart';
import 'package:dlu_lms_mobile/features/reminders/domain/reminder_repository.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_plan.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_planner_repository.dart';

final testNow = DateTime(2030, 6, 3, 9);

StudyRecommendation recommendation({bool planned = false}) =>
    StudyRecommendation(
      assignmentId: 'assignment-1',
      assignmentCode: 'A01',
      assignmentName: 'Phân tích yêu cầu ứng dụng học tập',
      courseId: 'course-1',
      courseCode: 'C01',
      courseName: 'Phát triển ứng dụng di động',
      dueAt: testNow.add(const Duration(days: 2)),
      submissionStatus: 'not_submitted',
      priority: StudyPriority.high,
      reasons: const ['Bài tập sắp đến hạn.', 'Chưa có bài nộp được ghi nhận.'],
      planned: planned,
      recommendedDurationMinutes: 45,
    );

StudyPlanItem planItem({
  String id = 'plan-1',
  DateTime? start,
  StudyPlanStatus status = StudyPlanStatus.planned,
  int minutes = 45,
  String notes = '',
}) => StudyPlanItem(
  id: id,
  assignmentId: 'assignment-1',
  assignmentCode: 'A01',
  courseId: 'course-1',
  courseName: 'Phát triển ứng dụng di động',
  title: 'Phân tích yêu cầu ứng dụng học tập',
  dueAt: testNow.add(const Duration(days: 2)),
  priority: StudyPriority.high,
  reasons: const ['Bài tập sắp đến hạn.'],
  scheduledStartAt: start ?? testNow.add(const Duration(hours: 1)),
  estimatedMinutes: minutes,
  notes: notes,
  status: status,
  createdAt: testNow,
  updatedAt: testNow,
);

class MemoryStudyRepository implements StudyPlannerRepository {
  final List<StudyPlanItem> items = [];
  int creates = 0;
  int updates = 0;
  int deletes = 0;
  int recommendationReads = 0;
  int planReads = 0;
  Future<List<StudyRecommendation>> Function()? onRecommendations;
  Future<List<StudyPlanItem>> Function()? onPlan;
  Future<void> Function()? afterWrite;

  @override
  Future<List<StudyRecommendation>> getRecommendations() async {
    recommendationReads++;
    return onRecommendations != null
        ? onRecommendations!()
        : [recommendation(planned: items.isNotEmpty)];
  }

  @override
  Future<List<StudyPlanItem>> getPlan() async {
    planReads++;
    return onPlan != null ? onPlan!() : List.of(items);
  }

  @override
  Future<StudyPlanItem> createItem({
    required String assignmentId,
    required DateTime scheduledStartAt,
    required int estimatedMinutes,
    required String notes,
  }) async {
    creates++;
    final item = planItem(
      id: 'plan-$creates',
      start: scheduledStartAt,
      minutes: estimatedMinutes,
      notes: notes,
    );
    items.add(item);
    await afterWrite?.call();
    return item;
  }

  @override
  Future<StudyPlanItem> updateItem(
    String id, {
    DateTime? scheduledStartAt,
    int? estimatedMinutes,
    String? notes,
    StudyPlanStatus? status,
  }) async {
    updates++;
    final index = items.indexWhere((item) => item.id == id);
    final old = items[index];
    final item = planItem(
      id: id,
      start: scheduledStartAt ?? old.scheduledStartAt,
      minutes: estimatedMinutes ?? old.estimatedMinutes,
      notes: notes ?? old.notes,
      status: status ?? old.status,
    );
    items[index] = item;
    await afterWrite?.call();
    return item;
  }

  @override
  Future<void> deleteItem(String id) async {
    deletes++;
    items.removeWhere((item) => item.id == id);
    await afterWrite?.call();
  }
}

class MemoryStudyAuth implements AuthRepository {
  MemoryStudyAuth({this.role = DluRole.student});
  DluRole role;
  String userId = 'student-1';
  Completer<AuthSession?>? pending;
  @override
  Stream<void> get sessionInvalidations => const Stream.empty();
  @override
  Future<AuthSession?> restoreSession() async =>
      pending?.future ??
      AuthSession(userId: userId, displayName: 'Người dùng mẫu', role: role);
  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async => (await restoreSession())!;
  @override
  Future<void> signOut() async {}
}

class MemoryStudyReminders implements ReminderRepository {
  final List<LearningReminder> entries = [];
  bool failCreate = false;
  bool failDelete = false;
  int creates = 0;
  @override
  Future<List<LearningReminder>> listForOwner(String ownerId) async =>
      entries.where((entry) => entry.ownerId == ownerId).toList();
  @override
  Future<LearningReminder> create({
    required String ownerId,
    required LearningReminderDraft draft,
  }) async {
    if (failCreate) throw StateError('notification unavailable');
    final result = LearningReminder(
      id: 'reminder-${++creates}',
      ownerId: ownerId,
      courseId: draft.courseId,
      assignmentId: draft.assignmentId,
      dueAt: draft.dueAt,
      remindAt: draft.remindAt,
      isEnabled: draft.isEnabled,
      createdAt: testNow,
      updatedAt: testNow,
    );
    entries.add(result);
    return result;
  }

  @override
  Future<void> delete({
    required String ownerId,
    required String reminderId,
  }) async {
    if (failDelete) throw StateError('notification cancellation unavailable');
    entries.removeWhere(
      (entry) => entry.ownerId == ownerId && entry.id == reminderId,
    );
  }

  @override
  Future<LearningReminder> setEnabled({
    required String ownerId,
    required String reminderId,
    required bool isEnabled,
  }) => throw UnimplementedError();
  @override
  Future<LearningReminder> update({
    required String ownerId,
    required LearningReminder reminder,
  }) => throw UnimplementedError();
}
