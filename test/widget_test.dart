// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Nibble app loads with bottom navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app has the bottom navigation bar with expected tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Chef AI'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify we start on the home screen
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('Navigation between tabs works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap on Pantry tab
    await tester.tap(find.text('Pantry'));
    await tester.pump();

    // Verify we navigated to pantry screen
    expect(find.text('Pantry Screen'), findsOneWidget);

    // Tap on Cook tab
    await tester.tap(find.text('Cook'));
    await tester.pump();

    // Verify we navigated to cook screen
    expect(find.text('Cook Screen'), findsOneWidget);
  });
}
