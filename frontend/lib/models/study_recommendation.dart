double? _d(Object? v) => v is num ? v.toDouble() : null;
int? _i(Object? v) => v is num ? v.toInt() : null;

class StudySuggestion {
  final String activityName;
  final String? activityType;
  final int? courseModuleId;
  final String? moodlePath;
  final String reason;

  const StudySuggestion({
    required this.activityName,
    required this.reason,
    this.activityType,
    this.courseModuleId,
    this.moodlePath,
  });

  factory StudySuggestion.fromJson(Map<String, dynamic> j) => StudySuggestion(
    activityName: j['activityName']?.toString() ?? 'Hoạt động',
    activityType: j['activityType']?.toString(),
    courseModuleId: _i(j['courseModuleId']),
    moodlePath: j['moodlePath']?.toString(),
    reason: j['reason']?.toString() ?? '',
  );
}

/// One weak chapter (Moodle section) with the reasons in numbers and up to three suggestions.
class WeakChapter {
  final int? courseId;
  final String? courseName;
  final String sectionName;
  final double severity;
  final double? average;
  final double? classAverage;
  final List<String> reasons;
  final List<StudySuggestion> suggestions;

  const WeakChapter({
    required this.sectionName,
    required this.severity,
    required this.reasons,
    required this.suggestions,
    this.courseId,
    this.courseName,
    this.average,
    this.classAverage,
  });

  factory WeakChapter.fromJson(
    Map<String, dynamic> j, {
    int? courseId,
    String? courseName,
  }) => WeakChapter(
    courseId: _i(j['courseId']) ?? courseId,
    courseName: j['courseName']?.toString() ?? courseName,
    sectionName: (j['sectionName']?.toString().trim().isNotEmpty ?? false)
        ? j['sectionName'].toString()
        : 'Chương ${_i(j['sectionNumber']) ?? ''}'.trim(),
    severity: _d(j['severity']) ?? 0,
    average: _d(j['average']),
    classAverage: _d(j['classAverage']),
    reasons: (j['reasons'] is List ? j['reasons'] as List : const [])
        .map((e) => e.toString())
        .toList(),
    suggestions:
        (j['suggestions'] is List ? j['suggestions'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(StudySuggestion.fromJson)
            .toList(),
  );

  /// Parses either the per-course or the all-courses response into chapters.
  static List<WeakChapter> listFrom(Map<String, dynamic> json) {
    final courseId = _i(json['courseId']);
    final courseName = json['courseName']?.toString();
    return (json['chapters'] is List ? json['chapters'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => WeakChapter.fromJson(
            c,
            courseId: courseId,
            courseName: courseName,
          ),
        )
        .toList();
  }
}
