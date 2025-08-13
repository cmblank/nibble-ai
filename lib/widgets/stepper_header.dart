import 'package:flutter/material.dart';

/// Figma-spec Stepper Header
/// - Background: #2A8469
/// - Progress track: #E8EAED, bar: #E48B07, height: 6, radius 4
/// - Padding: top 32, left/right 16, bottom 24
/// - Title: Manrope 20, bold, color #F7FDFB
/// - Subtitle: Manrope 12, medium, color #F7FDFB
class StepperHeader extends StatelessWidget {
  final int step; // 1-based step index
  final int totalSteps;
  final String title;
  final String? subtitle;

  const StepperHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (step.clamp(1, totalSteps)) / totalSteps;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 24),
      color: const Color(0xFF2A8469),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar with rounded caps
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE8EAED),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE48B07)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7FDFB),
              fontSize: 20,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Color(0xFFF7FDFB),
                fontSize: 12,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                height: 1.33,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
