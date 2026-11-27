import '../../../../core/network/api_failure.dart';
import '../../domain/entities/marketplace_product.dart';

/// Strict wire parser for the bounded marketplace detail snapshot (§9.5).
///
/// The review list is bounded to 20 by the server. A missing product object,
/// a malformed review row or a missing eligibility boolean is drift, never an
/// "unowned, cannot buy" default.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> rows(
    Object? value,
    String key,
    String endpoint,
  ) {
    if (value is! List) {
      throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
    }
    return value.map((row) => map(row, '$key row', endpoint)).toList();
  }

  static int intOf(Object? value, String key, String endpoint) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation('Expected $key to be an int', endpoint: endpoint);
  }

  static int? optionalInt(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation(
      'Expected $key to be an int or null',
      endpoint: endpoint,
    );
  }

  static double doubleOf(Object? value, String key, String endpoint) {
    if (value is num) return value.toDouble();
    throw ContractViolation('Expected $key to be a number', endpoint: endpoint);
  }

  static String string(Object? value, String key, String endpoint) {
    if (value is String && value.isNotEmpty) return value;
    throw ContractViolation('Expected $key to be a string', endpoint: endpoint);
  }

  static String? optionalString(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is String) return value;
    throw ContractViolation(
      'Expected $key to be a string or null',
      endpoint: endpoint,
    );
  }

  static bool boolOf(Object? value, String key, String endpoint) {
    if (value is bool) return value;
    throw ContractViolation('Expected $key to be a bool', endpoint: endpoint);
  }
}

class MarketplaceProductDto {
  const MarketplaceProductDto({required this.data});
  final Map<String, dynamic> data;

  factory MarketplaceProductDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/marketplace/products/{product}',
  }) {
    final product = _Parse.map(data['product'], 'product', endpoint);
    _Parse.intOf(product['id'], 'product.id', endpoint);
    _Parse.string(product['title'], 'product.title', endpoint);
    _Parse.intOf(product['price_coins'], 'product.price_coins', endpoint);
    _Parse.boolOf(product['is_free'], 'product.is_free', endpoint);
    _Parse.rows(data['reviews'], 'reviews', endpoint);
    _Parse.boolOf(data['owned'], 'owned', endpoint);
    _Parse.boolOf(data['can_purchase'], 'can_purchase', endpoint);
    _Parse.intOf(data['coin_balance'], 'coin_balance', endpoint);
    _Parse.optionalString(
      data['purchase_blocked_reason'],
      'purchase_blocked_reason',
      endpoint,
    );
    return MarketplaceProductDto(data: data);
  }

  MarketplaceProductDetail toDomain({
    String endpoint = '/quiz/marketplace/products/{product}',
  }) {
    final product = _Parse.map(data['product'], 'product', endpoint);
    final detail = MarketplaceProduct(
      id: _Parse.intOf(product['id'], 'product.id', endpoint),
      title: _Parse.string(product['title'], 'product.title', endpoint),
      priceCoins: _Parse.intOf(product['price_coins'], 'product.price_coins', endpoint),
      isFree: _Parse.boolOf(product['is_free'], 'product.is_free', endpoint),
      type: _Parse.optionalString(product['type'], 'product.type', endpoint),
      description: _Parse.optionalString(
        product['description'],
        'product.description',
        endpoint,
      ),
      previewUrl: _Parse.optionalString(
        product['preview_url'],
        'product.preview_url',
        endpoint,
      ),
      priceCents: _Parse.optionalInt(product['price_cents'], 'product.price_cents', endpoint),
      currency: _Parse.optionalString(product['currency'], 'product.currency', endpoint),
      ratingAvg: _Parse.doubleOf(product['rating_avg'], 'product.rating_avg', endpoint),
      ratingCount: _Parse.intOf(product['rating_count'], 'product.rating_count', endpoint),
      salesCount: _Parse.intOf(product['sales_count'], 'product.sales_count', endpoint),
      qualityScore: _Parse.doubleOf(product['quality_score'], 'product.quality_score', endpoint),
      categoryName: _Parse.optionalString(
        product['category_name'],
        'product.category_name',
        endpoint,
      ),
      creatorName: _Parse.optionalString(
        product['creator_name'],
        'product.creator_name',
        endpoint,
      ),
      creatorUsername: _Parse.optionalString(
        product['creator_username'],
        'product.creator_username',
        endpoint,
      ),
      viewsCount: _Parse.intOf(product['views_count'], 'product.views_count', endpoint),
      publishedAt: _Parse.optionalString(
        product['published_at'],
        'product.published_at',
        endpoint,
      ),
    );

    return MarketplaceProductDetail(
      product: detail,
      reviews: _Parse.rows(data['reviews'], 'reviews', endpoint)
          .map((row) => MarketplaceReview(
                id: _Parse.intOf(row['id'], 'reviews.id', endpoint),
                rating: _Parse.intOf(row['rating'], 'reviews.rating', endpoint),
                body: _Parse.string(row['body'], 'reviews.body', endpoint),
                isVerifiedPurchase: _Parse.boolOf(
                  row['is_verified_purchase'],
                  'reviews.is_verified_purchase',
                  endpoint,
                ),
                authorName: _Parse.optionalString(
                  row['author_name'],
                  'reviews.author_name',
                  endpoint,
                ),
                createdAt: _Parse.optionalString(
                  row['created_at'],
                  'reviews.created_at',
                  endpoint,
                ),
              ))
          .toList(),
      owned: _Parse.boolOf(data['owned'], 'owned', endpoint),
      canPurchase: _Parse.boolOf(data['can_purchase'], 'can_purchase', endpoint),
      purchaseBlockedReason: _Parse.optionalString(
        data['purchase_blocked_reason'],
        'purchase_blocked_reason',
        endpoint,
      ),
      coinBalance: _Parse.intOf(data['coin_balance'], 'coin_balance', endpoint),
    );
  }
}
