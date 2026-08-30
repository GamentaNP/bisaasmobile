// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/economy_controller.dart';

/// Resource inventory — 8 city resources + catalog + recent activity.
/// Live via GET /economy/resources/inventory (throttle:economy-read).
/// Tolerant additive parsing; shows empty/beta placeholder when degraded.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(economyControllerProvider.notifier).fetchInventory();
      ref.read(economyControllerProvider.notifier).fetchLeaderboard();
      ref.read(economyControllerProvider.notifier).fetchFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(economyControllerProvider);
    final theme = Theme.of(context);
    final bundle = state.inventoryBundle;
    final isLoading = state.isInventoryLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(economyControllerProvider.notifier).fetchInventory(),
          ref.read(economyControllerProvider.notifier).fetchLeaderboard(),
          ref.read(economyControllerProvider.notifier).fetchFeed(),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (bundle?.isDegraded == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.brand.withValues(alpha: 0.2))),
                child: Row(children: [const Icon(Icons.science_rounded, size: 16, color: AppColors.brand), const SizedBox(width: 8), const Expanded(child: Text('Inventory in beta — catalog will populate when economy resources sync.', style: TextStyle(fontSize: 11, color: AppColors.brandDark)))]),
              ),
            if (state.inventoryError != null)
              Card(
                color: AppColors.wrongRed.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.inventoryError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(economyControllerProvider.notifier).fetchInventory(), child: const Text('Retry'))]),
                ),
              ),
            if (isLoading && bundle == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),

            // ── Inventory headline ────────────────────────────────────────────
            if (bundle != null) ...[
              Text('Your resources', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${bundle.inventory.length} held • ${bundle.catalog.length} catalog • ${bundle.recentActivity.length} recent',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              if (bundle.inventory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Icon(Icons.inventory_2_rounded, size: 28, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(height: 8),
                    const Text('No resources yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Resources are earned via city / economy flows and quiz rewards. They appear here when available.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
                  ]),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2),
                  itemCount: bundle.inventory.length,
                  itemBuilder: (context, i) {
                    final item = bundle.inventory[i];
                    return _ResourceTile(name: item.name, resourceKey: item.key, quantity: item.quantity, category: item.category, icon: item.icon);
                  },
                ),
              const SizedBox(height: 18),
              Text('Catalog', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (bundle.catalog.isEmpty)
                const Text('Catalog empty — server will populate material list.', style: TextStyle(fontSize: 11, color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bundle.catalog.map((c) => Chip(label: Text(c.name, style: const TextStyle(fontSize: 11)), avatar: Icon(_iconForKey(c.icon ?? c.key), size: 14))).toList(),
                ),
              const SizedBox(height: 18),
              Text('Recent activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (bundle.recentActivity.isEmpty)
                const Text('No recent activity.', style: TextStyle(fontSize: 11, color: Colors.grey))
              else
                ...bundle.recentActivity.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (a.delta >= 0 ? AppColors.correctGreen : AppColors.wrongRed).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(a.delta >= 0 ? Icons.add_rounded : Icons.remove_rounded, size: 14, color: a.delta >= 0 ? AppColors.correctGreen : AppColors.wrongRed)),
                        title: Text('${a.resourceName}  ${a.delta >= 0 ? '+' : ''}${a.delta}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        subtitle: Text('${a.reason ?? a.sourceType ?? ''} • ${_fmt(a.occurredAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('${a.balanceAfter}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    )),
            ],

            const SizedBox(height: 20),
            const Divider(),
            // ── Donations (live) ──────────────────────────────────────────────
            Text('Donations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Live via GET /donations/leaderboard + /feed. Coins can freeze a donor streak.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: state.isFreezingStreak
                        ? null
                        : () async {
                            final res = await ref.read(economyControllerProvider.notifier).freezeStreak();
                            if (!context.mounted) return;
                            final msg = res?.message ?? (res?.frozen == true ? 'Streak frozen!' : 'Freeze failed');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: res?.frozen == true ? AppColors.correctGreen : AppColors.wrongRed));
                          },
                    icon: state.isFreezingStreak ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.ac_unit_rounded, size: 16),
                    label: const Text('Freeze streak (50 coins)', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            if (state.freezeMessage != null) ...[
              const SizedBox(height: 6),
              Text(state.freezeMessage!, style: TextStyle(fontSize: 11, color: state.lastFreezeResult?.frozen == true ? AppColors.correctGreen : AppColors.wrongRed)),
            ],
            const SizedBox(height: 12),
            if (state.isLeaderboardLoading || state.isFeedLoading)
              const LinearProgressIndicator(),
            if (state.leaderboardError != null || state.feedError != null) ...[
              Text('Leaderboard/feed: ${state.leaderboardError ?? state.feedError}', style: const TextStyle(fontSize: 11, color: AppColors.wrongRed)),
              TextButton(onPressed: () => Future.wait([ref.read(economyControllerProvider.notifier).fetchLeaderboard(), ref.read(economyControllerProvider.notifier).fetchFeed()]), child: const Text('Retry')),
            ],
            if (state.leaderboard.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Leaderboard', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...state.leaderboard.take(5).map((e) => ListTile(
                    dense: true,
                    leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: _parseColor(e.badgeColor), shape: BoxShape.circle)),
                    title: Text(e.donorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    subtitle: Text('${e.badgeLabel} • ${e.streakMonths} mo streak', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Text(e.totalDonatedFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  )),
            ],
            if (state.feed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Live feed', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...state.feed.take(5).map((e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.favorite_rounded, size: 14, color: AppColors.wrongRed),
                    title: Text('${e.displayName} — ${e.amountFormatted}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    subtitle: Text('${e.message ?? ''} • ${e.timeAgo}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
            ],
            if (state.leaderboard.isEmpty && state.feed.isEmpty && !state.isLeaderboardLoading && !state.isFeedLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Donation leaderboard and feed are empty.', style: TextStyle(fontSize: 11, color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat.MMMd().add_jm().format(d.toLocal());

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.grey;
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.name, required this.resourceKey, required this.quantity, this.category, this.icon});
  final String name;
  final String resourceKey;
  final int quantity;
  final String? category;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(_iconForKey(icon ?? resourceKey), size: 16, color: AppColors.brand)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(resourceKey, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
        ],
      ),
    );
  }
}

IconData _iconForKey(String key) {
  final k = key.toLowerCase();
  if (k.contains('brick')) return Icons.view_module_rounded;
  if (k.contains('cement')) return Icons.layers_rounded;
  if (k.contains('steel')) return Icons.construction_rounded;
  if (k.contains('sand')) return Icons.landscape_rounded;
  if (k.contains('wood')) return Icons.forest_rounded;
  if (k.contains('paint')) return Icons.format_paint_rounded;
  if (k.contains('glass')) return Icons.window_rounded;
  if (k.contains('tile')) return Icons.grid_view_rounded;
  if (k.contains('frame')) return Icons.crop_square_rounded;
  if (k.contains('badge')) return Icons.military_tech_rounded;
  return Icons.inventory_2_rounded;
}
