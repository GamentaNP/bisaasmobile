import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/leaderboard_remote_data_source.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/entities/leaderboard.dart';
import '../../domain/repositories/leaderboard_repository.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final leaderboardRemoteDataSourceProvider = Provider<LeaderboardRemoteDataSource>((ref) {
  return LeaderboardRemoteDataSource(DioClient.instance.dio);
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(ref.watch(leaderboardRemoteDataSourceProvider));
});

// ── State ───────────────────────────────────────────────────────────────────

class LeaderboardState {
  const LeaderboardState({
    this.entries = const [],
    this.leaderboard,
    this.myRank,
    this.isLoading = false,
    this.error,
    this.myRanks = const [],
    this.isMyRankLoading = false,
    this.myRanksError,
    this.donorEntries = const [],
    this.isDonorLoading = false,
    this.donorError,
    this.selectedScope = 'global',
    this.selectedLeaderboardId,
  });

  final List<LeaderboardEntry> entries;
  final Leaderboard? leaderboard;
  final int? myRank;
  final bool isLoading;
  final String? error;

  final List<MyRank> myRanks;
  final bool isMyRankLoading;
  final String? myRanksError;

  final List<DonorLeaderboardEntry> donorEntries;
  final bool isDonorLoading;
  final String? donorError;

  final String selectedScope; // global | friends | league | donors
  final int? selectedLeaderboardId;

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    Leaderboard? leaderboard,
    Object? myRank = const Object(),
    bool? isLoading,
    Object? error = const Object(),
    List<MyRank>? myRanks,
    bool? isMyRankLoading,
    Object? myRanksError = const Object(),
    List<DonorLeaderboardEntry>? donorEntries,
    bool? isDonorLoading,
    Object? donorError = const Object(),
    String? selectedScope,
    Object? selectedLeaderboardId = const Object(),
  }) =>
      LeaderboardState(
        entries: entries ?? this.entries,
        leaderboard: leaderboard ?? this.leaderboard,
        myRank: myRank == const Object() ? this.myRank : myRank as int?,
        isLoading: isLoading ?? this.isLoading,
        error: error == const Object() ? this.error : error as String?,
        myRanks: myRanks ?? this.myRanks,
        isMyRankLoading: isMyRankLoading ?? this.isMyRankLoading,
        myRanksError: myRanksError == const Object() ? this.myRanksError : myRanksError as String?,
        donorEntries: donorEntries ?? this.donorEntries,
        isDonorLoading: isDonorLoading ?? this.isDonorLoading,
        donorError: donorError == const Object() ? this.donorError : donorError as String?,
        selectedScope: selectedScope ?? this.selectedScope,
        selectedLeaderboardId: selectedLeaderboardId == const Object() ? this.selectedLeaderboardId : selectedLeaderboardId as int?,
      );
}

// ── Controller ──────────────────────────────────────────────────────────────

class LeaderboardController extends Notifier<LeaderboardState> {
  @override
  LeaderboardState build() => const LeaderboardState();

  LeaderboardRepository get _repo => ref.read(leaderboardRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchLeaderboard(int id, {int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null, selectedLeaderboardId: id);
    try {
      final show = await _repo.getLeaderboard(id, limit: limit);
      state = state.copyWith(entries: show.entries, leaderboard: show.leaderboard, myRank: show.myRank, isLoading: false);
    } catch (e, st) {
      AppLogger.w('leaderboard fetch $id failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> fetchMyRanks() async {
    state = state.copyWith(isMyRankLoading: true, myRanksError: null);
    try {
      final ranks = await _repo.getMyRanks();
      state = state.copyWith(myRanks: ranks, isMyRankLoading: false);
      // Auto-select first if none selected based on scope
      if (state.selectedLeaderboardId == null && ranks.isNotEmpty) {
        // Prefer global, else first
        final global = ranks.where((r) => r.leaderboard.scope == 'global').toList();
        final pick = global.isNotEmpty ? global.first : ranks.first;
        // Only auto-fetch if scope matches
        if (state.selectedScope == pick.leaderboard.scope || state.selectedScope == 'global') {
          await fetchLeaderboard(pick.leaderboard.id);
        }
      }
    } catch (e, st) {
      AppLogger.w('myRank failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isMyRankLoading: false, myRanksError: _msg(e));
    }
  }

  Future<void> fetchDonationLeaderboard() async {
    state = state.copyWith(isDonorLoading: true, donorError: null);
    try {
      final entries = await _repo.getDonationLeaderboard();
      state = state.copyWith(donorEntries: entries, isDonorLoading: false);
    } catch (e, st) {
      AppLogger.w('donor leaderboard failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isDonorLoading: false, donorError: _msg(e));
    }
  }

  Future<Map<String, dynamic>?> submitScore({
    required String mode,
    required int score,
    required int correct,
    required int total,
    required int streak,
  }) async {
    try {
      final res = await _repo.submitScore(mode: mode, score: score, correct: correct, total: total, streak: streak);
      // Refresh current leaderboard after submit if selected
      if (state.selectedLeaderboardId != null) {
        await fetchLeaderboard(state.selectedLeaderboardId!);
      }
      await fetchMyRanks();
      return res;
    } catch (e, st) {
      AppLogger.w('submitScore failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(error: _msg(e));
      return null;
    }
  }

  void setScope(String scope) {
    state = state.copyWith(selectedScope: scope);
  }

  void clearErrors() => state = state.copyWith(error: null, myRanksError: null, donorError: null);
}

final leaderboardControllerProvider = NotifierProvider<LeaderboardController, LeaderboardState>(LeaderboardController.new);

// Optional future provider for direct reads
final myRankProvider = FutureProvider<List<MyRank>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.getMyRanks();
});
