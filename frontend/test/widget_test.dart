import 'package:flutter_test/flutter_test.dart';
import 'package:lms_mobile_app/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LMSApp());
    expect(find.text('Hỗ trợ học tập LMS'), findsOneWidget);
  });
}
