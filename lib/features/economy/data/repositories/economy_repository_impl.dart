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
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<Map<String, dynamic>> purchasePack(String packId, {String? idempotencyKey}) =>
      _remote.purchasePack(packId, idempotencyKey: idempotencyKey);
}
