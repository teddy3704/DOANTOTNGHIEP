import 'package:flutter/foundation.dart';

class TeacherCourse {
  final int courseId;
  final String courseName;
  final String? courseShortname;
  final int? studentCount;
  final double? averageProgress;
  final int? highRiskStudents;
  final int? studentsNeedAttention;
  final int? upcomingDeadlines7Days;
  final int? needsGradingCount;

  /// Course start (epoch seconds); shown as "Bắt đầu MM/YYYY" so every screen says which term it is.
  final int? startEpoch;

  /// Real data only: course of the current term (null on demo, where every course counts).
  final bool? currentTerm;

  String? get startLabel {
    final e = startEpoch;
    if (e == null || e <= 0) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(e * 1000);
    return 'Bắt đầu ${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  TeacherCourse({
    required this.courseId,
    required this.courseName,
    this.courseShortname,
    this.studentCount,
    this.averageProgress,
    this.highRiskStudents,
    this.studentsNeedAttention,
    this.upcomingDeadlines7Days,
    this.needsGradingCount,
    this.startEpoch,
    this.currentTerm,
  });

  factory TeacherCourse.fromJson(Map<String, dynamic> json) {
    final rawCourseId = json['courseid'] ?? json['course_id'] ?? json['id'];
    if (rawCourseId == null || rawCourseId is! num) {
      throw FormatException(
        'Thiếu hoặc sai kiểu dữ liệu courseid trong TeacherCourse JSON: $json',
      );
    }
    final parsedCourseId = rawCourseId.toInt();

    final course = TeacherCourse(
      courseId: parsedCourseId,
      courseName:
          json['course_name'] as String? ??
          json['name'] as String? ??
          'Khóa học',
      courseShortname:
          json['course_shortname'] as String? ?? json['shortname'] as String?,
      studentCount: (json['student_count'] as num?)?.toInt(),
      averageProgress:
          (json['average_progress'] as num?)?.toDouble() ??
          (json['average_progress_percentage'] as num?)?.toDouble(),
      highRiskStudents: (json['high_risk_students'] as num?)?.toInt(),
      studentsNeedAttention: (json['students_need_attention'] as num?)?.toInt(),
      upcomingDeadlines7Days: (json['upcoming_deadlines_7_days'] as num?)
          ?.toInt(),
      needsGradingCount: (json['needs_grading_count'] as num?)?.toInt(),
      startEpoch: (json['course_startdate'] as num?)?.toInt(),
      currentTerm: json['current_term'] as bool?,
    );

    debugPrint(
      'TEACHER COURSE PARSED: courseId=${course.courseId}, name=${course.courseName}',
    );
    return course;
  }
}
