class StudentAnalytics {
  final int? courseId;
  final String? courseName;
  final double? progressPercentage;
  final double? averageGradePercentage;
  final double? attendancePercentage;
  final int? completedTasks;
  final int? pendingTasks;
  final int? overdueTasks;
  final int? eventsLast7Days;
  final int? activeDaysLast7Days;
  final int? daysSinceLastActivity;
  final double? riskScore;
  final String? riskLevel;

  StudentAnalytics({
    this.courseId,
    this.courseName,
    this.progressPercentage,
    this.averageGradePercentage,
    this.attendancePercentage,
    this.completedTasks,
    this.pendingTasks,
    this.overdueTasks,
    this.eventsLast7Days,
    this.activeDaysLast7Days,
    this.daysSinceLastActivity,
    this.riskScore,
    this.riskLevel,
  });

  factory StudentAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAnalytics(
      courseId:
          (json['courseid'] as num?)?.toInt() ??
          (json['course_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt(),
      courseName: json['course_name'] as String?,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ??
          (json['progress'] as num?)?.toDouble(),
      averageGradePercentage:
          (json['average_grade_percentage'] as num?)?.toDouble() ??
          (json['average_grade'] as num?)?.toDouble(),
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ??
          (json['attendance'] as num?)?.toDouble(),
      completedTasks: (json['completed_tasks'] as num?)?.toInt(),
      pendingTasks: (json['pending_tasks'] as num?)?.toInt(),
      overdueTasks: (json['overdue_tasks'] as num?)?.toInt(),
      eventsLast7Days: (json['events_last_7_days'] as num?)?.toInt(),
      activeDaysLast7Days: (json['active_days_last_7_days'] as num?)?.toInt(),
      daysSinceLastActivity: (json['days_since_last_activity'] as num?)
          ?.toInt(),
      riskScore: (json['risk_score'] as num?)?.toDouble(),
      riskLevel: json['risk_level'] as String?,
    );
  }
}
