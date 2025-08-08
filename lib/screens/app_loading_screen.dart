import 'package:flutter/material.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/app_loading_bg.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/nibble_logo_white.png',
                      width: 240,
                      height: 240,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Helping you make food happen',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
