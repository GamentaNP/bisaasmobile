/// Pure Dart view of `GET /quiz/marketplace/products/{product}` (§9.5).
///
/// `owned`, `can_purchase`, the blocked reason and the coin balance are the
/// server's conclusions. This screen never debits coins and never decides
/// eligibility locally; there is no cash buy flow in this payload.
library;

class MarketplaceProductDetail {
  const MarketplaceProductDetail({
    required this.product,
    required this.reviews,
    required this.owned,
    required this.canPurchase,
    required this.coinBalance,
    this.purchaseBlockedReason,
  });

  final MarketplaceProduct product;
  final List<MarketplaceReview> reviews;
  final bool owned;
  final bool canPurchase;
  final String? purchaseBlockedReason;
  final int coinBalance;
}

class MarketplaceProduct {
  const MarketplaceProduct({
    required this.id,
    required this.title,
    required this.priceCoins,
    required this.isFree,
    this.type,
    this.description,
    this.previewUrl,
    this.priceCents,
    this.currency,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.salesCount = 0,
    this.qualityScore = 0,
    this.categoryName,
    this.creatorName,
    this.creatorUsername,
    this.viewsCount = 0,
    this.publishedAt,
  });

  final int id;
  final String title;
  final int priceCoins;
  final bool isFree;
  final String? type;
  final String? description;
  final String? previewUrl;
  final int? priceCents;
  final String? currency;
  final double ratingAvg;
  final int ratingCount;
  final int salesCount;
  final double qualityScore;
  final String? categoryName;
  final String? creatorName;
  final String? creatorUsername;
  final int viewsCount;
  final String? publishedAt;
}

class MarketplaceReview {
  const MarketplaceReview({
    required this.id,
    required this.rating,
    required this.body,
    required this.isVerifiedPurchase,
    this.authorName,
    this.createdAt,
  });

  final int id;
  final int rating;
  final String body;
  final bool isVerifiedPurchase;
  final String? authorName;
  final String? createdAt;
}
