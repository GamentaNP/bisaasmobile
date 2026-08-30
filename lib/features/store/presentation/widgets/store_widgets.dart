import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/store.dart';

class AssetGridCard extends StatelessWidget {
  const AssetGridCard({super.key, required this.asset, required this.isPurchasing, required this.onBuy});
  final StoreAsset asset;
  final bool isPurchasing;
  final VoidCallback onBuy;

  Color _rarityColor(String r) {
    switch (r.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFEAB308);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'rare':
        return const Color(0xFF22D3EE);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _icon(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('frame')) return Icons.crop_square_rounded;
    if (c.contains('badge')) return Icons.military_tech_rounded;
    if (c.contains('avatar')) return Icons.person_rounded;
    if (c.contains('theme')) return Icons.palette_rounded;
    return Icons.diamond_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor(asset.rarity);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: rc.withValues(alpha: 0.35)), color: Theme.of(context).colorScheme.surface),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: rc, borderRadius: BorderRadius.circular(6)), child: Text(asset.rarity.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))), const Spacer(), if (asset.isFeatured) const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAB308))]),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: rc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: Icon(_icon(asset.category), size: 22, color: rc)),
          const SizedBox(height: 8),
          Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(asset.category ?? asset.slug, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const Spacer(),
          Row(children: [const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.coinYellow), const SizedBox(width: 4), Text('${asset.priceCoins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.coinYellow))]),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: isPurchasing ? null : onBuy, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)), child: isPurchasing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(asset.isOwned ? 'Owned' : 'Buy', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
        ]),
      ),
    );
  }
}

/// Beta banner reused across economy/store degraded surfaces.
class BetaBanner extends StatelessWidget {
  const BetaBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.brand.withValues(alpha: 0.2))),
      child: Row(children: [const Icon(Icons.science_rounded, size: 16, color: AppColors.brand), const SizedBox(width: 8), Expanded(child: Text(message, style: const TextStyle(fontSize: 11, color: AppColors.brandDark, height: 1.3))), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)), child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)))]),
    );
  }
}
