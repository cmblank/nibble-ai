/// Spacing Design Tokens
/// Based on 8px grid system and cb_designSystem spacing scale
class SpacingTokens {
  // Base unit (8px)
  static const double unit = 8.0;
  
  // Spacing scale
  static const double space0 = 0.0;
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;   // 1x
  static const double space12 = 12.0; // 1.5x
  static const double space16 = 16.0; // 2x
  static const double space20 = 20.0; // 2.5x
  static const double space24 = 24.0; // 3x
  static const double space28 = 28.0; // 3.5x
  static const double space32 = 32.0; // 4x
  static const double space40 = 40.0; // 5x
  static const double space48 = 48.0; // 6x
  static const double space56 = 56.0; // 7x
  static const double space64 = 64.0; // 8x
  static const double space80 = 80.0; // 10x
  static const double space96 = 96.0; // 12x
  static const double space112 = 112.0; // 14x
  static const double space128 = 128.0; // 16x
  
  // Semantic spacing
  static const double spaceXS = space4;
  static const double spaceSM = space8;
  static const double spaceMD = space16;
  static const double spaceLG = space24;
  static const double spaceXL = space32;
  static const double space2XL = space48;
  static const double space3XL = space64;
  static const double space4XL = space80;
  static const double space5XL = space96;
}

/// Border Radius Design Tokens
class RadiusTokens {
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double xxxl = 24.0;
  static const double full = 9999.0; // Pill shape
}

/// Shadow Design Tokens
class ShadowTokens {
  static const List<double> none = [0, 0, 0, 0];
  static const List<double> xs = [0, 1, 2, 0];
  static const List<double> sm = [0, 1, 3, 0];
  static const List<double> md = [0, 4, 6, -1];
  static const List<double> lg = [0, 10, 15, -3];
  static const List<double> xl = [0, 20, 25, -5];
  static const List<double> xxl = [0, 25, 50, -12];
  static const List<double> inner = [0, 2, 4, 0]; // Inset shadow
}

/// Z-Index (Elevation) Design Tokens
class ElevationTokens {
  static const double base = 0;
  static const double raised = 1;
  static const double floating = 2;
  static const double overlay = 3;
  static const double modal = 4;
  static const double popover = 5;
  static const double tooltip = 6;
  static const double notification = 7;
  static const double maximum = 8;
}

/// Component Size Tokens
class SizeTokens {
  // Height tokens for components
  static const double heightXS = 24.0;
  static const double heightSM = 32.0;
  static const double heightMD = 40.0;
  static const double heightLG = 48.0;
  static const double heightXL = 56.0;
  static const double heightXXL = 64.0;
  
  // Width tokens for components
  static const double widthXS = 64.0;
  static const double widthSM = 128.0;
  static const double widthMD = 256.0;
  static const double widthLG = 384.0;
  static const double widthXL = 512.0;
  static const double widthXXL = 768.0;
  
  // Icon sizes
  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;
}

/// Layout Breakpoints
class BreakpointTokens {
  static const double mobile = 375.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;
  static const double wide = 1440.0;
}
