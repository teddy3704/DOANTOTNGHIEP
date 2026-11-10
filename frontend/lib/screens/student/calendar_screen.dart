import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ics.dart';
import '../../models/calendar_event.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/learning_widgets.dart';
import '../../widgets/moodle_button.dart';

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
String _two(int v) => v.toString().padLeft(2, '0');
bool _same(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color kindColor(BuildContext context, CalendarKind k) => switch (k) {
  CalendarKind.deadline => Theme.of(context).colorScheme.error,
  CalendarKind.plan => Theme.of(context).colorScheme.primary,
  CalendarKind.attendance => const Color(0xFF1565C0),
};

/// .ics events: deadlines get a VALARM `hoursBefore` hours ahead (N7 setting); plan items are
/// all-day; attendance sessions keep their real start/end. Done items are left out.
List<IcsEvent> icsEventsFor(List<CalendarEvent> events, {int? hoursBefore}) => [
  for (final e in events)
    if (!e.done)
      IcsEvent(
        uid: e.uid,
        title: e.kind == CalendarKind.deadline
            ? 'Hạn nộp: ${e.title}'
            : e.title,
        description: [
          if (e.courseName != null) e.courseName!,
          if (e.minutes != null) '${e.minutes} phút',
        ].join(' · '),
        start: e.start,
        end: e.end,
        allDay: e.allDay,
        alarmMinutesBefore:
            e.kind == CalendarKind.deadline && hoursBefore != null
            ? hoursBefore * 60
            : null,
      ),
];

typedef ShareIcs = Future<void> Function(List<int> bytes, String fileName);

Future<void> _shareSystem(List<int> bytes, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'text/calendar',
          name: fileName,
        ),
      ],
      fileNameOverrides: [fileName],
      subject: fileName,
    ),
  );
}

/// V2-N12 "Lịch học": month grid or week agenda of deadlines, plan items and attendance sessions;
/// tap a day for its list; export the shown month or week as .ics to open in Google Calendar.
class CalendarScreen extends StatefulWidget {
  final ApiService api;
  final DateTime Function() now;
  final ShareIcs share;
  const CalendarScreen({
    super.key,
    required this.api,
    this.now = DateTime.now,
    this.share = _shareSystem,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month = DateTime(widget.now().year, widget.now().month);
  late DateTime _day = widget.now();
  bool _week = false;
  late DateTime _weekStart = mondayOf(widget.now());
  late Future<List<CalendarEvent>> _future = _load();

  Future<List<CalendarEvent>> _load() => _week
      ? widget.api.getCalendar(
          from: _weekStart,
          to: DateTime(_weekStart.year, _weekStart.month, _weekStart.day + 6),
        )
      : widget.api.getCalendar(
          from: _month,
          to: DateTime(_month.year, _month.month + 1, 0),
        );

  void _shift(int steps) => setState(() {
    if (_week) {
      _weekStart = DateTime(
        _weekStart.year,
        _weekStart.month,
        _weekStart.day + 7 * steps,
      );
      _day = _weekStart;
    } else {
      _month = DateTime(_month.year, _month.month + steps);
      _day = _month;
    }
    _future = _load();
  });

  void _setWeek(bool week) => setState(() {
    _week = week;
    if (week) {
      _weekStart = mondayOf(_day);
    } else {
      _month = DateTime(_day.year, _day.month);
    }
    _future = _load();
  });

  Future<void> _export(List<CalendarEvent> events) async {
    int? hours;
    try {
      final prefs = await widget.api.getNotificationPreferences();
      if (prefs['pushEnabled'] != false &&
          prefs['reminderBeforeHours'] is int) {
        hours = prefs['reminderBeforeHours'] as int;
      }
    } catch (e) {
      debugPrint('Calendar export prefs: $e');
      hours = 24;
    }
    final ics = buildIcs(
      icsEventsFor(events, hoursBefore: hours),
      now: widget.now(),
    );
    await widget.share(
      utf8.encode(ics),
      _week
          ? 'lich-hoc-tuan-${_weekStart.year}-${_two(_weekStart.month)}-${_two(_weekStart.day)}.ics'
          : 'lich-hoc-${_month.year}-${_two(_month.month)}.ics',
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CalendarEvent>>(
    future: _future,
    builder: (context, snap) {
      final events = snap.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch học'),
          actions: [
            IconButton(
              key: const Key('calendar-export'),
              tooltip: 'Xuất sang Google Calendar (.ics)',
              icon: const Icon(Icons.ios_share),
              onPressed: events == null || events.isEmpty
                  ? null
                  : () => _export(events),
            ),
          ],
        ),
        body: _body(context, snap, events),
      );
    },
  );

  Widget _body(
    BuildContext context,
    AsyncSnapshot<List<CalendarEvent>> snap,
    List<CalendarEvent>? events,
  ) {
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError || events == null) {
      return ListView(
        children: [
          EmptyState(apiErrorMessage(snap.error ?? ''), icon: Icons.cloud_off),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _future = _load();
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }
    final theme = Theme.of(context);
    final header = [
      Center(
        child: SegmentedButton<bool>(
          key: const Key('calendar-mode'),
          segments: const [
            ButtonSegment(value: false, label: Text('Tháng')),
            ButtonSegment(value: true, label: Text('Tuần')),
          ],
          selected: {_week},
          showSelectedIcon: false,
          onSelectionChanged: (v) => _setWeek(v.first),
        ),
      ),
      Row(
        children: [
          IconButton(
            key: const Key('calendar-prev'),
            tooltip: _week ? 'Tuần trước' : 'Tháng trước',
            onPressed: () => _shift(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              _week
                  ? weekTitle(_weekStart)
                  : 'Tháng ${_month.month}/${_month.year}',
              key: const Key('calendar-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('calendar-next'),
            tooltip: _week ? 'Tuần sau' : 'Tháng sau',
            onPressed: () => _shift(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ];
    if (_week) {
      // A week is short: build it whole so every day exists for screen readers too.
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            for (var i = 0; i < 7; i++)
              ..._weekDay(
                context,
                DateTime(_weekStart.year, _weekStart.month, _weekStart.day + i),
                events,
              ),
          ],
        ),
      );
    }
    final first = DateTime(_month.year, _month.month);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final today = widget.now();
    final ofDay = events.where((e) => e.onDay(_day)).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...header,
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(w, style: theme.textTheme.labelMedium),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            // Day number + dot row, tall enough for large text on narrow phones.
            mainAxisExtent: 18 + MediaQuery.textScalerOf(context).scale(24),
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _DayCell(
                date: DateTime(_month.year, _month.month, d),
                kinds: {
                  for (final e in events)
                    if (e.onDay(DateTime(_month.year, _month.month, d))) e.kind,
                },
                selected: _same(_day, DateTime(_month.year, _month.month, d)),
                today: _same(today, DateTime(_month.year, _month.month, d)),
                onTap: () => setState(
                  () => _day = DateTime(_month.year, _month.month, d),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            for (final k in CalendarKind.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: kindColor(context, k),
                  ),
                  const SizedBox(width: 4),
                  Text(k.label, style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Ngày ${_day.day}/${_day.month}',
          style: theme.textTheme.titleMedium,
        ),
        if (ofDay.isEmpty)
          const EmptyState(
            'Không có việc trong ngày',
            icon: Icons.event_available,
          ),
        for (final e in ofDay) _eventCard(context, e),
      ],
    );
  }

  /// One day of the week agenda: its heading, then its events (or a dash).
  List<Widget> _weekDay(
    BuildContext context,
    DateTime date,
    List<CalendarEvent> events,
  ) {
    final theme = Theme.of(context);
    final ofDay = events.where((e) => e.onDay(date)).toList();
    final today = _same(widget.now(), date);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 2),
        child: Text(
          '${_weekdays[date.weekday - 1]} ${date.day}/${date.month}'
          '${today ? ' · Hôm nay' : ''}',
          key: Key('calendar-week-day-${date.day}'),
          style: theme.textTheme.titleSmall?.copyWith(
            color: today ? theme.colorScheme.primary : null,
          ),
        ),
      ),
      if (ofDay.isEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Không có việc',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final e in ofDay) _eventCard(context, e),
    ];
  }

  Widget _eventCard(BuildContext context, CalendarEvent e) => Card(
    child: ListTile(
      key: Key('calendar-event-${e.uid}'),
      leading: CircleAvatar(
        radius: 6,
        backgroundColor: kindColor(context, e.kind),
      ),
      title: Text(
        e.title,
        style: e.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          e.kind.label,
          if (!e.allDay) '${_two(e.start.hour)}:${_two(e.start.minute)}',
          if (e.minutes != null) '${e.minutes} phút',
          ?e.courseName,
        ].join(' · '),
      ),
      trailing: e.moodlePath != null && e.courseModuleId != null
          ? MoodleButton(
              path: e.moodlePath,
              courseModuleId: e.courseModuleId,
              compact: true,
            )
          : null,
    ),
  );
}

/// Monday 00:00 of the week holding [d] (weeks run Monday–Sunday).
DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// "Tuần 16/11 – 22/11/2026"; the end may fall in the next month or year.
String weekTitle(DateTime monday) {
  final end = DateTime(monday.year, monday.month, monday.day + 6);
  return 'Tuần ${monday.day}/${monday.month} – ${end.day}/${end.month}/${end.year}';
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final Set<CalendarKind> kinds;
  final bool selected, today;
  final VoidCallback onTap;
  const _DayCell({
    required this.date,
    required this.kinds,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('calendar-day-${date.day}'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(8),
          border: today ? Border.all(color: scheme.primary, width: 1.5) : null,
        ),
        // Large text on a 320 dp phone: shrink the cell content rather than overflow it.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', maxLines: 1, softWrap: false),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final k in CalendarKind.values)
                    if (kinds.contains(k))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: kindColor(context, k),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
