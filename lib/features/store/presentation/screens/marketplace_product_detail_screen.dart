import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/marketplace_product_controller.dart';

/// One published product with its visible reviews and server eligibility.
///
/// Read-only: the coin balance and `can_purchase` come from the server and no
/// purchase is attempted from this screen. A blocked product shows the exact
/// reason the server published.
class MarketplaceProductDetailScreen extends ConsumerWidget {
  const MarketplaceProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(marketplaceProductProvider(productId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storeCoinShop)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(marketplaceProductProvider(productId)),
        ),
        data: (detail) {
          final product = detail.product;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(product.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(product.isFree
                  ? l10n.libraryFree
                  : l10n.libraryCoinsLabel(product.priceCoins)),
              if (product.creatorName != null)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.libraryByUploader(product.creatorName!)),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.commonWallet),
                  trailing: Text(l10n.libraryCoinsLabel(detail.coinBalance)),
                ),
              ),
              ListTile(
                dense: true,
                leading: Icon(detail.owned
                    ? Icons.check_circle_outline
                    : Icons.shopping_bag_outlined),
                title: Text(l10n.storeOwned),
                trailing: Text(detail.owned
                    ? l10n.commonSuccess
                    : l10n.commonFailed),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.socialStatus(detail.canPurchase
                    ? l10n.commonSuccess
                    : l10n.commonFailed)),
                subtitle: Text(detail.purchaseBlockedReason ?? ''),
              ),
              const SizedBox(height: 8),
              Text(l10n.libraryAbout, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(product.description ?? ''),
              const SizedBox(height: 16),
              Text(l10n.libraryReviews, style: Theme.of(context).textTheme.titleSmall),
              if (detail.reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.libraryNoReviews,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final review in detail.reviews)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.star_outline),
                    title: Text(review.body),
                    subtitle: review.authorName == null
                        ? null
                        : Text(l10n.libraryByUploader(review.authorName!)),
                    trailing: Text(
                      '${review.rating}${review.isVerifiedPurchase ? ' ${l10n.libraryVerified}' : ''}',
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
