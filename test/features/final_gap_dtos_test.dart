/// Strict parsing proofs for the last six §9.5 learner reads.
///
/// Every DTO must reject a drifted 2xx body instead of inventing an empty
/// detail/status. These tests exercise the boundary one layer at a time; the
/// cross-layer transport proof lives in the matching integration test.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/battle/data/models/battle_room_detail_dto.dart';
import 'package:bisaasmobile/features/learning/data/models/knowledge_atom_dto.dart';
import 'package:bisaasmobile/features/onboarding/data/models/profile_onboarding_status_dto.dart';
import 'package:bisaasmobile/features/profile/data/models/creator_application_dto.dart';
import 'package:bisaasmobile/features/social/data/models/sandbox_attempt_dto.dart';
import 'package:bisaasmobile/features/store/data/models/marketplace_product_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _atom() => <String, dynamic>{
      'id': 7,
      'title': 'Key term',
      'type': 'formula',
      'summary': 'A short summary.',
      'topic_id': 3,
    };

Map<String, dynamic> _onboarding() => <String, dynamic>{
      'status': <String, dynamic>{
        'is_onboarded': false,
        'should_show_wizard': true,
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
        'type': 'book',
        'price_coins': 40,
        'price_cents': 0,
        'currency': 'NPR',
        'is_free': false,
        'rating_avg': 4.5,
        'rating_count': 2,
        'sales_count': 9,
        'quality_score': 88,
        'category_name': 'Civil',
        'creator_name': 'Ada',
        'creator_username': 'ada',
        'description': 'A description.',
        'preview_url': null,
        'views_count': 12,
        'published_at': '2026-11-01T00:00:00+00:00',
      },
      'reviews': <dynamic>[
        <String, dynamic>{
          'id': 5,
          'rating': 5,
          'body': 'Useful',
          'is_verified_purchase': true,
          'author_name': 'Sam',
          'created_at': '2026-11-02T00:00:00+00:00',
        },
      ],
      'owned': false,
      'can_purchase': true,
      'purchase_blocked_reason': null,
      'coin_balance': 120,
    };

Map<String, dynamic> _creator() => <String, dynamic>{
      'eligibility': <String, dynamic>{
        'is_eligible': true,
        'level': 16,
        'level_required': 15,
        'reputation_score': 600,
        'reputation_required': 500,
        'meets_level': true,
        'meets_reputation': true,
      },
      'existing': null,
      'top_subjects': <dynamic>[
        <String, dynamic>{
          'category_id': 4,
          'category_name': 'Math',
          'mastery_score': 71.5,
          'label': 'strong',
          'retention_score': null,
          'accuracy_score': 80,
          'evidence_count': 12,
          'confidence': 0.7,
        },
      ],
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
        // Settlement and question keys must never reach the entity.
        'question_ids': <dynamic>[1, 2],
        'reward_settlement_status': 'settled',
        'host': <String, dynamic>{'id': 1, 'name': 'Host'},
        'participants': <dynamic>[
          <String, dynamic>{
            'id': 8,
            'user_id': 1,
            'user_name': 'Host',
            'score': 3,
            'rank': 1,
            'is_spectating': false,
            'joined_at': null,
            'evicted_at': null,
          },
        ],
        'started_at': null,
        'finished_at': null,
        'scheduled_for': null,
      },
    };

Map<String, dynamic> _sandbox() => <String, dynamic>{
      'summary': <String, dynamic>{
        'score': 66.5,
        'correct': 2,
        'wrong': 1,
        'skipped': 0,
        'total': 3,
      },
      'items': <dynamic>[
        <String, dynamic>{
          'question_id': 9,
          'type': 'single_choice',
          'question_text': 'Two plus two?',
          'options': <dynamic>['3', '4'],
          'given_answer': '4',
          'is_skipped': false,
          'is_correct': true,
          'explanation': 'Basic arithmetic.',
          // A leaked answer key is ignored, not stored or rendered.
          'correct_answer': '4',
        },
      ],
    };

void main() {
  test('knowledge atom keeps only the popover fields and rejects drift', () {
    final atom = KnowledgeAtomDto.fromJson(_atom()).toDomain();
    expect(atom.id, 7);
    expect(atom.title, 'Key term');
    expect(atom.type, 'formula');
    expect(atom.summary, 'A short summary.');
    expect(atom.topicId, 3);

    final drifted = _atom()..remove('id');
    expect(
      () => KnowledgeAtomDto.fromJson(drifted),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('onboarding status parses both flags and all three option lists', () {
    final status = ProfileOnboardingStatusDto.fromJson(_onboarding()).toDomain();
    expect(status.isOnboarded, isFalse);
    expect(status.shouldShowWizard, isTrue);
    expect(status.educationLevels.single.name, 'SEE');
    expect(status.domains.single.id, 2);
    expect(status.courses.single.domainId, 2);

    final drifted = _onboarding()..remove('domains');
    expect(
      () => ProfileOnboardingStatusDto.fromJson(drifted),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('marketplace detail parses product, reviews and eligibility', () {
    final detail = MarketplaceProductDto.fromJson(_product()).toDomain();
    expect(detail.product.title, 'Notes');
    expect(detail.product.priceCoins, 40);
    expect(detail.reviews.single.rating, 5);
    expect(detail.owned, isFalse);
    expect(detail.canPurchase, isTrue);
    expect(detail.coinBalance, 120);

    final drifted = _product();
    drifted['reviews'] = 'not a list';
    expect(
      () => MarketplaceProductDto.fromJson(drifted),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('creator status keeps null existing and validates every flag', () {
    final status = CreatorApplicationDto.fromJson(_creator()).toDomain();
    expect(status.eligibility.isEligible, isTrue);
    expect(status.existing, isNull);
    expect(status.topSubjects.single.masteryScore, 71.5);

    final drifted = _creator();
    (drifted['eligibility'] as Map<String, dynamic>)['is_eligible'] = 'yes';
    expect(
      () => CreatorApplicationDto.fromJson(drifted),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('battle lobby parses safe fields and ignores settlement keys', () {
    final detail = BattleRoomDetailDto.fromJson(_lobby()).toDomain();
    expect(detail.lobby.code, 'ABC123');
    expect(detail.lobby.wagerCoins, 25);
    expect(detail.lobby.host.name, 'Host');
    expect(detail.lobby.participants.single.score, 3);
    // The entity has no representation for either sensitive key.
    expect(detail.lobby.toString(), isNot(contains('settlement')));

    final drifted = _lobby();
    (drifted['lobby'] as Map<String, dynamic>).remove('participants');
    expect(
      () => BattleRoomDetailDto.fromJson(drifted),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('sandbox results parse verdicts only and reject a missing summary', () {
    final results = SandboxAttemptDto.fromJson(_sandbox()).toDomain();
    expect(results.summary.score, 66.5);
    expect(results.summary.total, 3);
    final item = results.items.single;
    expect(item.isCorrect, isTrue);
    expect(item.questionText, 'Two plus two?');
    expect(item.options.length, 2);

    final drifted = _sandbox()..remove('summary');
    expect(
      () => SandboxAttemptDto.fromJson(drifted),
      throwsA(isA<ContractViolation>()),
    );
  });
}
