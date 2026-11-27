/// Pure Dart models for `GET /quiz/feed`.
///
/// Cards are authored and visibility-filtered by the server. The `*_url`
/// values in [FeedActions] are already `/api/v1/*` literals — never rewrite
/// them into web URLs. This feature reads the feed; it does not invent local
/// activities or grade anything on-device.
library;

class FeedOption {
  const FeedOption({required this.value, required this.label});

  final String value;
  final String label;
}

class FeedActor {
  const FeedActor({
    required this.id,
    required this.name,
    this.username,
    this.isCurrentUser = false,
    this.isFriendOrSelf = false,
  });

  final String id;
  final String name;
  final String? username;
  final bool isCurrentUser;
  final bool isFriendOrSelf;
}

class FeedComment {
  const FeedComment({
    required this.id,
    required this.body,
    required this.author,
    this.commentedAt,
    this.relativeTime,
    this.canDelete = false,
    this.deleteUrl,
  });

  final String id;
  final String body;
  final FeedActor author;
  final DateTime? commentedAt;
  final String? relativeTime;
  final bool canDelete;
  final String? deleteUrl;
}

class FeedComments {
  const FeedComments({this.count = 0, this.recent = const <FeedComment>[]});

  final int count;
  final List<FeedComment> recent;
}

class FeedReactions {
  const FeedReactions({
    this.like = 0,
    this.fire = 0,
    this.genius = 0,
    this.total = 0,
    this.viewerTypes = const <String>[],
  });

  final int like;
  final int fire;
  final int genius;
  final int total;
  final List<String> viewerTypes;
}

class FeedActions {
  const FeedActions({
    this.canChallenge = false,
    this.challengeUrl,
    this.canMute = false,
    this.muteUrl,
    this.canUpdateVisibility = false,
    this.visibilityOptions = const <FeedOption>[],
    this.canComment = false,
    this.commentUrl,
    this.canShare = false,
    this.shareUrl,
  });

  final bool canChallenge;
  final String? challengeUrl;
  final bool canMute;
  final String? muteUrl;
  final bool canUpdateVisibility;
  final List<FeedOption> visibilityOptions;
  final bool canComment;
  final String? commentUrl;
  final bool canShare;
  final String? shareUrl;
}

class FeedAttempt {
  const FeedAttempt({
    required this.id,
    this.mode,
    this.modeLabel,
    this.score = 0,
    this.totalPoints,
    this.correctCount,
    this.wrongCount,
    this.skippedCount,
    this.timeTakenSeconds,
    this.courseName,
    this.categoryName,
  });

  final int id;
  final String? mode;
  final String? modeLabel;
  final double score;
  final int? totalPoints;
  final int? correctCount;
  final int? wrongCount;
  final int? skippedCount;
  final int? timeTakenSeconds;
  final String? courseName;
  final String? categoryName;
}

class FeedCard {
  const FeedCard({
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
}
