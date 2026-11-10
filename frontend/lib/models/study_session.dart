int _i(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

/// V2-N10 focus-timer presets (focus minutes / break minutes).
enum FocusPreset {
  short(25, 5),
  long(50, 10);

  final int focus, rest;
  const FocusPreset(this.focus, this.rest);
  String get label => '$focus/$rest';
}

class StudyDay {
  final DateTime date;
  final int minutes, sessions;
  const StudyDay(this.date, this.minutes, this.sessions);
}

class StudyCourseMinutes {
  final int? courseId;
  final String? courseName;
  final int minutes;
  const StudyCourseMinutes(this.courseId, this.courseName, this.minutes);
}

class StudySummary {
  final int totalMinutes, sessions;
  final List<StudyDay> days;
  final List<StudyCourseMinutes> courses;
  const StudySummary({
    required this.totalMinutes,
    required this.sessions,
    required this.days,
    required this.courses,
  });

  factory StudySummary.fromJson(Map<String, dynamic> j) {
    final days = j['days'];
    if (days is! List) throw const FormatException('Expected days');
    return StudySummary(
      totalMinutes: _i(j['totalMinutes']),
      sessions: _i(j['sessions']),
      days: [
        for (final d in days.whereType<Map<String, dynamic>>())
          StudyDay(
            DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime(1970),
            _i(d['minutes']),
            _i(d['sessions']),
          ),
      ],
      courses: [
        for (final c
            in (j['courses'] as List? ?? const [])
                .whereType<Map<String, dynamic>>())
          StudyCourseMinutes(
            c['courseId'] is num ? (c['courseId'] as num).toInt() : null,
            c['courseName'] as String?,
            _i(c['minutes']),
          ),
      ],
    );
  }

  int minutesOn(DateTime day) => days
      .where(
        (d) =>
            d.date.year == day.year &&
            d.date.month == day.month &&
            d.date.day == day.day,
      )
      .fold(0, (s, d) => s + d.minutes);
}

/// Whole focus minutes between [start] and [end], capped at [planned] (computed from timestamps,
/// not by counting ticks, so the timer stays right while the app is in the background).
int focusMinutes(DateTime start, DateTime end, int planned) {
  final m = end.difference(start).inMinutes;
  return m < 0 ? 0 : (m > planned ? planned : m);
}
