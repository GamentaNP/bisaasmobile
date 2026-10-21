import 'package:bisaasmobile/core/network/pagination.dart';

import '../entities/store.dart';

abstract class StoreRepository {
  /// A page of the catalogue.
  ///
  /// `GET /store/assets` is cursor-paginated, so the first page is not the
  /// whole catalogue. The caller passes the returned cursor back to load the
  /// rest.
  Future<Page<StoreAsset>> getAssets({String? cursor, int perPage});

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
