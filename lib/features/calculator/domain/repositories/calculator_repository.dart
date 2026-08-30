import '../entities/calculator.dart';
import '../../data/models/calculator_dto.dart';

abstract class CalculatorRepository {
  Future<CalculatorCatalogDto> getCatalog();
  Future<CalculatorConfig> getConfig(String domain, String slug);
  Future<CalculationResult> calculate({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
  });
  Future<List<Map<String, dynamic>>> getHistory(String domain, String slug);
}
