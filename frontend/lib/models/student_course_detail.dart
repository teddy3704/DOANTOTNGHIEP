import '../core/display_text.dart';
export '../core/date_time_text.dart' show formatDeadline;

// Field names follow StudentRepository and the saved schema verification output.
int? _int(dynamic value) => (value as num?)?.toInt();
double? _double(dynamic value) => (value as num?)?.toDouble();

DateTime? unixSeconds(int? value) => value == null || value <= 0
    ? null
    : DateTime.fromMillisecondsSinceEpoch(value * 1000);

String activityLabel(String type) => switch (type) {
  'forum' => 'Diễn đàn',
  'resource' => 'Tài liệu',
  'folder' => 'Thư mục',
  'assign' || 'assignment' => 'Bài tập',
  'quiz' => 'Bài kiểm tra',
  'attendance' => 'Điểm danh',
  _ => 'Hoạt động',
};

class StudentLearningItem {
  final String? courseName;
  final int? courseId;
  final int? completionState;
  final int? completionTracking;
  final int? sectionNumber;
  final String? sectionName;
  final String name;
  final String activityType;
  final int? courseModuleId;
  final String? moodlePath;

  StudentLearningItem.fromJson(Map<String, dynamic> json)
    : courseName = json['course_name'] as String?,
      courseId = _int(json['courseid']),
      completionState = _int(json['completionstate']),
      completionTracking = _int(json['completion_tracking']),
      sectionNumber = _int(json['section_number']),
      sectionName = json['section_name'] as String?,
      name = json['activity_name'] as String? ?? 'Hoạt động',
      activityType = json['activity_type'] as String? ?? '',
      courseModuleId = _int(json['coursemoduleid']),
      moodlePath = json['moodle_path'] as String?;

  String get sectionTitle => sectionName?.trim().isNotEmpty == true
      ? DemoDisplayNames.section(sectionName!)
      : sectionNumber == 0
      ? 'Tổng quan'
      : 'Phần ${sectionNumber ?? "khác"}';
}

class StudentTask {
  final int? courseId;
  final String? courseName;
  final int? sourceId;
  final String title;
  final String type;
  final int? dueTime;
  final String? taskStatus;
  final String? sourceStatus;
  final String? quizState;
  final int? courseModuleId;
  final String? moodlePath;

  StudentTask.fromJson(Map<String, dynamic> json)
    : courseId = _int(json['courseid']),
      courseName = json['course_name'] as String?,
      sourceId = _int(json['source_id']),
      title = json['title'] as String? ?? 'Việc cần làm',
      type = json['task_type'] as String? ?? '',
      dueTime = _int(json['due_time']),
      taskStatus = json['task_status'] as String?,
      sourceStatus = json['source_status'] as String?,
      quizState = json['quiz_state'] as String?,
      courseModuleId = _int(json['coursemoduleid']),
      moodlePath = json['moodle_path'] as String?;

  bool get isAssignment => type == 'assignment';
  bool get isSubmitted => isAssignment && sourceStatus == 'submitted';
  bool get isQuizFinished => type == 'quiz' && quizState == 'finished';
  bool get isDone => taskStatus == 'completed' || isSubmitted || isQuizFinished;
  bool get isPending =>
      !isDone && (taskStatus == 'pending' || taskStatus == 'overdue');
  DateTime? get deadline => unixSeconds(dueTime);

  bool isOverdue(DateTime now) =>
      !isDone &&
      (taskStatus == 'overdue' ||
          (isPending && deadline != null && deadline!.isBefore(now)));
  bool isDueSoon(DateTime now) =>
      isPending &&
      !isOverdue(now) &&
      deadline != null &&
      !deadline!.isBefore(now) &&
      deadline!.difference(now) <= const Duration(hours: 48);

  String get statusLabel {
    if (isSubmitted) return 'Đã nộp';
    if (isQuizFinished) return 'Đã làm';
    if (isDone) return 'Đã hoàn thành';
    if (isPending) return 'Chưa hoàn thành';
    return 'Chưa có trạng thái';
  }

  String get actionLabel {
    if (isAssignment) return isDone ? 'Xem bài trên LMS' : 'Mở LMS để nộp bài';
    if (type == 'quiz') {
      return isDone ? 'Xem bài kiểm tra trên LMS' : 'Mở LMS để làm bài';
    }
    return 'Mở trên LMS';
  }

  int priority(DateTime now) => isDone
      ? 3
      : isOverdue(now)
      ? 0
      : isDueSoon(now)
      ? 1
      : 2;

  static List<StudentTask> sorted(List<StudentTask> tasks, DateTime now) {
    return [...tasks]..sort((a, b) {
      final group = a.priority(now).compareTo(b.priority(now));
      if (group != 0) return group;
      final byDate = (a.deadline?.millisecondsSinceEpoch ?? 8640000000000000)
          .compareTo(b.deadline?.millisecondsSinceEpoch ?? 8640000000000000);
      if (byDate != 0) return byDate;
      final byType = a.type.compareTo(b.type);
      return byType != 0
          ? byType
          : (a.sourceId ?? 0).compareTo(b.sourceId ?? 0);
    });
  }
}

class StudentGrade {
  final String name;
  final int? categoryId;
  final String? categoryName;
  final double? finalGrade;
  final double? gradeMax;
  final double? percentage;
  final String? feedback;

  StudentGrade.fromJson(Map<String, dynamic> json)
    : name = json['activity_name'] as String? ?? 'Hoạt động',
      categoryId = _int(json['category_id']),
      categoryName = json['category_name'] as String?,
      finalGrade = _double(json['finalgrade']),
      gradeMax = _double(json['grademax']),
      percentage = _double(json['grade_percentage']),
      feedback = json['feedback'] as String?;

  bool get isGraded => finalGrade != null || percentage != null;
  String get gradingStatus => isGraded ? 'Đã chấm' : 'Chưa chấm';
  String get scoreLabel {
    if (!isGraded) return 'Chưa có điểm';
    final percent =
        percentage ??
        (finalGrade == 0
            ? 0
            : finalGrade != null && gradeMax != null && gradeMax! > 0
            ? finalGrade! / gradeMax! * 100
            : null);
    if (percent != null) return formatPercentageVi(percent);
    return '${vietnameseDecimal(finalGrade!)}'
        '${gradeMax == null ? "" : " / ${vietnameseDecimal(gradeMax!)}"}';
  }
}

class StudentGradeCategory {
  final int? id;
  final String name;
  final double? averagePercentage;
  final int? gradedCount;
  final int? totalCount;

  StudentGradeCategory.fromJson(Map<String, dynamic> json)
    : id = _int(json['category_id']),
      name = json['category_name'] as String? ?? 'Nhóm điểm',
      averagePercentage = _double(json['category_average_percentage']),
      gradedCount = _int(json['graded_item_count']),
      totalCount = _int(json['grade_item_count']);
}

class StudentAttendance {
  final double? percentage;
  final int? totalSessions;
  final int? present;
  final int? late;
  final int? excused;
  final int? absent;

  StudentAttendance.fromJson(Map<String, dynamic> json)
    : percentage = _double(json['attendance_percentage']),
      totalSessions = _int(json['total_sessions']),
      present = _int(json['present_count']),
      late = _int(json['late_count']),
      excused = _int(json['excused_count']),
      absent = _int(json['absent_count']);
}
