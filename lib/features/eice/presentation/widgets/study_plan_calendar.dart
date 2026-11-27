import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/eice_data.dart';

/// The server's day-by-day plan. It renders only typed values from
/// [EicePayload]; no endpoint name and no JSON ever reaches the screen.
class StudyPlanCalendar extends StatelessWidget {
  const StudyPlanCalendar({super.key, required this.payload});

  final EicePayload payload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = payload.dailyPlan.take(7).toList(growable: false);
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.eiceNothingHere,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payload.hasCombinedDailyPlan)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.eiceStudyPlanCombined,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final day in days)
                _DayTile(day: day),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});

  final StudyPlanDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: day.isRestDay
            ? AppColors.surfaceSecondary
            : colorScheme.surface,
        borderRadius: AppRadii.smAll,
        border: day.isRestDay
            ? Border.all(color: AppColors.brandLight)
            : null,
        boxShadow: AppShadows.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _shortDate(day.date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                day.isRestDay
                    ? Icons.weekend_rounded
                    : Icons.quiz_outlined,
                size: 14,
                color: day.isRestDay
                    ? AppColors.correctGreen
                    : AppColors.brand,
              ),
              const SizedBox(width: 4),
              Text(
                '${day.questionCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (day.isRestDay)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.coachingNoTasksToday,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.correctGreen,
                ),
              ),
            ),
          for (final allocation in day.allocations.take(2))
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.selectedBlueBg,
                borderRadius: AppRadii.xsAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    allocation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${allocation.progressPercent}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.brandDark,
                    ),
                  ),
                  if (allocation.contextName != null)
                    Text(
                      allocation.contextName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The server publishes ISO dates (`2026-11-27`). Showing `11/27` keeps the
  /// tile compact without inventing a localized month name.
  String _shortDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) return '${parts[1]}/${parts[2]}';
    return date;
  }
}
