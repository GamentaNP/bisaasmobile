import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/datasources/store_remote_data_source.dart';
import '../controllers/store_controller.dart';
import '../../domain/entities/store.dart';
import '../../../../l10n/app_localizations.dart';

/// Wardrobe — equip owned premium assets.
///
/// `GET /store/wardrobe` publishes every slot with the asset equipped in it;
/// `PUT /store/wardrobe/equipment` equips and `DELETE` clears. Every write
/// carries an Idempotency-Key.
///
/// The server's slot names are fixed (`avatar_frame`, `avatar`, `quiz_theme`,
/// `sound_pack`, `mascot`), so an asset whose category is not one of them
/// cannot be equipped and the button is disabled rather than sending a
/// request the server will reject.
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _equippingSlot = slot);
    final ok = await ref.read(storeControllerProvider.notifier).equip(slot, assetId);
    if (!mounted) return;
    setState(() => _equippingSlot = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? l10n.storeEquipped : l10n.storeEquipFailed), backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(storeControllerProvider);
    final theme = Theme.of(context);
    final wardrobe = state.wardrobe;
    final catalog = state.catalog;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storeWardrobeTitle)),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([ref.read(storeControllerProvider.notifier).fetchWardrobe(), ref.read(storeControllerProvider.notifier).fetchCatalog()]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isWardrobeLoading && wardrobe == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            if (state.wardrobeError != null)
              Card(color: AppColors.wrongRed.withValues(alpha: 0.08), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.wardrobeError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(storeControllerProvider.notifier).fetchWardrobe(), child: Text(l10n.retry))]))),
            if (wardrobe != null) ...[
              const SizedBox(height: 12),
              Text(l10n.storeEquippedLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (wardrobe.slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [Icon(Icons.checkroom_rounded, size: 28, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)), const SizedBox(height: 8), Text(l10n.storeNothingEquipped, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 4), Text(l10n.storeNothingEquippedBody, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))]),
                )
              else
                ...wardrobe.slots.map((slot) => _SlotTile(
                      slot: slot,
                      isEquipping: _equippingSlot == slot.slot,
                      onClear: () => ref.read(storeControllerProvider.notifier).unequip(slot.slot),
                    )),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              Text(l10n.storeAvailableToEquip, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(l10n.storeEquipHint, style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              if (catalog == null || catalog.assets.isEmpty)
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: Text(l10n.storeNoAssets, style: TextStyle(fontSize: 11, color: Colors.grey))))
              else
                ...catalog.assets.take(6).map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _rarityColor(a.rarity).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(_iconForAsset(a.category), size: 16, color: _rarityColor(a.rarity))),
                        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        subtitle: Text(l10n.storeAssetMeta(a.category ?? a.slug, a.rarity, a.priceCoins), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: _EquipButton(
                          isEquipping: _equippingSlot == a.category,
                          isOwned: a.isOwned,
                          // The server only accepts its own slot names
                          // (`StoreController::WARDROBE_SLOTS`); the previous
                          // fallback of `'frame'` was a guaranteed 422.
                          onPressed: _isEquippableSlot(a.category)
                              ? () => _equip(a.category!, a.id)
                              : null,
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
    final l10n = AppLocalizations.of(context)!;
    final equipped = slot.equippedAsset;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(_iconForSlot(slot.slot), size: 16, color: AppColors.brand)),
        title: Text(slot.slot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        subtitle: Text(equipped != null ? '${equipped.name}  ${equipped.rarity}' : l10n.storeEmptyEquip, style: TextStyle(fontSize: 11, color: equipped != null ? AppColors.correctGreen : Colors.grey)),
        trailing: isEquipping
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : equipped != null
                // Clear a slot. This button existed in the widget signature but
                // was never rendered, and the call site passed `() {}`.
                ? IconButton(
                    tooltip: l10n.storeClearSlot(slot),
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    color: AppColors.wrongRed,
                    onPressed: onClear,
                  )
                : const Icon(Icons.chevron_right_rounded, size: 18),
      ),
    );
  }
}

class _EquipButton extends StatelessWidget {
  const _EquipButton({required this.isEquipping, required this.isOwned, required this.onPressed});
  final bool isEquipping;
  final bool isOwned;

  /// Null when the asset's category is not a slot the server accepts.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        onPressed: isEquipping ? null : onPressed,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: isEquipping
            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(onPressed == null ? '—' : (isOwned ? 'Equip' : 'Preview'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

/// Whether [category] is one of the wardrobe slots the server accepts.
///
/// `PUT /store/wardrobe/equipment` validates `slot` against
/// `StoreController::WARDROBE_SLOTS`, so an asset in any other category
/// cannot be equipped at all.
bool _isEquippableSlot(String? category) {
  if (category == null) return false;
  return StoreRemoteDataSource.wardrobeSlots.contains(category);
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
