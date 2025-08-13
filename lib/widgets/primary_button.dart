import 'package:flutter/material.dart';

/// App-wide primary CTA button.
/// Defaults: orange (#E43707), white text, full width, 8px radius.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final Color textColor;
  final bool fullWidth;
  final double fontSize;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  this.borderRadius = 8,
  this.color = const Color(0xFFE43707),
    this.textColor = Colors.white,
    this.fullWidth = true,
  this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final child = leading == null
        ? Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: fontSize,
              fontWeight: FontWeight.w600, // Semibold per spec
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading!,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600, // Semibold per spec
                ),
              ),
            ],
          );

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final hoveredOrSelected =
            states.contains(WidgetState.hovered) || states.contains(WidgetState.selected);
        // Hover/selected color is fixed to color-brick-1100 per spec
        return hoveredOrSelected ? const Color(0xFF9E2605) : color; // 9E2605 on hover,  E43707 at rest
      }),
  foregroundColor: WidgetStatePropertyAll(textColor),
      padding: WidgetStatePropertyAll(padding),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          // Subtle wash; spec doesn't define pressed. Keep a light overlay.
          return Colors.white.withValues(alpha: 0.08);
        }
        return null; // no extra overlay for hover; color already changes
      }),
    );

    final button = ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: child,
    );

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
 
