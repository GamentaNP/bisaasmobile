import '../../../../core/network/api_failure.dart';
import '../../domain/entities/feed.dart';

/// Wire DTO for one `data.items[]` card of `GET /quiz/feed`.
///
/// The controller snake_cases every nested key, so only snake_case names are
/// read here. An unreadable card is contract drift, not a card to skip.
abstract final class _Parse {
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

  static Map<String, dynamic> mapOf(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static List<Object?> listOf(Object? value) =>
      value is List ? value : const <Object?>[];

  static DateTime? dateOf(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String requireString(Object? value, String key, {required String endpoint}) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A feed card has no $key', endpoint: endpoint);
    }
    return text;
  }
}

class FeedCardDto {
  const FeedCardDto({
    required this.id,
    required this.activityType,
    required this.message,
    required this.actor,
    required this.actions,
    required this.reactions,
    required this.comments,
    this.visibility,
    this.attempt,
    this.occurredAt,
    this.relativeTime,
  });

  factory FeedCardDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/feed',
  }) {
    final actor = _Parse.mapOf(j['actor']);
    return FeedCardDto(
      id: _Parse.requireString(j['id'], 'id', endpoint: endpoint),
      activityType: _Parse.requireString(j['activity_type'] ?? j['activityType'], 'activity_type', endpoint: endpoint),
      message: (j['message'] ?? '').toString(),
      visibility: j['visibility'] as String?,
      actor: FeedActor(
        id: (actor['id'] ?? '').toString(),
        name: (actor['name'] ?? '').toString(),
        username: actor['username'] as String?,
        isCurrentUser: actor['is_current_user'] == true,
        isFriendOrSelf: actor['is_friend_or_self'] == true,
      ),
      actions: _actions(_Parse.mapOf(j['actions'])),
      reactions: _reactions(_Parse.mapOf(j['reactions'])),
      comments: _comments(_Parse.mapOf(j['comments'])),
      attempt: j['attempt'] is Map<String, dynamic>
          ? _attempt(j['attempt'] as Map<String, dynamic>)
          : null,
      occurredAt: _Parse.dateOf(j['occurred_at'] ?? j['occurredAt']),
      relativeTime: (j['relative_time'] ?? j['relativeTime']) as String?,
    );
  }

  final String id;
  final String activityType;
  final String message;
  final FeedActor actor;
  final FeedActions actions;
  final FeedReactions reactions;
  final FeedComments comments;
  final String? visibility;
  final FeedAttempt? attempt;
  final DateTime? occurredAt;
  final String? relativeTime;

  static FeedActions _actions(Map<String, dynamic> j) => FeedActions(
        canChallenge: j['can_challenge'] == true,
        challengeUrl: j['challenge_url'] as String?,
        canMute: j['can_mute'] == true,
        muteUrl: j['mute_url'] as String?,
        canUpdateVisibility: j['can_update_visibility'] == true,
        visibilityOptions: _Parse.listOf(j['visibility_options'])
            .whereType<Map<String, dynamic>>()
            .map((o) => FeedOption(
                  value: (o['value'] ?? '').toString(),
                  label: (o['label'] ?? '').toString(),
                ))
            .toList(),
        canComment: j['can_comment'] == true,
        commentUrl: j['comment_url'] as String?,
        canShare: j['can_share'] == true,
        shareUrl: j['share_url'] as String?,
      );

  static FeedReactions _reactions(Map<String, dynamic> j) {
    final counts = _Parse.mapOf(j['counts']);
    return FeedReactions(
      like: _Parse.intOf(counts['like']),
      fire: _Parse.intOf(counts['fire']),
      genius: _Parse.intOf(counts['genius']),
      total: _Parse.intOf(j['total']),
      viewerTypes: _Parse.listOf(j['viewer_types'])
          .map((type) => type.toString())
          .toList(),
    );
  }

  static FeedComments _comments(Map<String, dynamic> j) => FeedComments(
        count: _Parse.intOf(j['count']),
        recent: _Parse.listOf(j['recent'])
            .whereType<Map<String, dynamic>>()
            .map((row) {
          final author = _Parse.mapOf(row['author']);
          return FeedComment(
            id: (row['id'] ?? '').toString(),
            body: (row['body'] ?? '').toString(),
            author: FeedActor(
              id: (author['id'] ?? '').toString(),
              name: (author['name'] ?? '').toString(),
              username: author['username'] as String?,
              isCurrentUser: author['is_current_user'] == true,
            ),
            commentedAt: _Parse.dateOf(row['commented_at']),
            relativeTime: row['relative_time'] as String?,
            canDelete: row['can_delete'] == true,
            deleteUrl: row['delete_url'] as String?,
          );
        }).toList(),
      );

  static FeedAttempt _attempt(Map<String, dynamic> j) => FeedAttempt(
        id: _Parse.intOf(j['id']),
        mode: j['mode'] as String?,
        modeLabel: j['mode_label'] as String?,
        score: _Parse.doubleOf(j['score']),
        totalPoints: j.containsKey('total_points') ? _Parse.intOf(j['total_points']) : null,
        correctCount: j.containsKey('correct_count') ? _Parse.intOf(j['correct_count']) : null,
        wrongCount: j.containsKey('wrong_count') ? _Parse.intOf(j['wrong_count']) : null,
        skippedCount: j.containsKey('skipped_count') ? _Parse.intOf(j['skipped_count']) : null,
        timeTakenSeconds: j.containsKey('time_taken_seconds')
            ? _Parse.intOf(j['time_taken_seconds'])
            : null,
        courseName: j['course_name'] as String?,
        categoryName: j['category_name'] as String?,
      );

  FeedCard toDomain() => FeedCard(
        id: id,
        activityType: activityType,
        message: message,
        actor: actor,
        actions: actions,
        reactions: reactions,
        comments: comments,
        visibility: visibility,
        attempt: attempt,
        occurredAt: occurredAt,
        relativeTime: relativeTime,
      );
}
