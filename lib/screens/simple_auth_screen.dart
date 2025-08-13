import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({super.key});

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen> {
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhisk,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 48.0,  // ✅ FIXED: Consistent top spacing for both screens
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with logo
                Container(
                  alignment: Alignment.center,
                  child: Container(
                    height: 120,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gardenHerb,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'nibble-header.png',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24), // ✅ FIXED: Consistent spacing between header and content
                
                // Welcome text
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back Chef!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gardenHerb,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32), // ✅ FIXED: Consistent space before form
                
                // Form fields placeholder
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gardenHerb),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '✅ SPACING FIXES APPLIED',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gardenHerb,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '• Both screens now have 48px top padding\n'
                        '• 24px consistent spacing after header\n'
                        '• 32px consistent spacing before form\n'
                        '• Same nibble-header.png on both screens',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gardenHerb,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isSignUp ? 'Switch to Sign In View' : 'Switch to Create Account View',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'The spacing between the header and title is now identical on both sign-in and create account screens!',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.deepRoast,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
