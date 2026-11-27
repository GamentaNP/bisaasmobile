import '../../../../core/network/api_failure.dart';
import '../../domain/entities/analytics.dart';

/// Wire DTO for the composed analytics snapshot.
///
/// All three sections are mandatory; a 2xx body missing one is drift rather
/// than "the learner has no data". Empty inner lists are fine when published.
abstract final class _Parse {
  static Map<String, dynamic> requireMap(
    Object? value, {
    required String endpoint,
    required String key,
  }) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> requireList(
    Object? value, {
    required String endpoint,
    required String key,
  }) {
    if (value is List) return value.whereType<Map<String, dynamic>>().toList();
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static int intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double doubleOf(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class AnalyticsOverviewDto {
  const AnalyticsOverviewDto({
    required this.userStats,
    required this.categoryPerformance,
    required this.heatmap,
  });

  factory AnalyticsOverviewDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/analytics/overview',
  }) {
    final stats = _Parse.requireMap(j['user_stats'], endpoint: endpoint, key: 'user_stats');
    final heatmap = _Parse.requireMap(
      j['weak_topic_heatmap'],
      endpoint: endpoint,
      key: 'weak_topic_heatmap',
    );
    final heatmapSummary = _Parse.requireMap(
      heatmap['summary'],
      endpoint: endpoint,
      key: 'weak_topic_heatmap.summary',
    );
    return AnalyticsOverviewDto(
      userStats: AnalyticsUserStats(
        totalAttempts: _Parse.intOf(stats['total_attempts']),
        completedAttempts: _Parse.intOf(stats['completed_attempts']),
        totalQuestionsAnswered: _Parse.intOf(stats['total_questions_answered']),
        correctAnswers: _Parse.intOf(stats['correct_answers']),
        accuracyPercent: _Parse.doubleOf(stats['accuracy_percent']),
        averageScore: _Parse.doubleOf(stats['average_score']),
      ),
      categoryPerformance: _Parse.requireList(
        j['category_performance'],
        endpoint: endpoint,
        key: 'category_performance',
      ).map((row) {
        final id = _Parse.intOf(row['category_id']);
        return AnalyticsCategory(
          categoryId: id,
          categoryName: (row['category_name'] ?? '').toString(),
          accuracyPercent: _Parse.doubleOf(row['accuracy_percent']),
          totalAnswered: _Parse.intOf(row['total_answered']),
        );
      }).toList(),
      heatmap: WeakTopicHeatmap(
        summary: AnalyticsHeatmapSummary(
          topicsCount: _Parse.intOf(heatmapSummary['topics_count']),
          weakCount: _Parse.intOf(heatmapSummary['weak_count']),
          developingCount: _Parse.intOf(heatmapSummary['developing_count']),
          strongCount: _Parse.intOf(heatmapSummary['strong_count']),
          totalAnswered: _Parse.intOf(heatmapSummary['total_answered']),
          averageAccuracy: _Parse.doubleOf(heatmapSummary['average_accuracy']),
        ),
        topics: _Parse.requireList(
          heatmap['topics'],
          endpoint: endpoint,
          key: 'weak_topic_heatmap.topics',
        ).map((row) => AnalyticsTopic(
              topicKey: (row['topic_key'] ?? '').toString(),
              topicName: (row['topic_name'] ?? '').toString(),
              categoryName: row['category_name'] as String?,
              categorySlug: row['category_slug'] as String?,
              totalAnswered: _Parse.intOf(row['total_answered']),
              correctAnswers: _Parse.intOf(row['correct_answers']),
              missedAnswers: _Parse.intOf(row['missed_answers']),
              accuracyPercent: _Parse.doubleOf(row['accuracy_percent']),
              averageTimeSeconds: row.containsKey('average_time_seconds') &&
                      row['average_time_seconds'] != null
                  ? _Parse.intOf(row['average_time_seconds'])
                  : null,
              band: row['band'] as String?,
              intensity: _Parse.intOf(row['intensity']),
              recommendation: row['recommendation'] as String?,
              weeklyTrend: row['weekly_trend'] as String?,
            )).toList(),
      ),
    );
  }

  final AnalyticsUserStats userStats;
  final List<AnalyticsCategory> categoryPerformance;
  final WeakTopicHeatmap heatmap;

  AnalyticsOverview toDomain() => AnalyticsOverview(
        userStats: userStats,
        categoryPerformance: categoryPerformance,
        heatmap: heatmap,
      );
}
