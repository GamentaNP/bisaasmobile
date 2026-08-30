import '../entities/streak.dart';

abstract class StreakRepository {
  Future<Streak> getStreak();
  /// Returns true if freeze succeeded, false if insufficient coins / no donor badge.
  /// Throws on network / server error.
  Future<bool> freezeStreak();
}
