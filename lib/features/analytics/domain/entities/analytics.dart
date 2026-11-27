/// Pure Dart models for the composed `GET /quiz/analytics/overview` snapshot.
///
/// Every number is computed and tenant-scoped by the server. The client must
/// not recompute accuracy from response rows — it only renders them.
library;

class AnalyticsUserStats {
  const AnalyticsUserStats({
    this.totalAttempts = 0,
    this.completedAttempts = 0,
    this.totalQuestionsAnswered = 0,
    this.correctAnswers = 0,
    this.accuracyPercent = 0,
    this.averageScore = 0,
  });

  final int totalAttempts;
  final int completedAttempts;
  final int totalQuestionsAnswered;
  final int correctAnswers;
  final double accuracyPercent;
  final double averageScore;
}

class AnalyticsCategory {
  const AnalyticsCategory({
    required this.categoryId,
    required this.categoryName,
    this.accuracyPercent = 0,
    this.totalAnswered = 0,
  });

  final int categoryId;
  final String categoryName;
  final double accuracyPercent;
  final int totalAnswered;
}

class AnalyticsHeatmapSummary {
  const AnalyticsHeatmapSummary({
    this.topicsCount = 0,
    this.weakCount = 0,
    this.developingCount = 0,
    this.strongCount = 0,
    this.totalAnswered = 0,
    this.averageAccuracy = 0,
  });

  final int topicsCount;
  final int weakCount;
  final int developingCount;
  final int strongCount;
  final int totalAnswered;
  final double averageAccuracy;
}

class AnalyticsTopic {
  const AnalyticsTopic({
    required this.topicKey,
    required this.topicName,
    this.categoryName,
    this.categorySlug,
    this.totalAnswered = 0,
    this.correctAnswers = 0,
    this.missedAnswers = 0,
    this.accuracyPercent = 0,
    this.averageTimeSeconds,
    this.band,
    this.intensity = 0,
    this.recommendation,
    this.weeklyTrend,
  });

  final String topicKey;
  final String topicName;
  final String? categoryName;
  final String? categorySlug;
  final int totalAnswered;
  final int correctAnswers;
  final int missedAnswers;
  final double accuracyPercent;
  final int? averageTimeSeconds;
  final String? band;
  final int intensity;
  final String? recommendation;
  final String? weeklyTrend;
}

class WeakTopicHeatmap {
  const WeakTopicHeatmap({required this.summary, required this.topics});

  final AnalyticsHeatmapSummary summary;
  final List<AnalyticsTopic> topics;
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.userStats,
    required this.categoryPerformance,
    required this.heatmap,
  });

  final AnalyticsUserStats userStats;
  final List<AnalyticsCategory> categoryPerformance;
  final WeakTopicHeatmap heatmap;
}
