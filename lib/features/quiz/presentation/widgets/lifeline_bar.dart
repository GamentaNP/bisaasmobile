import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/lifeline_dto.dart';

/// Attempt lifelines, rendered from the server's own catalogue.
///
/// The bar is **not** a fixed set of three chips. It draws whatever
/// `GET /quiz/attempts/{attempt}/lifelines` returned, in the server's order,
/// and each chip is enabled only when the server marked it usable
/// (`canUse` and not `lockedByMode`). If the kill switch is off the caller
/// renders nothing at all.
///
/// Note the slugs are the `economy_lifelines.slug` column — the real values
/// include `fifty_fifty`, **not** `50_50`, which an earlier hardcoded version
/// of this widget assumed and which would have 404'd against
/// `{lifeline:slug}` route-model binding.
class LifelineBar extends StatelessWidget {
  const LifelineBar({
    required this.lifelines,
    required this.walletBalance,
    required this.onUse,
    this.busySlug,
    this.enabled = true,
    super.key,
  });

  final List<LifelineDto> lifelines;
  final int walletBalance;
  final void Function(LifelineDto lifeline) onUse;

  /// Slug currently being spent — that chip alone shows a spinner.
  final String? busySlug;

  /// The server's kill switch for this attempt.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || lifelines.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: lifelines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final lifeline = lifelines[i];
          return _LifelineChip(
            lifeline: lifeline,
            walletBalance: walletBalance,
            busy: busySlug == lifeline.slug,
            onTap: () => onUse(lifeline),
          );
        },
      ),
    );
  }
}

class _LifelineChip extends StatelessWidget {
  const _LifelineChip({
    required this.lifeline,
    required this.walletBalance,
    required this.busy,
    required this.onTap,
  });

  final LifelineDto lifeline;
  final int walletBalance;
  final bool busy;
  final VoidCallback onTap;

  /// The server decides availability; we only explain *why* it is unavailable.
  String? get _blockedReason {
    if (lifeline.lockedByMode) {
      return lifeline.lockReason ?? 'Not available in this mode';
    }
    if (lifeline.isAvailable) return null;
    // Not purchasable and not banked — say which of the two is the problem.
    if (walletBalance < lifeline.costCoins) {
      return 'Needs ${lifeline.costCoins} coins (you have $walletBalance)';
    }
    return 'Unavailable right now';
  }

  @override
  Widget build(BuildContext context) {
    final reason = _blockedReason;
    final usable = reason == null;
    // A banked token covers the cost regardless of wallet balance.
    final affordable = lifeline.hasBankedUse || walletBalance >= lifeline.costCoins;
    final discounted = (lifeline.discountPct ?? 0) > 0;

    return Semantics(
      button: true,
      enabled: usable && !busy,
      label: usable
          ? '${lifeline.name} lifeline, ${lifeline.costCoins} coins'
          : '${lifeline.name} lifeline unavailable: $reason',
      child: Tooltip(
        message: reason ?? '${lifeline.name} · ${lifeline.costCoins} coins',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: usable && !busy ? onTap : null,
          child: Opacity(
            opacity: usable ? 1.0 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lifelineCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.lifelineCyan.withValues(alpha: usable ? 0.4 : 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lifelineCyan),
                    )
                  else
                    Icon(_iconFor(lifeline.effectType), size: 14, color: AppColors.lifelineCyan),
                  const SizedBox(width: 5),
                  Text(
                    lifeline.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lifelineCyan,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 11,
                    color: affordable ? AppColors.coinYellow : AppColors.wrongRed,
                  ),
                  if (discounted && lifeline.baseCostCoins != null) ...[
                    // Struck-through base price, then the real amount charged.
                    Text(
                      '${lifeline.baseCostCoins}',
                      style: TextStyle(
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        color: affordable ? AppColors.textTertiaryLight : AppColors.wrongRed,
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    '${lifeline.costCoins}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: discounted ? FontWeight.bold : FontWeight.normal,
                      color: affordable ? AppColors.coinYellow : AppColors.wrongRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Icon chosen from the server's `effect_type`, with a safe default so a new
  /// server effect type still renders something sensible.
  static IconData _iconFor(String effectType) => switch (effectType) {
        'fifty_fifty' => Icons.filter_alt_outlined,
        'skip' => Icons.skip_next_rounded,
        'hint' => Icons.lightbulb_outline_rounded,
        'explanation' => Icons.menu_book_rounded,
        'eliminate_one' => Icons.remove_circle_outline_rounded,
        'question_swap' => Icons.swap_horiz_rounded,
        'reveal_correct' => Icons.visibility_rounded,
        'audience_poll' => Icons.bar_chart_rounded,
        'time_freeze' => Icons.ac_unit_rounded,
        'extra_time' => Icons.timer_outlined,
        'double_xp' => Icons.bolt_rounded,
        'shield' => Icons.shield_outlined,
        'second_chance' => Icons.replay_rounded,
        _ => Icons.auto_awesome_rounded,
      };
}
