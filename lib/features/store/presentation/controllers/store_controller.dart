import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/store_remote_data_source.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final storeRemoteDataSourceProvider = Provider<StoreRemoteDataSource>((ref) {
  return StoreRemoteDataSource(DioClient.instance.dio);
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepositoryImpl(ref.watch(storeRemoteDataSourceProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class StoreState {
  const StoreState({
    this.isLoading = false,
    this.error,
    this.catalog,
    this.isCatalogLoading = false,
    this.catalogError,
    this.selectedAsset,
    this.isAssetLoading = false,
    this.assetError,
    this.wardrobe,
    this.isWardrobeLoading = false,
    this.wardrobeError,
    this.market = const [],
    this.isMarketLoading = false,
    this.marketError,
    this.isMarketDegraded = false,
    this.isPurchasing = false,
    this.purchaseError,
    this.lastPurchaseResult,
    this.isEquipping = false,
    this.equipError,
  });

  final bool isLoading;
  final String? error;

  final StoreCatalog? catalog;
  final bool isCatalogLoading;
  final String? catalogError;

  final StoreAsset? selectedAsset;
  final bool isAssetLoading;
  final String? assetError;

  final Wardrobe? wardrobe;
  final bool isWardrobeLoading;
  final String? wardrobeError;

  final List<MarketListing> market;
  final bool isMarketLoading;
  final String? marketError;
  final bool isMarketDegraded;

  final bool isPurchasing;
  final String? purchaseError;
  final StorePurchaseResult? lastPurchaseResult;

  final bool isEquipping;
  final String? equipError;

  /// Global degraded: store is entirely WO-3 beta until backend ships.
  bool get isDegraded => catalog?.isDegraded == true || wardrobe?.isDegraded == true;

  static const _sentinel = Object();

  StoreState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    Object? catalog = _sentinel,
    bool? isCatalogLoading,
    Object? catalogError = _sentinel,
    Object? selectedAsset = _sentinel,
    bool? isAssetLoading,
    Object? assetError = _sentinel,
    Object? wardrobe = _sentinel,
    bool? isWardrobeLoading,
    Object? wardrobeError = _sentinel,
    List<MarketListing>? market,
    bool? isMarketLoading,
    Object? marketError = _sentinel,
    bool? isMarketDegraded,
    bool? isPurchasing,
    Object? purchaseError = _sentinel,
    Object? lastPurchaseResult = _sentinel,
    bool? isEquipping,
    Object? equipError = _sentinel,
  }) {
    return StoreState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      catalog: catalog == _sentinel ? this.catalog : catalog as StoreCatalog?,
      isCatalogLoading: isCatalogLoading ?? this.isCatalogLoading,
      catalogError: catalogError == _sentinel ? this.catalogError : catalogError as String?,
      selectedAsset: selectedAsset == _sentinel ? this.selectedAsset : selectedAsset as StoreAsset?,
      isAssetLoading: isAssetLoading ?? this.isAssetLoading,
      assetError: assetError == _sentinel ? this.assetError : assetError as String?,
      wardrobe: wardrobe == _sentinel ? this.wardrobe : wardrobe as Wardrobe?,
      isWardrobeLoading: isWardrobeLoading ?? this.isWardrobeLoading,
      wardrobeError: wardrobeError == _sentinel ? this.wardrobeError : wardrobeError as String?,
      market: market ?? this.market,
      isMarketLoading: isMarketLoading ?? this.isMarketLoading,
      marketError: marketError == _sentinel ? this.marketError : marketError as String?,
      isMarketDegraded: isMarketDegraded ?? this.isMarketDegraded,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseError: purchaseError == _sentinel ? this.purchaseError : purchaseError as String?,
      lastPurchaseResult: lastPurchaseResult == _sentinel ? this.lastPurchaseResult : lastPurchaseResult as StorePurchaseResult?,
      isEquipping: isEquipping ?? this.isEquipping,
      equipError: equipError == _sentinel ? this.equipError : equipError as String?,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class StoreController extends Notifier<StoreState> {
  @override
  StoreState build() => const StoreState();

  StoreRepository get _repo => ref.read(storeRepositoryProvider);
  static const _uuid = Uuid();

  String _msg(Object e) => e.toString();

  Future<void> fetchCatalog() async {
    state = state.copyWith(isCatalogLoading: true, catalogError: null);
    try {
      final c = await _repo.getAssets();
      state = state.copyWith(catalog: c, isCatalogLoading: false);
      if (c.isDegraded) AppLogger.w('store fetchCatalog: serving local mock degraded placeholder');
    } catch (e, st) {
      AppLogger.w('store fetchCatalog failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isCatalogLoading: false, catalogError: _msg(e));
    }
  }

  Future<void> fetchAsset(String slug) async {
    state = state.copyWith(isAssetLoading: true, assetError: null);
    try {
      final a = await _repo.getAsset(slug);
      state = state.copyWith(selectedAsset: a, isAssetLoading: false);
      if (a == null) state = state.copyWith(assetError: 'Asset not found');
    } catch (e, st) {
      AppLogger.w('store fetchAsset $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isAssetLoading: false, assetError: _msg(e));
    }
  }

  Future<StorePurchaseResult?> purchase(String slug) async {
    state = state.copyWith(isPurchasing: true, purchaseError: null, lastPurchaseResult: null);
    try {
      final res = await _repo.purchaseAsset(slug, idempotencyKey: _uuid.v4());
      if (res.isDegraded) AppLogger.w('store purchase $slug degraded: ${res.message}');
      state = state.copyWith(isPurchasing: false, lastPurchaseResult: res, purchaseError: res.success ? null : res.message);
      if (res.success) {
        await fetchCatalog();
        await fetchWardrobe();
      }
      return res;
    } catch (e, st) {
      AppLogger.w('store purchase $slug failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isPurchasing: false, purchaseError: _msg(e));
      return null;
    }
  }

  Future<void> fetchWardrobe() async {
    state = state.copyWith(isWardrobeLoading: true, wardrobeError: null);
    try {
      final w = await _repo.getWardrobe();
      state = state.copyWith(wardrobe: w, isWardrobeLoading: false);
    } catch (e, st) {
      AppLogger.w('store fetchWardrobe failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isWardrobeLoading: false, wardrobeError: _msg(e));
    }
  }

  Future<bool> equip(String slot, String assetId) async {
    state = state.copyWith(isEquipping: true, equipError: null);
    try {
      final ok = await _repo.equip(slot, assetId, idempotencyKey: _uuid.v4());
      state = state.copyWith(isEquipping: false, equipError: ok ? null : 'Equip failed (beta — not available yet)');
      if (ok) await fetchWardrobe();
      return ok;
    } catch (e, st) {
      AppLogger.w('store equip $slot/$assetId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isEquipping: false, equipError: _msg(e));
      return false;
    }
  }

  Future<void> fetchMarket() async {
    state = state.copyWith(isMarketLoading: true, marketError: null);
    try {
      final m = await _repo.getMarket();
      final degraded = m.isEmpty;
      state = state.copyWith(market: m, isMarketLoading: false, isMarketDegraded: degraded);
      if (degraded) AppLogger.w('store fetchMarket: empty — beta placeholder');
    } catch (e, st) {
      AppLogger.w('store fetchMarket failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isMarketLoading: false, marketError: _msg(e), isMarketDegraded: true);
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchCatalog(), fetchWardrobe(), fetchMarket()]);
  }
}

final storeControllerProvider = NotifierProvider<StoreController, StoreState>(StoreController.new);

final storeCatalogProvider = FutureProvider<StoreCatalog>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getAssets();
});
