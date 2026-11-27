import '../entities/impact_leaders.dart';

/// Read boundary for the impact-leaderboard snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class ImpactLeadersRepository {
  Future<ImpactLeadersSnapshot> getLeaders();
}
