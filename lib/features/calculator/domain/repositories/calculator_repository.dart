import '../entities/calculator.dart';
import '../entities/calculator_assistant.dart';
import '../../data/models/calculator_dto.dart';

abstract class CalculatorRepository {
  Future<CalculatorCatalogDto> getCatalog();
  Future<CalculatorConfig> getConfig(String domain, String slug);
  Future<CalculationResult> calculate({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
    required String idempotencyKey,
  });
  Future<List<Map<String, dynamic>>> getHistory(String domain, String slug);

  /// Mints a shareable permalink for a calculation.
  ///
  /// Uses `POST /api/v1/calculator/permalinks` with the inline payload.
  /// The sibling `POST /api/v1/share` is snapshot-only — it demands a
  /// `calculable_id` + `calculable_type` pair the client cannot mint — so
  /// the permalink route is the one a mobile client can actually use.
  Future<CalculatorPermalinkDto> createPermalink({
    required String domain,
    required String calculatorSlug,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> results,
  });

  /// Asks the server's calculator assistant about the current form.
  ///
  /// The assistant is advisory: it proposes field values, and the user
  /// decides whether to apply them. The client never calculates.
  Future<CalculatorAssistant> assist({
    required String message,
    String? domain,
    String? slug,
    String? name,
    List<Map<String, dynamic>>? fields,
    Map<String, dynamic>? currentInputs,
  });
}
