// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lexi_central/main.dart';

void main() {
  testWidgets('Lexi Central app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: LexiCentralApp(),
      ),
    );

    // Wait for loading screen to complete
    await tester.pump(const Duration(seconds: 4));

    // Verify that the home screen is displayed
    expect(find.text('Welcome to Lexi Central!'), findsOneWidget);
  });
}
