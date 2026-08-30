import 'package:meta/meta.dart';

@immutable
class LibraryCategory {
  const LibraryCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.fileCount,
    this.children = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int? fileCount;
  final List<LibraryCategory> children;
}

@immutable
class LibraryCategoryRef {
  const LibraryCategoryRef({required this.id, required this.name, required this.slug});
  final int id;
  final String name;
  final String slug;
}

@immutable
class LibraryUploader {
  const LibraryUploader({required this.id, required this.name});
  final int id;
  final String name;
}

@immutable
class LibraryFile {
  const LibraryFile({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.fileType,
    required this.visibility,
    required this.coinPrice,
    required this.averageRating,
    required this.reviewCount,
    required this.downloadCount,
    required this.isFeatured,
    this.tags = const [],
    this.createdAt,
    this.category,
    this.uploader,
    this.isUnlocked,
  });

  final int id;
  final String title;
  final String slug;
  final String? description;
  final String fileType;
  final String visibility;
  final int coinPrice;
  final double averageRating;
  final int reviewCount;
  final int downloadCount;
  final bool isFeatured;
  final List<String> tags;
  final DateTime? createdAt;
  final LibraryCategoryRef? category;
  final LibraryUploader? uploader;
  final bool? isUnlocked;

  bool get isFree => coinPrice == 0;
}

@immutable
class LibraryReviewUser {
  const LibraryReviewUser({required this.id, required this.name});
  final int id;
  final String name;
}

@immutable
class LibraryReview {
  const LibraryReview({
    required this.id,
    required this.rating,
    this.comment,
    required this.isVerifiedDownload,
    this.user,
    this.createdAt,
  });

  final int id;
  final int rating;
  final String? comment;
  final bool isVerifiedDownload;
  final LibraryReviewUser? user;
  final DateTime? createdAt;
}

@immutable
class LibraryUnlockResult {
  const LibraryUnlockResult({required this.unlocked, required this.coinsSpent, this.unlockedAt});
  final bool unlocked;
  final int coinsSpent;
  final DateTime? unlockedAt;
}

@immutable
class LibraryUnlockItem {
  const LibraryUnlockItem({required this.file, required this.coinsSpent, this.unlockedAt});
  final LibraryFile file;
  final int coinsSpent;
  final DateTime? unlockedAt;
}
