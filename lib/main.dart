import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nibble',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85A4F), // Warm coral/orange from the chef
          primary: const Color(0xFFE85A4F), // Main coral orange
          secondary: const Color(0xFF4A9B8F), // Teal green
          tertiary: const Color(0xFFF4A261), // Lighter orange accent
          surface: const Color(0xFFFFF8F3), // Warm cream
          background: const Color(0xFFFFF8F3), // Warm cream background
        ),
        useMaterial3: true,
        fontFamily: 'System',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A9B8F), // Teal for app bars
          foregroundColor: Color(0xFFFFF8F3), // Cream text
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE85A4F), // Coral buttons
            foregroundColor: const Color(0xFFFFF8F3), // Cream text
          ),
        ),
      ),
      home: const AuthWrapper(), // Use AuthWrapper for authentication flow
      debugShowCheckedModeBanner: false,
    );
  }
}