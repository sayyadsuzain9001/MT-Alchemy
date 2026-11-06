import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart'; // InfoCard

/// Reusable on the Course Player and the Learner Dashboard.
/// [progress] is 0.0 to 1.0.
class ProgressBarCard extends StatelessWidget {
  const ProgressBarCard({
    super.key,
    required this.progress,
    this.label = 'Course Progress',
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return InfoCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: deepBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: deepBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              color: purple,
              backgroundColor: softYellow.withValues(alpha: .35),
            ),
          ),
        ],
      ),
    );
  }
}
