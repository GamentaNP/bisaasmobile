import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/economy_remote_data_source.dart';
import '../../data/repositories/economy_repository_impl.dart';
import '../../domain/entities/economy.dart';
import '../../domain/repositories/economy_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final economyRemoteDataSourceProvider = Provider<EconomyRemoteDataSource>((ref) {
  return EconomyRemoteDataSource(DioClient.instance.dio);
});

final economyRepositoryProvider = Provider<EconomyRepository>((ref) {
  return EconomyRepositoryImpl(ref.watch(economyRemoteDataSourceProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class EconomyState {
  const EconomyState({
    this.isLoading = false,
    this.error,
    this.inventoryBundle,
    this.isInventoryLoading = false,
    this.inventoryError,
    this.leaderboard = const [],
    this.isLeaderboardLoading = false,
    this.leaderboardError,
    this.feed = const [],
    this.isFeedLoading = false,
    this.feedError,
    this.wallet,
    this.isWalletLoading = false,
    this.walletError,
    this.ledger = const [],
    this.isLedgerLoading = false,
    this.ledgerError,
    this.isLedgerDegraded = false,
    this.packs = const [],
    this.isPacksLoading = false,
    this.packsError,
    this.isPacksDegraded = false,
    this.isFreezingStreak = false,
    this.freezeMessage,
    this.lastFreezeResult,
    this.isPurchasing = false,
    this.purchaseError,
    this.purchaseMessage,
  });

  final bool isLoading;
  final String? error;

  final EconomyInventoryBundle? inventoryBundle;
  final bool isInventoryLoading;
  final String? inventoryError;

  final List<DonorLeaderboardEntry> leaderboard;
  final bool isLeaderboardLoading;
  final String? leaderboardError;

  final List<DonationFeedEntry> feed;
  final bool isFeedLoading;
  final String? feedError;

  final Wallet? wallet;
  final bool isWalletLoading;
  final String? walletError;

  final List<LedgerEntry> ledger;
  final bool isLedgerLoading;
  final String? ledgerError;
  final bool isLedgerDegraded;

  final List<CoinPack> packs;
  final bool isPacksLoading;
  final String? packsError;
  final bool isPacksDegraded;

  final bool isFreezingStreak;
  final String? freezeMessage;
  final FreezeStreakResult? lastFreezeResult;

  final bool isPurchasing;
  final String? purchaseError;
  final String? purchaseMessage;

  /// Global degraded: any WO missing surface is in beta placeholder mode.
  /// Wallet/ledger/shop/market/wardrobe have no API per master :134.
  bool get isDegraded => isLedgerDegraded || isPacksDegraded || inventoryBundle?.isDegraded == true;

  static const _sentinel = Object();

  EconomyState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    Object? inventoryBundle = _sentinel,
    bool? isInventoryLoading,
    Object? inventoryError = _sentinel,
    List<DonorLeaderboardEntry>? leaderboard,
    bool? isLeaderboardLoading,
    Object? leaderboardError = _sentinel,
    List<DonationFeedEntry>? feed,
    bool? isFeedLoading,
    Object? feedError = _sentinel,
    Object? wallet = _sentinel,
    bool? isWalletLoading,
    Object? walletError = _sentinel,
    List<LedgerEntry>? ledger,
    bool? isLedgerLoading,
    Object? ledgerError = _sentinel,
    bool? isLedgerDegraded,
    List<CoinPack>? packs,
    bool? isPacksLoading,
    Object? packsError = _sentinel,
    bool? isPacksDegraded,
    bool? isFreezingStreak,
    Object? freezeMessage = _sentinel,
    Object? lastFreezeResult = _sentinel,
    bool? isPurchasing,
    Object? purchaseError = _sentinel,
    Object? purchaseMessage = _sentinel,
  }) {
    return EconomyState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      inventoryBundle: inventoryBundle == _sentinel ? this.inventoryBundle : inventoryBundle as EconomyInventoryBundle?,
      isInventoryLoading: isInventoryLoading ?? this.isInventoryLoading,
      inventoryError: inventoryError == _sentinel ? this.inventoryError : inventoryError as String?,
      leaderboard: leaderboard ?? this.leaderboard,
      isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
      leaderboardError: leaderboardError == _sentinel ? this.leaderboardError : leaderboardError as String?,
      feed: feed ?? this.feed,
      isFeedLoading: isFeedLoading ?? this.isFeedLoading,
      feedError: feedError == _sentinel ? this.feedError : feedError as String?,
      wallet: wallet == _sentinel ? this.wallet : wallet as Wallet?,
      isWalletLoading: isWalletLoading ?? this.isWalletLoading,
      walletError: walletError == _sentinel ? this.walletError : walletError as String?,
      ledger: ledger ?? this.ledger,
      isLedgerLoading: isLedgerLoading ?? this.isLedgerLoading,
      ledgerError: ledgerError == _sentinel ? this.ledgerError : ledgerError as String?,
      isLedgerDegraded: isLedgerDegraded ?? this.isLedgerDegraded,
      packs: packs ?? this.packs,
      isPacksLoading: isPacksLoading ?? this.isPacksLoading,
      packsError: packsError == _sentinel ? this.packsError : packsError as String?,
      isPacksDegraded: isPacksDegraded ?? this.isPacksDegraded,
      isFreezingStreak: isFreezingStreak ?? this.isFreezingStreak,
      freezeMessage: freezeMessage == _sentinel ? this.freezeMessage : freezeMessage as String?,
      lastFreezeResult: lastFreezeResult == _sentinel ? this.lastFreezeResult : lastFreezeResult as FreezeStreakResult?,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseError: purchaseError == _sentinel ? this.purchaseError : purchaseError as String?,
      purchaseMessage: purchaseMessage == _sentinel ? this.purchaseMessage : purchaseMessage as String?,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class EconomyController extends Notifier<EconomyState> {
  @override
  EconomyState build() => const EconomyState();

  EconomyRepository get _repo => ref.read(economyRepositoryProvider);
  static const _uuid = Uuid();

  String _msg(Object e) => e.toString();

  // ── Inventory (live) ──────────────────────────────────────────────────────

  Future<void> fetchInventory({int activityLimit = 10}) async {
    state = state.copyWith(isInventoryLoading: true, inventoryError: null);
    try {
      final bundle = await _repo.getInventory(activityLimit: activityLimit);
      state = state.copyWith(inventoryBundle: bundle, isInventoryLoading: false);
    } catch (e, st) {
      AppLogger.w('economy fetchInventory failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isInventoryLoading: false, inventoryError: _msg(e));
    }
  }

  // ── Donations (live) ──────────────────────────────────────────────────────

  Future<void> fetchLeaderboard() async {
    state = state.copyWith(isLeaderboardLoading: true, leaderboardError: null);
    try {
      final l = await _repo.getDonationLeaderboard();
      state = state.copyWith(leaderboard: l, isLeaderboardLoading: false);
    } catch (e, st) {
      AppLogger.w('economy fetchLeaderboard failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLeaderboardLoading: false, leaderboardError: _msg(e));
    }
  }

  Future<void> fetchFeed() async {
    state = state.copyWith(isFeedLoading: true, feedError: null);
    try {
      final f = await _repo.getDonationFeed();
      state = state.copyWith(feed: f, isFeedLoading: false);
    } catch (e, st) {
      AppLogger.w('economy fetchFeed failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isFeedLoading: false, feedError: _msg(e));
    }
  }

  Future<FreezeStreakResult?> freezeStreak() async {
    state = state.copyWith(isFreezingStreak: true, freezeMessage: null, lastFreezeResult: null);
    try {
      final res = await _repo.freezeStreak(idempotencyKey: _uuid.v4());
      state = state.copyWith(isFreezingStreak: false, lastFreezeResult: res, freezeMessage: res.message);
      return res;
    } catch (e, st) {
      AppLogger.w('economy freezeStreak failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isFreezingStreak: false, freezeMessage: _msg(e));
      return null;
    }
  }

  // ── Wallet / Ledger (WO-1 degraded) ───────────────────────────────────────

  Future<void> fetchWallet() async {
    state = state.copyWith(isWalletLoading: true, walletError: null);
    try {
      final w = await _repo.getWallet();
      state = state.copyWith(wallet: w, isWalletLoading: false);
    } catch (e, st) {
      AppLogger.w('economy fetchWallet failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isWalletLoading: false, walletError: _msg(e));
    }
  }

  Future<void> fetchLedger({int page = 1, int perPage = 20}) async {
    state = state.copyWith(isLedgerLoading: true, ledgerError: null);
    try {
      final ledger = await _repo.getLedger(page: page, perPage: perPage);
      // Repository returns empty with isDegraded heuristic when WO-1 missing.
      // Surface degraded flag so UI can show beta placeholder.
      state = state.copyWith(ledger: ledger.entries, isLedgerLoading: false, isLedgerDegraded: ledger.isDegraded);
    } catch (e, st) {
      AppLogger.w('economy fetchLedger failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLedgerLoading: false, ledgerError: _msg(e), isLedgerDegraded: true);
    }
  }

  // ── Shop packs (WO-2 degraded) ────────────────────────────────────────────

  Future<void> fetchPacks() async {
    state = state.copyWith(isPacksLoading: true, packsError: null);
    try {
      final p = await _repo.getShopPacks();
      final reallyDegraded = _isMockPacks(p);
      state = state.copyWith(packs: p, isPacksLoading: false, isPacksDegraded: reallyDegraded);
      if (reallyDegraded) AppLogger.w('economy fetchPacks: serving local mock degraded placeholder');
    } catch (e, st) {
      AppLogger.w('economy fetchPacks failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isPacksLoading: false, packsError: _msg(e), isPacksDegraded: true);
    }
  }

  bool _isMockPacks(List<CoinPack> p) {
    if (p.isEmpty) return true;
    const mockIds = {'pack_100', 'pack_300', 'pack_700', 'pack_1500', 'pack_3500'};
    return p.every((e) => mockIds.contains(e.id));
  }

  Future<Map<String, dynamic>?> purchasePack(String packId) async {
    state = state.copyWith(isPurchasing: true, purchaseError: null, purchaseMessage: null);
    try {
      final res = await _repo.purchasePack(packId, idempotencyKey: _uuid.v4());
      final success = res['success'] as bool? ?? false;
      final isDegraded = res['is_degraded'] as bool? ?? false;
      if (isDegraded) {
        AppLogger.w('economy purchasePack $packId degraded: ${res['message']}');
        state = state.copyWith(isPurchasing: false, purchaseMessage: res['message'] as String? ?? 'Shop not available yet (beta)');
        return res;
      }
      if (!success) {
        state = state.copyWith(isPurchasing: false, purchaseError: res['message'] as String? ?? 'Purchase failed');
        return res;
      }
      state = state.copyWith(isPurchasing: false, purchaseMessage: res['message'] as String? ?? 'Purchase successful');
      // Refresh wallet/ledger after success when WO-1 ships
      await fetchWallet();
      await fetchLedger();
      return res;
    } catch (e, st) {
      AppLogger.w('economy purchasePack $packId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isPurchasing: false, purchaseError: _msg(e));
      return null;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchInventory(), fetchLeaderboard(), fetchFeed(), fetchWallet(), fetchLedger(), fetchPacks()]);
  }
}

final economyControllerProvider = NotifierProvider<EconomyController, EconomyState>(EconomyController.new);

// ── Convenience future providers for isolated screens ───────────────────────
final economyInventoryProvider = FutureProvider<EconomyInventoryBundle>((ref) async {
  final repo = ref.watch(economyRepositoryProvider);
  return repo.getInventory();
});

final donationLeaderboardProvider = FutureProvider<List<DonorLeaderboardEntry>>((ref) async {
  final repo = ref.watch(economyRepositoryProvider);
  return repo.getDonationLeaderboard();
});

final donationFeedProvider = FutureProvider<List<DonationFeedEntry>>((ref) async {
  final repo = ref.watch(economyRepositoryProvider);
  return repo.getDonationFeed();
});
