import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

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
      home: CookingProfileOnboarding(
        onFinish: () {}, // no-op for preview
        initialData: const {},
      ),
    );
  }
}
