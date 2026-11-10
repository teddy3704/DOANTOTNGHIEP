import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/student/achievements_screen.dart';

import 'support/mock_api.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _badges = {
  'achieved': 2,
  'badges': [
    {
      'key': 'on_time',
      'title': 'Đúng hạn 3 lần liền',
      'description': 'd',
      'achieved': false,
      'achievedOn': null,
      'progress': 2,
      'target': 3,
    },
    {
      'key': 'minutes_300',
      'title': '300 phút tập trung',
      'description': 'd',
      'achieved': true,
      'achievedOn': '2026-11-12',
      'progress': 300,
      'target': 300,
    },
    {
      'key': 'goal',
      'title': 'Đạt mục tiêu',
      'description': 'd',
      'achieved': true,
      'achievedOn': null,
      'progress': 1,
      'target': 1,
    },
  ],
};

void main() {
  testWidgets(
    'achieved first with date or plain "Đã đạt", others with progress; entry opens screen',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = testApi(client: MockClient((r) async => _json(_badges)));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AchievementsEntry(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã đạt 2/3 huy hiệu'), findsOneWidget);
      await tester.tap(find.byKey(const Key('achievements-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Đã đạt 2/3'), findsOneWidget);
      final minutes = tester.getTopLeft(
        find.byKey(const Key('badge-minutes_300')),
      );
      final onTime = tester.getTopLeft(find.byKey(const Key('badge-on_time')));
      expect(minutes.dy, lessThan(onTime.dy));
      expect(find.text('Đạt ngày 12/11/2026'), findsOneWidget);
      expect(find.text('Đã đạt'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
    },
  );

  testWidgets('entry hidden on error', (tester) async {
    final api = testApi(
      client: MockClient((r) async => http.Response('', 500)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AchievementsEntry(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('achievements-entry')), findsNothing);
  });
}
