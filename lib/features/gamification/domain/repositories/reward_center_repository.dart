import '../entities/reward_center.dart';

/// Read boundary for the reward-center snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class RewardCenterRepository {
  Future<RewardCenterSnapshot> getSnapshot();
}
