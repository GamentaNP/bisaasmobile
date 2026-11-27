import '../../../../core/network/api_failure.dart';
import '../../domain/entities/profile_onboarding_status.dart';

/// Strict wire parser for the bounded onboarding-status snapshot (§9.5).
///
/// All four arrays are required: a missing one would silently drop the only
/// choices the wizard can persist. A drifted row throws instead of becoming
/// an empty picker.
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

  static int? optionalInt(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation(
      'Expected $key to be an int or null',
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

class ProfileOnboardingStatusDto {
  const ProfileOnboardingStatusDto({required this.data});
  final Map<String, dynamic> data;

  factory ProfileOnboardingStatusDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/profile-onboarding/status',
  }) {
    final status = _Parse.map(data['status'], 'status', endpoint);
    _Parse.boolOf(status['is_onboarded'], 'is_onboarded', endpoint);
    _Parse.boolOf(status['should_show_wizard'], 'should_show_wizard', endpoint);
    _Parse.rows(data['education_levels'], 'education_levels', endpoint);
    _Parse.rows(data['domains'], 'domains', endpoint);
    _Parse.rows(data['courses'], 'courses', endpoint);
    return ProfileOnboardingStatusDto(data: data);
  }

  ProfileOnboardingStatus toDomain({
    String endpoint = '/quiz/profile-onboarding/status',
  }) {
    final status = _Parse.map(data['status'], 'status', endpoint);
    OnboardingOptionRow option(Map<String, dynamic> row) => OnboardingOptionRow(
          id: _Parse.intOf(row['id'], 'id', endpoint),
          name: _Parse.string(row['name'], 'name', endpoint),
          description: _Parse.optionalString(
            row['description'],
            'description',
            endpoint,
          ),
        );

    return ProfileOnboardingStatus(
      isOnboarded: _Parse.boolOf(status['is_onboarded'], 'is_onboarded', endpoint),
      shouldShowWizard: _Parse.boolOf(
        status['should_show_wizard'],
        'should_show_wizard',
        endpoint,
      ),
      educationLevels: _Parse.rows(data['education_levels'], 'education_levels', endpoint)
          .map(option)
          .toList(),
      domains: _Parse.rows(data['domains'], 'domains', endpoint)
          .map(option)
          .toList(),
      courses: _Parse.rows(data['courses'], 'courses', endpoint)
          .map((row) => OnboardingCourseRow(
                id: _Parse.intOf(row['id'], 'id', endpoint),
                name: _Parse.string(row['name'], 'name', endpoint),
                domainId: _Parse.optionalInt(
                  row['quiz_domain_id'],
                  'quiz_domain_id',
                  endpoint,
                ),
              ))
          .toList(),
    );
  }
}
