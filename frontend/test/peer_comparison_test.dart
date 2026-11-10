import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/peer_comparison.dart';
import 'package:lms_mobile_app/widgets/peer_comparison_widgets.dart';

import 'support/mock_api.dart';

final visible = <String, dynamic>{
  'courseId': 3000015,
  'minClassSize': 5,
  'progress': {
    'classSize': 15,
    'suppressed': false,
    'median': 55.0,
    'histogram': [
      for (final c in [3, 2, 3, 4, 3]) {'from': 0, 'to': 20, 'count': c},
    ],
    'mine': 65.0,
    'percentBelow': 64.3,
    'myBin': 3,
  },
  'grade': {'classSize': 4, 'suppressed': true, 'reason': 'CLASS_TOO_SMALL'},
};

void main() {
  test('Conclusions use only aggregates and explain suppression', () {
    final p = PeerComparison.fromJson(visible);
    expect(
      p.progress.conclusion('Tiến độ'),
      'Tiến độ của bạn 65,0%, cao hơn 64,3% bạn cùng lớp · trung vị lớp 55,0%',
    );
    expect(p.grade.suppressed, isTrue);
    expect(p.grade.conclusion('Điểm'), 'Lớp quá nhỏ để so sánh ẩn danh');
  });

  testWidgets('Card shows the chart, then the suppressed message for grades', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode(visible),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeerComparisonCard(api: api, courseId: 3000015),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('cao hơn 64,3%'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);

    await tester.tap(find.text('Điểm TB'));
    await tester.pumpAndSettle();
    expect(find.text('Lớp quá nhỏ để so sánh ẩn danh'), findsOneWidget);
    expect(find.textContaining('hiện có 4'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });
}
