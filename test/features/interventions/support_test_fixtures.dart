// MOCK data: synthetic test accounts and app-owned support records only.
import 'dart:async';
import 'package:dlu_lms_mobile/features/auth/domain/auth_repository.dart';
import 'package:dlu_lms_mobile/features/auth/domain/auth_session.dart';
import 'package:dlu_lms_mobile/features/interventions/domain/intervention_models.dart';
import 'package:dlu_lms_mobile/features/interventions/domain/intervention_repository.dart';

const snapshot = LearningSnapshot(
  progressPercent: 25,
  pendingTasks: 3,
  overdueTasks: 2,
);
const attention = AttentionStudent(
  courseId: 'course-test',
  courseName: 'Học phần thử nghiệm',
  studentId: 'student-test',
  studentName: 'Sinh viên mẫu',
  priority: AttentionPriority.high,
  priorityScore: 75,
  reasons: ['2 bài tập quá hạn chưa hoàn tất'],
  snapshot: snapshot,
);
final now = DateTime(2030, 6, 1, 10);
TeacherIntervention record({
  InterventionStatus status = InterventionStatus.open,
}) => TeacherIntervention(
  id: 'support-test',
  courseId: attention.courseId,
  studentId: attention.studentId,
  studentName: attention.studentName,
  courseName: attention.courseName,
  title: 'Liên hệ hỗ trợ học tập',
  note: 'Đã trao đổi cách lập kế hoạch.',
  actionType: InterventionAction.contacted,
  status: status,
  followUpAt: now.subtract(const Duration(days: 1)),
  createdAt: now.subtract(const Duration(days: 4)),
  updatedAt: now,
  reasons: attention.reasons,
  baseline: snapshot,
  current: const LearningSnapshot(
    progressPercent: 50,
    pendingTasks: 2,
    overdueTasks: 1,
  ),
  followups: [
    InterventionFollowup(
      id: 'followup-test',
      note: 'Đã kiểm tra kế hoạch cùng sinh viên.',
      createdAt: now,
      outcomeStatus: InterventionStatus.followingUp,
      snapshot: snapshot,
    ),
  ],
);

class MockSupportAuth implements AuthRepository {
  MockSupportAuth({this.role = DluRole.teacher});
  DluRole role;
  String userId = 'teacher-test';
  @override
  Stream<void> get sessionInvalidations => const Stream.empty();
  @override
  Future<AuthSession?> restoreSession() async =>
      AuthSession(userId: userId, displayName: 'Người dùng mẫu', role: role);
  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async => (await restoreSession())!;
  @override
  Future<void> signOut() async {}
}

class RecordingInterventions implements InterventionRepository {
  List<AttentionStudent> attentionRows = [attention];
  List<TeacherIntervention> records = [record()];
  Object? readError;
  Completer<List<AttentionStudent>>? attentionPending;
  int attentionCalls = 0, recordCalls = 0, creates = 0, followups = 0;
  InterventionDraft? lastDraft;
  FollowupDraft? lastFollowup;
  String? lastId;
  Completer<TeacherIntervention>? pending;
  @override
  Future<List<AttentionStudent>> getAttention() async {
    attentionCalls++;
    if (readError case final error?) throw error;
    return attentionPending?.future ?? attentionRows;
  }

  @override
  Future<List<TeacherIntervention>> getInterventions() async {
    recordCalls++;
    if (readError case final error?) throw error;
    return records;
  }

  @override
  Future<TeacherIntervention> createIntervention(
    InterventionDraft draft,
  ) async {
    creates++;
    lastDraft = draft;
    return pending?.future ?? Future.value(record());
  }

  @override
  Future<TeacherIntervention> addFollowup(
    String id,
    FollowupDraft draft,
  ) async {
    followups++;
    lastId = id;
    lastFollowup = draft;
    return pending?.future ?? Future.value(record());
  }
}

Map<String, dynamic> recordJson() => {
  'id': 'support-test',
  'courseId': 'course-test',
  'studentId': 'student-test',
  'studentName': 'Sinh viên mẫu',
  'courseName': 'Học phần thử nghiệm',
  'title': 'Hỗ trợ',
  'note': 'Ghi nhận thử nghiệm',
  'actionType': 'contacted',
  'status': 'following_up',
  'followUpAt': '2030-06-03T09:00:00Z',
  'createdAt': '2030-05-28T09:00:00Z',
  'updatedAt': '2030-06-01T09:00:00Z',
  'reasons': ['Cần theo dõi tiến độ'],
  'baseline': snapshotJson(),
  'current': snapshotJson(),
  'followups': <Object>[],
};
Map<String, dynamic> snapshotJson() => {
  'progressPercent': 25,
  'pendingTasks': 3,
  'overdueTasks': 2,
};

Map<String, dynamic> attentionJson() => {
  'courseId': 'course-test',
  'courseName': 'Học phần thử nghiệm',
  'studentId': 'student-test',
  'studentName': 'Sinh viên mẫu',
  'priority': 'high',
  'priorityScore': 75,
  'reasons': ['2 bài tập quá hạn chưa hoàn tất'],
  ...snapshotJson(),
};
