import 'package:flutter/material.dart';

/// Nibble app brand colors matching the chef mascot design
class AppColors {
  // Primary brand colors
  static const Color primaryOrange = Color(0xFFE85A4F); // Warm coral/orange from chef
  static const Color primaryTeal = Color(0xFF4A9B8F); // Teal green
  static const Color buttonColor = Color(0xFF277F6D); // Button and active link color
  static const Color darkTeal = Color(0xFF1A5A4E); // Darker teal for text on white
  static const Color accentOrange = Color(0xFFF4A261); // Lighter orange accent
  
  // Neutral colors
  static const Color cream = Color(0xFFFFF8F3); // Warm cream background
  static const Color warmWhite = Color(0xFFFFFAF7); // Slightly warmer white
  static const Color lightGray = Color(0xFFE5E7EB); // Light borders/dividers
  static const Color mediumGray = Color(0xFF6B7280); // Secondary text
  static const Color darkGray = Color(0xFF374151); // Primary text
  
  // Status colors
  static const Color success = Color(0xFF10B981); // Green for success
  static const Color error = Color(0xFFEF4444); // Red for errors
  static const Color warning = Color(0xFFF59E0B); // Yellow for warnings
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [cream, warmWhite],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
