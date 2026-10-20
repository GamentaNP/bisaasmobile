import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/economy.dart';
import '../controllers/economy_controller.dart';

/// Coin shop — materials and bundles bought with coins.
///
/// `GET /economy/shop` publishes `data.resources` (priced with
/// `base_price_coins`) and `data.bundles` (priced with `price_coins`).
/// `POST /economy/shop/purchase` takes `{type, key, quantity}` and requires an
/// Idempotency-Key, so a retried purchase never charges twice.
///
/// The screen renders exactly what the server published. There is no local
/// placeholder catalogue and no "beta" mode: the endpoint is live, so a
/// failure is an error with a retry, and an empty catalogue is an empty
/// catalogue.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _purchasingKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(economyControllerProvider.notifier).fetchShopItems();
    });
  }

  Future<void> _purchase(ShopItem item) async {
    setState(() => _purchasingKey = item.key);
    final result = await ref.read(economyControllerProvider.notifier).purchaseShopItem(item);
    if (!mounted) return;
    setState(() => _purchasingKey = null);

    final message = result?.message ??
        (result?.success == true ? 'Purchased ${item.name}' : 'Purchase failed');
    final ok = result?.success == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(economyControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    final items = state.shopItems;
    final resources = items.where((i) => i.type == ShopItemType.resource).toList();
    final bundles = items.where((i) => i.type == ShopItemType.bundle).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Coin Shop')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(economyControllerProvider.notifier).fetchShopItems(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.coinYellow.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.coinYellow),
                  const SizedBox(width: 10),
                  Text('${state.wallet?.coins ?? user?.coins ?? 0} coins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coinYellow)),
                ],
              ),
            ),
            if (state.isShopLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            if (state.shopError != null)
              Card(
                color: AppColors.wrongRed.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.shopError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(economyControllerProvider.notifier).fetchShopItems(), child: const Text('Retry'))]),
                ),
              ),
            if (!state.isShopLoading && items.isEmpty && state.shopError == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.store_rounded, size: 28, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(height: 8),
                    const Text('Nothing for sale yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('The shop has no items published on the server right now.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            if (bundles.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Bundles', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...bundles.map((b) => _ShopRow(
                    item: b,
                    isPurchasing: _purchasingKey == b.key,
                    onBuy: () => _purchase(b),
                  )),
            ],
            if (resources.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Materials', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.92),
                itemCount: resources.length,
                itemBuilder: (context, i) {
                  final p = resources[i];
                  return _MaterialCard(
                    item: p,
                    isPurchasing: _purchasingKey == p.key,
                    onBuy: () => _purchase(p),
                  );
                },
              ),
            ],
            if (state.purchaseError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.purchaseError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)))]),
              ),
            ],
            if (state.purchaseMessage != null && state.purchaseError == null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.correctGreen), const SizedBox(width: 8), Expanded(child: Text(state.purchaseMessage!, style: const TextStyle(fontSize: 12, color: AppColors.correctGreen)))]),
              ),
            ],
            const SizedBox(height: 18),
            const Text('If a purchase does not go through, retrying is safe — you are never charged twice.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.item, required this.isPurchasing, required this.onBuy});
  final ShopItem item;
  final bool isPurchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.icon == null ? Icons.inventory_2_rounded : Icons.category_rounded,
              color: AppColors.coinYellow,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (item.category != null) ...[
              const SizedBox(height: 2),
              Text(item.category!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
            const Spacer(),
            Text('${item.priceCoins} coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.coinYellow)),
            if (item.sellPriceCoins != null) ...[
              const SizedBox(height: 2),
              Text('sells back for ${item.sellPriceCoins}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isPurchasing ? null : onBuy,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                child: isPurchasing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.item, required this.isPurchasing, required this.onBuy});
  final ShopItem item;
  final bool isPurchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: AppColors.xpGold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${item.priceCoins} coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.coinYellow)),
                      if (item.discountCoins > 0) ...[
                        const SizedBox(width: 6),
                        Text('save ${item.discountCoins}', style: const TextStyle(fontSize: 10, color: AppColors.correctGreen, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isPurchasing ? null : onBuy,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              child: isPurchasing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
