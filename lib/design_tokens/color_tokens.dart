import 'package:flutter/material.dart';

/// Design Tokens - Base Color Palette
/// Based on cb_designSystem themes.json
class DesignTokens {
  // Base colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Gray scale
  static const Color gray100 = Color(0xFFF9FAFB);
  static const Color gray200 = Color(0xFFF3F5F6);
  static const Color gray300 = Color(0xFFE8EAED);
  static const Color gray400 = Color(0xFFD7DBE0);
  static const Color gray500 = Color(0xFFB7BEC8);
  static const Color gray600 = Color(0xFF98A2AF);
  
  // Brand colors (maintaining Nibble brand)
  static const Color nibbleRed = Color(0xFFD73001);
  static const Color goldenCrust = Color(0xFFEDB660);
  static const Color deepRoast = Color(0xFF5F1408);
  static const Color creamWhisk = Color(0xFFF3E3B2);
  static const Color gardenHerb = Color(0xFF2A8270);
  static const Color flameOrange = Color(0xFFFD7804);
  // Sage scale (for hover states in chips)
  static const Color sage100 = Color(0xFFF7FDFB);
  static const Color sage1000 = Color(0xFF319B7B);

  // Brick scale (aliases/matches to brand reds used in spec)
  // brick900 aligns with our primary brand red
  static const Color brick900 = Color(0xFFE43707);
  // brick1100 is a darker red used for hover/selected states in some components
  static const Color brick1100 = Color(0xFF9E2605);
  // brick1400 used for rest (unselected) labels/icons in tab bar
  static const Color brick1400 = Color(0xFF4A0F02);
  // brick1300 used for chip label in rest state per spec
  static const Color brick1300 = Color(0xFF541403);
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color information = Color(0xFF3B82F6);
}

/// Text Color Tokens
class TextColors {
  static const Color primary = DesignTokens.deepRoast;
  static const Color secondary = DesignTokens.gray600;
  static const Color tertiary = DesignTokens.gray500;
  static const Color inverse = DesignTokens.white;
  static const Color dark = Color(0xFF1D2126);
  static const Color disabled = DesignTokens.gray400;
  static const Color success = DesignTokens.success;
  static const Color danger = DesignTokens.danger;
  static const Color warning = DesignTokens.warning;
  static const Color information = DesignTokens.information;

  // Aliases for design token naming
  // color/text/medium → use secondary by spec
  static const Color textMedium = secondary;
}

/// Background Color Tokens
class BackgroundColors {
  static const Color primary = DesignTokens.white;
  static const Color secondary = DesignTokens.gray100;
  static const Color tertiary = DesignTokens.gray200;
  static const Color inverse = DesignTokens.deepRoast;
  static const Color brand = DesignTokens.gardenHerb;
  static const Color success = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFFFFBEB);
  static const Color information = Color(0xFFEFF6FF);
}

/// Border Color Tokens
class BorderColors {
  static const Color primary = DesignTokens.gray300;
  static const Color secondary = DesignTokens.gray200;
  static const Color tertiary = DesignTokens.gray100;
  static const Color focus = DesignTokens.gardenHerb;
  static const Color danger = DesignTokens.danger;
  static const Color success = DesignTokens.success;
  static const Color warning = DesignTokens.warning;
}

/// Button Color Tokens
class ButtonColors {
  // Brand Primary Button
  static const Color brandPrimaryBackground = DesignTokens.gardenHerb;
  static const Color brandPrimaryText = DesignTokens.white;
  static const Color brandPrimaryBorder = DesignTokens.gardenHerb;
  
  // Brand Secondary Button
  static const Color brandSecondaryBackground = DesignTokens.white;
  static const Color brandSecondaryText = DesignTokens.gardenHerb;
  static const Color brandSecondaryBorder = DesignTokens.gardenHerb;
  
  // Neutral Primary Button
  static const Color neutralPrimaryBackground = DesignTokens.gray600;
  static const Color neutralPrimaryText = DesignTokens.white;
  static const Color neutralPrimaryBorder = DesignTokens.gray600;
  
  // Danger Primary Button
  static const Color dangerPrimaryBackground = DesignTokens.danger;
  static const Color dangerPrimaryText = DesignTokens.white;
  static const Color dangerPrimaryBorder = DesignTokens.danger;
}

/// Input Field Color Tokens
class InputColors {
  static const Color background = DesignTokens.white;
  static const Color backgroundHover = DesignTokens.gray100;
  static const Color backgroundFocus = DesignTokens.white;
  static const Color backgroundDisabled = DesignTokens.gray100;
  
  static const Color border = DesignTokens.gray300;
  static const Color borderHover = DesignTokens.gray400;
  static const Color borderFocus = DesignTokens.gardenHerb;
  static const Color borderDanger = DesignTokens.danger;
  static const Color borderDisabled = DesignTokens.gray200;
  
  static const Color text = DesignTokens.deepRoast;
  static const Color placeholder = DesignTokens.gray500;
  static const Color label = DesignTokens.gray600;
}
