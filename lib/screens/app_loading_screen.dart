import 'package:flutter/material.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeIn)),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack)),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
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
          // Background image from attachment
          Image.asset(
            'assets/images/app_loading_bg.png',
            fit: BoxFit.cover,
          ),
          // Centered logo + tight tagline spacing
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      // Logo from attachment (capped at 200px wide)
                      'assets/images/nibble_logo_white-load.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _taglineFade,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Text(
                      'Helping you make food happen',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 1.2,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
