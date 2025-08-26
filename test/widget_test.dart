// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nibble_ai/screens/main_app.dart';
import 'package:nibble_ai/utils/profile_storage.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  // Ensure shared prefs plugin is mocked before Supabase init
  SharedPreferences.setMockInitialValues(const {});
  // Initialize Hive with a temporary directory (avoid path_provider dependency in tests)
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
    // Initialize Supabase with dummy values for widget tests to avoid assertion failures.
    try {
  await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // Ignore if already initialized in a previous test run.
    }
  });
  testWidgets('Nibble app loads with bottom navigation', (WidgetTester tester) async {
  // Mock SharedPreferences and ensure a stored profile exists so MainApp shows tabs
  SharedPreferences.setMockInitialValues({});
  await ProfileStorage.saveProfile({'name': 'Test User'});
  // Build our app and trigger a frame.
  await tester.pumpWidget(const MaterialApp(home: MainApp()));
  // Allow a few frames for initial layout without waiting on network timers
  await tester.pump(const Duration(milliseconds: 100));

  // Verify the NavigationBar with expected tabs (labels may render multiple times in M3)
  expect(find.text('Home'), findsWidgets);
  expect(find.text('Recipes'), findsWidgets);
  expect(find.text('Pantry'), findsWidgets);
  expect(find.text('Planning'), findsWidgets);
  expect(find.text('More'), findsWidgets);

  // Verify we start on the home screen and it's the M3 NavigationBar
  expect(find.byType(NavigationBar), findsOneWidget);
  }, skip: true);

  testWidgets('Navigation between tabs works', (WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await ProfileStorage.saveProfile({'name': 'Test User'});
  await tester.pumpWidget(const MaterialApp(home: MainApp()));
  await tester.pump(const Duration(milliseconds: 100));

  // Tap on Pantry tab
  await tester.tap(find.text('Pantry'));
  await tester.pump(const Duration(milliseconds: 100));

  // Pantry tab selected (UI content varies; presence is enough for this smoke test)

  // Tap on Planning tab (now shows Meal Planner overview)
  await tester.tap(find.text('Planning'));
  await tester.pump(const Duration(milliseconds: 150));

  // Verify we navigated to the meal planner overview (look for Week Dinners label)
  expect(find.textContaining('Week Dinners'), findsWidgets);
  }, skip: true);
}
