import '../entities/feed.dart';

/// Read boundary for the activity feed.
///
/// Throws on transport failure, non-2xx status or an unreadable body; an empty
/// list is only returned when the server published zero cards.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class FeedRepository {
  Future<List<FeedCard>> getFeed({
    required String scope,
    required String activityType,
  });
}
