import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'auth_wrapper.dart';
import 'services/deep_link_logger.dart';
import 'screens/app_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Start deep link logging to verify password recovery links on macOS
  await DeepLinkLogger.init();

  // Log auth changes early to verify deep links (e.g., passwordRecovery)
  // are received when launching from email links on macOS.
  // ignore: avoid_print
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) => print('Auth state: ${data.event}, hasSession=${data.session != null}')
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
      // Show loading screen first, then route into AuthWrapper.
      home: const _SplashGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Simple splash gate that shows the loading screen briefly, then goes to AuthWrapper.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    // Give the loading animation a moment, then continue.
  Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const AppLoadingScreen();
}

// AuthWrapper listens to Supabase auth state and routes accordingly.