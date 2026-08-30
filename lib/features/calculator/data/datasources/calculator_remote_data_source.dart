import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/calculator_dto.dart';
import '../../domain/entities/calculator.dart';

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
    final res = await _dio.get<Map<String, dynamic>>('/$domain/$slug');
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
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/$domain/$slug/calculate',
      data: inputs,
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
      // ignore: unnecessary_type_check — raw may be Map or primitive
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

  Future<List<Map<String, dynamic>>> getHistory(String domain, String slug) async {
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
}
