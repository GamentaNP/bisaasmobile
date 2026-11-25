import '../../domain/entities/numerical.dart';
import '../../domain/repositories/numerical_repository.dart';
import '../datasources/numerical_remote_data_source.dart';

/// Thin repository over the existing numericals data source.
///
/// The data source keeps the envelope/DTO parsing exactly as it was - a
/// wrong-shaped 2xx still throws rather than reading as "no problem".
class NumericalRepositoryImpl implements NumericalRepository {
  const NumericalRepositoryImpl(this._remote);

  final NumericalRemoteDataSource _remote;

  @override
  Future<Numerical?> randomize(int numericalId) =>
      _remote.randomize(numericalId);

  @override
  Future<NumericalCheck?> checkAnswer(int numericalId, double answer) =>
      _remote.checkAnswer(numericalId, answer);

  @override
  Future<Numerical?> solve(int numericalId, {Map<String, double>? parameters}) =>
      _remote.solve(numericalId, parameters: parameters);

  @override
  Future<String?> getCivilCalLink(int numericalId,
          {Map<String, double>? parameters}) =>
      _remote.getCivilCalLink(numericalId, parameters: parameters);
}
