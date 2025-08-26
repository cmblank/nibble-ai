import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/recipe_event_service.dart';
import 'services/weekly_planner_service.dart';
import 'config/supabase_config.dart';
import 'auth_wrapper.dart';
import 'services/deep_link_logger.dart';
import 'services/deep_link_auth_handler.dart';
import 'screens/app_loading_screen.dart';
import 'services/ai_image_service.dart';
import 'services/settings_service.dart';
import 'services/household_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global flutter error logger to capture first stack traces clearly.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('==== FLUTTER ERROR START ====');
    debugPrint(details.exceptionAsString());
    debugPrintStack(stackTrace: details.stack);
    debugPrint('==== FLUTTER ERROR END ====');
  };

  // Initialize Hive for local persistence (events, caches)
  bool hiveOk = true;
  try { await Hive.initFlutter(); } catch (e) { hiveOk = false; developer.log('Hive init failed', error: e, name: 'Init'); }

  bool supabaseOk = true;
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  // Read AI image API key from a compile-time dart-define (never commit the key)
  AiImageService.apiKey = const String.fromEnvironment('OPENAI_API_KEY');
  } catch (e) {
    supabaseOk = false; developer.log('Supabase init failed', error: e, name: 'Init');
  }

  // Start deep link logging to verify password recovery links on macOS
  await DeepLinkLogger.init(); // existing lightweight logger (optional)
  await DeepLinkAuthHandler.init(); // handles auth callbacks & recovery

  // Init event persistence
  if (hiveOk) {
    try { await RecipeEventService.init(); } catch(e){ developer.log('Event service init failed', error: e, name: 'Init'); }
    try { await WeeklyPlannerService.init(); } catch(e){ developer.log('Planner service init failed', error: e, name: 'Init'); }
  }

  // Log auth changes early to verify deep links (e.g., passwordRecovery)
  // are received when launching from email links on macOS.
  // ignore: avoid_print
  Supabase.instance.client.auth.onAuthStateChange.listen(
  (data) => developer.log('Auth state: ${data.event}, hasSession=${data.session != null}', name: 'Auth')
  );

  // Attach household auth-driven lifecycle (realtime subscription etc.)
  HouseholdService.attachAuthListener();

  runApp(MyApp(initStatus: AppInitStatus(hiveOk: hiveOk, supabaseOk: supabaseOk)));
}

class AppInitStatus {
  final bool hiveOk;
  final bool supabaseOk;
  const AppInitStatus({required this.hiveOk, required this.supabaseOk});
  bool get allOk => hiveOk && supabaseOk;
}

class SettingsProvider extends InheritedNotifier<SettingsService> {
  SettingsProvider({super.key, required super.child}) : super(notifier: SettingsService());
  static SettingsService of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SettingsProvider>()!.notifier!;
}

class MyApp extends StatefulWidget {
  final AppInitStatus initStatus;
  const MyApp({super.key, required this.initStatus});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final settings = SettingsService();

  @override
  void initState() {
    super.initState();
    settings.load();
  }

  ThemeMode _themeModeFromSetting() {
    switch (settings.themeMode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsProvider(
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final baseLight = ThemeData(
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
          );
          final dark = ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE85A4F),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Manrope',
          );
          return MaterialApp(
            title: 'Nibble',
            navigatorKey: DeepLinkAuthHandler.navigatorKey,
            theme: baseLight,
            darkTheme: dark,
            themeMode: _themeModeFromSetting(),
            home: widget.initStatus.allOk ? const _SplashGate() : _InitErrorScreen(status: widget.initStatus),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
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

class _InitErrorScreen extends StatelessWidget {
  final AppInitStatus status;
  const _InitErrorScreen({required this.status});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup Error')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Some services failed to initialize.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!status.hiveOk) const Text('• Local storage (Hive) failed – offline data disabled.'),
            if (!status.supabaseOk) const Text('• Cloud connection failed – online sync & auth unavailable.'),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const _SplashGate())); }, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// AuthWrapper listens to Supabase auth state and routes accordingly.