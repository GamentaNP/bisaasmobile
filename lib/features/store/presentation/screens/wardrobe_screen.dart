import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/store_controller.dart';
import '../../domain/entities/store.dart';

/// Wardrobe — equip owned premium assets.
/// WO-3 missing → tolerant degraded placeholder (local mock slots + beta banner).
/// POST /store/wardrobe/equip carries Idempotency-Key.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String? _equippingSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeControllerProvider.notifier).fetchWardrobe();
      ref.read(storeControllerProvider.notifier).fetchCatalog();
    });
  }

  Future<void> _equip(String slot, String assetId) async {
    setState(() => _equippingSlot = slot);
    final ok = await ref.read(storeControllerProvider.notifier).equip(slot, assetId);
    if (!mounted) return;
    setState(() => _equippingSlot = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Equipped!' : 'Equip in beta — will be live when WO-3 ships.'), backgroundColor: ok ? AppColors.correctGreen : AppColors.brandDark));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeControllerProvider);
    final theme = Theme.of(context);
    final wardrobe = state.wardrobe;
    final catalog = state.catalog;
    final isDegraded = state.isDegraded;

    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([ref.read(storeControllerProvider.notifier).fetchWardrobe(), ref.read(storeControllerProvider.notifier).fetchCatalog()]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isDegraded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.brand.withValues(alpha: 0.2))),
                child: Row(children: [const Icon(Icons.science_rounded, size: 16, color: AppColors.brand), const SizedBox(width: 8), const Expanded(child: Text('Wardrobe in beta — preview slots only until GET /store/wardrobe ships (WO-3). Equipping is local preview.', style: TextStyle(fontSize: 11, color: AppColors.brandDark, height: 1.3))), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)), child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)))]),
              ),
            if (state.isWardrobeLoading && wardrobe == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            if (state.wardrobeError != null)
              Card(color: AppColors.wrongRed.withValues(alpha: 0.08), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.wardrobeError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(storeControllerProvider.notifier).fetchWardrobe(), child: const Text('Retry'))]))),
            if (wardrobe != null) ...[
              const SizedBox(height: 12),
              Text('Equipped', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (wardrobe.slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [Icon(Icons.checkroom_rounded, size: 28, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)), const SizedBox(height: 8), const Text('Nothing equipped', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 4), const Text('Buy assets in the Premium Store, then equip them here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))]),
                )
              else
                ...wardrobe.slots.map((slot) => _SlotTile(
                      slot: slot,
                      isEquipping: _equippingSlot == slot.slot,
                      onClear: () {}, // WO-3 has no unequip; preview only
                    )),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              Text('Available to equip', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tap Equip to preview — server equip is Idempotency-Key guarded.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              if (catalog == null || catalog.assets.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: Text('No assets yet — visit Premium Store.', style: TextStyle(fontSize: 11, color: Colors.grey))))
              else
                ...catalog.assets.take(6).map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _rarityColor(a.rarity).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(_iconForAsset(a.category), size: 16, color: _rarityColor(a.rarity))),
                        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        subtitle: Text('${a.category ?? a.slug} • ${a.rarity} • ${a.priceCoins} coins', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: _EquipButton(
                          isEquipping: _equippingSlot == (a.category ?? a.id),
                          isOwned: a.isOwned,
                          onPressed: () => _equip(a.category ?? 'frame', a.id),
                        ),
                      ),
                    )),
            ],
            if (state.equipError != null) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.equipError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)))])),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.isEquipping, required this.onClear});
  final WardrobeSlot slot;
  final bool isEquipping;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final equipped = slot.equippedAsset;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(_iconForSlot(slot.slot), size: 16, color: AppColors.brand)),
        title: Text(slot.slot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        subtitle: Text(equipped != null ? '${equipped.name} • ${equipped.rarity}' : 'Empty — equip from store', style: TextStyle(fontSize: 11, color: equipped != null ? AppColors.correctGreen : Colors.grey)),
        trailing: isEquipping ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : (equipped != null ? const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.correctGreen) : const Icon(Icons.chevron_right_rounded, size: 18)),
      ),
    );
  }
}

class _EquipButton extends StatelessWidget {
  const _EquipButton({required this.isEquipping, required this.isOwned, required this.onPressed});
  final bool isEquipping;
  final bool isOwned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        onPressed: isEquipping ? null : onPressed,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: isEquipping
            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(isOwned ? 'Equip' : 'Preview', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

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

IconData _iconForSlot(String slot) {
  final s = slot.toLowerCase();
  if (s.contains('frame')) return Icons.crop_square_rounded;
  if (s.contains('badge')) return Icons.military_tech_rounded;
  if (s.contains('theme')) return Icons.palette_rounded;
  if (s.contains('title')) return Icons.title_rounded;
  if (s.contains('avatar')) return Icons.person_rounded;
  return Icons.checkroom_rounded;
}

IconData _iconForAsset(String? cat) {
  final c = (cat ?? '').toLowerCase();
  if (c.contains('frame')) return Icons.crop_square_rounded;
  if (c.contains('badge')) return Icons.military_tech_rounded;
  if (c.contains('avatar')) return Icons.person_rounded;
  if (c.contains('theme')) return Icons.palette_rounded;
  return Icons.diamond_rounded;
}
