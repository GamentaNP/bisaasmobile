library;

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/onboarding_options.dart';

const _endpoint = '/quiz/onboarding/options';

/// Strict wire parser for `GET /quiz/onboarding/options`.
///
/// The endpoint publishes one object with four arrays. Every field the wizard
/// relies on is required and type-checked: a missing array, a string where an
/// id should be, or a body that is not the canonical envelope is a contract
/// drift and throws [ContractViolation]. It can never surface as an empty
/// option list — an empty list would silently drop the user's only choices.
class OnboardingOptionsDto {
  const OnboardingOptionsDto({
    required this.educationLevels,
    required this.domains,
    required this.courses,
    required this.goalIntensities,
  });

  final List<EducationLevelOption> educationLevels;
  final List<DomainOption> domains;
  final List<CourseOption> courses;
  final List<GoalIntensityOption> goalIntensities;

  static const endpoint = _endpoint;

  /// Reads the canonical envelope, then the four arrays under `data`.
  factory OnboardingOptionsDto.fromEnvelope(
    Map<String, dynamic>? body, {
    String endpoint = _endpoint,
  }) {
    final data = requireDataMap(body, endpoint: endpoint);
    return OnboardingOptionsDto.fromData(data, endpoint: endpoint);
  }

  factory OnboardingOptionsDto.fromData(
    Map<String, dynamic> data, {
    String endpoint = _endpoint,
  }) {
    final levels = _rows(data, 'education_levels', endpoint, required: true)
        .map((j) => EducationLevelOption(
              id: _int(j, 'id', endpoint),
              name: _string(j, 'name', endpoint),
              description: _optionalString(j, 'description', endpoint),
            ))
        .toList();

    final domains = _rows(data, 'domains', endpoint, required: true)
        .map((j) => DomainOption(
              id: _int(j, 'id', endpoint),
              name: _string(j, 'name', endpoint),
              slug: _string(j, 'slug', endpoint),
              description: _optionalString(j, 'description', endpoint),
            ))
        .toList();

    final courses = _rows(data, 'courses', endpoint)
        .map((j) => CourseOption(
              id: _int(j, 'id', endpoint),
              name: _string(j, 'name', endpoint),
              slug: _string(j, 'slug', endpoint),
              description: _optionalString(j, 'description', endpoint),
              domainId: _optionalInt(j, 'domain_id', endpoint),
            ))
        .toList();

    final intensities = _rows(data, 'goal_intensities', endpoint, required: true)
        .map((j) => GoalIntensityOption(
              value: _string(j, 'value', endpoint),
              label: _string(j, 'label', endpoint),
              defaultMinutes: _int(j, 'default_minutes', endpoint),
            ))
        .toList();

    return OnboardingOptionsDto(
      educationLevels: levels,
      domains: domains,
      courses: courses,
      goalIntensities: intensities,
    );
  }

  static List<Map<String, dynamic>> _rows(
    Map<String, dynamic> data,
    String field,
    String endpoint, {
    bool required = false,
  }) {
    final raw = data[field];
    if (raw is! List) {
      throw ContractViolation(
        '`$field` must be an array, got ${raw.runtimeType}',
        endpoint: endpoint,
      );
    }
    if (required && raw.isEmpty) {
      throw ContractViolation('`$field` must not be empty', endpoint: endpoint);
    }
    return raw.map((row) {
      if (row is! Map<String, dynamic>) {
        throw ContractViolation(
          '`$field` row must be an object, got ${row.runtimeType}',
          endpoint: endpoint,
        );
      }
      return row;
    }).toList();
  }

  static int _int(Map<String, dynamic> j, String field, String endpoint) {
    final value = j[field];
    if (value is int) return value;
    throw ContractViolation(
      '`$field` must be an int, got ${value.runtimeType}',
      endpoint: endpoint,
    );
  }

  static String _string(Map<String, dynamic> j, String field, String endpoint) {
    final value = j[field];
    if (value is String && value.isNotEmpty) return value;
    throw ContractViolation(
      '`$field` must be a non-empty string, got ${value.runtimeType}',
      endpoint: endpoint,
    );
  }

  static String? _optionalString(
    Map<String, dynamic> j,
    String field,
    String endpoint,
  ) {
    final value = j[field];
    if (value == null) return null;
    if (value is String) return value;
    throw ContractViolation(
      '`$field` must be a string or null, got ${value.runtimeType}',
      endpoint: endpoint,
    );
  }

  static int? _optionalInt(
    Map<String, dynamic> j,
    String field,
    String endpoint,
  ) {
    final value = j[field];
    if (value == null) return null;
    if (value is int) return value;
    throw ContractViolation(
      '`$field` must be an int or null, got ${value.runtimeType}',
      endpoint: endpoint,
    );
  }

  OnboardingOptions toDomain() => OnboardingOptions(
        educationLevels: educationLevels,
        domains: domains,
        courses: courses,
        goalIntensities: goalIntensities,
      );
}
