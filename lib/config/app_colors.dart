import 'package:flutter/material.dart';

/// Nibble app brand colors matching the chef mascot design
class AppColors {
  // Nibble Brand Colors
  static const Color nibbleRed = Color(0xFFD73001); // Primary accent (logo, highlights)
  static const Color goldenCrust = Color(0xFFEDB660); // Backgrounds, secondary accents
  static const Color deepRoast = Color(0xFF5F1408); // Text, shadows, outlines
  static const Color creamWhisk = Color(0xFFF3E3B2); // Backgrounds, light surfaces
  static const Color gardenHerb = Color(0xFF2A8270); // Natural contrast, call-to-actions
  static const Color flameOrange = Color(0xFFFD7804); // Buttons, energetic UI elements

  // Status colors
  static const Color success = Color(0xFF10B981); // Green for success
  static const Color error = Color(0xFFEF4444); // Red for errors
  static const Color warning = Color(0xFFF59E0B); // Yellow for warnings

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [nibbleRed, flameOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [creamWhisk, goldenCrust],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
