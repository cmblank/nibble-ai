import 'package:flutter/material.dart';

/// App tertiary (text-only) button, ideal for "Skip" actions.
/// Defaults to gray text, no background, subtle press overlay.
class TertiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final bool selected;
  // When true, renders a subtle gray pill background even at rest to match the Figma "filled tertiary" variant.
  final bool filled;

  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFF596573), // color-text-light per spec
    this.fontSize = 16,
  this.fontWeight = FontWeight.w600, // semibold per spec
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.selected = false,
  this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(color),
      padding: WidgetStatePropertyAll(padding),
  minimumSize: const WidgetStatePropertyAll(Size(0, 0)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Use a neutral gray background for hover/selected to match Figma.
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final hovered = states.contains(WidgetState.hovered) || states.contains(WidgetState.focused);
        if (hovered || selected) {
          return const Color(0xFFE8EAED); // color-gray-300 per spec
        }
        // Rest state is white per spec when used as a pill; allow transparent when not filled
        return filled ? Colors.white : Colors.transparent;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return const Color(0xFFD1D5DB).withValues(alpha: 0.6); // subtle press wash
        }
        return null;
      }),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
