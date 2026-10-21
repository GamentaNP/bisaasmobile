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

  /// True when any surface is failing.
  ///
  /// There is no "beta placeholder" mode: every store endpoint the app calls
  /// exists on the server, so a failure is a failure and the UI shows it.
  bool get hasErrors =>
      error != null ||
      catalogError != null ||
      assetError != null ||
      wardrobeError != null ||
      purchaseError != null ||
      equipError != null;

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

  /// Loads a page of the catalogue.
  ///
  /// `GET /store/assets` is cursor-paginated, so the first page is not the
  /// whole catalogue. Pass the cursor back to append the rest.
  Future<void> fetchCatalog({String? cursor, bool append = false}) async {
    state = state.copyWith(isCatalogLoading: true, catalogError: null);
    try {
      final page = await _repo.getAssets(cursor: cursor);
      final assets = append
          ? [...state.catalog?.assets ?? const <StoreAsset>[], ...page.items]
          : page.items;
      state = state.copyWith(
        catalog: StoreCatalog(
          assets: assets,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
        isCatalogLoading: false,
      );
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
      state = state.copyWith(isEquipping: false, equipError: ok ? null : 'Could not equip $slot');
      if (ok) await fetchWardrobe();
      return ok;
    } catch (e, st) {
      AppLogger.w('store equip $slot/$assetId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isEquipping: false, equipError: _msg(e));
      return false;
    }
  }

  /// Empty a wardrobe slot. The clear affordance used to be wired to `() {}`.
  Future<bool> unequip(String slot) async {
    state = state.copyWith(isEquipping: true, equipError: null);
    try {
      final ok = await _repo.unequip(slot, idempotencyKey: _uuid.v4());
      state = state.copyWith(isEquipping: false, equipError: ok ? null : 'Could not clear $slot');
      if (ok) await fetchWardrobe();
      return ok;
    } catch (e, st) {
      AppLogger.w('store unequip $slot failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isEquipping: false, equipError: _msg(e));
      return false;
    }
  }

  /// REMOVED 2026-09-27: `fetchMarket()` existed only to call
  /// `GET /api/v1/store/market`, a route the server has never had. It could only
  /// ever 404 into an empty list. The store screen now links to the real
  /// trading surface (`/economy/shop` and `/economy/inventory`).

  Future<void> refreshAll() async {
    await Future.wait([fetchCatalog(), fetchWardrobe()]);
  }
}

final storeControllerProvider = NotifierProvider<StoreController, StoreState>(StoreController.new);

/// The first page of the catalogue, for surfaces that only need a read.
///
/// The endpoint is cursor-paginated, so this is the **first page**, not the
/// whole catalogue. The store screen uses the controller instead, because it
/// can walk the pages.
final storeCatalogProvider = FutureProvider<StoreCatalog>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  final page = await repo.getAssets();
  return StoreCatalog(
    assets: page.items,
    hasMore: page.hasMore,
    nextCursor: page.nextCursor,
  );
});
