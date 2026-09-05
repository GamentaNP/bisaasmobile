import '../../domain/entities/economy.dart';
import '../../domain/repositories/economy_repository.dart';
import '../datasources/economy_remote_data_source.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  const EconomyRepositoryImpl(this._remote);
  final EconomyRemoteDataSource _remote;

  @override
  Future<EconomyInventoryBundle> getInventory({int activityLimit = 10}) async {
    final dto = await _remote.getInventory(activityLimit: activityLimit);
    return dto.toDomain();
  }

  @override
  Future<List<DonorLeaderboardEntry>> getDonationLeaderboard() async {
    final dtos = await _remote.getDonationLeaderboard();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<List<DonationFeedEntry>> getDonationFeed() async {
    final dtos = await _remote.getDonationFeed();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<FreezeStreakResult> freezeStreak({String? idempotencyKey}) async {
    final dto = await _remote.freezeStreak(idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<Wallet?> getWallet() async {
    final dto = await _remote.getWallet();
    return dto?.toDomain();
  }

  @override
  Future<WalletLedger> getLedger({int page = 1, int perPage = 20}) async {
    final dto = await _remote.getLedger(page: page, perPage: perPage);
    final entries = dto.entries.map((d) => d.toDomain()).toList();
    // Degraded comes from the data source (explicit 404 detection), never from
    // an empty list — a new account with zero history is NOT a beta placeholder.
    return WalletLedger(entries: entries, isDegraded: dto.isDegraded, hasMore: false);
  }

  @override
  Future<List<CoinPack>> getShopPacks() async {
    final dtos = await _remote.getShopPacks();
    if (dtos.isNotEmpty) return dtos.map((d) => d.toDomain()).toList();
    // Local mock fallback for beta placeholder when WO-2 missing
    return _localMockPacks();
  }

  @override
  Future<Map<String, dynamic>> purchasePack(String packId, {String? idempotencyKey}) =>
      _remote.purchasePack(packId, idempotencyKey: idempotencyKey);

  // ── local mocks for degraded shop (prices never authority, just display) ────
  // Real purchase always POST /economy/shop/purchase with Idempotency-Key; mock never charges.
  List<CoinPack> _localMockPacks() => const [
        CoinPack(id: 'pack_100', coins: 100, price: 0.99, label: 'Starter', bonusCoins: 0),
        CoinPack(id: 'pack_300', coins: 300, price: 2.99, label: 'Builder', bonusCoins: 20, isPopular: true),
        CoinPack(id: 'pack_700', coins: 700, price: 4.99, label: 'Engineer', bonusCoins: 80, isBestValue: true),
        CoinPack(id: 'pack_1500', coins: 1500, price: 9.99, label: 'Architect', bonusCoins: 250),
        CoinPack(id: 'pack_3500', coins: 3500, price: 19.99, label: 'Master Builder', bonusCoins: 700, isBestValue: true),
      ];
}
