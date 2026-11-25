import '../datasources/streak_remote_data_source.dart';
import '../../domain/entities/streak.dart';
import '../../domain/entities/streak_self_service.dart';
import '../../domain/repositories/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  const StreakRepositoryImpl(this._remote);
  final StreakRemoteDataSource _remote;

  @override
  Future<Streak> getStreak() async {
    final dto = await _remote.getStreak();
    return dto.toDomain();
  }

  @override
  Future<bool> freezeStreak() async {
    final dto = await _remote.freezeStreak();
    return dto.frozen;
  }

  @override
  Future<StreakRepairEligibility> getRepairEligibility() async {
    final dto = await _remote.getRepairEligibility();
    return dto.toDomain();
  }

  @override
  Future<StreakRepairResult> repairStreak() async {
    final dto = await _remote.repairStreak();
    return dto.toDomain();
  }

  @override
  Future<StreakInsuranceStatus> getInsuranceStatus() async {
    final dto = await _remote.getInsuranceStatus();
    return dto.toDomain();
  }

  @override
  Future<StreakInsuranceResult> buyInsurance() async {
    final dto = await _remote.buyInsurance();
    return dto.toDomain();
  }

  @override
  Future<StreakInsuranceUsed> useInsurance() async {
    final dto = await _remote.useInsurance();
    return dto.toDomain();
  }

  @override
  Future<StreakWagerStatus> getActiveWager() async {
    final dto = await _remote.getActiveWager();
    return dto.toDomain();
  }

  @override
  Future<StreakWagerOpened> openWager({int coins = 100, int days = 7}) async {
    final dto = await _remote.openWager(coins: coins, days: days);
    return dto.toDomain();
  }
}
