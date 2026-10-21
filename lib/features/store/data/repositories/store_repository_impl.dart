import 'package:bisaasmobile/core/network/pagination.dart';

import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_data_source.dart';

class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl(this._remote);
  final StoreRemoteDataSource _remote;

  @override
  Future<Page<StoreAsset>> getAssets({String? cursor, int perPage = 25}) async {
    final page = await _remote.getAssets(cursor: cursor, perPage: perPage);
    return Page<StoreAsset>(
      items: page.items.map((d) => d.toDomain()).toList(),
      pagination: page.pagination,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<StoreAsset?> getAsset(String slug) async {
    final dto = await _remote.getAsset(slug);
    return dto?.toDomain();
  }

  @override
  Future<StorePurchaseResult> purchaseAsset(String slug, {String? idempotencyKey}) async {
    final dto = await _remote.purchaseAsset(slug, idempotencyKey: idempotencyKey);
    return dto.toDomain();
  }

  @override
  Future<Wardrobe> getWardrobe() async {
    final dto = await _remote.getWardrobe();
    return dto.toDomain();
  }

  @override
  Future<bool> unequip(String slot, {String? idempotencyKey}) =>
      _remote.unequip(slot, idempotencyKey: idempotencyKey);

  @override
  Future<bool> equip(String slot, String assetId, {String? idempotencyKey}) =>
      _remote.equip(slot, assetId, idempotencyKey: idempotencyKey);

}
