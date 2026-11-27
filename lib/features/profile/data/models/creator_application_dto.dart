import '../../../../core/network/api_failure.dart';
import '../../domain/entities/creator_application.dart';

/// Strict wire parser for the creator-application status snapshot (§9.5).
///
/// Every eligibility field is type-checked: a missing flag must never become
/// "eligible" by default and send a reader into a submit flow that cannot work.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> rows(
    Object? value,
    String key,
    String endpoint,
  ) {
    if (value is! List) {
      throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
    }
    return value.map((row) => map(row, '$key row', endpoint)).toList();
  }

  static int intOf(Object? value, String key, String endpoint) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation('Expected $key to be an int', endpoint: endpoint);
  }

  static double doubleOf(Object? value, String key, String endpoint) {
    if (value is num) return value.toDouble();
    throw ContractViolation('Expected $key to be a number', endpoint: endpoint);
  }

  static double? optionalDouble(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw ContractViolation(
      'Expected $key to be a number or null',
      endpoint: endpoint,
    );
  }

  static String string(Object? value, String key, String endpoint) {
    if (value is String && value.isNotEmpty) return value;
    throw ContractViolation('Expected $key to be a string', endpoint: endpoint);
  }

  static String? optionalString(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is String) return value;
    throw ContractViolation(
      'Expected $key to be a string or null',
      endpoint: endpoint,
    );
  }

  static bool boolOf(Object? value, String key, String endpoint) {
    if (value is bool) return value;
    throw ContractViolation('Expected $key to be a bool', endpoint: endpoint);
  }
}

class CreatorApplicationDto {
  const CreatorApplicationDto({required this.data});
  final Map<String, dynamic> data;

  factory CreatorApplicationDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/creator/applications/current',
  }) {
    final eligibility = _Parse.map(data['eligibility'], 'eligibility', endpoint);
    for (final key in <String>[
      'is_eligible',
      'meets_level',
      'meets_reputation',
    ]) {
      _Parse.boolOf(eligibility[key], key, endpoint);
    }
    for (final key in <String>[
      'level',
      'level_required',
      'reputation_score',
      'reputation_required',
    ]) {
      _Parse.intOf(eligibility[key], key, endpoint);
    }
    _Parse.rows(data['top_subjects'], 'top_subjects', endpoint);
    if (data['existing'] != null) {
      _Parse.map(data['existing'], 'existing', endpoint);
    }
    return CreatorApplicationDto(data: data);
  }

  CreatorApplicationStatus toDomain({
    String endpoint = '/quiz/creator/applications/current',
  }) {
    final eligibility = _Parse.map(data['eligibility'], 'eligibility', endpoint);
    final existing = data['existing'] == null
        ? null
        : _Parse.map(data['existing'], 'existing', endpoint);

    return CreatorApplicationStatus(
      eligibility: CreatorEligibility(
        isEligible: _Parse.boolOf(eligibility['is_eligible'], 'is_eligible', endpoint),
        level: _Parse.intOf(eligibility['level'], 'level', endpoint),
        levelRequired: _Parse.intOf(eligibility['level_required'], 'level_required', endpoint),
        reputationScore: _Parse.intOf(
          eligibility['reputation_score'],
          'reputation_score',
          endpoint,
        ),
        reputationRequired: _Parse.intOf(
          eligibility['reputation_required'],
          'reputation_required',
          endpoint,
        ),
        meetsLevel: _Parse.boolOf(eligibility['meets_level'], 'meets_level', endpoint),
        meetsReputation: _Parse.boolOf(
          eligibility['meets_reputation'],
          'meets_reputation',
          endpoint,
        ),
      ),
      existing: existing == null
          ? null
          : CreatorApplicationExisting(
              status: _Parse.optionalString(existing['status'], 'status', endpoint),
              appliedAt: _Parse.optionalString(
                existing['applied_at'],
                'applied_at',
                endpoint,
              ),
              approvedAt: _Parse.optionalString(
                existing['approved_at'],
                'approved_at',
                endpoint,
              ),
              notes: _Parse.optionalString(existing['notes'], 'notes', endpoint),
            ),
      topSubjects: _Parse.rows(data['top_subjects'], 'top_subjects', endpoint)
          .map((row) => CreatorSubject(
                categoryId: _Parse.intOf(row['category_id'], 'category_id', endpoint),
                categoryName: _Parse.string(row['category_name'], 'category_name', endpoint),
                masteryScore: _Parse.doubleOf(row['mastery_score'], 'mastery_score', endpoint),
                accuracyScore: _Parse.doubleOf(row['accuracy_score'], 'accuracy_score', endpoint),
                evidenceCount: _Parse.intOf(row['evidence_count'], 'evidence_count', endpoint),
                confidence: _Parse.doubleOf(row['confidence'], 'confidence', endpoint),
                label: _Parse.optionalString(row['label'], 'label', endpoint),
                retentionScore: _Parse.optionalDouble(
                  row['retention_score'],
                  'retention_score',
                  endpoint,
                ),
              ))
          .toList(),
    );
  }
}
