import '../entities/analytics.dart';

/// Read boundary for the learner analytics snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class AnalyticsRepository {
  Future<AnalyticsOverview> getOverview();
}
