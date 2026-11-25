/// The onboarding catalogue is server-owned. A drifted 2xx body must fail
/// loudly rather than render an empty wizard with no choices.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/onboarding/data/models/onboarding_options_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _body() => <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'education_levels': <dynamic>[
          <String, dynamic>{'id': 1, 'name': 'SEE', 'description': null},
        ],
        'domains': <dynamic>[
          <String, dynamic>{
            'id': 7,
            'name': 'Engineering',
            'slug': 'engineering',
            'description': null,
          },
        ],
        'courses': <dynamic>[
          <String, dynamic>{
            'id': 9,
            'name': 'Civil',
            'slug': 'civil',
            'description': null,
            'domain_id': 7,
          },
        ],
        'goal_intensities': <dynamic>[
          <String, dynamic>{
            'value': 'casual',
            'label': 'Casual',
            'default_minutes': 15,
          },
        ],
      },
    };

void main() {
  test('a well-formed envelope parses every server array', () {
    final options = OnboardingOptionsDto.fromEnvelope(_body()).toDomain();

    expect(options.educationLevels.single.id, 1);
    expect(options.educationLevels.single.name, 'SEE');
    expect(options.domains.single.slug, 'engineering');
    expect(options.courses.single.domainId, 7);
    expect(options.goalIntensities.single.value, 'casual');
    expect(options.goalIntensities.single.defaultMinutes, 15);
  });

  test('a drifted array throws instead of returning an empty option list', () {
    final body = _body();
    final data = body['data'] as Map<String, dynamic>;
    data['domains'] = 'not-an-array';
    expect(
      () => OnboardingOptionsDto.fromEnvelope(body),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('a missing array throws ContractViolation', () {
    final body = _body();
    final data = body['data'] as Map<String, dynamic>;
    data.remove('education_levels');
    expect(
      () => OnboardingOptionsDto.fromEnvelope(body),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('an envelope with no data object throws ContractViolation', () {
    expect(
      () => OnboardingOptionsDto.fromEnvelope(<String, dynamic>{'success': true}),
      throwsA(isA<ContractViolation>()),
    );
  });
}
