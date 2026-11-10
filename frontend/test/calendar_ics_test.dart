import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/ics.dart';
import 'package:lms_mobile_app/models/calendar_event.dart';
import 'package:lms_mobile_app/screens/student/calendar_screen.dart';

import 'support/mock_api.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _events = [
  {
    'uid': 'deadline-assign-1@dlu-lms-group',
    'type': 'deadline',
    'title': 'Bài tập 5.1; nộp, bản "cuối"',
    'courseName': 'Mobile',
    // 23:59 Asia/Ho_Chi_Minh = 16:59Z
    'start': '2026-11-17T16:59:00Z',
    'end': null,
    'allDay': false,
    'done': false,
    'moodlePath': '/mod/assign/view.php?id=91',
    'courseModuleId': 91,
  },
  {
    'uid': 'plan-7@dlu-lms-group',
    'type': 'plan',
    'title': 'Ôn chương 3',
    'courseName': 'Mobile',
    'start': '2026-11-15T17:00:00Z',
    'date': '2026-11-16',
    'allDay': true,
    'minutes': 45,
    'done': false,
  },
  {
    'uid': 'attendance-55@dlu-lms-group',
    'type': 'attendance',
    'title': 'Điểm danh: lớp',
    'start': '2026-11-18T00:30:00Z',
    'end': '2026-11-18T02:00:00Z',
    'allDay': false,
    'done': false,
  },
  {
    'uid': 'deadline-quiz-2@dlu-lms-group',
    'type': 'deadline',
    'title': 'Quiz đã làm',
    'start': '2026-11-20T16:59:00Z',
    'allDay': false,
    'done': true,
  },
];

void main() {
  group('ics', () {
    test('escaping and UTF-8 safe folding', () {
      expect(
        icsEscape(
          r'a;b,c\d'
          '\nđ',
        ),
        r'a\;b\,c\\d\nđ',
      );
      final long = 'SUMMARY:${'Nguyễn ' * 20}';
      final folded = icsFold(long);
      for (final line in folded.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
      expect(folded.replaceAll('\r\n ', ''), long);
    });

    test(
      'UTC times, all-day dates, stable uid, alarm, done items left out',
      () {
        final events = [for (final e in _events) CalendarEvent.fromJson(e)];
        expect(events[1].start, DateTime(2026, 11, 16));
        final ics = buildIcs(
          icsEventsFor(events, hoursBefore: 6),
          now: DateTime.utc(2026, 11, 10, 2),
        );
        expect(ics, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
        expect(ics, endsWith('END:VCALENDAR\r\n'));
        expect('BEGIN:VEVENT'.allMatches(ics).length, 3);
        expect(ics, contains('UID:deadline-assign-1@dlu-lms-group'));
        expect(ics, contains('DTSTART:20261117T165900Z'));
        expect(
          ics,
          contains(r'SUMMARY:Hạn nộp: Bài tập 5.1\; nộp\, bản "cuối"'),
        );
        expect(ics, contains('TRIGGER:-PT360M'));
        expect('BEGIN:VALARM'.allMatches(ics).length, 1);
        expect(
          ics,
          contains('DTSTART;VALUE=DATE:20261116\r\nDTEND;VALUE=DATE:20261117'),
        );
        expect(
          ics,
          contains('DTSTART:20261118T003000Z\r\nDTEND:20261118T020000Z'),
        );
        expect(ics, isNot(contains('Quiz đã làm')));
        expect(ics, contains('DTSTAMP:20261110T020000Z'));
        final again = buildIcs(
          icsEventsFor(events, hoursBefore: 6),
          now: DateTime.utc(2026, 11, 10, 2),
        );
        expect(again, ics);
      },
    );
  });

  testWidgets('month grid, day list, month navigation, export with N7 hours', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    final api = testApi(
      client: MockClient((r) async {
        calls.add('${r.url.path}?${r.url.query}');
        if (r.url.path.endsWith('/notification-preferences')) {
          return _json({'pushEnabled': true, 'reminderBeforeHours': 12});
        }
        return _json({
          'events': r.url.query.contains('2026-11-01') ? _events : [],
        });
      }),
    );
    List<int>? shared;
    String? name;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          api: api,
          now: () => DateTime(2026, 11, 16, 9),
          share: (b, n) async {
            shared = b;
            name = n;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.first, contains('from=2026-11-01&to=2026-11-30'));
    expect(find.text('Tháng 11/2026'), findsOneWidget);
    expect(find.text('Ôn chương 3'), findsOneWidget); // today = 16/11
    await tester.tap(find.byKey(const Key('calendar-day-18')));
    await tester.pump();
    expect(find.text('Điểm danh: lớp'), findsOneWidget);
    expect(find.textContaining('07:30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-export')));
    await tester.pumpAndSettle();
    expect(name, 'lich-hoc-2026-11.ics');
    expect(utf8.decode(shared!), contains('TRIGGER:-PT720M'));

    await tester.tap(find.byKey(const Key('calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 12/2026'), findsOneWidget);
    expect(calls.last, contains('from=2026-12-01&to=2026-12-31'));
    expect(find.text('Không có việc trong ngày'), findsOneWidget);
  });

  test('week helpers: Monday start, month and year boundaries', () {
    expect(mondayOf(DateTime(2026, 11, 16, 9)), DateTime(2026, 11, 16));
    expect(mondayOf(DateTime(2026, 11, 22, 23, 59)), DateTime(2026, 11, 16));
    expect(mondayOf(DateTime(2026, 12, 2)), DateTime(2026, 11, 30));
    expect(weekTitle(DateTime(2026, 11, 30)), 'Tuần 30/11 – 6/12/2026');
    expect(weekTitle(DateTime(2026, 12, 28)), 'Tuần 28/12 – 3/1/2027');
  });

  testWidgets('week agenda: 7 days, crosses the month, export names the week', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    final api = testApi(
      client: MockClient((r) async {
        calls.add(r.url.query);
        if (r.url.path.endsWith('/notification-preferences')) {
          return _json({'pushEnabled': false});
        }
        return _json({
          'events': r.url.query.contains('from=2026-11-16') ? _events : [],
        });
      }),
    );
    String? name;
    String? ics;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          api: api,
          now: () => DateTime(2026, 11, 16, 9),
          share: (b, n) async {
            name = n;
            ics = utf8.decode(b);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuần'));
    await tester.pumpAndSettle();
    expect(calls.last, contains('from=2026-11-16&to=2026-11-22'));
    expect(find.text('Tuần 16/11 – 22/11/2026'), findsOneWidget);
    expect(find.text('T2 16/11 · Hôm nay'), findsOneWidget);
    for (var d = 16; d <= 22; d++) {
      expect(find.byKey(Key('calendar-week-day-$d')), findsOneWidget);
    }
    // Every event of the week is listed under its own day; 3 days are empty.
    expect(find.text('Ôn chương 3'), findsOneWidget);
    expect(find.text('Điểm danh: lớp'), findsOneWidget);
    expect(find.text('Quiz đã làm'), findsOneWidget);
    expect(find.text('Không có việc'), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('calendar-export')));
    await tester.pumpAndSettle();
    expect(name, 'lich-hoc-tuan-2026-11-16.ics');
    expect(ics, isNot(contains('TRIGGER')));

    await tester.tap(find.byKey(const Key('calendar-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar-next')));
    await tester.pumpAndSettle();
    expect(calls.last, contains('from=2026-11-30&to=2026-12-06'));
    expect(find.text('Tuần 30/11 – 6/12/2026'), findsOneWidget);
    expect(find.text('Không có việc'), findsNWidgets(7));
    // Empty week: nothing to export.
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('calendar-export')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Tháng'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 11/2026'), findsOneWidget);
  });
}
