import 'package:flutter/material.dart';

/// Typography Design Tokens
/// Based on cb_designSystem typography scale
class TypographyTokens {
  // Font family
  static const String fontFamily = 'Manrope';
  
  // Font sizes
  static const double fontSize75 = 12.0;
  static const double fontSize85 = 14.0;
  static const double fontSize100 = 16.0;
  static const double fontSize125 = 20.0;
  static const double fontSize150 = 24.0;
  static const double fontSize175 = 28.0;
  static const double fontSize200 = 32.0;
  static const double fontSize250 = 40.0;
  static const double fontSize300 = 48.0;
  static const double fontSize350 = 56.0;
  static const double fontSize400 = 64.0;
  static const double fontSize500 = 80.0;
  static const double fontSize600 = 96.0;
  static const double fontSize700 = 112.0;
  static const double fontSize800 = 128.0;
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;
  
  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
}

/// Predefined Text Styles
class TextStyles {
  // Headings
  static const TextStyle heading800 = TextStyle(
    fontSize: TypographyTokens.fontSize800,
    fontWeight: TypographyTokens.black,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading700 = TextStyle(
    fontSize: TypographyTokens.fontSize700,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading600 = TextStyle(
    fontSize: TypographyTokens.fontSize600,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading500 = TextStyle(
    fontSize: TypographyTokens.fontSize500,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading400 = TextStyle(
    fontSize: TypographyTokens.fontSize400,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading350 = TextStyle(
    fontSize: TypographyTokens.fontSize350,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading300 = TextStyle(
    fontSize: TypographyTokens.fontSize300,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading250 = TextStyle(
    fontSize: TypographyTokens.fontSize250,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading200 = TextStyle(
    fontSize: TypographyTokens.fontSize200,
    fontWeight: TypographyTokens.bold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading175 = TextStyle(
    fontSize: TypographyTokens.fontSize175,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightTight,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading150 = TextStyle(
    fontSize: TypographyTokens.fontSize150,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle heading125 = TextStyle(
    fontSize: TypographyTokens.fontSize125,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  // Body text
  static const TextStyle body200 = TextStyle(
    fontSize: TypographyTokens.fontSize200,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightRelaxed,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle body175 = TextStyle(
    fontSize: TypographyTokens.fontSize175,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightRelaxed,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle body150 = TextStyle(
    fontSize: TypographyTokens.fontSize150,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightRelaxed,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle body125 = TextStyle(
    fontSize: TypographyTokens.fontSize125,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightRelaxed,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle body100 = TextStyle(
    fontSize: TypographyTokens.fontSize100,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle body85 = TextStyle(
    fontSize: TypographyTokens.fontSize85,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle body75 = TextStyle(
    fontSize: TypographyTokens.fontSize75,
    fontWeight: TypographyTokens.regular,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  // Captions and small text
  static const TextStyle caption = TextStyle(
    fontSize: TypographyTokens.fontSize75,
    fontWeight: TypographyTokens.medium,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: TypographyTokens.fontSize75,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
    letterSpacing: 0.5,
  );
  
  // Button text styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: TypographyTokens.fontSize100,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: TypographyTokens.fontSize85,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: TypographyTokens.fontSize75,
    fontWeight: TypographyTokens.semibold,
    height: TypographyTokens.lineHeightNormal,
    fontFamily: TypographyTokens.fontFamily,
  );
}
