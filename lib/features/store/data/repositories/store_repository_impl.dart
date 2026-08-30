import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_data_source.dart';
import '../models/store_dto.dart';

class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl(this._remote);
  final StoreRemoteDataSource _remote;

  @override
  Future<StoreCatalog> getAssets() async {
    final dtos = await _remote.getAssets();
    if (dtos.isNotEmpty) {
      return StoreCatalog(assets: dtos.map((d) => d.toDomain()).toList(), isDegraded: false);
    }
    // Degraded beta placeholder — local mocks with isDegraded flag
    final mocks = StoreAssetDto.localMocks().map((d) => d.toDomain()).toList();
    return StoreCatalog(assets: mocks, isDegraded: true);
  }

  @override
  Future<StoreAsset?> getAsset(String slug) async {
    final dto = await _remote.getAsset(slug);
    if (dto != null) return dto.toDomain();
    // Fallback to local mock lookup when WO-3 missing
    try {
      final mock = StoreAssetDto.localMocks().firstWhere((m) => m.slug == slug || m.id == slug);
      return mock.toDomain();
    } catch (_) {
      return null;
    }
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
  Future<bool> equip(String slot, String assetId, {String? idempotencyKey}) =>
      _remote.equip(slot, assetId, idempotencyKey: idempotencyKey);

  @override
  Future<List<MarketListing>> getMarket() async {
    final dtos = await _remote.getMarket();
    return dtos.map((d) => d.toDomain()).toList();
  }
}
