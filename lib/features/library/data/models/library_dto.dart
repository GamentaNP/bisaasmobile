// ignore_for_file: avoid_dynamic_calls, omit_local_variable_types, unnecessary_cast, dead_code, unnecessary_type_check
import '../../domain/entities/library.dart';

/// Tolerant DTOs — additive parsing, never throws on missing/extra fields.
/// Mirrors server resources:
/// - LibraryCategoryResource: id, name, slug, description, icon, children[], file_count
/// - LibraryFileResource: id, title, slug, description, file_type, visibility,
///   coin_price, average_rating, review_count, download_count, is_featured,
///   tags, created_at, category{uploader}, uploader
/// - LibraryReviewResource: id, rating, comment, is_verified_download, user, created_at
class LibraryCategoryDto {
  const LibraryCategoryDto({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.fileCount,
    this.children = const [],
  });

  factory LibraryCategoryDto.fromJson(Map<String, dynamic> j) {
    // children may be absent, null, or list. Tolerant.
    final rawChildren = j['children'];
    List<LibraryCategoryDto> children = [];
    if (rawChildren is List) {
      children = rawChildren
          .whereType<Map<String, dynamic>>()
          .map(LibraryCategoryDto.fromJson)
          .toList();
    }
    return LibraryCategoryDto(
      id: _asInt(j['id']) ?? 0,
      name: (j['name'] as String?) ?? '',
      slug: (j['slug'] as String?) ?? '',
      description: j['description'] as String?,
      icon: j['icon'] as String?,
      fileCount: _asInt(j['file_count'] ?? j['files_count']),
      children: children,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int? fileCount;
  final List<LibraryCategoryDto> children;

  LibraryCategory toDomain() => LibraryCategory(
        id: id,
        name: name,
        slug: slug,
        description: description,
        icon: icon,
        fileCount: fileCount,
        children: children.map((c) => c.toDomain()).toList(),
      );
}

/// Lightweight category ref inside a File — from LibraryFileResource category block.
class LibraryCategoryRefDto {
  const LibraryCategoryRefDto({required this.id, required this.name, required this.slug});
  factory LibraryCategoryRefDto.fromJson(Map<String, dynamic> j) => LibraryCategoryRefDto(
        id: _asInt(j['id']) ?? 0,
        name: (j['name'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
      );
  final int id;
  final String name;
  final String slug;

  LibraryCategoryRef toDomain() => LibraryCategoryRef(id: id, name: name, slug: slug);
}

class LibraryUploaderDto {
  const LibraryUploaderDto({required this.id, required this.name});
  factory LibraryUploaderDto.fromJson(Map<String, dynamic> j) => LibraryUploaderDto(
        id: _asInt(j['id']) ?? 0,
        name: (j['name'] as String?) ?? '',
      );
  final int id;
  final String name;
  LibraryUploader toDomain() => LibraryUploader(id: id, name: name);
}

class LibraryFileDto {
  const LibraryFileDto({
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

  factory LibraryFileDto.fromJson(Map<String, dynamic> j) {
    // Tolerant: every field optional with sensible default.
    // Server may add fields like metadata, license, view_count, etc. — ignored.
    final catRaw = j['category'];
    LibraryCategoryRefDto? cat;
    if (catRaw is Map<String, dynamic>) {
      cat = LibraryCategoryRefDto.fromJson(catRaw);
    }
    final upRaw = j['uploader'];
    LibraryUploaderDto? up;
    if (upRaw is Map<String, dynamic>) {
      up = LibraryUploaderDto.fromJson(upRaw);
    }
    final tagsRaw = j['tags'];
    List<String> tags = [];
    if (tagsRaw is List) {
      tags = tagsRaw.map((e) => e.toString()).toList();
    }

    DateTime? created;
    final createdRaw = j['created_at'] ?? j['approved_at'];
    if (createdRaw is String) created = DateTime.tryParse(createdRaw);

    // is_unlocked may be added later — additive
    bool? unlocked;
    if (j.containsKey('is_unlocked')) {
      final v = j['is_unlocked'];
      if (v is bool) unlocked = v;
      if (v is int) unlocked = v == 1;
      if (v is String) unlocked = v.toLowerCase() == 'true' || v == '1';
    }

    return LibraryFileDto(
      id: _asInt(j['id']) ?? 0,
      title: (j['title'] as String?) ?? '',
      slug: (j['slug'] as String?) ?? '',
      description: j['description'] as String?,
      fileType: (j['file_type'] as String?) ?? (j['fileType'] as String?) ?? 'unknown',
      visibility: (j['visibility'] as String?) ?? 'public',
      coinPrice: _asInt(j['coin_price']) ?? 0,
      averageRating: _asDouble(j['average_rating']) ?? 0.0,
      reviewCount: _asInt(j['review_count']) ?? 0,
      downloadCount: _asInt(j['download_count']) ?? 0,
      isFeatured: (j['is_featured'] as bool?) ?? false,
      tags: tags,
      createdAt: created,
      category: cat,
      uploader: up,
      isUnlocked: unlocked,
    );
  }

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
  final LibraryCategoryRefDto? category;
  final LibraryUploaderDto? uploader;
  final bool? isUnlocked;

  LibraryFile toDomain() => LibraryFile(
        id: id,
        title: title,
        slug: slug,
        description: description,
        fileType: fileType,
        visibility: visibility,
        coinPrice: coinPrice,
        averageRating: averageRating,
        reviewCount: reviewCount,
        downloadCount: downloadCount,
        isFeatured: isFeatured,
        tags: tags,
        createdAt: createdAt,
        category: category?.toDomain(),
        uploader: uploader?.toDomain(),
        isUnlocked: isUnlocked,
      );
}

class LibraryReviewUserDto {
  const LibraryReviewUserDto({required this.id, required this.name});
  factory LibraryReviewUserDto.fromJson(Map<String, dynamic> j) => LibraryReviewUserDto(
        id: _asInt(j['id']) ?? 0,
        name: (j['name'] as String?) ?? '',
      );
  final int id;
  final String name;
  LibraryReviewUser toDomain() => LibraryReviewUser(id: id, name: name);
}

class LibraryReviewDto {
  const LibraryReviewDto({
    required this.id,
    required this.rating,
    this.comment,
    required this.isVerifiedDownload,
    this.user,
    this.createdAt,
  });

  factory LibraryReviewDto.fromJson(Map<String, dynamic> j) {
    final userRaw = j['user'];
    LibraryReviewUserDto? user;
    if (userRaw is Map<String, dynamic>) {
      user = LibraryReviewUserDto.fromJson(userRaw);
    }
    DateTime? created;
    final cRaw = j['created_at'];
    if (cRaw is String) created = DateTime.tryParse(cRaw);

    return LibraryReviewDto(
      id: _asInt(j['id']) ?? 0,
      rating: _asInt(j['rating']) ?? 0,
      comment: j['comment'] as String?,
      isVerifiedDownload: (j['is_verified_download'] as bool?) ?? false,
      user: user,
      createdAt: created,
    );
  }

  final int id;
  final int rating;
  final String? comment;
  final bool isVerifiedDownload;
  final LibraryReviewUserDto? user;
  final DateTime? createdAt;

  LibraryReview toDomain() => LibraryReview(
        id: id,
        rating: rating,
        comment: comment,
        isVerifiedDownload: isVerifiedDownload,
        user: user?.toDomain(),
        createdAt: createdAt,
      );
}

/// Unlock result from POST /library/files/{slug}/unlock
class LibraryUnlockDto {
  const LibraryUnlockDto({required this.unlocked, required this.coinsSpent, this.unlockedAt});
  factory LibraryUnlockDto.fromJson(Map<String, dynamic> j) => LibraryUnlockDto(
        unlocked: (j['unlocked'] as bool?) ?? true,
        coinsSpent: _asInt(j['coins_spent']) ?? 0,
        unlockedAt: j['unlocked_at'] is String ? DateTime.tryParse(j['unlocked_at'] as String) : null,
      );
  final bool unlocked;
  final int coinsSpent;
  final DateTime? unlockedAt;

  LibraryUnlockResult toDomain() => LibraryUnlockResult(unlocked: unlocked, coinsSpent: coinsSpent, unlockedAt: unlockedAt);
}

/// Entry from GET /library/me/unlocks — {file: FileResource, coins_spent, unlocked_at}
class LibraryUnlockItemDto {
  const LibraryUnlockItemDto({required this.file, required this.coinsSpent, this.unlockedAt});
  factory LibraryUnlockItemDto.fromJson(Map<String, dynamic> j) {
    final rawFile = j['file'];
    final Map<String, dynamic> fileJson;
    if (rawFile is Map<String, dynamic>) {
      fileJson = rawFile;
    } else {
      // Fallback to j itself for flat test shapes — treat j as file
      fileJson = j;
    }
    final fileDto = LibraryFileDto.fromJson(fileJson);
    return LibraryUnlockItemDto(
      file: fileDto,
      coinsSpent: _asInt(j['coins_spent']) ?? 0,
      unlockedAt: j['unlocked_at'] is String ? DateTime.tryParse(j['unlocked_at'] as String) : null,
    );
  }
  final LibraryFileDto file;
  final int coinsSpent;
  final DateTime? unlockedAt;

  LibraryUnlockItem toDomain() => LibraryUnlockItem(file: file.toDomain(), coinsSpent: coinsSpent, unlockedAt: unlockedAt);
}

// ── helpers ───────────────────────────────────────────────────────────────────

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  if (v is num) return v.toInt();
  return null;
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  if (v is num) return v.toDouble();
  return null;
}
