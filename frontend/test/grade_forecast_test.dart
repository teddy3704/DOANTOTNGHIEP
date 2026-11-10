import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/grade_forecast.dart';
import 'package:lms_mobile_app/screens/student/grade_forecast_screen.dart';

import 'support/mock_api.dart';

// Two graded items (A: 80 → w .25, B: 40 → w .25) and two ungraded (w .25 each).
final sample = <String, dynamic>{
  'current': 60.0,
  'passPercent': 50.0,
  'passSource': 'items',
  'approximation': false,
  'gradedContribution': 30.0,
  'remainingWeight': 0.5,
  'items': [
    {'gradeItemId': 1, 'name': 'Bài A', 'scorePercent': 80.0, 'weight': 0.25},
    {'gradeItemId': 2, 'name': 'Bài B', 'scorePercent': 40.0, 'weight': 0.25},
    {'gradeItemId': 3, 'name': 'Bài C', 'scorePercent': null, 'weight': 0.25},
    {'gradeItemId': 4, 'name': 'Bài D', 'scorePercent': null, 'weight': 0.25},
  ],
};

void main() {
  test('Need, outcome and projection use the server weights', () {
    final f = GradeForecast.fromJson(sample);
    expect(f.remaining.length, 2);
    expect(f.needFor(50), closeTo(40, 1e-9));
    expect(f.outcomeFor(50), ForecastOutcome.feasible);
    expect(f.outcomeFor(20), ForecastOutcome.achieved);
    expect(f.outcomeFor(90), ForecastOutcome.notFeasible);
    expect(f.bestCase, closeTo(80, 1e-9));
    expect(f.projected({3: 100, 4: 0}), closeTo(55, 1e-9));
    expect(
      f.conclusion(50),
      'Bạn cần trung bình 40,0% ở 2 bài còn lại để đạt 50,0%.',
    );
    expect(
      f.conclusion(90),
      'Không thể đạt 90,0%: kể cả được 100% ở 2 bài còn lại, tổng tối đa là 80,0%.',
    );
  });

  test('Fully graded course reports the final grade', () {
    final f = GradeForecast.fromJson({
      ...sample,
      'remainingWeight': 0.0,
      'gradedContribution': 55.0,
      'items': [
        {'gradeItemId': 1, 'name': 'A', 'scorePercent': 55.0, 'weight': 1.0},
      ],
    });
    expect(f.outcomeFor(50), ForecastOutcome.noRemaining);
    expect(f.needFor(50), isNull);
    expect(f.conclusion(50), contains('đạt mục tiêu 50,0%'));
    expect(f.conclusion(60), contains('chưa đạt mục tiêu 60,0%'));
  });

  testWidgets('Dragging a slider updates the projected grade; goal saves', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? goalBody;
    final api = testApi(
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/goals')) {
          goalBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'id': 1, 'goal_type': 'target_grade'}),
            200,
          );
        }
        return http.Response(
          jsonEncode(sample),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: GradeForecastScreen(api: api, courseId: 13, courseName: 'Demo'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('60,0%'), findsOneWidget);
    expect(
      find.text('Bạn cần trung bình 40,0% ở 2 bài còn lại để đạt 50,0%.'),
      findsOneWidget,
    );
    // Sliders start at the average still needed, so the projection equals the target.
    expect(find.text('Điểm tổng kết dự kiến: 50,0%'), findsOneWidget);

    final slider = find.byKey(const Key('forecast-slider-3'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final rect = tester.getRect(slider);
    // Drag the thumb from its current spot to the far right of the track.
    final thumbX = rect.left + 24 + (rect.width - 48) * 0.4;
    final gesture = await tester.startGesture(Offset(thumbX, rect.center.dy));
    await gesture.moveTo(Offset(rect.right - 1, rect.center.dy));
    await gesture.up();
    await tester.pumpAndSettle();
    // Item 3 moves to 100: 30 + .25·100 + .25·40 = 65.
    await tester.scrollUntilVisible(
      find.byKey(const Key('forecast-projected')),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('forecast-projected'))).data,
      'Điểm tổng kết dự kiến: 65,0%',
    );

    final chip80 = find.widgetWithText(ChoiceChip, '80%');
    await tester.scrollUntilVisible(
      chip80,
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.tap(chip80);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('forecast-conclusion'))).data,
      'Bạn cần trung bình 100,0% ở 2 bài còn lại để đạt 80,0%.',
    );

    final save = find.textContaining('Lưu làm mục tiêu');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(goalBody, {
      'goal_type': 'target_grade',
      'target_value': 80.0,
      'course_id': 13,
    });
  });

  testWidgets('Course without gradable items shows an explained empty state', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({...sample, 'items': [], 'current': null}),
          200,
        ),
      ),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: GradeForecastScreen(api: api, courseId: 13, courseName: 'Demo'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Khóa học chưa có hoạt động tính điểm'), findsOneWidget);
  });
}
