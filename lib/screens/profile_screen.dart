import '../config/app_colors.dart';
import 'package:flutter/material.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhisk,
      body: Center(
        child: Text(
          'Profile Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
