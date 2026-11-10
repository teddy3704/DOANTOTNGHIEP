class StudentDashboard {
  final int? studentId;
  final String? fullName;
  final String? email;
  final String? studentCode, cohortCode, classCode, majorName;
  String? get identityLabel =>
      studentCode == null ? email : 'MSSV: $studentCode';
  String? get academicLabel {
    final parts = [cohortCode, classCode].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }

  final int? totalCourses;
  final double? averageProgress;
  final int? pendingTasks;
  final int? overdueTasks;
  final double? averageAttendancePercentage;

  StudentDashboard({
    this.studentId,
    this.fullName,
    this.email,
    this.studentCode,
    this.cohortCode,
    this.classCode,
    this.majorName,
    this.totalCourses,
    this.averageProgress,
    this.pendingTasks,
    this.overdueTasks,
    this.averageAttendancePercentage,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    String? text(dynamic value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    final combinedName = [
      text(json['firstname']),
      text(json['lastname']),
    ].whereType<String>().join(' ');
    return StudentDashboard(
      studentId:
          (json['userid'] as num?)?.toInt() ??
          (json['student_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt(),
      fullName:
          text(json['fullname']) ??
          text(json['full_name']) ??
          text(json['student_name']) ??
          text(json['name']) ??
          text(combinedName),
      email: text(json['email']),
      studentCode: text(json['student_code']),
      cohortCode: text(json['cohort_code']),
      classCode: text(json['class_code']),
      majorName: text(json['major_name']),
      totalCourses:
          (json['total_courses'] as num?)?.toInt() ??
          (json['course_count'] as num?)?.toInt(),
      averageProgress:
          (json['average_progress'] as num?)?.toDouble() ??
          (json['average_progress_percentage'] as num?)?.toDouble(),
      pendingTasks: (json['pending_tasks'] as num?)?.toInt(),
      overdueTasks: (json['overdue_tasks'] as num?)?.toInt(),
      averageAttendancePercentage:
          (json['average_attendance_percentage'] as num?)?.toDouble() ??
          (json['average_attendance'] as num?)?.toDouble(),
    );
  }
}
