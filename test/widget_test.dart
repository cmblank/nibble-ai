// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nibble_ai/screens/main_app.dart';
import 'package:nibble_ai/utils/profile_storage.dart';

void main() {
  testWidgets('Nibble app loads with bottom navigation', (WidgetTester tester) async {
  // Mock SharedPreferences and ensure a stored profile exists so MainApp shows tabs
  SharedPreferences.setMockInitialValues({});
  await ProfileStorage.saveProfile({'name': 'Test User'});
  // Build our app and trigger a frame.
  await tester.pumpWidget(const MaterialApp(home: MainApp()));
  await tester.pumpAndSettle();

  // Verify the NavigationBar with expected tabs (labels may render multiple times in M3)
  expect(find.text('Home'), findsWidgets);
  expect(find.text('Recipes'), findsWidgets);
  expect(find.text('Pantry'), findsWidgets);
  expect(find.text('Planning'), findsWidgets);
  expect(find.text('More'), findsWidgets);

  // Verify we start on the home screen and it's the M3 NavigationBar
  expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Navigation between tabs works', (WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await ProfileStorage.saveProfile({'name': 'Test User'});
  await tester.pumpWidget(const MaterialApp(home: MainApp()));
  await tester.pumpAndSettle();

  // Tap on Pantry tab
  await tester.tap(find.text('Pantry'));
  await tester.pumpAndSettle();

  // Pantry tab selected (UI content varies; presence is enough for this smoke test)

  // Tap on Planning tab (placeholder shows Cook screen for now)
  await tester.tap(find.text('Planning'));
  await tester.pumpAndSettle();

  // Verify we navigated to the planning placeholder (Cook screen)
  expect(find.text('Cook Screen'), findsOneWidget);
  });
}
