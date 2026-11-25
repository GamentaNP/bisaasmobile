import '../entities/rewards.dart';

/// Daily check-in and spin-wheel reads/writes.
///
/// The server decides the prize, the streak and whether a claim/spin is
/// allowed. A 409/422 that carries a real outcome is parsed as a value by the
/// data source; transport failures still throw.
abstract class RewardsRepository {
  Future<CheckInStatus> getCheckInStatus();
  Future<CheckInResult> claimCheckIn({String? idempotencyKey});
  Future<SpinStatus> getSpinStatus();
  Future<SpinResult> spin({String? idempotencyKey});
}
