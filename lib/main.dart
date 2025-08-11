import 'screens/app_loading_screen.dart';
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
          seedColor: const Color(0xFFE85A4F),
          primary: const Color(0xFFE85A4F),
          secondary: const Color(0xFF4A9B8F),
          tertiary: const Color(0xFFF4A261),
          surface: const Color(0xFFFFF8F3),
        ),
        useMaterial3: true,
        fontFamily: 'Manrope',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A9B8F),
          foregroundColor: Color(0xFFFFF8F3),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE85A4F),
            foregroundColor: const Color(0xFFFFF8F3),
          ),
        ),
      ),
      home: const _InitialLoader(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class _InitialLoader extends StatefulWidget {
  const _InitialLoader();

  @override
  State<_InitialLoader> createState() => _InitialLoaderState();
}

class _InitialLoaderState extends State<_InitialLoader> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AppLoadingScreen();
  }
}