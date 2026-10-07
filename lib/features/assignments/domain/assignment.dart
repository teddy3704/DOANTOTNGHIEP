enum AssignmentTiming { future, soon, overdue, noDeadline }

enum SubmissionState {
  notSubmitted,
  draft,
  submitted,
  late,
  graded,
  returnedForResubmission,
  missing,
}

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
  final DateTime? dueAt;
  final DateTime allowsSubmissionsFrom;
  final DateTime? cutoffAt;
  final AssignmentTiming timing;
  final SubmissionState submissionState;
  final DateTime? submittedAt;
  final double? grade;
  final double? gradeMax;
  final String? feedback;

  bool get isGraded => submissionState == SubmissionState.graded;
}

/// Known deadlines sort first. Missing dates are not treated as epoch zero.
int compareAssignmentDeadlines(
  AssignmentDetail first,
  AssignmentDetail second,
) {
  final firstDue = first.dueAt;
  final secondDue = second.dueAt;
  if (firstDue == null) return secondDue == null ? 0 : 1;
  if (secondDue == null) return -1;
  return firstDue.compareTo(secondDue);
}

extension SubmissionStateLabel on SubmissionState {
  String get label => switch (this) {
    SubmissionState.notSubmitted => 'Chưa nộp',
    SubmissionState.draft => 'Bản nháp',
    SubmissionState.submitted => 'Đã nộp · Chờ chấm',
    SubmissionState.late => 'Nộp trễ · Chờ chấm',
    SubmissionState.graded => 'Đã chấm',
    SubmissionState.returnedForResubmission => 'Cần nộp lại',
    SubmissionState.missing => 'Chưa nộp',
  };
}

extension AssignmentTimingLabel on AssignmentTiming {
  String get label => switch (this) {
    AssignmentTiming.future => 'Còn thời gian',
    AssignmentTiming.soon => 'Sắp đến hạn',
    AssignmentTiming.overdue => 'Đã quá hạn',
    AssignmentTiming.noDeadline => 'Chưa đặt hạn',
  };
}
