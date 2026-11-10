class LearningNotification {
  final int? id;
  final String title;
  final String? message, courseName, moodlePath;
  final int? courseModuleId;
  final int? courseId, sourceId;
  final DateTime? time;
  final bool reminder;

  /// Sent by a teacher from the analytics tab ("Nhắc N sinh viên").
  final bool fromTeacher;

  /// The teacher who sent it, when known.
  final String? senderName;

  /// Null for learning reminders, which have no read state.
  final bool? isRead;

  /// e.g. risk_alert, teacher_reminder, assignment_due.
  final String? type;
  final String? sourceType;

  /// The course this is about; a course-level notification may carry it as its source.
  int? get course => courseId ?? (sourceType == 'course' ? sourceId : null);

  /// "Sinh viên cần được hỗ trợ": the list behind it is on the course's analytics tab.
  bool get opensAnalytics => type == 'risk_alert';

  /// For a student: which tab of the course this notification is about, and the button
  /// label for it. Null when the type is unknown or there is no course to open.
  (int, String)? get studentCourseTab => course == null
      ? null
      : switch (type) {
          'grade_updated' => (3, 'Xem điểm'),
          'assignment_due' || 'quiz_due' => (2, 'Xem việc cần làm'),
          'teacher_reminder' => (2, 'Xem trong khóa học'),
          'learning_reminder' || 'learning_support' => (1, 'Vào học tiếp'),
          _ => null,
        };

  LearningNotification.fromJson(Map<String, dynamic> j)
    : type = j['notification_type'] as String?,
      sourceType = j['source_type'] as String?,
      id = (j['id'] as num?)?.toInt(),
      title = j['title'] as String? ?? 'Thông báo',
      message = j['message'] as String?,
      courseName = j['course_name'] as String?,
      moodlePath = j['moodle_path'] as String?,
      courseModuleId = (j['coursemoduleid'] as num?)?.toInt(),
      courseId = (j['course_id'] as num?)?.toInt(),
      sourceId = (j['source_id'] as num?)?.toInt(),
      time = j['event_time'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (j['event_time'] as num).toInt(),
            )
          : DateTime.tryParse(j['event_time']?.toString() ?? '')?.toLocal(),
      reminder = j['source_kind'] == 'reminder',
      fromTeacher = j['notification_type'] == 'teacher_reminder',
      senderName = (j['sender_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['sender_name'] as String).trim(),
      isRead = j['is_read'] as bool?;
}
