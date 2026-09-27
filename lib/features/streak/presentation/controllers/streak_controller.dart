import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/streak_remote_data_source.dart';
import '../../data/models/streak_dto.dart';
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
    this.repairEligibility,
    this.insurance,
    this.wager,
    this.isSelfServiceBusy = false,
    this.selfServiceError,
  });

  final Streak? streak;
  final bool isLoading;
  final bool isFreezing;
  final String? error;
  final String? freezeError;
  final bool lastFreezeSuccess;

  /// `GET /quiz/streak/repair` — drives whether the Repair action is live.
  final StreakRepairEligibilityDto? repairEligibility;

  /// `GET /quiz/streak/insurance` — banked tokens, cost, purchase eligibility.
  final StreakInsuranceStatusDto? insurance;

  /// `GET /quiz/streak/wager` — null when no wager is active.
  final StreakWagerStatusDto? wager;

  /// True while a repair/insurance/wager mutation is in flight.
  final bool isSelfServiceBusy;
  final String? selfServiceError;

  StreakState copyWith({
    Streak? streak,
    bool? isLoading,
    bool? isFreezing,
    Object? error = const Object(),
    Object? freezeError = const Object(),
    bool? lastFreezeSuccess,
    Object? repairEligibility = const Object(),
    Object? insurance = const Object(),
    Object? wager = const Object(),
    bool? isSelfServiceBusy,
    Object? selfServiceError = const Object(),
  }) =>
      StreakState(
        streak: streak ?? this.streak,
        isLoading: isLoading ?? this.isLoading,
        isFreezing: isFreezing ?? this.isFreezing,
        error: error == const Object() ? this.error : error as String?,
        freezeError: freezeError == const Object() ? this.freezeError : freezeError as String?,
        lastFreezeSuccess: lastFreezeSuccess ?? this.lastFreezeSuccess,
        repairEligibility: repairEligibility == const Object()
            ? this.repairEligibility
            : repairEligibility as StreakRepairEligibilityDto?,
        insurance: insurance == const Object() ? this.insurance : insurance as StreakInsuranceStatusDto?,
        wager: wager == const Object() ? this.wager : wager as StreakWagerStatusDto?,
        isSelfServiceBusy: isSelfServiceBusy ?? this.isSelfServiceBusy,
        selfServiceError:
            selfServiceError == const Object() ? this.selfServiceError : selfServiceError as String?,
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

  /// Load the three self-service surfaces. Each is independent — one failing
  /// (e.g. insurance hidden by a feature flag) must not blank the others, so
  /// failures are recorded but never surfaced as a screen-level error.
  Future<void> fetchSelfService() async {
    Future<T> guard<T>(Future<T> Function() run, T fallback) async {
      try {
        return await run();
      } catch (e) {
        AppLogger.w('streak self-service fetch failed: $e');
        return fallback;
      }
    }

    final results = await Future.wait([
      guard(_repo.getRepairEligibility,
          const StreakRepairEligibilityDto(eligible: false)),
      guard(_repo.getInsuranceStatus,
          const StreakInsuranceStatusDto(activeCount: 0, maxActive: 0, costCoins: 0, canPurchase: false)),
      guard(_repo.getActiveWager, const StreakWagerStatusDto(wager: null, currentStreak: 0)),
    ]);

    state = state.copyWith(
      repairEligibility: results[0] as StreakRepairEligibilityDto,
      insurance: results[1] as StreakInsuranceStatusDto,
      wager: results[2] as StreakWagerStatusDto,
    );
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchStreak(), fetchSelfService()]);
  }

  /// `POST /quiz/streak/repair` — 50 coins. Returns the server's outcome message
  /// so the UI can show the real reason when it is refused (not enough coins,
  /// window expired, monthly limit, nothing missed).
  Future<String?> repairStreak() async {
    state = state.copyWith(isSelfServiceBusy: true, selfServiceError: null);
    try {
      final res = await _repo.repairStreak();
      await refreshAll();
      if (res.repaired) {
        state = state.copyWith(isSelfServiceBusy: false);
        return null;
      }
      // A refusal arrives as a 422 with `error.details.reason`; fall back to the
      // generic message only when the server sent no reason at all.
      final reason = _repairReason(res.reason ?? res.message);
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: reason);
      return reason;
    } catch (e, st) {
      AppLogger.w('streak repair failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      final msg = _msg(e);
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: msg);
      return msg;
    }
  }

  /// `POST /quiz/streak/insurance` — buy one auto-repair token.
  Future<String?> buyInsurance() async {
    state = state.copyWith(isSelfServiceBusy: true, selfServiceError: null);
    try {
      final res = await _repo.buyInsurance();
      await fetchSelfService();
      if (res.purchased) {
        state = state.copyWith(isSelfServiceBusy: false);
        return null;
      }
      final reason = res.message ?? 'Insurance could not be bought.';
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: reason);
      return reason;
    } catch (e, st) {
      AppLogger.w('streak insurance purchase failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      final msg = _msg(e);
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: msg);
      return msg;
    }
  }

  /// `POST /quiz/streak/insurance/use` — spend a banked token.
  Future<String?> useInsurance() async {
    state = state.copyWith(isSelfServiceBusy: true, selfServiceError: null);
    try {
      final res = await _repo.useInsurance();
      await refreshAll();
      if (res.used) {
        state = state.copyWith(isSelfServiceBusy: false);
        return null;
      }
      const reason = 'No insurance available to use.';
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: reason);
      return reason;
    } catch (e, st) {
      AppLogger.w('streak insurance use failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      final msg = _msg(e);
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: msg);
      return msg;
    }
  }

  /// `POST /quiz/streak/wager` — commit coins across N consecutive days.
  Future<String?> openWager({int coins = 100, int days = 7}) async {
    state = state.copyWith(isSelfServiceBusy: true, selfServiceError: null);
    try {
      final res = await _repo.openWager(coins: coins, days: days);
      await fetchSelfService();
      if (res.opened) {
        state = state.copyWith(isSelfServiceBusy: false);
        return null;
      }
      final reason = _wagerReason(res.reason ?? res.message);
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: reason);
      return reason;
    } catch (e, st) {
      AppLogger.w('streak wager failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      final msg = _msg(e);
      state = state.copyWith(isSelfServiceBusy: false, selfServiceError: msg);
      return msg;
    }
  }

  /// The server reports refusals via `error.details.reason` with these slugs.
  /// Surface the human meaning rather than the raw identifier.
  static String _repairReason(String? message) => switch (message) {
        'not_missed_one_day' => 'You have not missed a day — nothing to repair.',
        'repair_window_expired' => 'The repair window for that missed day has closed.',
        'monthly_repair_limit_reached' => 'You have used all repairs allowed this month.',
        'insufficient_balance' => 'Not enough coins — a repair costs 50.',
        null => 'Repair was declined by the server.',
        _ => message,
      };

  /// Same treatment for wagers (routes/api/v1/quiz.php:274-295).
  static String _wagerReason(String? reason) => switch (reason) {
        'active_wager' => 'You already have a wager running.',
        'coins_too_low' => 'The minimum stake is 50 coins.',
        'days_too_short' => 'A wager must run for at least 3 days.',
        'insufficient_balance' => 'Not enough coins for that stake.',
        'duplicate_key' => 'That wager was already submitted — pull to refresh.',
        null => 'Wager could not be opened.',
        _ => reason,
      };

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

  void clearErrors() => state = state.copyWith(error: null, freezeError: null, selfServiceError: null);
}

final streakControllerProvider = NotifierProvider<StreakController, StreakState>(StreakController.new);
