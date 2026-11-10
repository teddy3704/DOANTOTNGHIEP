import '../core/relative_days.dart';
import 'student_course_detail.dart';

String? _text(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

class MonitoredStudent {
  final int id;
  final String name;
  final String? studentCode, cohortCode, classCode, majorName;
  String? get code => studentCode;
  String? get academicLabel {
    final parts = [cohortCode, classCode].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }

  bool get hasAcademicProfile =>
      [studentCode, cohortCode, classCode, majorName].any((v) => v != null);
  final String? email;
  final double? progress, attendance, averageGrade;
  final int? pending, overdue, inactiveDays;
  final String? risk;
  final bool? needsAttention;
  final List<StudentTask> tasks;

  /// What the overview numbers are made of; empty when an older backend omits them.
  final int? completedActivities,
      totalActivities,
      markedSessions,
      absentSessions,
      gradedItems;
  final List<ProgressItem> progressItems;
  final List<AttendanceSession> attendanceSessions;
  final List<GradeItem> gradeItems;

  MonitoredStudent.fromJson(Map<String, dynamic> j)
    : completedActivities = (j['completed_activities'] as num?)?.toInt(),
      totalActivities = (j['total_tracked_activities'] as num?)?.toInt(),
      markedSessions = (j['marked_sessions'] as num?)?.toInt(),
      absentSessions = (j['absent_sessions'] as num?)?.toInt(),
      gradedItems = (j['graded_items'] as num?)?.toInt(),
      progressItems = _rows(
        j['progress_items'],
      ).map(ProgressItem.fromJson).toList(),
      attendanceSessions = _rows(
        j['attendance_sessions'],
      ).map(AttendanceSession.fromJson).toList(),
      gradeItems = _rows(j['grade_items']).map(GradeItem.fromJson).toList(),
      id = (j['userid'] as num).toInt(),
      name = j['fullname'] as String? ?? 'Sinh viên #${j['userid']}',
      studentCode = _text(j['student_code']) ?? _text(j['idnumber']),
      cohortCode = _text(j['cohort_code']),
      classCode = _text(j['class_code']),
      majorName = _text(j['major_name']),
      email = _text(j['email']),
      progress = (j['progress'] as num?)?.toDouble(),
      attendance = (j['attendance'] as num?)?.toDouble(),
      averageGrade = (j['average_grade'] as num?)?.toDouble(),
      pending = (j['pending_tasks'] as num?)?.toInt(),
      overdue = (j['overdue_tasks'] as num?)?.toInt(),
      inactiveDays = (j['days_since_last_activity'] as num?)?.toInt(),
      risk = j['risk_level'] as String?,
      needsAttention = j['needs_attention'] as bool?,
      tasks = (j['tasks'] as List? ?? [])
          .map((v) => StudentTask.fromJson(v as Map<String, dynamic>))
          .toList();
  // Matches the confirmed teacher_course_overview definition: HIGH or MEDIUM.
  bool get needsSupport =>
      needsAttention ?? (risk == 'HIGH' || risk == 'MEDIUM');

  /// Observable risk V1 signals supplied by the monitoring API.
  /// Never recomputes backend risk_level; absent fields produce no reason.
  /// Engagement is not currently returned per student by this endpoint.
  List<String> get riskReasons => [
    if (overdue != null && overdue! > 0) '$overdue bài đã quá hạn',
    if (inactiveDays != null && inactiveDays! >= 7)
      '$inactiveDays ngày chưa hoạt động',
    if (progress != null && progress! < 30)
      'Tiến độ học tập dưới 30%'
    else if (progress != null && progress! < 60)
      'Tiến độ học tập còn thấp',
  ];

  /// Explains membership without inventing a cause for the API's risk level.
  String? get supportBasisLabel => !needsSupport
      ? null
      : risk?.toUpperCase() == 'HIGH'
      ? 'Cần theo dõi theo mức nguy cơ cao trong dữ liệu khóa học.'
      : risk?.toUpperCase() == 'MEDIUM'
      ? 'Cần theo dõi theo mức nguy cơ trung bình trong dữ liệu khóa học.'
      : 'Được đánh dấu cần theo dõi trong dữ liệu khóa học.';

  String get riskExplanationFallback =>
      risk?.toUpperCase() == 'LOW' &&
          progress != null &&
          overdue != null &&
          inactiveDays != null
      ? 'Chưa phát hiện dấu hiệu cần ưu tiên theo dõi.'
      : 'Chưa đủ dữ liệu để giải thích mức nguy cơ hiện tại.';

  String get activityLabel => inactiveDays == null
      ? 'Chưa có dữ liệu hoạt động'
      : 'Hoạt động gần nhất: ${daysAgoLabel(inactiveDays!)}';
  String get riskLabel => switch (risk?.toUpperCase()) {
    'HIGH' => 'Nguy cơ cao',
    'MEDIUM' => 'Nguy cơ trung bình',
    'LOW' => 'Nguy cơ thấp',
    _ => 'Chưa có mức nguy cơ',
  };
  String? get identityLabel => code != null ? 'MSSV: $code' : email;
}

class MonitoredActivity {
  final int id;
  final int? courseModuleId;
  final String title, type;
  final String? moodlePath;
  final DateTime? deadline;
  final int? total,
      done,
      notDone,
      unknown,
      needsGrading,
      notAttempted,
      inProgress;
  final double? average;
  MonitoredActivity.fromJson(Map<String, dynamic> j)
    : id = (j['source_id'] as num).toInt(),
      courseModuleId = (j['coursemoduleid'] as num?)?.toInt(),
      title = j['title'] as String? ?? 'Hoạt động',
      type = j['task_type'] as String,
      moodlePath = j['moodle_path'] as String?,
      deadline = unixSeconds((j['due_time'] as num?)?.toInt()),
      total = (j['student_count'] as num?)?.toInt(),
      done = (j['done_count'] as num?)?.toInt(),
      notAttempted = (j['not_attempted_count'] as num?)?.toInt(),
      inProgress = (j['inprogress_count'] as num?)?.toInt(),
      notDone = (j['not_done_count'] as num?)?.toInt(),
      unknown = (j['unknown_count'] as num?)?.toInt(),
      needsGrading = (j['needs_grading_count'] as num?)?.toInt(),
      average = (j['average_grade_percentage'] as num?)?.toDouble();
}

class ActivityStudent {
  final MonitoredStudent student;
  final bool? done;
  final String? sourceStatus, quizState;
  final double? grade, gradePercentage;
  ActivityStudent.fromJson(Map<String, dynamic> j)
    : student = MonitoredStudent.fromJson(j),
      done = j['done'] as bool?,
      sourceStatus = j['source_status'] as String?,
      quizState = j['quiz_state'] as String?,
      grade = (j['finalgrade'] as num?)?.toDouble(),
      gradePercentage = (j['grade_percentage'] as num?)?.toDouble();
  String get status => switch (sourceStatus ?? quizState) {
    'submitted' => 'Đã nộp',
    'draft' => 'Bản nháp',
    'new' => 'Chưa nộp',
    'finished' => 'Đã làm',
    'inprogress' => 'Đang làm',
    'overdue' => 'Quá hạn',
    'abandoned' => 'Chưa hoàn tất',
    _ => done == false ? 'Chưa hoàn thành' : 'Chưa có trạng thái',
  };
  String groupLabel(String activityType) {
    if (activityType == 'assignment') {
      if (sourceStatus == 'submitted' || done == true) return 'Đã nộp';
      return done == false ? 'Chưa nộp' : 'Chưa có trạng thái';
    }
    final state = quizState ?? sourceStatus;
    if (state == 'finished' || done == true) return 'Đã hoàn tất';
    if (state == 'inprogress') return 'Đang làm';
    if (state == null && done == false) return 'Chưa bắt đầu';
    // An abandoned/overdue attempt is not the same as never starting a quiz.
    return state == 'overdue' || state == 'abandoned'
        ? 'Chưa hoàn tất'
        : 'Chưa có trạng thái';
  }
}

List<Map<String, dynamic>> _rows(dynamic v) => [
  for (final e in (v as List? ?? const []))
    if (e is Map) e.cast<String, dynamic>(),
];

DateTime? _epoch(dynamic v) => v is num && v > 0
    ? DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000)
    : null;

/// One activity with completion tracking: it counts toward the progress %.
class ProgressItem {
  final String name, type;
  final String? section;
  final bool completed;
  final DateTime? completedAt, due;
  ProgressItem.fromJson(Map<String, dynamic> j)
    : name = _text(j['activity_name']) ?? 'Hoạt động',
      type = _text(j['activity_type']) ?? '',
      section = _text(j['section_name']),
      completed = j['completed'] == true,
      completedAt = _epoch(j['completed_at']),
      due = _epoch(j['due_time']);
}

/// One attendance session and this student's status in it, if marked.
class AttendanceSession {
  final DateTime? date;
  final int durationMinutes;
  final String? description, acronym, statusDescription, remarks;
  final double? statusGrade, maxGrade;
  AttendanceSession.fromJson(Map<String, dynamic> j)
    : date = _epoch(j['sessdate']),
      durationMinutes = ((j['duration'] as num?)?.toInt() ?? 0) ~/ 60,
      description = _text(j['description']),
      acronym = _text(j['acronym']),
      statusDescription = _text(j['status_description']),
      remarks = _text(j['remarks']),
      statusGrade = (j['status_grade'] as num?)?.toDouble(),
      maxGrade = (j['max_grade'] as num?)?.toDouble();
  bool get marked => acronym != null || statusDescription != null;
}

/// One gradebook row; [percentage] is null until it is graded.
class GradeItem {
  final String name, type;
  final double? finalGrade, gradeMax, gradePass, percentage;
  final bool? passed;
  GradeItem.fromJson(Map<String, dynamic> j)
    : name = _text(j['activity_name']) ?? 'Hoạt động',
      type = _text(j['activity_type']) ?? '',
      finalGrade = (j['finalgrade'] as num?)?.toDouble(),
      gradeMax = (j['grademax'] as num?)?.toDouble(),
      gradePass = (j['gradepass'] as num?)?.toDouble(),
      percentage = (j['grade_percentage'] as num?)?.toDouble(),
      passed = j['passed'] as bool?;
  bool get graded => finalGrade != null;
}
