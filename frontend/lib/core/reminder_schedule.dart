/// V2-N7: pure computation of which local reminders to schedule (no plugin, no clock of its own).
library;

/// Settings shared with the server (`app.notification_preferences`) plus the device-only daily time.
class ReminderPrefs {
  final bool pushEnabled;
  final bool assignmentReminder;
  final bool quizReminder;
  final bool learningReminder;
  final int reminderBeforeHours;

  /// Minutes after midnight for the daily study reminder (device setting).
  final int dailyMinute;

  const ReminderPrefs({
    this.pushEnabled = true,
    this.assignmentReminder = true,
    this.quizReminder = true,
    this.learningReminder = true,
    this.reminderBeforeHours = 24,
    this.dailyMinute = defaultDailyMinute,
  });

  static const defaultDailyMinute = 19 * 60;
  static const hourOptions = [1, 3, 6, 12, 24, 48, 72];

  factory ReminderPrefs.fromJson(
    Map<String, dynamic> j, {
    int dailyMinute = defaultDailyMinute,
  }) => ReminderPrefs(
    pushEnabled: j['pushEnabled'] != false,
    assignmentReminder: j['assignmentReminder'] != false,
    quizReminder: j['quizReminder'] != false,
    learningReminder: j['learningReminder'] != false,
    reminderBeforeHours: j['reminderBeforeHours'] is int
        ? j['reminderBeforeHours'] as int
        : 24,
    dailyMinute: dailyMinute,
  );

  /// Server fields only; the daily time never leaves the device.
  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'assignmentReminder': assignmentReminder,
    'quizReminder': quizReminder,
    'learningReminder': learningReminder,
    'reminderBeforeHours': reminderBeforeHours,
  };

  ReminderPrefs copyWith({
    bool? pushEnabled,
    bool? assignmentReminder,
    bool? quizReminder,
    bool? learningReminder,
    int? reminderBeforeHours,
    int? dailyMinute,
  }) => ReminderPrefs(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    assignmentReminder: assignmentReminder ?? this.assignmentReminder,
    quizReminder: quizReminder ?? this.quizReminder,
    learningReminder: learningReminder ?? this.learningReminder,
    reminderBeforeHours: reminderBeforeHours ?? this.reminderBeforeHours,
    dailyMinute: dailyMinute ?? this.dailyMinute,
  );
}

/// An open LMS deadline (already filtered to not done).
class DeadlineInput {
  final String title;
  final String? courseName;
  final DateTime due;
  final bool isQuiz;
  const DeadlineInput({
    required this.title,
    required this.due,
    this.courseName,
    this.isQuiz = false,
  });
}

/// Planned (not done/skipped) work for one day of the N6 plan.
class PlanDayInput {
  final DateTime date;
  final int openItems;
  final int openMinutes;
  const PlanDayInput(this.date, this.openItems, this.openMinutes);
}

enum ReminderKind { deadline, daily }

class PlannedReminder {
  final int id;
  final ReminderKind kind;
  final DateTime when;
  final String title;
  final String body;
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.when,
    required this.title,
    required this.body,
  });
}

class ReminderPlan {
  final List<PlannedReminder> reminders;

  /// Open deadlines still in the future (whether or not their reminder time already passed).
  final int upcomingDeadlines;
  const ReminderPlan(this.reminders, this.upcomingDeadlines);

  List<PlannedReminder> get deadlines =>
      reminders.where((r) => r.kind == ReminderKind.deadline).toList();
  List<PlannedReminder> get daily =>
      reminders.where((r) => r.kind == ReminderKind.daily).toList();
}

const maxDeadlineReminders = 40;
const dailyDays = 7;
const _deadlineIdBase = 1000;
const _dailyIdBase = 100;

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _dm(DateTime d) => '${d.day}/${d.month}';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Deadline reminders fire [ReminderPrefs.reminderBeforeHours] before the due time; a deadline in
/// the past, or whose reminder time has already passed, is not scheduled. Daily reminders cover the
/// next [dailyDays] occurrences of the daily time: the first carries today's due flashcard count,
/// each carries that day's open plan items. A day with nothing to say gets no daily reminder.
ReminderPlan planReminders({
  required DateTime now,
  required ReminderPrefs prefs,
  required List<DeadlineInput> deadlines,
  int dueCards = 0,
  List<PlanDayInput> planDays = const [],
}) {
  final upcoming = deadlines.where((d) => d.due.isAfter(now)).toList()
    ..sort((a, b) => a.due.compareTo(b.due));
  if (!prefs.pushEnabled) return ReminderPlan(const [], upcoming.length);
  final out = <PlannedReminder>[];
  final lead = Duration(hours: prefs.reminderBeforeHours);
  for (final d in upcoming) {
    if (d.isQuiz ? !prefs.quizReminder : !prefs.assignmentReminder) continue;
    final when = d.due.subtract(lead);
    if (!when.isAfter(now)) continue;
    if (out.length >= maxDeadlineReminders) break;
    final left = prefs.reminderBeforeHours == 0
        ? 'đến hạn bây giờ'
        : 'còn ${prefs.reminderBeforeHours} giờ';
    out.add(
      PlannedReminder(
        id: _deadlineIdBase + out.length,
        kind: ReminderKind.deadline,
        when: when,
        title: '${d.isQuiz ? 'Bài kiểm tra' : 'Bài tập'} $left: ${d.title}',
        body:
            '${d.courseName == null ? '' : '${d.courseName} · '}Hạn ${_hm(d.due)} ngày ${_dm(d.due)}',
      ),
    );
  }
  if (prefs.learningReminder) {
    final byDay = {for (final p in planDays) _day(p.date): p};
    final first = DateTime(
      now.year,
      now.month,
      now.day,
      prefs.dailyMinute ~/ 60,
      prefs.dailyMinute % 60,
    );
    var start = first.isAfter(now) ? first : first.add(const Duration(days: 1));
    for (var i = 0; i < dailyDays; i++) {
      final when = DateTime(
        start.year,
        start.month,
        start.day + i,
        start.hour,
        start.minute,
      );
      final plan = byDay[_day(when)];
      final parts = [
        if (i == 0 && dueCards > 0) 'cần ôn $dueCards thẻ',
        if (plan != null && plan.openItems > 0)
          '${plan.openItems} việc trong kế hoạch (${plan.openMinutes} phút)',
      ];
      if (parts.isEmpty) continue;
      final text = parts.join(' · ');
      out.add(
        PlannedReminder(
          id: _dailyIdBase + i,
          kind: ReminderKind.daily,
          when: when,
          title: 'Hôm nay học gì?',
          body: '${text[0].toUpperCase()}${text.substring(1)}',
        ),
      );
    }
  }
  out.sort((a, b) => a.when.compareTo(b.when));
  return ReminderPlan(out, upcoming.length);
}
