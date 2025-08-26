import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Figma-derived selectable card with radio/check visual.
/// States: normal, hover, selected. Radius 8. Border 1px (2px when selected).
class SelectCard extends StatefulWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;
  final double width;
  final EdgeInsets padding;
  // Spec: Show Option Description (Boolean), default true
  final bool showDescription;

  const SelectCard({
    super.key,
    required this.title,
    required this.description,
    this.selected = false,
    this.onTap,
    this.width = double.infinity,
  this.padding = const EdgeInsets.all(12),
  this.showDescription = true,
  });

  @override
  State<SelectCard> createState() => _SelectCardState();
}

class _SelectCardState extends State<SelectCard> {
  bool _hovered = false;
  void _setHoverDeferred(bool v) {
    if (_hovered == v || !mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      Future.microtask(() { if (mounted) setState(()=> _hovered = v); });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_){ if (mounted) setState(()=> _hovered = v); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

  // Background:
  // - Rest: white
  // - Hover: white (border highlights)
  // - Selected: sage-100 (#F7FDFB)
  final bg = selected
      ? const Color(0xFFF7FDFB)
      : Colors.white;
    final borderColor = selected || _hovered
        ? const Color(0xFF319B7B) // sage-1000
        : const Color(0xFFE8EAED); // subtle border
    final borderWidth = selected ? 2.0 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHoverDeferred(true),
      onExit: (_) => _setHoverDeferred(false),
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
              _RadioDot(selected: selected, hovered: _hovered),
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
                    if (widget.showDescription && widget.description.isNotEmpty) ...[
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
  final bool hovered;
  const _RadioDot({required this.selected, required this.hovered});

  @override
  Widget build(BuildContext context) {
    final border = (selected || hovered) ? const Color(0xFF319B7B) : const Color(0xFFE8EAED);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        color: Colors.transparent,
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF319B7B),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
