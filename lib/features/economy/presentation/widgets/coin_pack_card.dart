import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/economy.dart';

class CoinPackCard extends StatelessWidget {
  const CoinPackCard({super.key, required this.pack, required this.isPurchasing, required this.onBuy});
  final CoinPack pack;
  final bool isPurchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pack.isBestValue ? AppColors.xpGold.withValues(alpha: 0.5) : pack.isPopular ? AppColors.brand.withValues(alpha: 0.4) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (pack.isPopular || pack.isBestValue)
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: pack.isBestValue ? AppColors.xpGold : AppColors.brand, borderRadius: BorderRadius.circular(6)), child: Text(pack.isBestValue ? 'BEST VALUE' : 'POPULAR', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))),
          const SizedBox(height: 6),
          const Icon(Icons.monetization_on_rounded, color: AppColors.coinYellow, size: 24),
          const SizedBox(height: 6),
          Text(pack.label ?? '${pack.coins} coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text('${pack.totalCoins} coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.coinYellow)),
          if (pack.bonusCoins > 0) Text('+${pack.bonusCoins} bonus', style: const TextStyle(fontSize: 11, color: AppColors.correctGreen, fontWeight: FontWeight.w600)),
          const Spacer(),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: isPurchasing ? null : onBuy, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)), child: isPurchasing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(pack.displayPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
        ]),
      ),
    );
  }
}
