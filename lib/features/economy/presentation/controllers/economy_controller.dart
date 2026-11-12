import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/economy_remote_data_source.dart';
import '../../data/repositories/economy_repository_impl.dart';
import '../../domain/entities/economy.dart';
import '../../domain/repositories/economy_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final economyRemoteDataSourceProvider = Provider<EconomyRemoteDataSource>((
  ref,
) {
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
    this.ledgerHasMore = false,
    this.ledgerCursor,
    this.walletCategories,
    this.isCategoriesLoading = false,
    this.categoriesError,
    this.isFreezingStreak = false,
    this.freezeMessage,
    this.lastFreezeResult,
  });

  final bool isLoading;
  final String? error;

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

  /// Whether the server says another ledger page exists (cursor pagination).
  final bool ledgerHasMore;

  /// The opaque cursor for the next ledger page.
  final String? ledgerCursor;

  /// Own coin spending, grouped by category.
  final WalletCategories? walletCategories;
  final bool isCategoriesLoading;
  final String? categoriesError;

  final bool isFreezingStreak;
  final String? freezeMessage;
  final FreezeStreakResult? lastFreezeResult;

  /// True when any surface is currently failing.
  ///
  /// Every economy endpoint the app calls exists on the server, so a failure
  /// is a failure and the UI shows it instead of silently rendering an empty
  /// catalogue.
  bool get hasErrors =>
      error != null ||
      leaderboardError != null ||
      feedError != null ||
      walletError != null ||
      ledgerError != null ||
      categoriesError != null;

  static const _sentinel = Object();

  EconomyState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
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
    bool? ledgerHasMore,
    Object? ledgerCursor = _sentinel,
    Object? walletCategories = _sentinel,
    bool? isCategoriesLoading,
    Object? categoriesError = _sentinel,
    bool? isFreezingStreak,
    Object? freezeMessage = _sentinel,
    Object? lastFreezeResult = _sentinel,
  }) {
    return EconomyState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      leaderboard: leaderboard ?? this.leaderboard,
      isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
      leaderboardError: leaderboardError == _sentinel
          ? this.leaderboardError
          : leaderboardError as String?,
      feed: feed ?? this.feed,
      isFeedLoading: isFeedLoading ?? this.isFeedLoading,
      feedError: feedError == _sentinel ? this.feedError : feedError as String?,
      wallet: wallet == _sentinel ? this.wallet : wallet as Wallet?,
      isWalletLoading: isWalletLoading ?? this.isWalletLoading,
      walletError: walletError == _sentinel
          ? this.walletError
          : walletError as String?,
      ledger: ledger ?? this.ledger,
      isLedgerLoading: isLedgerLoading ?? this.isLedgerLoading,
      ledgerError: ledgerError == _sentinel
          ? this.ledgerError
          : ledgerError as String?,
      ledgerHasMore: ledgerHasMore ?? this.ledgerHasMore,
      ledgerCursor: ledgerCursor == _sentinel
          ? this.ledgerCursor
          : ledgerCursor as String?,
      walletCategories: walletCategories == _sentinel
          ? this.walletCategories
          : walletCategories as WalletCategories?,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      categoriesError: categoriesError == _sentinel
          ? this.categoriesError
          : categoriesError as String?,
      isFreezingStreak: isFreezingStreak ?? this.isFreezingStreak,
      freezeMessage: freezeMessage == _sentinel
          ? this.freezeMessage
          : freezeMessage as String?,
      lastFreezeResult: lastFreezeResult == _sentinel
          ? this.lastFreezeResult
          : lastFreezeResult as FreezeStreakResult?,
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

  // ── Donations (live) ──────────────────────────────────────────────────────

  Future<void> fetchLeaderboard() async {
    state = state.copyWith(isLeaderboardLoading: true, leaderboardError: null);
    try {
      final l = await _repo.getDonationLeaderboard();
      state = state.copyWith(leaderboard: l, isLeaderboardLoading: false);
    } catch (e, st) {
      AppLogger.w('economy fetchLeaderboard failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(
        isLeaderboardLoading: false,
        leaderboardError: _msg(e),
      );
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
    state = state.copyWith(
      isFreezingStreak: true,
      freezeMessage: null,
      lastFreezeResult: null,
    );
    try {
      final res = await _repo.freezeStreak(idempotencyKey: _uuid.v4());
      state = state.copyWith(
        isFreezingStreak: false,
        lastFreezeResult: res,
        freezeMessage: res.message,
      );
      return res;
    } catch (e, st) {
      AppLogger.w('economy freezeStreak failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isFreezingStreak: false, freezeMessage: _msg(e));
      return null;
    }
  }

  // ── Wallet / Ledger ────────────────────────────────────────────────────────

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

  /// Loads a page of the coin ledger.
  ///
  /// The endpoint is cursor-paginated, so [cursor] is the `next_cursor` the
  /// server handed out — there is no page number to jump to.
  Future<void> fetchLedger({
    String? cursor,
    int perPage = 20,
    bool append = false,
  }) async {
    state = state.copyWith(isLedgerLoading: true, ledgerError: null);
    try {
      final ledger = await _repo.getLedger(cursor: cursor, perPage: perPage);
      state = state.copyWith(
        ledger: append ? [...state.ledger, ...ledger.entries] : ledger.entries,
        isLedgerLoading: false,
        ledgerHasMore: ledger.hasMore,
        ledgerCursor: ledger.nextCursor,
      );
    } catch (e, st) {
      AppLogger.w('economy fetchLedger failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLedgerLoading: false, ledgerError: _msg(e));
    }
  }

  /// Own coin spending, grouped by source category.
  Future<void> fetchWalletCategories({String period = '30d'}) async {
    state = state.copyWith(isCategoriesLoading: true, categoriesError: null);
    try {
      final categories = await _repo.getWalletCategories(period: period);
      state = state.copyWith(
        walletCategories: categories,
        isCategoriesLoading: false,
      );
    } catch (e, st) {
      AppLogger.w('economy fetchWalletCategories failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(
        isCategoriesLoading: false,
        categoriesError: _msg(e),
      );
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchLeaderboard(),
      fetchFeed(),
      fetchWallet(),
      fetchLedger(),
      fetchWalletCategories(),
    ]);
  }
}

final economyControllerProvider =
    NotifierProvider<EconomyController, EconomyState>(EconomyController.new);
