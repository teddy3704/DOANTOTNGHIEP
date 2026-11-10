import 'package:flutter_test/flutter_test.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_analytics_sections.dart';

void main() {
  test('V2-N15 heat levels match the server rule', () {
    for (final (events, max, level) in [
      (0, 9, 0),
      (1, 0, 0),
      (1, 100, 1),
      (25, 100, 1),
      (26, 100, 2),
      (50, 100, 2),
      (51, 100, 3),
      (75, 100, 3),
      (76, 100, 4),
      (100, 100, 4),
      (6, 9, 3),
      (4, 9, 2),
    ]) {
      expect(heatLevel(events, max), level, reason: '$events/$max');
    }
  });
}
