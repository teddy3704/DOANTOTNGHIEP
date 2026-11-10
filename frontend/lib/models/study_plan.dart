/// V2-N6 weekly study plan (GET/POST /dev/students/{id}/study-plan).
library;

int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];

enum PlanStatus {
  planned,
  done,
  skipped;

  static PlanStatus parse(Object? v) => switch (v) {
    'done' => done,
    'skipped' => skipped,
    _ => planned,
  };
}

class PlanItem {
  final int id;
  final DateTime date;
  final int? courseId;
  final String sourceType;
  final String title;
  final int minutes;
  final PlanStatus status;

  const PlanItem({
    required this.id,
    required this.date,
    required this.sourceType,
    required this.title,
    required this.minutes,
    required this.status,
    this.courseId,
  });

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
    id: _i(j['id']),
    date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime(1970),
    courseId: j['courseId'] is num ? (j['courseId'] as num).toInt() : null,
    sourceType: j['sourceType']?.toString() ?? 'custom',
    title: j['title']?.toString() ?? 'Việc học',
    minutes: _i(j['minutes']),
    status: PlanStatus.parse(j['status']),
  );

  PlanItem withStatus(PlanStatus s) => PlanItem(
    id: id,
    date: date,
    courseId: courseId,
    sourceType: sourceType,
    title: title,
    minutes: minutes,
    status: s,
  );

  String get typeLabel => switch (sourceType) {
    'assign' => 'Bài tập',
    'quiz' => 'Quiz',
    'resource' => 'Ôn tập',
    'flashcards' => 'Thẻ ghi nhớ',
    _ => 'Việc học',
  };
}

class PlanDay {
  final DateTime date;
  final List<PlanItem> items;
  const PlanDay(this.date, this.items);

  int get plannedMinutes => items
      .where((i) => i.status != PlanStatus.skipped)
      .fold(0, (s, i) => s + i.minutes);
  int get doneMinutes => items
      .where((i) => i.status == PlanStatus.done)
      .fold(0, (s, i) => s + i.minutes);
  int get openCount =>
      items.where((i) => i.status == PlanStatus.planned).length;
}

class OverloadItem {
  final String title;
  final DateTime? due;
  final int minutes;
  const OverloadItem(this.title, this.due, this.minutes);
}

class StudyPlanWeek {
  final DateTime today;
  final int dailyMinutes;
  final List<PlanDay> days;
  final List<OverloadItem> overloaded;
  final int deferred;

  const StudyPlanWeek({
    required this.today,
    required this.dailyMinutes,
    required this.days,
    this.overloaded = const [],
    this.deferred = 0,
  });

  factory StudyPlanWeek.fromJson(Map<String, dynamic> j) {
    final days = j['days'];
    if (days is! List) throw const FormatException('Expected days');
    return StudyPlanWeek(
      today: DateTime.tryParse(j['today']?.toString() ?? '') ?? DateTime.now(),
      dailyMinutes: _i(j['dailyMinutes'], 60),
      days: _list(days)
          .map(
            (d) => PlanDay(
              DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime(1970),
              _list(d['items']).map(PlanItem.fromJson).toList(),
            ),
          )
          .toList(),
      overloaded: _list(j['overloaded'])
          .map(
            (o) => OverloadItem(
              o['title']?.toString() ?? 'Việc học',
              DateTime.tryParse(o['due']?.toString() ?? ''),
              _i(o['minutes']),
            ),
          )
          .toList(),
      deferred: _i(j['deferred']),
    );
  }

  PlanDay? dayOf(DateTime d) {
    for (final day in days) {
      if (day.date.year == d.year &&
          day.date.month == d.month &&
          day.date.day == d.day) {
        return day;
      }
    }
    return null;
  }

  bool get isEmpty => days.every((d) => d.items.isEmpty);

  StudyPlanWeek replace(PlanItem item) => StudyPlanWeek(
    today: today,
    dailyMinutes: dailyMinutes,
    overloaded: overloaded,
    deferred: deferred,
    days: [
      for (final d in days)
        PlanDay(d.date, [for (final i in d.items) i.id == item.id ? item : i]),
    ],
  );
}
