/// Pure Dart view of `GET /quiz/profile-onboarding/status` (§9.5).
///
/// The two booleans replace the web wizard's redirect. They are the server's
/// conclusion: the client does not infer onboarding state from local prefs on
/// this surface. Option lists are the server's active catalogue.
library;

class ProfileOnboardingStatus {
  const ProfileOnboardingStatus({
    required this.isOnboarded,
    required this.shouldShowWizard,
    required this.educationLevels,
    required this.domains,
    required this.courses,
  });

  final bool isOnboarded;
  final bool shouldShowWizard;
  final List<OnboardingOptionRow> educationLevels;
  final List<OnboardingOptionRow> domains;
  final List<OnboardingCourseRow> courses;
}

class OnboardingOptionRow {
  const OnboardingOptionRow({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
}

class OnboardingCourseRow {
  const OnboardingCourseRow({
    required this.id,
    required this.name,
    this.domainId,
  });

  final int id;
  final String name;
  final int? domainId;
}
