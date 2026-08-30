import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Small metric card used by coaching dashboard — readiness, projected score etc.
class CoachingMetricCard extends StatelessWidget {
  const CoachingMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon = Icons.insights_rounded,
    this.color = AppColors.brand,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }
}
