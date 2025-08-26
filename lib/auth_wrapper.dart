import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/main_app.dart';
import 'screens/reset_password_screen.dart';
import 'config/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.creamWhisk,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loading mascot
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.nibbleRed.withAlpha((255 * 0.1).round()),
                          AppColors.gardenHerb.withAlpha((255 * 0.1).round()),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: Image.asset(
                        'assets/images/chef_mascot.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('🐿️👨‍🍳', style: TextStyle(fontSize: 40)),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: AppColors.nibbleRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing your kitchen...',
                    style: TextStyle(
                      color: AppColors.gardenHerb,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.event == AuthChangeEvent.passwordRecovery) {
          // Navigate to reset password when recovering
          return const ResetPasswordScreen();
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const MainApp();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
