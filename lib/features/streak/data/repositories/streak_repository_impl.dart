import '../datasources/streak_remote_data_source.dart';
import '../models/streak_dto.dart';
import '../../domain/entities/streak.dart';
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
  Future<StreakRepairEligibilityDto> getRepairEligibility() => _remote.getRepairEligibility();

  @override
  Future<StreakRepairResultDto> repairStreak() => _remote.repairStreak();

  @override
  Future<StreakInsuranceStatusDto> getInsuranceStatus() => _remote.getInsuranceStatus();

  @override
  Future<StreakInsuranceResultDto> buyInsurance() => _remote.buyInsurance();

  @override
  Future<StreakInsuranceUsedDto> useInsurance() => _remote.useInsurance();

  @override
  Future<StreakWagerStatusDto> getActiveWager() => _remote.getActiveWager();

  @override
  Future<StreakWagerOpenedDto> openWager({int coins = 100, int days = 7}) =>
      _remote.openWager(coins: coins, days: days);
}
