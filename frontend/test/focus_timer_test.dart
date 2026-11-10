import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/learning_goal.dart';
import 'package:lms_mobile_app/models/study_session.dart';
import 'package:lms_mobile_app/screens/student/focus_timer_screen.dart';

import 'support/mock_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _summary() => {
  'from': '2026-11-12',
  'to': '2026-11-18',
  'totalMinutes': 75,
  'sessions': 3,
  'days': [
    for (var d = 12; d <= 18; d++)
      {
        'date': '2026-11-$d',
        'minutes': d == 18 ? 50 : (d == 16 ? 25 : 0),
        'sessions': d == 18 ? 2 : (d == 16 ? 1 : 0),
      },
  ],
  'courses': [
    {'courseId': 13, 'courseName': 'Software Testing', 'minutes': 75},
  ],
};

Map<String, dynamic> _plan() => {
  'today': '2026-11-18',
  'dailyMinutes': 60,
  'days': [
    {
      'date': '2026-11-18',
      'items': [
        {
          'id': 9,
          'date': '2026-11-18',
          'courseId': 13,
          'sourceType': 'quiz',
          'title': 'Quiz 3',
          'minutes': 45,
          'status': 'planned',
        },
      ],
    },
  ],
};

void main() {
  test('focus minutes come from timestamps and are capped', () {
    final s = DateTime(2026, 11, 18, 9);
    expect(
      focusMinutes(s, s.add(const Duration(minutes: 25, seconds: 40)), 25),
      25,
    );
    expect(focusMinutes(s, s.add(const Duration(minutes: 70)), 50), 50);
    expect(
      focusMinutes(s, s.add(const Duration(minutes: 12, seconds: 59)), 25),
      12,
    );
    expect(focusMinutes(s, s.subtract(const Duration(minutes: 1)), 25), 0);
  });

  test('summary model and API paths', () async {
    final calls = <String>[];
    final api = testApi(
      client: MockClient((r) async {
        calls.add(
          '${r.method} ${r.url.path}${r.url.hasQuery ? '?${r.url.query}' : ''} ${r.body}',
        );
        return r.method == 'POST' ? _json({'id': 1}) : _json(_summary());
      }),
    );
    final s = await api.getStudySummary(
      from: DateTime(2026, 11, 12),
      to: DateTime(2026, 11, 18),
    );
    expect(s.totalMinutes, 75);
    expect(s.minutesOn(DateTime(2026, 11, 18)), 50);
    expect(s.courses.single.courseName, 'Software Testing');
    await api.recordStudySession(
      startedAt: DateTime.utc(2026, 11, 18, 2, 0),
      endedAt: DateTime.utc(2026, 11, 18, 2, 25),
      focusMinutes: 25,
      planItemId: 9,
      markPlanItemDone: true,
    );
    expect(
      calls[0],
      startsWith(
        'GET /api/v1/dev/students/205/study-sessions/summary?from=2026-11-12&to=2026-11-18',
      ),
    );
    expect(
      calls[1],
      startsWith('POST /api/v1/dev/students/205/study-sessions '),
    );
    final body = jsonDecode(calls[1].split(' ').skip(2).join(' ')) as Map;
    expect(body['focusMinutes'], 25);
    expect(body['planItemId'], 9);
    expect(body['markPlanItemDone'], true);
    expect(body.containsKey('courseId'), isFalse);
    expect(body['startedAt'], '2026-11-18T02:00:00.000Z');
  });

  test('study minutes is an available goal type', () {
    expect(GoalType.parse('study_minutes'), GoalType.studyMinutes);
    expect(GoalType.studyMinutes.unit, 'phút');
  });

  testWidgets('full session with a fake clock saves and marks the plan item', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 18, 9, 0, 0);
    final posts = <Map<String, dynamic>>[];
    final api = testApi(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          posts.add(jsonDecode(r.body) as Map<String, dynamic>);
          return _json({'id': 1});
        }
        if (r.url.path.endsWith('/study-plan')) return _json(_plan());
        if (r.url.path.endsWith('/courses')) {
          return _json([
            {'courseid': 13, 'course_name': 'Software Testing'},
          ]);
        }
        return http.Response('', 404);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTimerScreen(api: api, now: () => now, initialPlanItemId: 9),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focus-mark-done')), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-start')));
    await tester.pump();
    expect(find.text('25:00'), findsOneWidget);

    // App in the background for 10 min: the display jumps, it does not count ticks.
    now = now.add(const Duration(minutes: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('15:00'), findsOneWidget);

    now = now.add(const Duration(minutes: 15, seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(posts, hasLength(1));
    expect(posts.single['focusMinutes'], 25);
    expect(posts.single['planItemId'], 9);
    expect(posts.single['courseId'], 13);
    expect(posts.single['markPlanItemDone'], true);
    expect(find.text('Nghỉ ngắn'), findsOneWidget);
    expect(find.text('Đã lưu 1 phiên · 25 phút'), findsOneWidget);

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Hết giờ nghỉ'), findsOneWidget);
  });

  testWidgets('stopping early saves elapsed minutes; failure can be retried', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 18, 9, 0, 0);
    var fail = true;
    final posts = <Map<String, dynamic>>[];
    final api = testApi(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          if (fail) return http.Response('', 500);
          posts.add(jsonDecode(r.body) as Map<String, dynamic>);
          return _json({'id': 2});
        }
        return http.Response('', 404);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTimerScreen(api: api, now: () => now),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('50/10'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('focus-start')));
    await tester.pump();
    expect(find.text('50:00'), findsOneWidget);
    now = now.add(const Duration(minutes: 18, seconds: 30));
    await tester.tap(find.byKey(const Key('focus-stop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focus-retry')), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const Key('focus-retry')));
    await tester.pump();
    expect(posts.single['focusMinutes'], 18);
    expect(posts.single.containsKey('planItemId'), isFalse);
    expect(find.text('Đã lưu 1 phiên · 18 phút'), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focus-start')), findsOneWidget);
  });

  testWidgets('under one minute is not saved; dashboard card and chart', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 18, 9);
    var posts = 0;
    final api = testApi(
      client: MockClient((r) async {
        if (r.method == 'POST') posts++;
        if (r.url.path.endsWith('/summary')) return _json(_summary());
        return http.Response('', 404);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTimerScreen(api: api, now: () => now),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focus-start')));
    await tester.pump();
    now = now.add(const Duration(seconds: 40));
    await tester.tap(find.byKey(const Key('focus-stop')));
    await tester.pumpAndSettle();
    expect(posts, 0);
    expect(find.text('Phiên dưới 1 phút nên không được lưu'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              FocusEntryCard(api: api),
              StudyMinutesChart(api: api),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('7 ngày 75 phút'), findsOneWidget);
    expect(find.text('Phút học 7 ngày · 75 phút'), findsOneWidget);
  });

  testWidgets(
    'dashboard focus card refreshes after a session saved elsewhere',
    (tester) async {
      var total = 0;
      final api = testApi(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            total += 25;
            return _json({'id': 1});
          }
          return _json({..._summary(), 'totalMinutes': total});
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FocusEntryCard(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('7 ngày 0 phút'), findsOneWidget);
      await api.recordStudySession(
        startedAt: DateTime.utc(2026, 11, 18, 2),
        endedAt: DateTime.utc(2026, 11, 18, 2, 25),
        focusMinutes: 25,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('7 ngày 25 phút'), findsOneWidget);
    },
  );
}
