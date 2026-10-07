enum AttentionPriority { high, medium, low }

enum InterventionStatus { open, followingUp, resolved }

enum InterventionAction { contacted, monitoring }

/// Source-observed measures; no inferred activity or outcome is fabricated.
class LearningSnapshot {
  const LearningSnapshot({
    required this.progressPercent,
    required this.pendingTasks,
    required this.overdueTasks,
  });
  final double progressPercent;
  final int pendingTasks, overdueTasks;

  factory LearningSnapshot.fromJson(Map<String, dynamic> json) =>
      LearningSnapshot(
        progressPercent: _progress(json['progressPercent']),
        pendingTasks: _count(json['pendingTasks']),
        overdueTasks: _count(json['overdueTasks']),
      );
}

class AttentionStudent {
  const AttentionStudent({
    required this.courseId,
    required this.courseName,
    required this.studentId,
    required this.studentName,
    required this.priority,
    required this.priorityScore,
    required this.reasons,
    required this.snapshot,
  });
  final String courseId, courseName, studentId, studentName;
  final AttentionPriority priority;
  final int priorityScore;
  final List<String> reasons;
  final LearningSnapshot snapshot;

  /// Keep low but non-zero signals visible; a healthy zero-score learner is
  /// still available in scoped details/history, not counted as needing help.
  bool get needsAttention => priorityScore > 0;

  factory AttentionStudent.fromJson(Map<String, dynamic> json) =>
      AttentionStudent(
        courseId: _id(json['courseId']),
        courseName: _text(json['courseName']),
        studentId: _id(json['studentId']),
        studentName: _text(json['studentName']),
        priority: AttentionPriority.values.byName(json['priority'] as String),
        priorityScore: _score(json['priorityScore']),
        reasons: _reasons(json['reasons']),
        snapshot: LearningSnapshot.fromJson(json),
      );
}

class InterventionFollowup {
  const InterventionFollowup({
    required this.id,
    required this.note,
    required this.createdAt,
    required this.outcomeStatus,
    required this.snapshot,
  });
  final String id, note;
  final DateTime createdAt;
  final InterventionStatus outcomeStatus;
  final LearningSnapshot snapshot;

  factory InterventionFollowup.fromJson(Map<String, dynamic> json) =>
      InterventionFollowup(
        id: _id(json['id']),
        note: _text(json['note']),
        createdAt: _date(json['createdAt']),
        outcomeStatus: interventionStatusFromJson(json['outcomeStatus']),
        snapshot: LearningSnapshot.fromJson(json),
      );
}

class TeacherIntervention {
  const TeacherIntervention({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.courseName,
    required this.title,
    required this.note,
    required this.actionType,
    required this.status,
    required this.followUpAt,
    required this.createdAt,
    required this.updatedAt,
    required this.reasons,
    required this.baseline,
    required this.current,
    required this.followups,
  });
  final String id, courseId, studentId, studentName, courseName, title, note;
  final InterventionAction actionType;
  final InterventionStatus status;
  final DateTime? followUpAt;
  final DateTime createdAt, updatedAt;
  final List<String> reasons;
  final LearningSnapshot baseline, current;
  final List<InterventionFollowup> followups;

  bool isDue(DateTime now) {
    if (status == InterventionStatus.resolved || followUpAt == null) {
      return false;
    }
    final local = now.toLocal();
    final tomorrow = DateTime(local.year, local.month, local.day + 1);
    return followUpAt!.isBefore(tomorrow);
  }

  factory TeacherIntervention.fromJson(
    Map<String, dynamic> json,
  ) => TeacherIntervention(
    id: _id(json['id']),
    courseId: _id(json['courseId']),
    studentId: _id(json['studentId']),
    studentName: _text(json['studentName']),
    courseName: _text(json['courseName']),
    title: _text(json['title']),
    note: _text(json['note']),
    actionType: InterventionAction.values.byName(json['actionType'] as String),
    status: interventionStatusFromJson(json['status']),
    followUpAt: json['followUpAt'] == null ? null : _date(json['followUpAt']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    reasons: _reasons(json['reasons']),
    baseline: LearningSnapshot.fromJson(
      json['baseline'] as Map<String, dynamic>,
    ),
    current: LearningSnapshot.fromJson(json['current'] as Map<String, dynamic>),
    followups: [
      for (final value in json['followups'] as List)
        InterventionFollowup.fromJson(value as Map<String, dynamic>),
    ],
  );
}

InterventionStatus interventionStatusFromJson(Object? value) => switch (value) {
  'open' => InterventionStatus.open,
  'following_up' => InterventionStatus.followingUp,
  'resolved' => InterventionStatus.resolved,
  _ => throw const FormatException('Invalid intervention status'),
};

String interventionStatusToJson(InterventionStatus value) => switch (value) {
  InterventionStatus.open => 'open',
  InterventionStatus.followingUp => 'following_up',
  InterventionStatus.resolved => 'resolved',
};

class InterventionDraft {
  const InterventionDraft({
    required this.courseId,
    required this.studentId,
    required this.title,
    required this.note,
    required this.actionType,
    this.followUpAt,
  });
  final String courseId, studentId, title, note;
  final InterventionAction actionType;
  final DateTime? followUpAt;
  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'studentId': studentId,
    'title': title.trim(),
    'note': note.trim(),
    'actionType': actionType.name,
    'followUpAt': followUpAt?.toUtc().toIso8601String(),
  };
}

class FollowupDraft {
  const FollowupDraft({
    required this.note,
    required this.outcomeStatus,
    this.nextFollowUpAt,
  });
  final String note;
  final InterventionStatus outcomeStatus;
  final DateTime? nextFollowUpAt;
  Map<String, dynamic> toJson() => {
    'note': note.trim(),
    'outcomeStatus': interventionStatusToJson(outcomeStatus),
    'nextFollowUpAt': nextFollowUpAt?.toUtc().toIso8601String(),
  };
}

String _id(Object? value) {
  if (value is String &&
      value.trim().isNotEmpty &&
      value == value.trim() &&
      value != 'null') {
    return value;
  }
  if (value is int && value > 0) return value.toString();
  throw const FormatException('Invalid support identity');
}

String _text(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  throw const FormatException('Invalid support text');
}

List<String> _reasons(Object? value) {
  if (value is List && value.isNotEmpty) {
    return List.unmodifiable(value.map(_text));
  }
  throw const FormatException('Invalid support reasons');
}

int _score(Object? value) {
  final score = _count(value);
  if (score <= 100) return score;
  throw const FormatException('Invalid attention score');
}

double _progress(Object? value) {
  if (value is num && value.isFinite && value >= 0 && value <= 100) {
    return value.toDouble();
  }
  throw const FormatException('Invalid learning progress');
}

int _count(Object? value) {
  if (value is num && value.isFinite && value >= 0 && value == value.round()) {
    return value.toInt();
  }
  throw const FormatException('Invalid learning count');
}

DateTime _date(Object? value) {
  if (value is String) {
    final prefix = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](\d{2}):(\d{2}))$',
    ).firstMatch(value);
    final date = DateTime.tryParse(value);
    if (prefix != null && date != null) {
      final year = int.parse(prefix[1]!);
      final month = int.parse(prefix[2]!);
      final day = int.parse(prefix[3]!);
      final normalized = DateTime.utc(year, month, day);
      if (normalized.year == year &&
          normalized.month == month &&
          normalized.day == day &&
          int.parse(prefix[4]!) < 24 &&
          int.parse(prefix[5]!) < 60 &&
          int.parse(prefix[6]!) < 60 &&
          (prefix[7] == null || int.parse(prefix[7]!) < 24) &&
          (prefix[8] == null || int.parse(prefix[8]!) < 60)) {
        return date;
      }
    }
  }
  throw const FormatException('Invalid support date');
}
