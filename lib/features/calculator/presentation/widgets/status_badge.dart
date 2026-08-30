import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/calculator.dart';

/// SAFE / CHECK / FAIL status badge for a [CalculationResult] when the
/// server returns `data.status` plus `limit_value` / `actual_value`.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.result, super.key});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    if (status == null) return const SizedBox.shrink();

    final Color color;
    final IconData icon;
    final String label;
    switch (status) {
      case 'safe':
        color = AppColors.correctGreen;
        icon = Icons.check_circle_rounded;
        label = 'SAFE';
      case 'check':
        color = AppColors.streakOrange;
        icon = Icons.warning_amber_rounded;
        label = 'CHECK';
      case 'fail':
        color = AppColors.wrongRed;
        icon = Icons.cancel_rounded;
        label = 'FAIL';
      default:
        color = Colors.grey;
        icon = Icons.info_outline_rounded;
        label = status.toUpperCase();
    }

    final limit = result.limitValue;
    final actual = result.actualValue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14, letterSpacing: 0.6)),
                if (limit != null || actual != null)
                  Text(
                    [
                      if (actual != null) 'actual: $actual',
                      if (limit != null) 'limit: $limit',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
