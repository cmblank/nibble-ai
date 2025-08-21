import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'typography_tokens.dart';
import 'spacing_tokens.dart';

/// Component Design Tokens
/// Pre-configured styles for common UI components based on cb_designSystem
class ComponentTokens {
  
  /// Button Styles
  static ButtonStyle primaryButton({Color? backgroundColor, Color? foregroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? ButtonColors.brandPrimaryBackground,
      foregroundColor: foregroundColor ?? ButtonColors.brandPrimaryText,
      textStyle: TextStyles.buttonMedium,
      minimumSize: const Size(0, SizeTokens.heightLG),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceLG,
        vertical: SpacingTokens.spaceMD,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
      ),
      elevation: ElevationTokens.raised,
    );
  }
  
  static ButtonStyle secondaryButton({Color? backgroundColor, Color? foregroundColor}) {
    return OutlinedButton.styleFrom(
      backgroundColor: backgroundColor ?? ButtonColors.brandSecondaryBackground,
      foregroundColor: foregroundColor ?? ButtonColors.brandSecondaryText,
      textStyle: TextStyles.buttonMedium,
      minimumSize: const Size(0, SizeTokens.heightLG),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceLG,
        vertical: SpacingTokens.spaceMD,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
      ),
      side: BorderSide(
        color: ButtonColors.brandSecondaryBorder,
        width: 1.5,
      ),
    );
  }
  
  static ButtonStyle textButton({Color? foregroundColor}) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor ?? ButtonColors.brandSecondaryText,
      textStyle: TextStyles.buttonMedium,
      minimumSize: const Size(0, SizeTokens.heightMD),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceMD,
        vertical: SpacingTokens.spaceSM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
    );
  }
  
  /// Input Field Styles
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: InputColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceMD,
        vertical: SpacingTokens.spaceMD,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        borderSide: const BorderSide(
          color: InputColors.border,
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        borderSide: const BorderSide(
          color: InputColors.border,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        borderSide: const BorderSide(
          color: InputColors.borderFocus,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        borderSide: const BorderSide(
          color: InputColors.borderDanger,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        borderSide: const BorderSide(
          color: InputColors.borderDanger,
          width: 2.0,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        borderSide: const BorderSide(
          color: InputColors.borderDisabled,
          width: 1.0,
        ),
      ),
      labelStyle: TextStyles.body85.copyWith(
        color: InputColors.label,
      ),
      hintStyle: TextStyles.body85.copyWith(
        color: InputColors.placeholder,
      ),
      helperStyle: TextStyles.body75.copyWith(
        color: TextColors.secondary,
      ),
      errorStyle: TextStyles.body75.copyWith(
        color: TextColors.danger,
      ),
    );
  }
  
  /// Card Styles
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    double? elevation,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? BackgroundColors.primary,
      borderRadius: BorderRadius.circular(borderRadius ?? RadiusTokens.xl),
      boxShadow: [
        BoxShadow(
          color: DesignTokens.gray400.withAlpha((255 * 0.1).round()),
          blurRadius: elevation ?? 8.0,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  /// AppBar Style
  static AppBarTheme appBarTheme() {
    return AppBarTheme(
      backgroundColor: BackgroundColors.brand,
      foregroundColor: TextColors.inverse,
      elevation: ElevationTokens.raised,
      titleTextStyle: TextStyles.heading125.copyWith(
        color: TextColors.inverse,
      ),
      toolbarHeight: SizeTokens.heightXXL,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(RadiusTokens.lg),
        ),
      ),
    );
  }
  
  /// Bottom Navigation Bar Style
  static BottomNavigationBarThemeData bottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: BackgroundColors.primary,
      selectedItemColor: ButtonColors.brandPrimaryBackground,
      unselectedItemColor: TextColors.secondary,
      selectedLabelStyle: TextStyles.body75.copyWith(
        fontWeight: TypographyTokens.semibold,
      ),
      unselectedLabelStyle: TextStyles.body75,
      type: BottomNavigationBarType.fixed,
      elevation: ElevationTokens.floating,
    );
  }
  
  /// Floating Action Button Style
  static FloatingActionButtonThemeData fabTheme() {
    return FloatingActionButtonThemeData(
      // Colors per spec: rest = brick900, pressed = brick1100 (approx via overlays)
      backgroundColor: DesignTokens.brick900,
      foregroundColor: DesignTokens.white,
  splashColor: DesignTokens.brick1100.withValues(alpha: 0.24),
  focusColor: DesignTokens.brick1100.withValues(alpha: 0.12),
  hoverColor: DesignTokens.brick1100.withValues(alpha: 0.08),
      elevation: ElevationTokens.floating,
      highlightElevation: ElevationTokens.floating + 2.0,
      shape: const CircleBorder(),
      // Size per spec: 48x48
      sizeConstraints: const BoxConstraints.tightFor(width: 48, height: 48),
    );
  }
  
  /// Chip Style
  static ChipThemeData chipTheme() {
    return ChipThemeData(
      backgroundColor: BackgroundColors.secondary,
      labelStyle: TextStyles.body75.copyWith(
        color: TextColors.primary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceSM,
        vertical: SpacingTokens.spaceXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.full),
      ),
    );
  }
  
  /// Dialog Style
  static DialogTheme dialogTheme() {
    return DialogTheme(
      backgroundColor: BackgroundColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.xxl),
      ),
      elevation: ElevationTokens.modal,
      titleTextStyle: TextStyles.heading150.copyWith(
        color: TextColors.primary,
      ),
      contentTextStyle: TextStyles.body100.copyWith(
        color: TextColors.secondary,
      ),
    );
  }
  
  /// Divider Style
  static DividerThemeData dividerTheme() {
    return const DividerThemeData(
      color: BorderColors.secondary,
      thickness: 1.0,
      space: SpacingTokens.spaceMD,
    );
  }
}
