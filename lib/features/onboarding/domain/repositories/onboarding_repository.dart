library;

import '../entities/onboarding_options.dart';

/// Domain-facing contract. The screen never sees Dio or the envelope.
// ignore: one_member_abstracts
abstract class OnboardingRepository {
  Future<OnboardingOptions> getOptions();
}
