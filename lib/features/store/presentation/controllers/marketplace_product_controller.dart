/// Provider for the marketplace detail read (§9.5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/marketplace_product_remote_data_source.dart';
import '../../data/repositories/marketplace_product_repository_impl.dart';
import '../../domain/entities/marketplace_product.dart';
import '../../domain/repositories/marketplace_product_repository.dart';

final marketplaceProductRemoteDataSourceProvider =
    Provider<MarketplaceProductRemoteDataSource>((ref) {
  return MarketplaceProductRemoteDataSource(ref.watch(dioProvider));
});

final marketplaceProductRepositoryProvider =
    Provider<MarketplaceProductRepository>((ref) {
  return MarketplaceProductRepositoryImpl(
    ref.watch(marketplaceProductRemoteDataSourceProvider),
  );
});

final marketplaceProductProvider =
    FutureProvider.family<MarketplaceProductDetail, String>((ref, productId) {
  return ref.watch(marketplaceProductRepositoryProvider).getProduct(productId);
});
