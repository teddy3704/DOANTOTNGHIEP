import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/study_plan.dart';
import 'package:lms_mobile_app/screens/student/study_plan_screen.dart';

import 'support/mock_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _item(
  int id,
  String date,
  String title,
  int minutes, {
  String status = 'planned',
  String type = 'quiz',
}) => {
  'id': id,
  'date': date,
  'courseId': 13,
  'sourceType': type,
  'sourceId': id,
  'title': title,
  'minutes': minutes,
  'status': status,
};

Map<String, dynamic> _week({
  int budget = 60,
  bool empty = false,
  List<Map<String, dynamic>> overloaded = const [],
}) => {
  'from': '2026-11-16',
  'to': '2026-11-22',
  'today': '2026-11-16',
  'dailyMinutes': budget,
  'days': [
    {
      'date': '2026-11-16',
      'items': empty
          ? []
          : [
              _item(
                1,
                '2026-11-16',
                'Bài tập 1 (phần 1/2)',
                45,
                type: 'assign',
              ),
              _item(2, '2026-11-16', 'Ôn 4 thẻ ghi nhớ', 6, type: 'flashcards'),
            ],
    },
    {
      'date': '2026-11-17',
      'items': empty ? [] : [_item(3, '2026-11-17', 'Quiz 3', 45)],
    },
    for (var d = 18; d <= 22; d++) {'date': '2026-11-$d', 'items': []},
  ],
  'overloaded': overloaded,
  'deferred': 0,
};

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  test('model: minutes per day, replace, empty', () {
    final w = StudyPlanWeek.fromJson(_week());
    final mon = w.dayOf(DateTime(2026, 11, 16))!;
    expect(mon.plannedMinutes, 51);
    expect(mon.openCount, 2);
    final done = w.replace(mon.items.first.withStatus(PlanStatus.done));
    expect(done.dayOf(DateTime(2026, 11, 16))!.doneMinutes, 45);
    expect(StudyPlanWeek.fromJson(_week(empty: true)).isEmpty, isTrue);
    expect(
      () => StudyPlanWeek.fromJson({'today': '2026-11-16'}),
      throwsFormatException,
    );
  });

  test('API paths and bodies', () async {
    final calls = <String>[];
    final api = testApi(
      client: MockClient((r) async {
        calls.add(
          '${r.method} ${r.url.path}${r.url.hasQuery ? '?${r.url.query}' : ''} ${r.body}',
        );
        if (r.method == 'PUT') {
          return _json(_item(3, '2026-11-17', 'Quiz 3', 45, status: 'done'));
        }
        return _json(_week());
      }),
    );
    await api.getStudyPlan(
      from: DateTime(2026, 11, 16),
      to: DateTime(2026, 11, 22),
    );
    await api.generateStudyPlan(90);
    final item = await api.setPlanItemStatus(3, PlanStatus.done);
    expect(item.status, PlanStatus.done);
    expect(calls, [
      'GET /api/v1/dev/students/205/study-plan?from=2026-11-16&to=2026-11-22 ',
      'POST /api/v1/dev/students/205/study-plan/generate {"dailyMinutes":90}',
      'PUT /api/v1/dev/students/205/study-plan/items/3/status {"status":"done"}',
    ]);
  });

  testWidgets('generate with chosen budget, overload warning, day strip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    String? body;
    final api = testApi(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          body = r.body;
          return _json(
            _week(
              budget: 90,
              overloaded: [
                {'title': 'Bài tập lớn', 'due': '2026-11-18', 'minutes': 90},
              ],
            ),
          );
        }
        return _json(_week(empty: true));
      }),
    );
    await tester.pumpWidget(_app(StudyPlanScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có kế hoạch'), findsOneWidget);
    expect(find.text('Lập kế hoạch 60 phút/ngày'), findsOneWidget);
    await tester.tap(find.text('90′'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-generate')));
    await tester.pumpAndSettle();
    expect(body, '{"dailyMinutes":90}');
    expect(find.text('Bài tập 1 (phần 1/2)'), findsOneWidget);
    expect(find.text('51/90 phút'), findsOneWidget);
    expect(find.text('Quá tải: 1 việc không kịp trước hạn'), findsOneWidget);
    expect(find.text('• Bài tập lớn (hạn 18/11)'), findsOneWidget);
    await tester.tap(find.text('T3'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz 3'), findsOneWidget);
    expect(find.text('Bài tập 1 (phần 1/2)'), findsNothing);
  });

  testWidgets('check off saves; failure reverts', (tester) async {
    var fail = false;
    final puts = <String>[];
    final api = testApi(
      client: MockClient((r) async {
        if (r.method == 'PUT') {
          puts.add(r.body);
          if (fail) return _json({'status': 404}, 404);
          return _json(
            _item(
              2,
              '2026-11-16',
              'Ôn 4 thẻ ghi nhớ',
              6,
              status: 'done',
              type: 'flashcards',
            ),
          );
        }
        return _json(_week());
      }),
    );
    await tester.pumpWidget(_app(StudyPlanScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-item-2')));
    await tester.pumpAndSettle();
    expect(puts, ['{"status":"done"}']);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('plan-item-2')))
          .value,
      isTrue,
    );
    fail = true;
    await tester.tap(find.byKey(const Key('plan-item-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('plan-item-1')))
          .value,
      isFalse,
    );
    expect(find.textContaining('Chưa tìm thấy dữ liệu'), findsOneWidget);
  });

  testWidgets('dashboard card', (tester) async {
    for (final (week, text) in [
      (_week(), 'Hôm nay: 2 việc · 51 phút'),
      (_week(empty: true), 'Lập kế hoạch học tuần'),
    ]) {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: TodayPlanCard(
              key: UniqueKey(),
              api: testApi(client: MockClient((_) async => _json(week))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
    }
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: TodayPlanCard(
            key: UniqueKey(),
            api: testApi(
              client: MockClient((_) async => http.Response('', 500)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('today-plan-card')), findsNothing);
  });
}
