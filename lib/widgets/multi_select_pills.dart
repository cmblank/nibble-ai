import 'package:flutter/material.dart';

/// A Figma-spec selection chip used inside MultiSelectPills.
/// States:
/// - rest: bg #F9FAFB, border #F3F5F6, text #1D2126, semi-bold
/// - hover: bg #F7FDFB, border #319B7B, text #1D2126, semi-bold
/// - selected: bg #319B7B, no border, white text bold, left icon (18x18)
class SelectionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<SelectionChip> createState() => _SelectionChipState();
}

class _SelectionChipState extends State<SelectionChip>
    with SingleTickerProviderStateMixin {
  static const _kDuration = Duration(milliseconds: 260);
  static const _kCurve = Curves.easeInOutCubic;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final bool hovered = _isHovered && !selected; // hover only affects non-selected

    // Colors per spec
    const restBg = Color(0xFFF9FAFB); // gray-100
    const restBorder = Color(0xFFF3F5F6); // gray-200
    const textDark = Color(0xFF1D2126);

    const hoverBg = Color(0xFFF7FDFB); // sage-100
    const hoverBorder = Color(0xFF319B7B); // sage-1000

    const selectedBg = Color(0xFF319B7B); // sage-1000

    final Color bg = selected
        ? selectedBg
        : hovered
            ? hoverBg
            : restBg;

    // 1px border in all states; selected uses same color as bg per spec
    final BorderSide side = BorderSide(
      width: 1,
      color: selected ? selectedBg : (hovered ? hoverBorder : restBorder),
    );

  // Padding per state values
  const double restPadH = 20; // left & right for rest/hover
  const double selPadLeft = 7;
  const double selPadRight = 9;

  // Padding per state:
  // - rest/hover: 20 left & right
  // - selected: 7 left, 10 right (trades padding for icon+gap to keep pill width stable)
  final EdgeInsets padding = selected
    ? EdgeInsets.only(left: selPadLeft, right: selPadRight, top: 10, bottom: 10)
    : EdgeInsets.symmetric(horizontal: restPadH, vertical: 10);

    // Icon + gap reserved space (constant), text will slide over this when unselected
  const double iconSize = 18;
  const double gap = 2;
  // Compensation so total chip width stays constant across states:
  // rest total = restPadH*2 + text
  // selected total = selPadLeft + icon + gap + text + spacer + selPadRight
  // spacer = restPadH*2 - (selPadLeft + selPadRight + icon + gap)
  final double compensationWidth =
    (restPadH * 2) - (selPadLeft + selPadRight + iconSize + gap);
  final double trailingSpacer = compensationWidth > 0 ? compensationWidth : 0;
  // iconSpace no longer needed since we animate icon width from 0

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _kDuration,
          curve: _kCurve,
          padding: padding,
          constraints: const BoxConstraints(minHeight: 32),
          decoration: ShapeDecoration(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(800),
              side: side,
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x0C000000), // shadow/xs 0 1 2 0 #000000
                blurRadius: 2,
                offset: Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          // Animate internals:
          // - color fade is handled by AnimatedContainer
          // - icon width grows from 0 -> 18 and fades in
          // - text naturally shifts right; width change smoothed by AnimatedSize
          child: AnimatedSize(
            duration: _kDuration,
            curve: _kCurve,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon area animates width from 0 to iconSize
                AnimatedContainer(
                  duration: _kDuration,
                  curve: _kCurve,
                  width: selected ? iconSize : 0,
                  height: iconSize,
                  child: AnimatedOpacity(
                    duration: _kDuration,
                    curve: _kCurve,
                    opacity: selected ? 1.0 : 0.0,
                    child: selected
                        ? Image.asset(
                            'assets/images/mulit-select-check.png',
                            width: iconSize,
                            height: iconSize,
                            filterQuality: FilterQuality.high,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                AnimatedContainer(
                  duration: _kDuration,
                  curve: _kCurve,
                  width: selected ? gap : 0,
                ),
                // Text style animates for color/weight
                AnimatedDefaultTextStyle(
                  duration: _kDuration,
                  curve: _kCurve,
                  style: TextStyle(
                    color: selected ? Colors.white : textDark,
                    fontSize: 14,
                    fontFamily: 'Manrope',
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    height: 1.43,
                  ),
                  child: Text(widget.label),
                ),
                // Trailing spacer to equalize overall width when selected
                AnimatedContainer(
                  duration: _kDuration,
                  curve: _kCurve,
                  width: selected ? trailingSpacer : 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-select pills group with Wrap layout.
class MultiSelectPills extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<String> onSelectionChanged;

  const MultiSelectPills({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return SelectionChip(
          label: option,
          selected: isSelected,
          onTap: () => onSelectionChanged(option),
        );
      }).toList(),
    );
  }
}
