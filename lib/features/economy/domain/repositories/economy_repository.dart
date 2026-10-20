import '../entities/economy.dart';

abstract class EconomyRepository {
  // ── Inventory / donations ───────────────────────────────────────────────────
  Future<EconomyInventoryBundle> getInventory({int activityLimit});
  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard();
  Future<List<DonationFeedEntry>> getDonationFeed();
  Future<FreezeStreakResult> freezeStreak({String? idempotencyKey});

  // ── Wallet ──────────────────────────────────────────────────────────────────
  /// The current coin balance.
  Future<Wallet> getWallet();

  /// A page of the coin ledger. Cursor-paginated: pass back the
  /// `next_cursor` the previous page returned.
  Future<WalletLedger> getLedger({String? cursor, int perPage});

  /// Own coin spending grouped by source category.
  Future<WalletCategories> getWalletCategories({String period});

  // ── Coin shop ───────────────────────────────────────────────────────────────
  /// The shop catalogue: materials and bundles, priced in coins.
  Future<List<ShopItem>> getShopItems();

  /// Buys a shop row with coins.
  Future<ShopPurchaseResult> purchaseShopItem({
    required ShopItemType type,
    required String key,
    int quantity,
    String? idempotencyKey,
  });

  /// Sells a material resource back for coins.
  Future<void> sellResource({
    required String resource,
    int quantity,
    String? idempotencyKey,
  });
}
