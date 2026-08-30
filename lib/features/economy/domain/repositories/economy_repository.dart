import '../entities/economy.dart';

abstract class EconomyRepository {
  // ── Verified live ───────────────────────────────────────────────────────────
  Future<EconomyInventoryBundle> getInventory({int activityLimit});
  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard();
  Future<List<DonationFeedEntry>> getDonationFeed();
  Future<FreezeStreakResult> freezeStreak({String? idempotencyKey});

  // ── WO-1 / WO-2 degraded — never throw on 404, return empty + isDegraded ──
  Future<Wallet?> getWallet();
  Future<WalletLedger> getLedger({int page, int perPage});
  Future<List<CoinPack>> getShopPacks();
  Future<Map<String, dynamic>> purchasePack(String packId, {String? idempotencyKey});
}
