// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:revguard_ai/main.dart';

void main() {
  testWidgets('RevGuard AI initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RevGuardApp());

    // Verify that the home screen is displayed with Title
    expect(find.text('REVGUARD AI'), findsOneWidget);
  });
}
