/// Pure Dart models for the bounded `GET /quiz/resources` snapshot (§9.5).
///
/// The four sections are the server's own cards with API member URLs, so a
/// bearer client never receives a first-party web path it cannot authenticate.
/// `upload_url` is null because uploads remain web-only.
library;

class ResourceCard {
  const ResourceCard({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.fileType,
    this.coinPrice = 0,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.downloadCount = 0,
    this.isUnlocked = false,
    this.isFeatured = false,
    this.detailUrl,
    this.categoryName,
    this.uploaderName,
  });

  final int id;
  final String slug;
  final String title;
  final String? description;
  final String? fileType;
  final int coinPrice;
  final num averageRating;
  final int reviewCount;
  final int downloadCount;
  final bool isUnlocked;
  final bool isFeatured;
  final String? detailUrl;
  final String? categoryName;
  final String? uploaderName;
}

class ResourceHub {
  const ResourceHub({
    required this.sections,
    this.libraryUrl,
    this.myLibraryUrl,
    this.uploadUrl,
  });

  /// Section key → cards. Keys are server-authored (recommended, trending,
  /// top_rated, recently_added); additive sections are tolerated.
  final Map<String, List<ResourceCard>> sections;
  final String? libraryUrl;
  final String? myLibraryUrl;
  final String? uploadUrl;
}
