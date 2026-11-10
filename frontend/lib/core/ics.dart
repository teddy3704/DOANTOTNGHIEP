/// V2-N12: RFC 5545 calendar export (UTF-8). Times are written in UTC ("Z"), which every calendar
/// app converts to the device zone; all-day plan items use VALUE=DATE (local date, no zone).
library;

import 'dart:convert';

class IcsEvent {
  /// Stable id from the server, so a re-import updates instead of duplicating.
  final String uid;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime? end;
  final bool allDay;

  /// Minutes before start for a VALARM; null = no alarm.
  final int? alarmMinutesBefore;

  const IcsEvent({
    required this.uid,
    required this.title,
    required this.start,
    this.end,
    this.description,
    this.allDay = false,
    this.alarmMinutesBefore,
  });
}

/// TEXT escaping (RFC 5545 §3.3.11): backslash, semicolon, comma, newline.
String icsEscape(String v) => v
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\r\n', r'\n')
    .replaceAll('\n', r'\n');

String _two(int v) => v.toString().padLeft(2, '0');

String icsUtc(DateTime t) {
  final u = t.toUtc();
  return '${u.year}${_two(u.month)}${_two(u.day)}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
}

String icsDate(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';

/// Folds a content line to ≤ 75 octets (continuation lines start with one space), never splitting
/// a UTF-8 character.
String icsFold(String line) {
  final out = StringBuffer();
  var count = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final size = utf8.encode(ch).length;
    if (count + size > 75) {
      out.write('\r\n ');
      count = 1;
    }
    out.write(ch);
    count += size;
  }
  return out.toString();
}

String buildIcs(
  List<IcsEvent> events, {
  required DateTime now,
  String name = 'Lịch học DLU LMS',
}) {
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//DLU LMS Group//Lich hoc//VI',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'X-WR-CALNAME:${icsEscape(name)}',
    'X-WR-TIMEZONE:Asia/Ho_Chi_Minh',
  ];
  for (final e in events) {
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${e.uid}',
      'DTSTAMP:${icsUtc(now)}',
      if (e.allDay) ...[
        'DTSTART;VALUE=DATE:${icsDate(e.start)}',
        'DTEND;VALUE=DATE:${icsDate(DateTime(e.start.year, e.start.month, e.start.day + 1))}',
      ] else ...[
        'DTSTART:${icsUtc(e.start)}',
        if (e.end != null) 'DTEND:${icsUtc(e.end!)}',
      ],
      'SUMMARY:${icsEscape(e.title)}',
      if (e.description != null && e.description!.isNotEmpty)
        'DESCRIPTION:${icsEscape(e.description!)}',
      if (e.alarmMinutesBefore != null) ...[
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'DESCRIPTION:${icsEscape(e.title)}',
        'TRIGGER:-PT${e.alarmMinutesBefore}M',
        'END:VALARM',
      ],
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  return '${lines.map(icsFold).join('\r\n')}\r\n';
}
