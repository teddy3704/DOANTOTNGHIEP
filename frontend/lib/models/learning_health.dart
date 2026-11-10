int _i(Object? v) => v is num ? v.toInt() : 0;

List<Map<String, dynamic>> _maps(Object? v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

enum HealthLevel {
  red('Đỏ', 'Cần hỗ trợ'),
  yellow('Vàng', 'Cần chú ý'),
  green('Xanh', 'Ổn định');

  final String label, meaning;
  const HealthLevel(this.label, this.meaning);

  static HealthLevel? parse(Object? v) => switch (v) {
    'RED' => HealthLevel.red,
    'YELLOW' => HealthLevel.yellow,
    'GREEN' => HealthLevel.green,
    _ => null,
  };
}

/// One reason with the points it adds; identical to what the teacher sees for this student.
class HealthReason {
  final int points;
  final String label;
  final String? code;
  const HealthReason(this.points, this.label, this.code);
  factory HealthReason.fromJson(Map<String, dynamic> j) => HealthReason(
    _i(j['points']),
    j['label']?.toString() ?? '',
    j['code']?.toString(),
  );
}

enum HealthTarget { tasks, openLms, recommendations }

class HealthAction {
  final String title;
  final HealthTarget? target;
  final int scoreDrop;
  final int courseId;
  final String? moodlePath;
  final int? courseModuleId;

  const HealthAction({
    required this.title,
    required this.target,
    required this.scoreDrop,
    required this.courseId,
    this.moodlePath,
    this.courseModuleId,
  });

  factory HealthAction.fromJson(Map<String, dynamic> j) => HealthAction(
    title: j['title']?.toString() ?? '',
    target: switch (j['target']) {
      'TASKS' => HealthTarget.tasks,
      'OPEN_LMS' => HealthTarget.openLms,
      'RECOMMENDATIONS' => HealthTarget.recommendations,
      _ => null,
    },
    scoreDrop: _i(j['scoreDrop']),
    courseId: _i(j['courseId']),
    moodlePath: j['moodlePath']?.toString(),
    courseModuleId: j['courseModuleId'] is num
        ? (j['courseModuleId'] as num).toInt()
        : null,
  );
}

class CourseHealth {
  final int courseId;
  final String courseName;
  final int score;
  final HealthLevel? level;
  final List<HealthReason> reasons;
  final List<HealthAction> actions;

  const CourseHealth({
    required this.courseId,
    required this.courseName,
    required this.score,
    required this.level,
    required this.reasons,
    required this.actions,
  });

  factory CourseHealth.fromJson(Map<String, dynamic> j) => CourseHealth(
    courseId: _i(j['courseId']),
    courseName: j['courseName']?.toString() ?? 'Khóa học',
    score: _i(j['score']),
    level: HealthLevel.parse(j['level']),
    reasons: _maps(j['reasons']).map(HealthReason.fromJson).toList(),
    actions: _maps(j['actions']).map(HealthAction.fromJson).toList(),
  );
}

class LearningHealthOverview {
  final HealthLevel? level;
  final Map<HealthLevel, int> counts;
  final List<CourseHealth> courses;

  const LearningHealthOverview({
    required this.level,
    required this.counts,
    required this.courses,
  });

  factory LearningHealthOverview.fromJson(Map<String, dynamic> j) {
    final raw = j['counts'] is Map ? j['counts'] as Map : const {};
    return LearningHealthOverview(
      level: HealthLevel.parse(j['level']),
      counts: {
        HealthLevel.red: _i(raw['RED']),
        HealthLevel.yellow: _i(raw['YELLOW']),
        HealthLevel.green: _i(raw['GREEN']),
      },
      courses: _maps(j['courses']).map(CourseHealth.fromJson).toList(),
    );
  }

  /// "1 khóa Đỏ · 1 khóa Vàng · 1 khóa Xanh", skipping zero counts.
  String get summary {
    final parts = [
      for (final l in HealthLevel.values)
        if ((counts[l] ?? 0) > 0) '${counts[l]} khóa ${l.label}',
    ];
    return parts.isEmpty ? 'Chưa có khóa học' : parts.join(' · ');
  }
}
