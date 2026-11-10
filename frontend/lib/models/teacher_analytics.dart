class TeacherAnalytics {
  final int? courseId;
  final String? courseName;
  final int? studentCount;
  final double? averageProgress;
  final double? averageGrade;
  final double? averageAttendancePercentage;
  final double? averageEventsLast7Days;
  final double? averageActiveDaysLast7Days;
  final int? pendingTasks;
  final int? overdueTasks;
  final int? highRiskStudents;
  final int? mediumRiskStudents;
  final int? lowRiskStudents;

  TeacherAnalytics({
    this.courseId,
    this.courseName,
    this.studentCount,
    this.averageProgress,
    this.averageGrade,
    this.averageAttendancePercentage,
    this.averageEventsLast7Days,
    this.averageActiveDaysLast7Days,
    this.pendingTasks,
    this.overdueTasks,
    this.highRiskStudents,
    this.mediumRiskStudents,
    this.lowRiskStudents,
  });

  factory TeacherAnalytics.fromJson(Map<String, dynamic> json) {
    return TeacherAnalytics(
      courseId:
          (json['courseid'] as num?)?.toInt() ??
          (json['course_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt(),
      courseName: json['course_name'] as String?,
      studentCount: (json['student_count'] as num?)?.toInt(),
      averageProgress:
          (json['average_progress'] as num?)?.toDouble() ??
          (json['average_progress_percentage'] as num?)?.toDouble(),
      averageGrade:
          (json['average_grade'] as num?)?.toDouble() ??
          (json['average_grade_percentage'] as num?)?.toDouble(),
      averageAttendancePercentage:
          (json['average_attendance_percentage'] as num?)?.toDouble() ??
          (json['average_attendance'] as num?)?.toDouble(),
      averageEventsLast7Days: (json['average_events_last_7_days'] as num?)
          ?.toDouble(),
      averageActiveDaysLast7Days:
          (json['average_active_days_last_7_days'] as num?)?.toDouble(),
      pendingTasks:
          (json['total_pending_tasks'] as num?)?.toInt() ??
          (json['pending_tasks'] as num?)?.toInt(),
      overdueTasks:
          (json['total_overdue_tasks'] as num?)?.toInt() ??
          (json['overdue_tasks'] as num?)?.toInt(),
      highRiskStudents: (json['high_risk_students'] as num?)?.toInt(),
      mediumRiskStudents: (json['medium_risk_students'] as num?)?.toInt(),
      lowRiskStudents: (json['low_risk_students'] as num?)?.toInt(),
    );
  }
}
