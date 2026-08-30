import '../entities/store.dart';

abstract class StoreRepository {
  Future<StoreCatalog> getAssets();
  Future<StoreAsset?> getAsset(String slug);
  Future<StorePurchaseResult> purchaseAsset(String slug, {String? idempotencyKey});
  Future<Wardrobe> getWardrobe();
  Future<bool> equip(String slot, String assetId, {String? idempotencyKey});
  Future<List<MarketListing>> getMarket();
}
