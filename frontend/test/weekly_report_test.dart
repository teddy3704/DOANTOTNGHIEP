import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/student/weekly_report_card.dart';

import 'support/mock_api.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('only real rows, trend arrows, streak, share PNG', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient(
        (r) async => _json({
          'weekStart': '2026-11-16',
          'weekEnd': '2026-11-22',
          'rows': [
            {
              'key': 'plan',
              'label': 'Việc trong kế hoạch đã xong',
              'value': 1,
              'previous': 2,
              'trend': -1,
              'total': 2,
            },
            {
              'key': 'minutes',
              'label': 'Phút học tập trung',
              'value': 75,
              'previous': 0,
              'trend': 1,
            },
          ],
          'streakDays': 3,
        }),
      ),
    );
    Uint8List? png;
    String? name;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyReportCard(
            api: api,
            share: (bytes, n) async {
              png = bytes;
              name = n;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('16/11 – 22/11'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(find.byKey(const Key('weekly-cards')), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.text('Chuỗi 3 ngày học liên tiếp'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('weekly-share')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(name, 'tuan-cua-ban-20261116.png');
    expect(png!.sublist(1, 4), utf8.encode('PNG'));
  });

  testWidgets('no data at all or an error hides the card', (tester) async {
    for (final response in [
      _json({'weekStart': '2026-11-16', 'weekEnd': '2026-11-22', 'rows': []}),
      http.Response('', 500),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyReportCard(
              key: UniqueKey(),
              api: testApi(client: MockClient((r) async => response)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('weekly-report-card')), findsNothing);
    }
  });
}
