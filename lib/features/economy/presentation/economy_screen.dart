import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Economy hub — destinations inside Profile (5 tabs stay Home/Play/Calculate/Learn/Profile per task_plan.md R4).
/// Routes: /economy/wallet (balance+ledger grouped by day), /economy/shop (packs), /economy/inventory (8 resources).
/// Wallet/Shop/Ledger are WO-1/WO-2 beta (no API yet) → tolerant degraded placeholders; never crash on added field (law 11).
/// Verified live: GET /economy/resources/inventory, GET /donations/leaderboard|feed, POST /donations/freeze-streak.
/// Flutter never mints, never grades, never ranks locally — coins are server-authoritative via EconomyService::debit.
class EconomyScreen extends ConsumerWidget {
  const EconomyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final coins = user?.coins ?? 0;
    final xp = user?.xp ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Economy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.coinYellow.withValues(alpha: 0.2))),
            child: Row(children: [const Icon(Icons.monetization_on_rounded, color: AppColors.coinYellow, size: 32), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$coins coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.coinYellow)), Text('$xp XP total', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))])]),
          ),
          const SizedBox(height: 12),
          const Text('Balance, ledger, shop and store are all live. Coins are minted server-side when a graded attempt completes.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _HubTile(icon: Icons.account_balance_wallet_rounded, title: 'Wallet - balance + ledger by day', subtitle: 'Balance, lifetime totals and your coin history', route: '/economy/wallet'),
          _HubTile(icon: Icons.shopping_bag_rounded, title: 'Coin Shop - resources & bundles', subtitle: 'Spend coins on materials and bundles', route: '/economy/shop'),
          _HubTile(icon: Icons.inventory_2_rounded, title: 'Inventory — resources + donations', subtitle: '8 materials + catalog + live donations feed/leaderboard', route: '/economy/inventory'),
          const Divider(height: 24),
          _HubTile(icon: Icons.diamond_rounded, title: 'Premium Store - assets & skins', subtitle: 'Buy frames, themes, badges and avatars', route: '/store'),
          _HubTile(icon: Icons.checkroom_rounded, title: 'Wardrobe - equip', subtitle: 'Equip or clear the assets you own', route: '/store/wardrobe'),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.icon, required this.title, required this.subtitle, required this.route});
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.brand)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () => context.go(route),
      ),
    );
  }
}
