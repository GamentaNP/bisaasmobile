import '../entities/profile_onboarding_status.dart';

/// Read boundary for the onboarding status snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class ProfileOnboardingStatusRepository {
  Future<ProfileOnboardingStatus> getStatus();
}
