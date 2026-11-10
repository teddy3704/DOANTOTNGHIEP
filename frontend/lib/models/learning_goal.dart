int? _int(dynamic v) => v is num ? v.toInt() : null;
double? _double(dynamic v) => v is num ? v.toDouble() : null;
String? _string(dynamic v) => v is String && v.trim().isNotEmpty ? v : null;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

/// Goals supported by the backend. `study_minutes` counts focus sessions recorded in the app (V2-N10).
enum GoalType {
  completionPercentage('completion_percentage', 'Hoàn thành tiến độ', '%'),
  activityCount('activity_count', 'Số hoạt động hoàn thành', 'hoạt động'),
  targetGrade('target_grade', 'Điểm trung bình mong muốn', '%'),
  studyMinutes('study_minutes', 'Phút học tập trung', 'phút');

  final String apiValue, label, unit;
  const GoalType(this.apiValue, this.label, this.unit);

  static GoalType? parse(String? value) {
    for (final t in values) {
      if (t.apiValue == value) return t;
    }
    return null;
  }
}

class LearningGoal {
  final int id;
  final GoalType? type;
  final int? courseId;
  final String? courseName;
  final double target;
  final String unit, status;
  final DateTime? startDate, endDate;
  final double? current, progressPercent, expectedPercent;
  final bool achieved;
  final String? attention, basis;
  final int? daysLeft;

  LearningGoal.fromJson(Map<String, dynamic> j)
    : id = _int(j['id']) ?? 0,
      type = GoalType.parse(_string(j['goal_type'])),
      courseId = _int(j['course_id']),
      courseName = _string(j['course_name']),
      target = _double(j['target_value']) ?? 0,
      unit = _string(j['unit']) ?? '',
      status = _string(j['status']) ?? 'active',
      startDate = _date(j['start_date']),
      endDate = _date(j['end_date']),
      current = _double(j['current_value']),
      progressPercent = _double(j['progress_percent']),
      expectedPercent = _double(j['expected_percent']),
      achieved = j['achieved'] == true,
      attention = _string(j['attention']),
      basis = _string(j['basis']),
      daysLeft = _int(j['days_left']);

  bool get isActive => status == 'active';

  String get title {
    final t = target == target.roundToDouble()
        ? target.toStringAsFixed(0)
        : target.toStringAsFixed(1).replaceAll('.', ',');
    return switch (type) {
      GoalType.completionPercentage => 'Hoàn thành $t% tiến độ',
      GoalType.activityCount => 'Hoàn thành $t hoạt động',
      GoalType.targetGrade => 'Điểm trung bình đạt $t%',
      GoalType.studyMinutes => 'Học tập trung $t phút',
      null => 'Mục tiêu học tập',
    };
  }

  String get statusLabel => switch (status) {
    'completed' => 'Đã đạt',
    'expired' => 'Hết hạn',
    'cancelled' => 'Đã hủy',
    _ => 'Đang thực hiện',
  };

  String? get attentionLabel => switch (attention) {
    'BEHIND_PACE' => 'Chậm hơn tiến độ kỳ vọng',
    'NEAR_DEADLINE' => 'Sắp đến hạn',
    _ => null,
  };
}
