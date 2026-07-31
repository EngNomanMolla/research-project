import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:research_project/main.dart';

void main() {
  testWidgets('Dr. Kache Home Screen Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title is displayed.
    expect(find.text('ডাক্তার কাছে (Dr. Kache)'), findsOneWidget);

    // Verify that the start button is displayed.
    expect(find.text('লক্ষণ যাচাই করুন (শুরু করুন)'), findsOneWidget);
  });
}
