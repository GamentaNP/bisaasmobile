/// Cross-layer proof for the last six §9.5 reads.
///
/// Real Dio → scripted adapter → envelope → DTO → domain → provider is exercised
/// here. It pins the exact paths, the absence of stray query keys, the sandbox
/// session binding and credential guard, and the failure contract (a non-2xx
/// or a drifted 2xx stays an error instead of rendering "no data").
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/battle/presentation/controllers/battle_room_detail_controller.dart';
import 'package:bisaasmobile/features/learning/data/datasources/knowledge_atom_remote_data_source.dart';
import 'package:bisaasmobile/features/learning/presentation/controllers/knowledge_atom_controller.dart';
import 'package:bisaasmobile/features/onboarding/presentation/controllers/profile_onboarding_status_controller.dart';
import 'package:bisaasmobile/features/profile/presentation/controllers/creator_application_controller.dart';
import 'package:bisaasmobile/features/social/data/datasources/sandbox_attempt_remote_data_source.dart';
import 'package:bisaasmobile/features/social/presentation/controllers/sandbox_attempt_controller.dart';
import 'package:bisaasmobile/features/store/presentation/controllers/marketplace_product_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _atom() => <String, dynamic>{
      'id': 7,
      'title': 'Key term',
      'type': 'formula',
      'summary': 'A short summary.',
      'topic_id': 3,
    };

Map<String, dynamic> _onboarding() => <String, dynamic>{
      'status': <String, dynamic>{
        'is_onboarded': true,
        'should_show_wizard': false,
      },
      'education_levels': <dynamic>[
        <String, dynamic>{'id': 1, 'name': 'SEE', 'description': null},
      ],
      'domains': <dynamic>[
        <String, dynamic>{'id': 2, 'name': 'Engineering', 'description': null},
      ],
      'courses': <dynamic>[
        <String, dynamic>{'id': 3, 'name': 'Civil', 'quiz_domain_id': 2},
      ],
    };

Map<String, dynamic> _product() => <String, dynamic>{
      'product': <String, dynamic>{
        'id': 11,
        'title': 'Notes',
        'price_coins': 40,
        'is_free': false,
        'rating_avg': 4.5,
        'rating_count': 2,
        'sales_count': 9,
        'quality_score': 88,
        'creator_name': 'Ada',
        'description': 'A description.',
        'views_count': 3,
      },
      'reviews': <dynamic>[],
      'owned': true,
      'can_purchase': false,
      'purchase_blocked_reason': 'You already own this product.',
      'coin_balance': 80,
    };

Map<String, dynamic> _creator() => <String, dynamic>{
      'eligibility': <String, dynamic>{
        'is_eligible': false,
        'level': 9,
        'level_required': 15,
        'reputation_score': 100,
        'reputation_required': 500,
        'meets_level': false,
        'meets_reputation': false,
      },
      'existing': <String, dynamic>{
        'status': 'pending',
        'applied_at': null,
        'approved_at': null,
        'notes': null,
      },
      'top_subjects': <dynamic>[],
    };

Map<String, dynamic> _lobby() => <String, dynamic>{
      'lobby': <String, dynamic>{
        'id': 21,
        'code': 'ABC123',
        'mode': 'ranked',
        'queue_type': 'quick',
        'status': 'active',
        'wager_coins': 25,
        'max_players': 4,
        'host': <String, dynamic>{'id': 1, 'name': 'Host'},
        'participants': <dynamic>[],
      },
    };

Map<String, dynamic> _sandbox() => <String, dynamic>{
      'summary': <String, dynamic>{
        'score': 50,
        'correct': 1,
        'wrong': 1,
        'skipped': 0,
        'total': 2,
      },
      'items': <dynamic>[
        <String, dynamic>{
          'question_id': 9,
          'question_text': 'Two plus two?',
          'options': <dynamic>[],
          'given_answer': '4',
          'is_skipped': false,
          'is_correct': true,
          'explanation': null,
        },
      ],
    };

void main() {
  late FakeApi api;
  ProviderContainer? container;

  ProviderContainer boot() => ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(dioFor(api)),
          // No real secure storage in a unit test: the credential proof is
          // injected. The anonymous-call test below stubs it to false.
          sandboxCredentialProvider.overrideWithValue(() async => true),
        ],
      );

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    container = null;
  });

  tearDown(() => container?.dispose());

  test('knowledge atom detail consumes the exact single-object read', () async {
    api.on('GET', '/quiz/knowledge-atoms/7', FakeRoute.ok(_atom()));
    container = boot();

    final atom = await container!.read(knowledgeAtomProvider('7').future);

    expect(atom.id, 7);
    expect(api.requests.single.path, '/quiz/knowledge-atoms/7');
    expect(api.queryOf(0), isEmpty);
    expect(api.misses, isEmpty);
  });

  test('onboarding status consumes the bounded snapshot with no query keys',
      () async {
    api.on(
      'GET',
      '/quiz/profile-onboarding/status',
      FakeRoute.ok(_onboarding()),
    );
    container = boot();

    final status = await container!.read(profileOnboardingStatusProvider.future);

    expect(status.shouldShowWizard, isFalse);
    expect(status.domains.single.name, 'Engineering');
    expect(api.requests.single.path, '/quiz/profile-onboarding/status');
    expect(api.queryOf(0), isEmpty);
  });

  test('marketplace detail consumes product, reviews and eligibility', () async {
    api.on('GET', '/quiz/marketplace/products/11', FakeRoute.ok(_product()));
    container = boot();

    final detail = await container!.read(marketplaceProductProvider('11').future);

    expect(detail.product.title, 'Notes');
    expect(detail.owned, isTrue);
    expect(detail.canPurchase, isFalse);
    expect(detail.purchaseBlockedReason, 'You already own this product.');
    expect(api.requests.single.path, '/quiz/marketplace/products/11');
    expect(api.queryOf(0), isEmpty);
  });

  test('creator status is a read-only snapshot', () async {
    api.on(
      'GET',
      '/quiz/creator/applications/current',
      FakeRoute.ok(_creator()),
    );
    container = boot();

    final status = await container!.read(creatorApplicationStatusProvider.future);

    expect(status.eligibility.isEligible, isFalse);
    expect(status.existing?.status, 'pending');
    expect(api.requests.single.path, '/quiz/creator/applications/current');
    expect(api.queryOf(0), isEmpty);
    expect(api.requests.where((r) => r.method != 'GET'), isEmpty);
  });

  test('battle lobby detail is a scoped read without settlement leakage',
      () async {
    api.on('GET', '/quiz/battle-rooms/21', FakeRoute.ok(_lobby()));
    container = boot();

    final detail = await container!.read(battleRoomDetailProvider('21').future);

    expect(detail.lobby.code, 'ABC123');
    expect(api.requests.single.path, '/quiz/battle-rooms/21');
    expect(api.queryOf(0), isEmpty);
  });

  test('sandbox results send only the session binding to the authenticated path',
      () async {
    api.on('GET', '/social/sandbox/attempts/9', FakeRoute.ok(_sandbox()));
    container = boot();
    const key = (attemptId: '9', guestSessionId: 'guest-session-123');

    final results = await container!.read(sandboxAttemptProvider(key).future);

    expect(results.summary.total, 2);
    expect(results.items.single.isCorrect, isTrue);
    expect(api.requests.single.path, '/social/sandbox/attempts/9');
    expect(api.queryOf(0)['guest_session_id'], 'guest-session-123');
    expect(api.queryOf(0).keys, <String>['guest_session_id']);
    expect(api.misses, isEmpty);
  });

  test('sandbox results refuse an anonymous call before any request', () async {
    final ds = SandboxAttemptRemoteDataSource(
      dioFor(api),
      hasCredential: () async => false,
    );

    expect(
      () => ds.getAttempt(attemptId: '9', guestSessionId: 'guest-session-123'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiErrorCode.authUnauthenticated)),
    );
    expect(api.requests, isEmpty);
  });

  test('sandbox results refuse a missing guest session binding', () async {
    final ds = SandboxAttemptRemoteDataSource(
      dioFor(api),
      hasCredential: () async => true,
    );

    expect(
      () => ds.getAttempt(attemptId: '9', guestSessionId: '  '),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiErrorCode.validationError)),
    );
    expect(api.requests, isEmpty);
  });

  test('a non-2xx stays an error instead of an empty detail', () async {
    api.on(
      'GET',
      '/quiz/knowledge-atoms/7',
      FakeRoute.error(403, 'FORBIDDEN', 'Not visible to you.'),
    );
    container = boot();

    await expectLater(
      KnowledgeAtomRemoteDataSource(dioFor(api)).getAtom('7'),
      throwsA(isA<DioException>()),
    );
  });

  test('a 2xx drift throws ContractViolation instead of an empty detail',
      () async {
    api.on(
      'GET',
      '/quiz/knowledge-atoms/7',
      FakeRoute.raw(<String, dynamic>{'success': true}),
    );

    await expectLater(
      KnowledgeAtomRemoteDataSource(dioFor(api)).getAtom('7'),
      throwsA(isA<ContractViolation>()),
    );
  });
}
