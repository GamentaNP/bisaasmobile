import '../../domain/entities/calculator.dart';
import '../../domain/repositories/calculator_repository.dart';
import '../datasources/calculator_remote_data_source.dart';
import '../models/calculator_dto.dart';

class CalculatorRepositoryImpl implements CalculatorRepository {
  const CalculatorRepositoryImpl(this._remote);
  final CalculatorRemoteDataSource _remote;

  @override
  Future<CalculatorCatalogDto> getCatalog() => _remote.getCatalog();

  @override
  Future<CalculatorConfig> getConfig(String domain, String slug) => _remote.getConfig(domain, slug);

  @override
  Future<CalculationResult> calculate({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
  }) => _remote.calculate(domain: domain, slug: slug, inputs: inputs);

  @override
  Future<List<Map<String, dynamic>>> getHistory(String domain, String slug) => _remote.getHistory(domain, slug);
}
