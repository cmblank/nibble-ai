import '../design_tokens/color_tokens.dart';
import 'package:flutter/material.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.gray300,
      body: Center(
        child: Text(
          'Profile Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
