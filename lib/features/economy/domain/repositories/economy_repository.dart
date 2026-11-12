import '../entities/economy.dart';

abstract class EconomyRepository {
  // ── Donations ───────────────────────────────────────────────────────────────
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
}
