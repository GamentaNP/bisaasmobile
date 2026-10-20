import '../../domain/entities/quiz_funnel.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// One sampled question from the funnel bundle.
///
/// The funnel is guest-tier: public courses and active questions only, never
/// answer keys, never explanations (`QuizFunnelResource` exposure policy).
class FunnelItemDto {
  const FunnelItemDto({
    required this.id,
    required this.questionText,
    this.type,
    this.typeLabel,
    this.difficulty,
    this.points = 0,
    this.options = const [],
    this.courseName,
    this.courseSlug,
    this.categoryName,
    this.subCategoryName,
    this.topicName,
  });

  factory FunnelItemDto.fromJson(Map<String, dynamic> j) {
    final options = <FunnelOptionDto>[];
    final rawOptions = j['options'];
    if (rawOptions is List) {
      for (var i = 0; i < rawOptions.length; i++) {
        final o = rawOptions[i];
        if (o is Map<String, dynamic>) {
          options.add(
            FunnelOptionDto(
              key: (o['key'] ?? o['id'] ?? '').toString(),
              text: (o['text'] ?? o['label'] ?? '').toString(),
            ),
          );
        }
      }
    }

    final course = j['course'];
    final courseMap =
        course is Map<String, dynamic> ? course : const <String, dynamic>{};

    return FunnelItemDto(
      id: _asInt(j['id']) ?? 0,
      questionText: (j['question_text'] ?? j['questionText'] ?? '').toString(),
      type: j['type'] as String?,
      typeLabel: j['type_label'] as String?,
      difficulty: j['difficulty'] as String?,
      points: _asInt(j['points']) ?? 0,
      options: options,
      courseName: courseMap['name'] as String?,
      courseSlug: courseMap['slug'] as String?,
      categoryName: _named(j['category']),
      subCategoryName: _named(j['sub_category']),
      topicName: _named(j['topic']),
    );
  }

  final int id;
  final String questionText;
  final String? type;
  final String? typeLabel;
  final String? difficulty;
  final int points;
  final List<FunnelOptionDto> options;
  final String? courseName;
  final String? courseSlug;
  final String? categoryName;
  final String? subCategoryName;
  final String? topicName;

  FunnelItem toDomain() => FunnelItem(
        id: id,
        questionText: questionText,
        type: type,
        typeLabel: typeLabel,
        difficulty: difficulty,
        points: points,
        options: options.map((o) => o.toDomain()).toList(),
        courseName: courseName,
        courseSlug: courseSlug,
        categoryName: categoryName,
        subCategoryName: subCategoryName,
        topicName: topicName,
      );

  /// The taxonomy fields arrive as `{name: "…"}` objects or null.
  static String? _named(Object? raw) {
    if (raw is Map) return raw['name'] as String?;
    if (raw is String) return raw;
    return null;
  }
}

class FunnelOptionDto {
  const FunnelOptionDto({required this.key, required this.text});

  final String key;
  final String text;

  FunnelOption toDomain() => FunnelOption(key: key, text: text);
}

/// The taxonomy counts the funnel publishes.
class FunnelCountsDto {
  const FunnelCountsDto({
    this.questions = 0,
    this.courses = 0,
    this.categories = 0,
    this.subCategories = 0,
    this.topics = 0,
    this.publicTypes = 0,
  });

  factory FunnelCountsDto.fromJson(Map<String, dynamic> j) => FunnelCountsDto(
        questions: _asInt(j['questions']) ?? 0,
        courses: _asInt(j['courses']) ?? 0,
        categories: _asInt(j['categories']) ?? 0,
        subCategories: _asInt(j['sub_categories']) ?? 0,
        topics: _asInt(j['topics']) ?? 0,
        publicTypes: _asInt(j['public_types']) ?? 0,
      );

  final int questions;
  final int courses;
  final int categories;
  final int subCategories;
  final int topics;
  final int publicTypes;

  FunnelCounts toDomain() => FunnelCounts(
        questions: questions,
        courses: courses,
        categories: categories,
        subCategories: subCategories,
        topics: topics,
        publicTypes: publicTypes,
      );
}

/// The fresh-content promo block.
class FunnelPromoDto {
  const FunnelPromoDto({
    this.latestCourse,
    this.latestCategory,
    this.hasFresh = false,
  });

  factory FunnelPromoDto.fromJson(Map<String, dynamic> j) => FunnelPromoDto(
        latestCourse: j['latest_course'] as String?,
        latestCategory: j['latest_category'] as String?,
        hasFresh: j['has_fresh'] as bool? ?? false,
      );

  final String? latestCourse;
  final String? latestCategory;
  final bool hasFresh;

  FunnelPromo toDomain() => FunnelPromo(
        latestCourse: latestCourse,
        latestCategory: latestCategory,
        hasFresh: hasFresh,
      );
}

/// The whole funnel bundle.
class QuizFunnelDto {
  const QuizFunnelDto({
    this.items = const [],
    this.counts = const FunnelCountsDto(),
    this.promo = const FunnelPromoDto(),
  });

  factory QuizFunnelDto.fromJson(Map<String, dynamic> j) {
    final items = <FunnelItemDto>[];
    final raw = j['items'];
    if (raw is List) {
      items.addAll(
        raw.whereType<Map<String, dynamic>>().map(FunnelItemDto.fromJson),
      );
    }
    final counts = j['counts'];
    final promo = j['promo'];
    return QuizFunnelDto(
      items: items,
      counts: counts is Map<String, dynamic>
          ? FunnelCountsDto.fromJson(counts)
          : const FunnelCountsDto(),
      promo: promo is Map<String, dynamic>
          ? FunnelPromoDto.fromJson(promo)
          : const FunnelPromoDto(),
    );
  }

  final List<FunnelItemDto> items;
  final FunnelCountsDto counts;
  final FunnelPromoDto promo;

  QuizFunnel toDomain() => QuizFunnel(
        items: items.map((i) => i.toDomain()).toList(),
        counts: counts.toDomain(),
        promo: promo.toDomain(),
      );
}

