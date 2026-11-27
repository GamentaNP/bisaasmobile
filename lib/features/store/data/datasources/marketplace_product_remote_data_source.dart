/// Data source for `GET /quiz/marketplace/products/{product}` (§9.5).
///
/// A GET must not mutate: unlike the web product page this read never calls
/// `recordView()` and it never purchases anything.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/marketplace_product.dart';
import '../models/marketplace_product_dto.dart';

class MarketplaceProductRemoteDataSource {
  const MarketplaceProductRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/marketplace/products';

  Future<MarketplaceProductDetail> getProduct(String productId) async {
    if (int.tryParse(productId) == null) {
      throw ContractViolation(
        'A marketplace product id must be numeric',
        endpoint: endpoint,
      );
    }
    final path = '$endpoint/$productId';
    final res = await _dio.get<Map<String, dynamic>>(path);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: path);
    }
    return MarketplaceProductDto.fromJson(
      requireDataMap(body, endpoint: path),
      endpoint: path,
    ).toDomain(endpoint: path);
  }
}
