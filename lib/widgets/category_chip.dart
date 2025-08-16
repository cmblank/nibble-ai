import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import '../design_tokens/color_tokens.dart';

/// CategoryChip – spec-aligned chip used for pantry filters.
/// States:
/// - rest: bg gray200, 1px gray300 border, text deep roast
/// - hover: bg gray100 (only on desktop/web), same border
/// - selected: bg gardenHerb, no border, text white, leading 18x18 check badge
class CategoryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _hover = false;
  bool get _hoverEnabled => kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    // Spec colors: rest gray200 + gray300 border; hover uses sage100 bg + sage1000 border; selected gardenHerb bg
    final Color bg;
    BoxBorder? border;
    if (selected) {
      bg = DesignTokens.sage1000;
      border = null; // no border on selected
    } else if (_hoverEnabled && _hover) {
      bg = DesignTokens.sage100; // #F7FDFB
      border = Border.all(color: DesignTokens.sage1000, width: 1); // #319B7B
    } else {
      bg = DesignTokens.gray200; // rest
      border = Border.all(color: BorderColors.primary, width: 1); // gray300
    }

    return MouseRegion(
      onEnter: (_) {
        if (_hoverEnabled) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hoverEnabled) setState(() => _hover = false);
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          // Spec padding:
          // - rest/hover: left 19, right 10
          // - selected: left 7, right 10
          padding: selected
              ? const EdgeInsets.only(left: 4, right:6)
              : const EdgeInsets.only(left: 15, right: 15),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/mulit-select-check.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 2),
              ],
        Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14, // spec text size
          // Spec: body/default/SB for rest/hover; selected can go bold
          fontWeight: selected
            ? FontWeight.w700
            : FontWeight.w600,
                  height: 1.43,
                  color: selected ? TextColors.inverse : ( _hover ? TextColors.dark : DesignTokens.brick1300 ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
