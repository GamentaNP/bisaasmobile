import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/store_controller.dart';
import '../../domain/entities/store.dart';
import '../../../../l10n/app_localizations.dart';

/// Premium store — assets and skins from `GET /api/v1/store/assets`.
///
/// The six hardcoded assets this screen used to fall back on were removed on
/// 2026-09-27: their prices and rarities were invented and none of their slugs
/// exist on the server, so a "buy" would have 404'd. An unavailable catalogue
/// now renders an honest error with a retry.
/// `POST /store/assets/{asset}/purchase` carries an Idempotency-Key (never
/// double-charge).
class PremiumStoreScreen extends ConsumerStatefulWidget {
  const PremiumStoreScreen({super.key});

  @override
  ConsumerState<PremiumStoreScreen> createState() => _PremiumStoreScreenState();
}

class _PremiumStoreScreenState extends ConsumerState<PremiumStoreScreen> {
  String? _selectedCategory;
  String? _purchasingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeControllerProvider.notifier).fetchCatalog();
    });
  }

  Future<void> _purchase(StoreAsset asset) async {
    setState(() => _purchasingId = asset.id);
    final res = await ref.read(storeControllerProvider.notifier).purchase(asset.slug.isNotEmpty ? asset.slug : asset.id);
    if (!mounted) return;
    setState(() => _purchasingId = null);
    final msg = res?.message ?? (res?.success == true ? 'Purchased ${asset.name}!' : 'Purchase failed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: res?.success == true ? AppColors.correctGreen : AppColors.wrongRed),
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(storeControllerProvider);
    final catalog = state.catalog;
    final theme = Theme.of(context);

    final assets = <StoreAsset>[...catalog?.assets ?? []];
    if (_selectedCategory != null) {
      assets.retainWhere((a) => a.category?.toLowerCase() == _selectedCategory!.toLowerCase());
    }
    assets.sort((a, b) => b.rarityRank.compareTo(a.rarityRank));

    final categories = (catalog?.assets ?? []).map((a) => a.category).whereType<String>().toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storeTitle)),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([ref.read(storeControllerProvider.notifier).fetchCatalog()]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isCatalogLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            if (state.catalogError != null)
              Card(
                color: AppColors.wrongRed.withValues(alpha: 0.08),
                child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.catalogError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(storeControllerProvider.notifier).fetchCatalog(), child: Text(l10n.retry))])),
              ),
            if (catalog != null && categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(label: Text(l10n.storeAll, style: TextStyle(fontSize: 12)), selected: _selectedCategory == null, onSelected: (_) => setState(() => _selectedCategory = null)),
                    const SizedBox(width: 8),
                    for (final c in categories) ...[
                      ChoiceChip(label: Text(c, style: const TextStyle(fontSize: 12)), selected: _selectedCategory == c, onSelected: (v) => setState(() => _selectedCategory = v ? c : null)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
            if (catalog != null) ...[
              const SizedBox(height: 14),
              Text(l10n.storeAssetsCount(assets.length), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (assets.isEmpty)
                Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(l10n.storeNoAssetsInCategory, style: TextStyle(fontSize: 11, color: Colors.grey))))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.88),
                  itemCount: assets.length,
                  itemBuilder: (context, i) {
                    final a = assets[i];
                    return _AssetCard(asset: a, isPurchasing: _purchasingId == a.id, onBuy: () => _purchase(a));
                  },
                ),
              // The catalogue is cursor-paginated, so the first page is not the
              // whole catalogue. Without this the user sees 25 of 60 assets
              // and no way to know 35 more exist.
              if (catalog.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: state.isCatalogLoading
                        ? null
                        : () => ref.read(storeControllerProvider.notifier).fetchCatalog(
                              cursor: catalog.nextCursor,
                              append: true,
                            ),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(l10n.commonLoadMore),
                  ),
                ),
            ],
            if (state.lastPurchaseResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (state.lastPurchaseResult!.success ? AppColors.correctGreen : AppColors.wrongRed).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [Icon(state.lastPurchaseResult!.success ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 16, color: state.lastPurchaseResult!.success ? AppColors.correctGreen : AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.lastPurchaseResult!.message ?? (state.lastPurchaseResult!.success ? 'Success' : 'Failed'), style: TextStyle(fontSize: 12, color: state.lastPurchaseResult!.success ? AppColors.correctGreen : AppColors.wrongRed)))]),
              ),
            ],
            const SizedBox(height: 18),
            // ── Trading ─────────────────────────────────────────────────────
            // There is no community resale marketplace: GET /store/market has
            // never existed on the server. Point at the real coin-trading
            // surface (the economy shop) instead of a permanent placeholder.
            Text(l10n.storeTrading, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.storeTradingExplain,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/economy/shop'),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: Text(l10n.storeCoinShop),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/economy/inventory'),
                    icon: const Icon(Icons.sell_rounded, size: 18),
                    label: Text(l10n.storeSellItems),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.isPurchasing, required this.onBuy});
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rarityColor = _rarityColor(asset.rarity);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: rarityColor.withValues(alpha: 0.35)), color: Theme.of(context).colorScheme.surface),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: rarityColor, borderRadius: BorderRadius.circular(6)), child: Text(asset.rarity.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))), const Spacer(), if (asset.isFeatured) const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAB308))]),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: rarityColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: Icon(_iconForCategory(asset.category), size: 22, color: rarityColor)),
            const SizedBox(height: 8),
            Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(asset.category ?? asset.slug, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Spacer(),
            Row(children: [const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.coinYellow), const SizedBox(width: 4), Text('${asset.priceCoins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.coinYellow)), if (asset.isOwned) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text(l10n.storeOwnedBadge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.correctGreen)))]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // An owned asset cannot be bought again. The button used to
                // fire a purchase for something the user already owned.
                onPressed: (isPurchasing || asset.isOwned) ? null : onBuy,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), backgroundColor: asset.isOwned ? AppColors.correctGreen : null),
                child: isPurchasing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(asset.isOwned ? l10n.storeOwned : l10n.streakBuy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('frame')) return Icons.crop_square_rounded;
    if (c.contains('badge')) return Icons.military_tech_rounded;
    if (c.contains('avatar')) return Icons.person_rounded;
    if (c.contains('theme')) return Icons.palette_rounded;
    if (c.contains('title')) return Icons.title_rounded;
    if (c.contains('effect')) return Icons.auto_awesome_rounded;
    return Icons.diamond_rounded;
  }
}
