import 'package:flutter/material.dart';
import 'days_per_week_meter.dart';

/// Simple wrapper that adds standard spacing above the DaysPerWeekMeter.
class DaysPerWeekSliderCard extends StatelessWidget {
  final int value; // 0..7
  final ValueChanged<int> onChanged;

  const DaysPerWeekSliderCard({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        DaysPerWeekMeter(value: value.clamp(0, 7), onChanged: onChanged),
      ],
    );
  }
}
