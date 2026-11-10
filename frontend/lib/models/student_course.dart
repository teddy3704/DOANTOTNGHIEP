import 'package:flutter/foundation.dart';

class StudentCourse {
  final int courseId;
  final String courseName;
  final String? courseShortname;
  final double? progressPercentage;
  final int? completedTasks;
  final int? totalTasks;
  final double? attendancePercentage;
  final int? pendingTasks, overdueTasks;
  // The view counts pending and overdue separately.
  int? get unfinishedTasks => pendingTasks == null || overdueTasks == null
      ? null
      : pendingTasks! + overdueTasks!;

  StudentCourse({
    required this.courseId,
    required this.courseName,
    this.courseShortname,
    this.progressPercentage,
    this.completedTasks,
    this.totalTasks,
    this.attendancePercentage,
    this.pendingTasks,
    this.overdueTasks,
  });

  factory StudentCourse.fromJson(Map<String, dynamic> json) {
    final rawCourseId = json['courseid'] ?? json['course_id'] ?? json['id'];
    if (rawCourseId == null || rawCourseId is! num) {
      throw FormatException(
        'Thiếu hoặc sai kiểu dữ liệu courseid trong StudentCourse JSON: $json',
      );
    }
    final parsedCourseId = rawCourseId.toInt();

    final course = StudentCourse(
      courseId: parsedCourseId,
      courseName:
          json['course_name'] as String? ??
          json['name'] as String? ??
          'Khóa học',
      courseShortname:
          json['course_shortname'] as String? ?? json['shortname'] as String?,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ??
          (json['progress'] as num?)?.toDouble(),
      // These properties back the activity-completion label, not task counts.
      completedTasks: (json['completed_activities'] as num?)?.toInt(),
      totalTasks: (json['total_tracked_activities'] as num?)?.toInt(),
      pendingTasks: (json['pending_tasks'] as num?)?.toInt(),
      overdueTasks: (json['overdue_tasks'] as num?)?.toInt(),
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ??
          (json['attendance'] as num?)?.toDouble(),
    );

    debugPrint(
      'STUDENT COURSE PARSED: courseId=${course.courseId}, name=${course.courseName}',
    );
    return course;
  }
}
