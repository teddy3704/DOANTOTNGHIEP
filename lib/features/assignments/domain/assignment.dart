enum AssignmentTiming { future, soon, overdue }

enum SubmissionState { notSubmitted, draft, submitted, graded }

class AssignmentDetail {
  const AssignmentDetail({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.dueAt,
    required this.allowsSubmissionsFrom,
    required this.cutoffAt,
    required this.timing,
    required this.submissionState,
    this.submittedAt,
    this.grade,
    this.gradeMax,
    this.feedback,
  });

  final String id;
  final String courseId;
  final String name;
  final String description;
  final DateTime dueAt;
  final DateTime allowsSubmissionsFrom;
  final DateTime cutoffAt;
  final AssignmentTiming timing;
  final SubmissionState submissionState;
  final DateTime? submittedAt;
  final double? grade;
  final double? gradeMax;
  final String? feedback;

  bool get isGraded => submissionState == SubmissionState.graded;
}

extension SubmissionStateLabel on SubmissionState {
  String get label => switch (this) {
    SubmissionState.notSubmitted => 'Chưa nộp',
    SubmissionState.draft => 'Bản nháp',
    SubmissionState.submitted => 'Đã nộp · Chờ chấm',
    SubmissionState.graded => 'Đã chấm',
  };
}

extension AssignmentTimingLabel on AssignmentTiming {
  String get label => switch (this) {
    AssignmentTiming.future => 'Còn thời gian',
    AssignmentTiming.soon => 'Sắp đến hạn',
    AssignmentTiming.overdue => 'Đã quá hạn',
  };
}
