import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/calculator.dart';
import '../models/calculator_assistant_dto.dart';
import '../models/calculator_dto.dart';

class CalculatorRemoteDataSource {
  const CalculatorRemoteDataSource(this._dio);
  final Dio _dio;

  Future<CalculatorCatalogDto> getCatalog() async {
    final res = await _dio.get<Map<String, dynamic>>('/calculators');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => CalculatorCatalogDto.fromJson(json! as Map<String, dynamic>),
    );
    return envelope.data ??
        const CalculatorCatalogDto(totalCalculators: 0, domains: []);
  }

  Future<CalculatorConfig> getConfig(String domain, String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/$domain/$slug/schema');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => CalculatorConfigDto.fromJson(json! as Map<String, dynamic>),
    );
    final dto = envelope.data;
    if (dto == null) throw Exception('Config missing for $domain/$slug');
    return dto.toDomain();
  }

  Future<CalculationResult> calculate({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
    required String idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/$domain/$slug/calculate',
      data: inputs,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    // Calculate envelope varies — some calculators return {success,data,message}
    // others return direct result under data. We normalize.
    final body = res.data!;
    // If ApiResponse envelope, data is inside data; else body is result.
    if (body.containsKey('success')) {
      final envelope = ApiResponse.fromJson(
        body,
        (json) => json as Map<String, dynamic>?,
      );
      final raw = envelope.data ?? body['data'] ?? body;
      final map = raw is Map<String, dynamic> ? raw : {'result': raw};
      return CalculationResult(
        inputs: Map<String, dynamic>.from(inputs),
        data: map,
        message: envelope.message ?? body['message'] as String?,
      );
    }
    return CalculationResult(
      inputs: Map<String, dynamic>.from(inputs),
      data: body['data'] as Map<String, dynamic>? ?? body,
      message: body['message'] as String?,
    );
  }

  Future<List<Map<String, dynamic>>> getHistory(
    String domain,
    String slug,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>('/$domain/$slug/history');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
    // paginated envelope may nest items under data
    if (envelope.data != null) return envelope.data!;
    if (res.data!['data'] is List) {
      return (res.data!['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Share ───────────────────────────────────────────────────────────────────

  /// Mints a shareable permalink for a calculation.
  ///
  /// `POST /api/v1/calculator/permalinks` with the **inline** payload
  /// (`domain`, `calculator_slug`, `inputs`, `results`).
  ///
  /// The sibling route `POST /api/v1/share` is snapshot-only: it demands
  /// `calculable_id` + `calculable_type`, and `calculable_type` is the PHP
  /// class name of a row the client has no way to mint. The permalink route
  /// is the canonical one and accepts the payload a mobile client actually
  /// has — the calculation it just performed.
  ///
  /// The intent is `rehydrate`: the recipient's calculator prefills the form
  /// and stops, so the result they see is computed on their side rather than
  /// being a number this client asserted.
  Future<CalculatorPermalinkDto> createPermalink({
    required String domain,
    required String calculatorSlug,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> results,
    String intent = 'rehydrate',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/calculator/permalinks',
      data: <String, dynamic>{
        'domain': domain,
        'calculator_slug': calculatorSlug,
        'inputs': inputs,
        'results': results,
        'intent': intent,
      },
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/calculator/permalinks',
      );
    }
    final data = requireDataMap(body, endpoint: '/calculator/permalinks');
    return CalculatorPermalinkDto.fromJson(data);
  }

  // ── AI assistant ───────────────────────────────────────────────────────────

  /// Asks the server's calculator assistant about the current form.
  ///
  /// `POST /api/v1/ai/calculator-assist` — the **non-streaming** endpoint
  /// (`MOBILE_API_INTEGRATION_GUIDE.md` §6: the SSE variant is web-only).
  ///
  /// The assistant is advisory. It proposes values for the calculator's
  /// fields; the user decides whether to apply them. The client never
  /// calculates anything itself.
  ///
  /// The server refuses with 503 when the assistant is disabled for this
  /// calculator, 402 when the budget cap is exhausted and 429 when the rate
  /// limit is hit — all of which arrive as an ApiException with the
  /// server's own message.
  Future<CalculatorAssistantDto> assist({
    required String message,
    String? domain,
    String? slug,
    String? name,
    List<Map<String, dynamic>>? fields,
    Map<String, dynamic>? currentInputs,
  }) async {
    final context = <String, dynamic>{
      if (domain != null && domain.isNotEmpty) 'domain': domain,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      if (name != null && name.isNotEmpty) 'name': name,
      if (fields != null && fields.isNotEmpty) 'fields': fields,
    };

    final res = await _dio.post<Map<String, dynamic>>(
      '/ai/calculator-assist',
      data: <String, dynamic>{
        'message': message,
        if (context.isNotEmpty) 'calculator_context': context,
        if (currentInputs != null && currentInputs.isNotEmpty)
          'current_inputs': currentInputs,
      },
    );

    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty assistant response',
        endpoint: '/ai/calculator-assist',
      );
    }
    final data = requireDataMap(body, endpoint: '/ai/calculator-assist');
    final assistant = data['assistant'];
    if (assistant is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Assistant payload missing',
        endpoint: '/ai/calculator-assist',
      );
    }
    final metadata = data['metadata'];
    return CalculatorAssistantDto.fromJson(
      assistant,
      metadata: metadata is Map<String, dynamic> ? metadata : const {},
    );
  }
}
