import '../entities/store.dart';

abstract class StoreRepository {
  Future<StoreCatalog> getAssets();
  Future<StoreAsset?> getAsset(String slug);
  Future<StorePurchaseResult> purchaseAsset(String slug, {String? idempotencyKey});
  Future<Wardrobe> getWardrobe();
  Future<bool> equip(String slot, String assetId, {String? idempotencyKey});

  /// Empty a slot — `DELETE /store/wardrobe/equipment` with `{slot}`.
  Future<bool> unequip(String slot, {String? idempotencyKey});

  /// `getMarket()` was removed 2026-09-27 — it called `GET /store/market`,
  /// which has never existed on the server. There is no community resale
  /// marketplace; coin trading lives in the economy group
  /// (`GET /economy/shop`, `POST /economy/market/sells`), reached from the
  /// Economy tab.
}
