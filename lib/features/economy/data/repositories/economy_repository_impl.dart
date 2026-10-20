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
  Future<Wallet> getWallet() async {
    final dto = await _remote.getWallet();
    return dto.toDomain();
  }

  @override
  Future<WalletLedger> getLedger({String? cursor, int perPage = 20}) async {
    final dto = await _remote.getLedger(cursor: cursor, perPage: perPage);
    return WalletLedger(
      entries: dto.entries.map((d) => d.toDomain()).toList(),
      hasMore: dto.hasMore,
      nextCursor: dto.nextCursor,
    );
  }

  @override
  Future<WalletCategories> getWalletCategories({String period = '30d'}) async {
    final dto = await _remote.getWalletCategories(period: period);
    return dto.toDomain();
  }

  @override
  Future<List<ShopItem>> getShopItems() async {
    final dtos = await _remote.getShopItems();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<ShopPurchaseResult> purchaseShopItem({
    required ShopItemType type,
    required String key,
    int quantity = 1,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.purchaseShopItem(
      type: type,
      key: key,
      quantity: quantity,
      idempotencyKey: idempotencyKey,
    );
    return ShopPurchaseResult(
      success: dto.success,
      itemKey: dto.itemKey,
      itemType: dto.itemType,
      quantity: dto.quantity,
      coinsSpent: dto.coinsSpent,
      coinBalance: dto.coinBalance,
      message: dto.message,
    );
  }

  @override
  Future<void> sellResource({
    required String resource,
    int quantity = 1,
    String? idempotencyKey,
  }) =>
      _remote.sellResource(
        resource: resource,
        quantity: quantity,
        idempotencyKey: idempotencyKey,
      );
}
