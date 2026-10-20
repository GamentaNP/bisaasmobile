import 'package:meta/meta.dart';

/// The guest-tier funnel bundle.
///
/// The server publishes the same bundle to the web carousel and to the mobile
/// client: sampled public questions, live taxonomy counts and a fresh-content
/// promo. It is **guest-tier only** — public courses and active questions,
/// never answer keys, never explanations.
@immutable
class FunnelOption {
  const FunnelOption({required this.key, required this.text});

  final String key;
  final String text;
}

@immutable
class FunnelItem {
  const FunnelItem({
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

  final int id;
  final String questionText;
  final String? type;
  final String? typeLabel;
  final String? difficulty;
  final int points;
  final List<FunnelOption> options;
  final String? courseName;
  final String? courseSlug;
  final String? categoryName;
  final String? subCategoryName;
  final String? topicName;

  bool get hasOptions => options.isNotEmpty;
}

/// Live taxonomy counts.
@immutable
class FunnelCounts {
  const FunnelCounts({
    this.questions = 0,
    this.courses = 0,
    this.categories = 0,
    this.subCategories = 0,
    this.topics = 0,
    this.publicTypes = 0,
  });

  final int questions;
  final int courses;
  final int categories;
  final int subCategories;
  final int topics;
  final int publicTypes;

  bool get hasContent => questions > 0;
}

/// The fresh-content promo.
@immutable
class FunnelPromo {
  const FunnelPromo({
    this.latestCourse,
    this.latestCategory,
    this.hasFresh = false,
  });

  final String? latestCourse;
  final String? latestCategory;
  final bool hasFresh;
}

/// The whole funnel bundle.
@immutable
class QuizFunnel {
  const QuizFunnel({
    this.items = const [],
    this.counts = const FunnelCounts(),
    this.promo = const FunnelPromo(),
  });

  final List<FunnelItem> items;
  final FunnelCounts counts;
  final FunnelPromo promo;

  bool get isEmpty => items.isEmpty && !counts.hasContent;
}
