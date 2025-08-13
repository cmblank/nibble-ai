import 'package:flutter/material.dart';

/// Figma-derived selectable card with radio/check visual.
/// States: normal, hover, selected. Radius 8. Border 1px (2px when selected).
class SelectCard extends StatefulWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final EdgeInsets padding;

  const SelectCard({
    super.key,
    required this.title,
    required this.description,
    this.selected = false,
    this.onTap,
    this.width = double.infinity,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  State<SelectCard> createState() => _SelectCardState();
}

class _SelectCardState extends State<SelectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

  final bg = selected
    ? const Color(0xFFF7FDFB) // selected bg
    : (_hovered
      ? const Color(0xFFF7FDFB) // hover mirrors selected per desktop spec
      : Colors.white);
    final borderColor = selected || _hovered
        ? const Color(0xFF319B7B) // sage-1000
        : const Color(0xFFE8EAED); // subtle border
    final borderWidth = selected ? 2.0 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          padding: widget.padding,
          decoration: ShapeDecoration(
            color: bg,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: borderWidth, color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Color(0xFF1D2126),
                        fontSize: 14,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        color: Color(0xFF353C45),
                        fontSize: 12,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFF319B7B) : const Color(0xFFE8EAED);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        color: selected ? const Color(0xFF319B7B) : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}
