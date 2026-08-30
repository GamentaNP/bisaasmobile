import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/contests_remote_data_source.dart';
import '../../data/repositories/contests_repository_impl.dart';
import '../../domain/entities/contest.dart';
import '../../domain/repositories/contests_repository.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final contestsRemoteDataSourceProvider = Provider<ContestsRemoteDataSource>((ref) {
  return ContestsRemoteDataSource(DioClient.instance.dio);
});

final contestsRepositoryProvider = Provider<ContestsRepository>((ref) {
  return ContestsRepositoryImpl(ref.watch(contestsRemoteDataSourceProvider));
});

// ── List state ──────────────────────────────────────────────────────────────

class ContestsState {
  const ContestsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.total,
    this.currentPage = 1,
    this.perPage = 20,
    this.hasMore = false,
  });

  final List<Contest> items;
  final bool isLoading;
  final String? error;
  final int? total;
  final int currentPage;
  final int perPage;
  final bool hasMore;

  ContestsState copyWith({
    List<Contest>? items,
    bool? isLoading,
    Object? error = const Object(),
    int? total,
    int? currentPage,
    int? perPage,
    bool? hasMore,
  }) =>
      ContestsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error == const Object() ? this.error : error as String?,
        total: total ?? this.total,
        currentPage: currentPage ?? this.currentPage,
        perPage: perPage ?? this.perPage,
        hasMore: hasMore ?? this.hasMore,
      );
}

class ContestsController extends Notifier<ContestsState> {
  @override
  ContestsState build() => const ContestsState();

  ContestsRepository get _repo => ref.read(contestsRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchContests({int page = 1, int perPage = 20, bool append = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getContests(page: page, perPage: perPage);
      final newItems = append ? [...state.items, ...res.items] : res.items;
      final hasMore = res.total != null ? newItems.length < res.total! : res.items.length == perPage;
      state = state.copyWith(items: newItems, isLoading: false, total: res.total, currentPage: page, perPage: perPage, hasMore: hasMore);
    } catch (e, st) {
      AppLogger.w('contests fetch failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> refresh() => fetchContests(page: 1);
}

// ── Detail state ────────────────────────────────────────────────────────────

class ContestDetailState {
  const ContestDetailState({
    this.detail,
    this.isLoading = false,
    this.error,
    this.isJoining = false,
    this.joinError,
    this.isEntering = false,
    this.enterError,
    this.lastAttempt,
    this.leaderboard = const [],
    this.isLeaderboardLoading = false,
    this.leaderboardError,
    this.recap,
    this.isRecapLoading = false,
    this.recapError,
  });

  final ContestDetail? detail;
  final bool isLoading;
  final String? error;

  final bool isJoining;
  final String? joinError;

  final bool isEntering;
  final String? enterError;
  final ContestAttempt? lastAttempt;

  final List<ContestEntry> leaderboard;
  final bool isLeaderboardLoading;
  final String? leaderboardError;

  final ContestRecap? recap;
  final bool isRecapLoading;
  final String? recapError;

  ContestDetailState copyWith({
    Object? detail = const Object(),
    bool? isLoading,
    Object? error = const Object(),
    bool? isJoining,
    Object? joinError = const Object(),
    bool? isEntering,
    Object? enterError = const Object(),
    Object? lastAttempt = const Object(),
    List<ContestEntry>? leaderboard,
    bool? isLeaderboardLoading,
    Object? leaderboardError = const Object(),
    Object? recap = const Object(),
    bool? isRecapLoading,
    Object? recapError = const Object(),
  }) =>
      ContestDetailState(
        detail: detail == const Object() ? this.detail : detail as ContestDetail?,
        isLoading: isLoading ?? this.isLoading,
        error: error == const Object() ? this.error : error as String?,
        isJoining: isJoining ?? this.isJoining,
        joinError: joinError == const Object() ? this.joinError : joinError as String?,
        isEntering: isEntering ?? this.isEntering,
        enterError: enterError == const Object() ? this.enterError : enterError as String?,
        lastAttempt: lastAttempt == const Object() ? this.lastAttempt : lastAttempt as ContestAttempt?,
        leaderboard: leaderboard ?? this.leaderboard,
        isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
        leaderboardError: leaderboardError == const Object() ? this.leaderboardError : leaderboardError as String?,
        recap: recap == const Object() ? this.recap : recap as ContestRecap?,
        isRecapLoading: isRecapLoading ?? this.isRecapLoading,
        recapError: recapError == const Object() ? this.recapError : recapError as String?,
      );
}

class ContestDetailController extends Notifier<ContestDetailState> {
  @override
  ContestDetailState build() => const ContestDetailState();

  ContestsRepository get _repo => ref.read(contestsRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _repo.getContest(id);
      state = state.copyWith(detail: detail, isLoading: false);
    } catch (e, st) {
      AppLogger.w('contest $id detail failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> join(int id, {String? joinIntent}) async {
    state = state.copyWith(isJoining: true, joinError: null);
    try {
      await _repo.joinContest(id, joinIntent: joinIntent);
      state = state.copyWith(isJoining: false);
      await fetchDetail(id);
      return true;
    } catch (e, st) {
      AppLogger.w('contest $id join failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isJoining: false, joinError: _msg(e));
      return false;
    }
  }

  Future<ContestAttempt?> enter(int id) async {
    state = state.copyWith(isEntering: true, enterError: null, lastAttempt: null);
    try {
      final attempt = await _repo.enterContest(id);
      state = state.copyWith(isEntering: false, lastAttempt: attempt);
      return attempt;
    } catch (e, st) {
      AppLogger.w('contest $id enter failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isEntering: false, enterError: _msg(e));
      return null;
    }
  }

  Future<void> fetchLeaderboard(int id, {int limit = 20}) async {
    state = state.copyWith(isLeaderboardLoading: true, leaderboardError: null);
    try {
      final entries = await _repo.getLeaderboard(id, limit: limit);
      state = state.copyWith(leaderboard: entries, isLeaderboardLoading: false);
    } catch (e, st) {
      AppLogger.w('contest $id leaderboard failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLeaderboardLoading: false, leaderboardError: _msg(e));
    }
  }

  Future<void> fetchRecap(int id) async {
    state = state.copyWith(isRecapLoading: true, recapError: null);
    try {
      final recap = await _repo.getRecap(id);
      state = state.copyWith(recap: recap, isRecapLoading: false);
    } catch (e, st) {
      AppLogger.w('contest $id recap failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isRecapLoading: false, recapError: _msg(e));
    }
  }

  Future<bool> leave(int id) async {
    try {
      await _repo.leaveContest(id);
      await fetchDetail(id);
      return true;
    } catch (e, st) {
      AppLogger.w('contest $id leave failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(joinError: _msg(e));
      return false;
    }
  }

  void clearErrors() => state = state.copyWith(error: null, joinError: null, enterError: null, leaderboardError: null, recapError: null);
}

final contestsControllerProvider = NotifierProvider<ContestsController, ContestsState>(ContestsController.new);
final contestDetailControllerProvider = NotifierProvider<ContestDetailController, ContestDetailState>(ContestDetailController.new);
