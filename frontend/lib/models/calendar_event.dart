/// V2-N12 calendar event from GET /dev/students/{id}/calendar.
enum CalendarKind {
  deadline('deadline', 'Hạn nộp'),
  plan('plan', 'Kế hoạch'),
  attendance('attendance', 'Buổi học');

  final String key, label;
  const CalendarKind(this.key, this.label);

  static CalendarKind parse(Object? v) =>
      CalendarKind.values.firstWhere((k) => k.key == v, orElse: () => plan);
}

class CalendarEvent {
  final String uid;
  final CalendarKind kind;
  final String title;
  final String? courseName;
  final DateTime start;
  final DateTime? end;
  final bool allDay, done;
  final int? minutes;
  final String? moodlePath;
  final int? courseModuleId;

  const CalendarEvent({
    required this.uid,
    required this.kind,
    required this.title,
    required this.start,
    this.end,
    this.courseName,
    this.allDay = false,
    this.done = false,
    this.minutes,
    this.moodlePath,
    this.courseModuleId,
  });

  static DateTime? _time(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  factory CalendarEvent.fromJson(Map<String, dynamic> j) {
    final allDay = j['allDay'] == true;
    final date = j['date'] is String ? DateTime.tryParse(j['date']) : null;
    return CalendarEvent(
      uid: j['uid']?.toString() ?? '',
      kind: CalendarKind.parse(j['type']),
      title: j['title']?.toString() ?? '',
      courseName: j['courseName'] as String?,
      // All-day items are a local date; never shift them through a time zone.
      start: allDay && date != null
          ? DateTime(date.year, date.month, date.day)
          : _time(j['start']) ?? DateTime(1970),
      end: _time(j['end']),
      allDay: allDay,
      done: j['done'] == true,
      minutes: j['minutes'] is num ? (j['minutes'] as num).toInt() : null,
      moodlePath: j['moodlePath'] as String?,
      courseModuleId: j['courseModuleId'] is num
          ? (j['courseModuleId'] as num).toInt()
          : null,
    );
  }

  bool onDay(DateTime d) =>
      start.year == d.year && start.month == d.month && start.day == d.day;
}
