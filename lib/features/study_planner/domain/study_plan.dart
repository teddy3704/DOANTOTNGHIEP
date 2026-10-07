enum StudyPriority { high, medium, low }

enum StudyPlanStatus { planned, handled }

enum StudyPlanPeriod { today, tomorrow, week }

extension StudyPriorityLabel on StudyPriority {
  String get label => switch (this) {
    StudyPriority.high => 'Ưu tiên cao',
    StudyPriority.medium => 'Nên dành thời gian',
    StudyPriority.low => 'Chủ động chuẩn bị',
  };
}

class StudyRecommendation {
  const StudyRecommendation({
    required this.assignmentId,
    required this.assignmentCode,
    required this.assignmentName,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.dueAt,
    required this.submissionStatus,
    required this.priority,
    required this.reasons,
    required this.planned,
    required this.recommendedDurationMinutes,
  });

  final String assignmentId;
  final String assignmentCode;
  final String assignmentName;
  final String courseId;
  final String courseCode;
  final String courseName;
  final DateTime? dueAt;
  final String submissionStatus;
  final StudyPriority priority;
  final List<String> reasons;
  final bool planned;
  final int recommendedDurationMinutes;
}

/// An app-owned study session. Handled never means submitted/graded on LMS.
class StudyPlanItem {
  const StudyPlanItem({
    required this.id,
    required this.assignmentId,
    required this.assignmentCode,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.dueAt,
    required this.priority,
    required this.reasons,
    required this.scheduledStartAt,
    required this.estimatedMinutes,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String assignmentId;
  final String assignmentCode;
  final String courseId;
  final String courseName;
  final String title;
  final DateTime? dueAt;
  final StudyPriority priority;
  final List<String> reasons;
  final DateTime scheduledStartAt;
  final int estimatedMinutes;
  final String notes;
  final StudyPlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get scheduledEndAt =>
      scheduledStartAt.add(Duration(minutes: estimatedMinutes));
}

DateTime studyDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<StudyPlanItem> filterStudyPlan(
  List<StudyPlanItem> items,
  StudyPlanPeriod period,
  DateTime now,
) {
  final today = studyDay(now);
  final start = switch (period) {
    StudyPlanPeriod.today => today,
    StudyPlanPeriod.tomorrow => today.add(const Duration(days: 1)),
    StudyPlanPeriod.week => today.subtract(Duration(days: today.weekday - 1)),
  };
  final end = start.add(Duration(days: period == StudyPlanPeriod.week ? 7 : 1));
  return items.where((item) {
    final time = item.scheduledStartAt.toLocal();
    return !time.isBefore(start) && time.isBefore(end);
  }).toList()..sort((a, b) => a.scheduledStartAt.compareTo(b.scheduledStartAt));
}

String studyDateTime(DateTime date) {
  final value = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}, ${two(value.day)}/${two(value.month)}/${value.year}';
}

String studyDeadline(DateTime? due, DateTime now) {
  if (due == null) return 'Chưa có hạn nộp';
  final remaining = due.difference(now);
  if (remaining.isNegative) return 'Đã qua hạn · kiểm tra trên LMS';
  if (remaining.inHours < 1) return 'Còn dưới 1 giờ';
  if (remaining.inHours < 24) return 'Còn ${remaining.inHours} giờ';
  return 'Còn ${remaining.inDays} ngày';
}
