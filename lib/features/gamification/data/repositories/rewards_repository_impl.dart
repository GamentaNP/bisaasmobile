import '../../domain/entities/rewards.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_data_source.dart';

/// Thin repository over the existing rewards data source.
///
/// The data source keeps the documented envelope inconsistency (check-in is
/// enveloped, spin answers raw JSON) and the 409/422 result parsing. Nothing
/// about those semantics is re-implemented here.
class RewardsRepositoryImpl implements RewardsRepository {
  const RewardsRepositoryImpl(this._remote);

  final RewardsRemoteDataSource _remote;

  @override
  Future<CheckInStatus> getCheckInStatus() async =>
      (await _remote.getCheckInStatus()).toDomain();

  @override
  Future<CheckInResult> claimCheckIn({String? idempotencyKey}) async =>
      (await _remote.claimCheckIn(idempotencyKey: idempotencyKey)).toDomain();

  @override
  Future<SpinStatus> getSpinStatus() async =>
      (await _remote.getSpinStatus()).toDomain();

  @override
  Future<SpinResult> spin({String? idempotencyKey}) async =>
      (await _remote.spin(idempotencyKey: idempotencyKey)).toDomain();
}
