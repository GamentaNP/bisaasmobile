import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/streak.dart';

/// Calendar grid showing last 35 days, highlighting active days and breaks.
/// Server-authoritative `Streak` decides shape; local calendar derives visuals.
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key, required this.streak, this.onTapDate});

  final Streak streak;
  final ValueChanged<DateTime>? onTapDate;

  List<DateTime> _days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Show last 35 days (5 weeks)
    return List.generate(35, (i) => today.subtract(Duration(days: 34 - i)));
  }

  bool _isActive(DateTime day) {
    if (streak.lastActivityDate == null) return false;
    final last = streak.lastActivityDate!;
    final lastDay = DateTime(last.year, last.month, last.day);
    // Active if day is within streak window: last - (currentStreak-1) .. last
    // plus today if isActiveToday
    final streakStart = lastDay.subtract(Duration(days: streak.currentStreak - 1));
    if (day.isBefore(streakStart) || day.isAfter(lastDay)) {
      // Today special: if streak.isActiveToday then today is also active even if last is today
      if (streak.isActiveToday && day == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) return true;
      return false;
    }
    return true;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final days = _days();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday labels
        Row(
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: Colors.grey)))))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, i) {
            final d = days[i];
            final active = _isActive(d);
            final today = _isToday(d);
            final future = _isFuture(d);
            final color = future
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : active
                    ? AppColors.streakOrange
                    : theme.colorScheme.surfaceContainerHighest;
            final textColor = active
                ? Colors.white
                : future
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.65);

            return GestureDetector(
              onTap: onTapDate == null || future ? null : () => onTapDate!(d),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: today ? Border.all(color: AppColors.brand, width: 2) : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${d.day}',
                        style: TextStyle(fontSize: 12, fontWeight: today ? FontWeight.bold : FontWeight.w500, color: textColor),
                      ),
                    ),
                    if (active)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    if (today && !active)
                      Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(width: 16, height: 3, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(3))),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
