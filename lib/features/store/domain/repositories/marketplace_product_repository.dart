import '../entities/marketplace_product.dart';

/// Read boundary for one published marketplace product.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class MarketplaceProductRepository {
  Future<MarketplaceProductDetail> getProduct(String productId);
}
