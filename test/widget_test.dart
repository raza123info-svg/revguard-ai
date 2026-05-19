import 'package:flutter_test/flutter_test.dart';
import 'package:revguard_ai/main.dart';

void main() {
  testWidgets('App boot and title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RevGuardAIApp());

    // Verify that the title RevGuard AI is found in the widget tree
    expect(find.text('REVGUARD AI'), findsOneWidget);
  });
}
