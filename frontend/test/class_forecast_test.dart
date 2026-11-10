import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/class_forecast.dart';
import 'package:lms_mobile_app/screens/teacher/class_forecast_section.dart';

import 'support/mock_api.dart';

final data = <String, dynamic>{
  'passPercent': 50.0,
  'counts': {
    'NOT_FEASIBLE': 1,
    'HIGH_RISK': 0,
    'EFFORT': 0,
    'SAFE': 1,
    'SURE_PASS': 1,
    'NO_DATA': 0,
  },
  'students': [
    {
      'userid': 203,
      'fullname': 'Chi',
      'band': 'NOT_FEASIBLE',
      'current': 0.0,
      'need': 200.0,
      'bestCase': 25.0,
      'gradedCount': 3,
      'remainingCount': 1,
    },
    {
      'userid': 202,
      'fullname': 'Binh',
      'band': 'SAFE',
      'current': 40.0,
      'need': 60.0,
      'bestCase': 70.0,
      'gradedCount': 2,
      'remainingCount': 2,
    },
    {
      'userid': 201,
      'fullname': 'An',
      'band': 'SURE_PASS',
      'current': 100.0,
      'need': -100.0,
      'bestCase': 100.0,
      'gradedCount': 2,
      'remainingCount': 2,
    },
  ],
};

void main() {
  test('Band explanations carry the student number', () {
    expect(PassBand.safe.explain(60), 'Cần trung bình 60,0% ở các bài còn lại');
    expect(PassBand.parse('???'), PassBand.noData);
  });

  testWidgets('Counts filter the list and a row opens the student', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = testApi(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.dispose);
    int? opened;
    StudentPassForecast? reminded;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassForecastSection(
              api: api,
              courseId: 13,
              onOpenStudent: (id, _) => opened = id,
              onRemindOne: (s) => reminded = s,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không còn khả thi (1)'), findsOneWidget);
    expect(find.text('An toàn (1)'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(
      find.text('An toàn · Cần trung bình 60,0% ở các bài còn lại'),
      findsOneWidget,
    );
    // Sure-pass students do not get a reminder button.
    expect(find.text('Nhắc riêng'), findsNWidgets(2));

    await tester.tap(find.text('An toàn (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Chi'), findsNothing);
    expect(find.text('Binh'), findsOneWidget);

    await tester.tap(find.text('Binh'));
    expect(opened, 202);
    await tester.tap(find.text('Nhắc riêng'));
    expect(reminded?.userId, 202);
  });
}
