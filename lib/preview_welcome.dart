import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_app.dart';

void main() {
  runApp(const _WelcomePreviewApp());
}

class _WelcomePreviewApp extends StatelessWidget {
  const _WelcomePreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nibble Welcome Preview',
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => CookingProfileOnboarding(
          onFinish: () {
            // In preview, route into the app's main shell (Home tab)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainApp()),
            );
          },
          initialData: const {},
        ),
      ),
    );
  }
}
