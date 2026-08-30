import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/economy_controller.dart';
import '../../domain/entities/economy.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Coin shop — packs (WO-2). Idempotency-Key on every POST /economy/shop/purchase
/// even when endpoint returns 404 (graceful beta — never crashes, never double-charges).
/// Prices are never hardcoded beyond local mock placeholder; server price wins when it ships.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _purchasingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(economyControllerProvider.notifier).fetchPacks();
    });
  }

  Future<void> _purchase(CoinPack pack) async {
    setState(() => _purchasingId = pack.id);
    final res = await ref.read(economyControllerProvider.notifier).purchasePack(pack.id);
    if (!mounted) return;
    setState(() => _purchasingId = null);
    final msg = res?['message'] as String? ?? (res?['is_degraded'] == true ? 'Shop is in beta — purchases will be live when WO-2 ships.' : 'Purchase attempted.');
    final isDegraded = res?['is_degraded'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isDegraded ? AppColors.brandDark : (res?['success'] == true ? AppColors.correctGreen : AppColors.wrongRed),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(economyControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    final packs = state.packs;

    return Scaffold(
      appBar: AppBar(title: const Text('Coin Shop')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(economyControllerProvider.notifier).fetchPacks(),
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
                  Text('${user?.coins ?? 0} coins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coinYellow)),
                  const Spacer(),
                  if (state.isPacksDegraded)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)), child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
            if (state.isPacksDegraded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.brand.withValues(alpha: 0.2))),
                child: Row(
                  children: [
                    const Icon(Icons.science_rounded, size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Shop is in beta — packs are preview only until GET /economy/shop ships (WO-2). No real charge yet.', style: TextStyle(fontSize: 11, color: AppColors.brandDark, height: 1.3))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)), child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                ),
              ),
            ],
            if (state.isPacksLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            if (state.packsError != null)
              Card(
                color: AppColors.wrongRed.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.packsError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(economyControllerProvider.notifier).fetchPacks(), child: const Text('Retry'))]),
                ),
              ),
            if (!state.isPacksLoading && packs.isEmpty && state.packsError == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.store_rounded, size: 28, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(height: 8),
                    const Text('No packs yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Coin packs will appear here when the shop ships.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            if (packs.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Packs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.92),
                itemCount: packs.length,
                itemBuilder: (context, i) {
                  final p = packs[i];
                  final isPurchasing = _purchasingId == p.id;
                  return _PackCard(pack: p, isPurchasing: isPurchasing, onBuy: () => _purchase(p));
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
            const Text('Purchases use Idempotency-Key — retries reuse the same key so you are never double-charged. Server is source of truth for balance.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.isPurchasing, required this.onBuy});
  final CoinPack pack;
  final bool isPurchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pack.isBestValue ? AppColors.xpGold.withValues(alpha: 0.5) : pack.isPopular ? AppColors.brand.withValues(alpha: 0.4) : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35), width: pack.isBestValue || pack.isPopular ? 1.5 : 1),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pack.isPopular || pack.isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: pack.isBestValue ? AppColors.xpGold : AppColors.brand, borderRadius: BorderRadius.circular(6)),
                    child: Text(pack.isBestValue ? 'BEST VALUE' : 'POPULAR', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                const SizedBox(height: 8),
                const Icon(Icons.monetization_on_rounded, color: AppColors.coinYellow, size: 28),
                const SizedBox(height: 6),
                Text(pack.label ?? '${pack.coins} coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${pack.totalCoins} coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.coinYellow)),
                if (pack.bonusCoins > 0) Text('+${pack.bonusCoins} bonus', style: const TextStyle(fontSize: 11, color: AppColors.correctGreen, fontWeight: FontWeight.w600)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isPurchasing ? null : onBuy,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: isPurchasing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(pack.displayPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
