import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/skill_axes_dto.dart';

/// 6-axis skill radar from server-computed per-category accuracy.
///
/// Renders only with >= 3 axes (a radar polygon needs at least a triangle).
/// Accuracy (0..1) is scaled to 0..100 for readability.
class SkillRadarChart extends StatelessWidget {
  const SkillRadarChart({required this.axes, super.key});

  final List<SkillAxis> axes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (axes.length < 3) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            axes.isEmpty
                ? 'Take quizzes to reveal your skill radar.'
                : 'Answer more categories to reveal your skill radar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.brand.withValues(alpha: 0.25),
              borderColor: AppColors.brand,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: axes
                  .map((a) => RadarEntry(value: (a.accuracy * 100).clamp(0, 100).toDouble()))
                  .toList(),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          tickCount: 4,
          ticksTextStyle: const TextStyle(fontSize: 8, color: Colors.grey),
          tickBorderData: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
          gridBorderData: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          getTitle: (index, angle) {
            final label = axes[index].label;
            final short = label.length > 14 ? '${label.substring(0, 13)}…' : label;
            return RadarChartTitle(text: short);
          },
          titleTextStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
