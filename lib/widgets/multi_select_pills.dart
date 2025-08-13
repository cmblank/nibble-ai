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
  // Nudge spacer slightly smaller to avoid fractional overflows in tight wraps
  final double trailingSpacer = compensationWidth > 0
      ? (compensationWidth - 2).clamp(0, double.infinity)
      : 0;
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
          // Clip any sub-pixel overflow from animated internals to avoid debug stripes
          clipBehavior: Clip.antiAlias,
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
class MultiSelectPills extends StatefulWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<String> onSelectionChanged;
  final String otherLabel;
  final bool enableOtherInput;
  final String otherPlaceholder;
  // When true, always show the inline "Other" text input even if otherLabel
  // is not present in options. Useful when you want to remove the literal
  // "Other" chip but keep the custom entry input.
  final bool showOtherInput;

  const MultiSelectPills({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.otherLabel = 'Other',
    this.enableOtherInput = true,
  this.otherPlaceholder = 'Add other...',
  this.showOtherInput = false,
  });

  @override
  State<MultiSelectPills> createState() => _MultiSelectPillsState();
}

class _MultiSelectPillsState extends State<MultiSelectPills> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    if (!widget.selectedOptions.contains(raw)) {
      widget.onSelectionChanged(raw);
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
  final hasOther = widget.enableOtherInput &&
    (widget.options.contains(widget.otherLabel) || widget.showOtherInput);
    // Custom entries are those selected that aren't in the base options.
    final customEntries = widget.selectedOptions
        .where((s) => !widget.options.contains(s))
        .toList(growable: false);

    final List<Widget> children = [];

    for (final option in widget.options) {
      final isSelected = widget.selectedOptions.contains(option);
      children.add(
        SelectionChip(
          label: option,
          selected: isSelected,
          onTap: () {
            // If tapping the 'Other' chip and input is enabled, also focus the input.
            widget.onSelectionChanged(option);
            if (hasOther && option == widget.otherLabel) {
              _focusNode.requestFocus();
            }
          },
        ),
      );
    }

    // Render custom chips after base options.
    for (final custom in customEntries) {
      children.add(
        SelectionChip(
          label: custom,
          selected: true,
          onTap: () => widget.onSelectionChanged(custom), // toggles off
        ),
      );
    }

    // Append inline input for custom entries if 'Other' is available.
    if (hasOther) {
      children.add(_OtherInlineInput(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: widget.otherPlaceholder,
        onSubmitted: _submitCustom,
      ));
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children,
    );
  }
}

class _OtherInlineInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final String placeholder;

  const _OtherInlineInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.placeholder,
  });

  @override
  State<_OtherInlineInput> createState() => _OtherInlineInputState();
}

class _OtherInlineInputState extends State<_OtherInlineInput> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Colors matching SelectionChip rest/hover states
    const restBg = Color(0xFFF9FAFB);
    const restBorder = Color(0xFFF3F5F6);
    const hoverBg = Color(0xFFF7FDFB);
    const hoverBorder = Color(0xFF319B7B);

    final Color bg = _hovered ? hoverBg : restBg;
    final Color border = _hovered ? hoverBorder : restBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.focusNode.requestFocus(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: SizedBox(
            height: 42, // match SelectionChip visual height with line-height rounding
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              decoration: ShapeDecoration(
                color: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(800),
                  side: BorderSide(color: border, width: 1),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      onSubmitted: (_) => widget.onSubmitted(),
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        height: 1.43,
                        color: Color(0xFF1D2126),
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        hintText: widget.placeholder,
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
