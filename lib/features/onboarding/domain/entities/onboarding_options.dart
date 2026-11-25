library;

/// The option catalogue published by `GET /api/v1/quiz/onboarding/options`.
///
/// Pure Dart: no Dio, no envelope, no Flutter. The wire shape is parsed by
/// `OnboardingOptionsDto` in the data layer; the screen only ever sees these
/// entities. Every option is server-authored — the client invents none.
class OnboardingOptions {
  const OnboardingOptions({
    required this.educationLevels,
    required this.domains,
    required this.courses,
    required this.goalIntensities,
  });

  final List<EducationLevelOption> educationLevels;
  final List<DomainOption> domains;
  final List<CourseOption> courses;
  final List<GoalIntensityOption> goalIntensities;
}

/// A server education level (SEE, IAG, BBS, MBBS, …).
///
/// The wire `description` is kept for contract fidelity but is never rendered:
/// these names are acronyms/proper nouns and the server's English prose is not
/// translated.
class EducationLevelOption {
  const EducationLevelOption({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
}

/// A server study field/domain (Engineering, Medical, …).
class DomainOption {
  const DomainOption({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
}

/// A course offered under a domain, kept so the catalogue is complete even
/// though the wizard itself only reads domains, intensities and levels.
class CourseOption {
  const CourseOption({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.domainId,
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final int? domainId;
}

/// One of the server's pacing presets.
///
/// `value` is the stable protocol key (`casual`/`serious`/`beast`) that must be
/// translated locally; `label` is the server's English display copy and is
/// deliberately never shown to the reader. `defaultMinutes` is the value that
/// is persisted in `Preferences.dailyGoalMinutes`.
class GoalIntensityOption {
  const GoalIntensityOption({
    required this.value,
    required this.label,
    required this.defaultMinutes,
  });

  final String value;
  final String label;
  final int defaultMinutes;
}
