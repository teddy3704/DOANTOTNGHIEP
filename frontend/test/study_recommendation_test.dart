import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/study_recommendation.dart';
import 'package:lms_mobile_app/widgets/study_recommendation_widgets.dart';

import 'support/mock_api.dart';

final course = <String, dynamic>{
  'courseId': 3000015,
  'courseName': 'Hỗ trợ học tập số',
  'passPercent': 50.0,
  'chapters': [
    {
      'sectionNumber': 3,
      'sectionName': 'Chương 3',
      'severity': 30.0,
      'average': 20.0,
      'classAverage': null,
      'overdueCount': 0,
      'reasons': ['Trung bình chương 20,0% dưới ngưỡng qua 50,0%'],
      'suggestions': [
        {
          'activityName': 'Slide chương 3',
          'activityType': 'resource',
          'courseModuleId': 11,
          'moodlePath': '/mod/resource/view.php?id=11',
          'reason': 'Chưa hoàn thành trong chương này',
        },
        {
          'activityName': 'MVP3 - Quiz 3.1',
          'activityType': 'quiz',
          'courseModuleId': 12,
          'moodlePath': '/mod/quiz/view.php?id=12',
          'reason': 'MVP3 - Quiz 3.1: 0,0% (lớp 36,5%)',
        },
      ],
    },
  ],
};

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: ListView(children: [child])),
);

void main() {
  test('Course response keeps course id on every chapter', () {
    final list = WeakChapter.listFrom(course);
    expect(list.single.courseId, 3000015);
    expect(list.single.suggestions.length, 2);
  });

  testWidgets('Course section lists reasons and suggestion actions', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode(course),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      host(StudyRecommendationsSection(api: api, courseId: 3000015)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nên ôn lại'), findsOneWidget);
    expect(
      find.text('Trung bình chương 20,0% dưới ngưỡng qua 50,0%'),
      findsOneWidget,
    );
    expect(find.text('MVP3 - Quiz 3.1: 0,0% (lớp 36,5%)'), findsOneWidget);
    expect(find.text('Tạo thẻ ghi nhớ'), findsNWidgets(2));
    expect(find.text('Mở trên LMS'), findsNWidgets(2));
  });

  testWidgets('Empty course result is explained; empty Home result hides', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient(
        (r) async =>
            http.Response(jsonEncode({'total': 0, 'chapters': []}), 200),
      ),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(host(StudyRecommendationsSection(api: api)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('study-recommendations')), findsNothing);

    await tester.pumpWidget(
      host(StudyRecommendationsSection(api: api, courseId: 13)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa thấy chương nào cần ôn lại'), findsOneWidget);
  });
}
