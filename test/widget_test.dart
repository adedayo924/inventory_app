import 'package:flutter_test/flutter_test.dart';
import 'package:jims/main.dart';

void main() {
  testWidgets('JimsApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JimsApp());

    // Verify app renders
    expect(find.byType(JimsApp), findsOneWidget);
  });
}
