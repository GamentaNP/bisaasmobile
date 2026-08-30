import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/streak_remote_data_source.dart';
import '../../data/repositories/streak_repository_impl.dart';
import '../../domain/entities/streak.dart';
import '../../domain/repositories/streak_repository.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>((ref) {
  return StreakRemoteDataSource(DioClient.instance.dio);
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(ref.watch(streakRemoteDataSourceProvider));
});

// Future provider for read-only surfaces
final streakProvider = FutureProvider<Streak>((ref) async {
  final repo = ref.watch(streakRepositoryProvider);
  return repo.getStreak();
});

// ── State ───────────────────────────────────────────────────────────────────

class StreakState {
  const StreakState({
    this.streak,
    this.isLoading = false,
    this.isFreezing = false,
    this.error,
    this.freezeError,
    this.lastFreezeSuccess = false,
  });

  final Streak? streak;
  final bool isLoading;
  final bool isFreezing;
  final String? error;
  final String? freezeError;
  final bool lastFreezeSuccess;

  StreakState copyWith({
    Streak? streak,
    bool? isLoading,
    bool? isFreezing,
    Object? error = const Object(),
    Object? freezeError = const Object(),
    bool? lastFreezeSuccess,
  }) =>
      StreakState(
        streak: streak ?? this.streak,
        isLoading: isLoading ?? this.isLoading,
        isFreezing: isFreezing ?? this.isFreezing,
        error: error == const Object() ? this.error : error as String?,
        freezeError: freezeError == const Object() ? this.freezeError : freezeError as String?,
        lastFreezeSuccess: lastFreezeSuccess ?? this.lastFreezeSuccess,
      );
}

// ── Controller ──────────────────────────────────────────────────────────────

class StreakController extends Notifier<StreakState> {
  @override
  StreakState build() => const StreakState();

  StreakRepository get _repo => ref.read(streakRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  Future<void> fetchStreak() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final streak = await _repo.getStreak();
      state = state.copyWith(streak: streak, isLoading: false);
    } catch (e, st) {
      AppLogger.w('streak fetch failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> freezeStreak() async {
    state = state.copyWith(isFreezing: true, freezeError: null, lastFreezeSuccess: false);
    try {
      final ok = await _repo.freezeStreak();
      if (ok) {
        state = state.copyWith(isFreezing: false, lastFreezeSuccess: true);
        // Refresh streak to reflect frozenUntil / freezeCount
        await fetchStreak();
        return true;
      } else {
        state = state.copyWith(isFreezing: false, freezeError: 'Insufficient coins or no donor badge for freeze.');
        return false;
      }
    } catch (e, st) {
      AppLogger.w('streak freeze failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isFreezing: false, freezeError: _msg(e));
      return false;
    }
  }

  void clearErrors() => state = state.copyWith(error: null, freezeError: null);
}

final streakControllerProvider = NotifierProvider<StreakController, StreakState>(StreakController.new);
