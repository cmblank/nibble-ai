import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Figma-spec 0–7 days/week meter with animated track fill and hover/selected states.
class DaysPerWeekMeter extends StatelessWidget {
  final int value; // 0..7
  final ValueChanged<int> onChanged;

  const DaysPerWeekMeter({super.key, required this.value, required this.onChanged})
      : assert(value >= 0 && value <= 7);

  @override
  Widget build(BuildContext context) {
    const int steps = 8; // 0..7
    const double trackHeight = 6;
    const double dotSize = 16;
    const double minFillAtZero = 9; // per Figma
    const duration = Duration(milliseconds: 240);
    const curve = Curves.easeInOutCubic;

    const Color trackBg = Color(0xFFD9D9D9);
    final Color fillColor = AppColors.gardenHerb;
    const Color textDark = Color(0xFF1D2126);
    const Color textPlaceholder = Color(0xFF616F7F);
    const Color hoverBg = Color(0xFFE0F5EF); // sage-300
    const Color hoverBorder = Color(0xFF319B7B); // sage-1000

    // Cap the meter to a maximum width while keeping it left-aligned in wider layouts.
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double stepSpan = (steps - 1) > 0 ? width / (steps - 1) : width;
        final double targetX = value * stepSpan;
        final double fillWidth = value == 0 ? minFillAtZero : targetX.clamp(minFillAtZero, width);

        void _handleLocal(Offset localPos) {
          final double x = localPos.dx.clamp(0.0, width);
          final int idx = (x / stepSpan).round().clamp(0, steps - 1);
          if (idx != value) onChanged(idx);
        }

        int? hoverIndex;

  return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleLocal(d.localPosition),
          onPanUpdate: (d) => _handleLocal(d.localPosition),
          child: SizedBox(
            height: 40, // enough for dots + labels + track
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                // Track background
                Positioned(
                  left: 0,
                  top: (dotSize / 2) - (trackHeight / 2), // 5px when 16/6
                  right: 0,
                  child: Container(
                    height: trackHeight,
                    decoration: ShapeDecoration(
                      color: trackBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(800),
                      ),
                    ),
                  ),
                ),
                // Animated fill
                Positioned(
                  left: 0,
                  top: (dotSize / 2) - (trackHeight / 2),
                  child: AnimatedContainer(
                    duration: duration,
                    curve: curve,
                    width: fillWidth,
                    height: trackHeight,
                    decoration: ShapeDecoration(
                      color: fillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(800),
                      ),
                    ),
                  ),
                ),
                // Steps (dot + label) overlay with local hover state
                Positioned.fill(
                  child: StatefulBuilder(
                    builder: (context, setSBState) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(steps, (i) {
                          final bool isSelected = i == value;
                          final bool isHover = hoverIndex == i && !isSelected;
                          final Color labelColor = isSelected
                              ? textDark
                              : (isHover ? textDark : textPlaceholder);
                          final FontWeight weight = isSelected
                              ? FontWeight.w600
                              : (isHover ? FontWeight.w600 : FontWeight.w400);

                          return MouseRegion(
                            onEnter: (_) => setSBState(() => hoverIndex = i),
                            onExit: (_) => setSBState(() => hoverIndex = null),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onChanged(i),
                              child: SizedBox(
                                width: dotSize,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: dotSize,
                                      height: dotSize,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Base circle (selected or null)
                                          AnimatedContainer(
                                            duration: duration,
                                            curve: curve,
                                            width: dotSize,
                                            height: dotSize,
                                            decoration: BoxDecoration(
                                              color: isSelected ? fillColor : Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: isSelected
                                                  ? Border.all(color: fillColor, width: 1)
                                                  : null, // null state: no border
                                            ),
                                          ),
                                          // Hover overlay fades in/out smoothly (only when not selected)
                                          if (!isSelected)
                                            AnimatedOpacity(
                                              duration: const Duration(milliseconds: 150),
                                              curve: Curves.easeOutCubic,
                                              opacity: isHover ? 1.0 : 0.0,
                                              child: Container(
                                                width: dotSize,
                                                height: dotSize,
                                                decoration: BoxDecoration(
                                                  color: hoverBg,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: hoverBorder, width: 1),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: duration,
                                      curve: curve,
                                      style: TextStyle(
                                        color: labelColor,
                                        fontSize: 14,
                                        fontFamily: 'Manrope',
                                        fontWeight: weight,
                                        height: 1.43,
                                      ),
                                      textAlign: TextAlign.center,
                                      child: Text('$i'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
        ),
      ),
    );
  }
}
