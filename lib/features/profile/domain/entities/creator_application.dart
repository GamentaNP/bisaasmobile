/// Pure Dart view of `GET /quiz/creator/applications/current` (§9.5).
///
/// Eligibility is computed by the server from XP and reputation. The client
/// only renders it and never guesses whether the POST submit will succeed.
/// This read creates no application.
library;

class CreatorApplicationStatus {
  const CreatorApplicationStatus({
    required this.eligibility,
    required this.topSubjects,
    this.existing,
  });

  final CreatorEligibility eligibility;
  final CreatorApplicationExisting? existing;
  final List<CreatorSubject> topSubjects;
}

class CreatorEligibility {
  const CreatorEligibility({
    required this.isEligible,
    required this.level,
    required this.levelRequired,
    required this.reputationScore,
    required this.reputationRequired,
    required this.meetsLevel,
    required this.meetsReputation,
  });

  final bool isEligible;
  final int level;
  final int levelRequired;
  final int reputationScore;
  final int reputationRequired;
  final bool meetsLevel;
  final bool meetsReputation;
}

class CreatorApplicationExisting {
  const CreatorApplicationExisting({
    this.status,
    this.appliedAt,
    this.approvedAt,
    this.notes,
  });

  final String? status;
  final String? appliedAt;
  final String? approvedAt;
  final String? notes;
}

class CreatorSubject {
  const CreatorSubject({
    required this.categoryId,
    required this.categoryName,
    required this.masteryScore,
    required this.accuracyScore,
    required this.evidenceCount,
    required this.confidence,
    this.label,
    this.retentionScore,
  });

  final int categoryId;
  final String categoryName;
  final double masteryScore;
  final double accuracyScore;
  final int evidenceCount;
  final double confidence;
  final String? label;
  final double? retentionScore;
}
