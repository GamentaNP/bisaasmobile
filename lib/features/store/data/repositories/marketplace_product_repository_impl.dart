import '../../domain/entities/marketplace_product.dart';
import '../../domain/repositories/marketplace_product_repository.dart';
import '../datasources/marketplace_product_remote_data_source.dart';

class MarketplaceProductRepositoryImpl implements MarketplaceProductRepository {
  const MarketplaceProductRepositoryImpl(this._remote);

  final MarketplaceProductRemoteDataSource _remote;

  @override
  Future<MarketplaceProductDetail> getProduct(String productId) =>
      _remote.getProduct(productId);
}
