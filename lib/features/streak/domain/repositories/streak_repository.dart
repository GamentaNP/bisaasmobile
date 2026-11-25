import '../entities/streak.dart';
import '../entities/streak_self_service.dart';

abstract class StreakRepository {
  Future<Streak> getStreak();
  /// Returns true if freeze succeeded, false if insufficient coins / no donor badge.
  /// Throws on network / server error.
  Future<bool> freezeStreak();

  // ── Streak self-service (server-authoritative; client never computes these) ──

  /// `GET /quiz/streak/repair` — can a missed day be repaired right now?
  Future<StreakRepairEligibility> getRepairEligibility();

  /// `POST /quiz/streak/repair` — spend 50 coins to bridge a missed day.
  Future<StreakRepairResult> repairStreak();

  /// `GET /quiz/streak/insurance` — banked tokens, cost and whether more can be bought.
  Future<StreakInsuranceStatus> getInsuranceStatus();

  /// `POST /quiz/streak/insurance` — buy one auto-repair token.
  Future<StreakInsuranceResult> buyInsurance();

  /// `POST /quiz/streak/insurance/use` — spend a banked token now.
  Future<StreakInsuranceUsed> useInsurance();

  /// `GET /quiz/streak/wager` — the active wager, if any.
  Future<StreakWagerStatus> getActiveWager();

  /// `POST /quiz/streak/wager` — commit coins to N consecutive days.
  Future<StreakWagerOpened> openWager({int coins, int days});
}
