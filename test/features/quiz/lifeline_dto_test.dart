import 'package:bisaasmobile/features/quiz/data/models/lifeline_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the attempt-lifeline wire format, read from
/// `QuizLifelineApiController` + `LifelineEffectService` (bisaas, 2026-09-27).
///
/// The server is deliberately inconsistent here, and the client has to match
/// it exactly:
///   * `GET  /lifelines`                 → camelCase
///   * `POST /lifelines/{slug}/use`      → snake_case at the top level
///   * `effect` **inside** those POSTs    → snake_case, server-built
void main() {
  group('LifelineCatalogueDto', () {
    test('parses the real camelCase index payload', () {
      final dto = LifelineCatalogueDto.fromJson(const {
        'enabled': true,
        'walletBalance': 130,
        'lifelines': [
          {
            'slug': 'fifty_fifty',
            'name': '50/50',
            'iconUrl': null,
            'costCoins': 50,
            'baseCostCoins': 50,
            'discountPct': 0,
            'effectType': 'fifty_fifty',
            'maxUsesPerAttempt': 1,
            'purchasedUses': 0,
            'usedUses': 0,
            'remainingUses': 1,
            'inventoryUses': 0,
            'canPurchase': true,
            'canUse': true,
            'lockedByMode': false,
            'lockReason': null,
            'adUnlockEnabled': false,
            'lastPayload': null,
          },
        ],
      });

      expect(dto.enabled, isTrue);
      expect(dto.walletBalance, 130);
      expect(dto.lifelines, hasLength(1));

      final lifeline = dto.lifelines.first;
      expect(lifeline.slug, 'fifty_fifty');
      expect(lifeline.name, '50/50');
      expect(lifeline.costCoins, 50);
      expect(lifeline.effectType, 'fifty_fifty');
      expect(lifeline.remainingUses, 1);
      expect(lifeline.canUse, isTrue);
      expect(lifeline.isAvailable, isTrue);
    });

    test('the kill switch yields enabled:false and no lifelines', () {
      // The server answers exactly this when the feature is off; the UI must
      // hide the bar rather than render a dead row of chips.
      final dto = LifelineCatalogueDto.fromJson(const {
        'enabled': false,
        'walletBalance': 0,
        'lifelines': <dynamic>[],
      });
      expect(dto.enabled, isFalse);
      expect(dto.lifelines, isEmpty);
    });

    test('a mode-locked lifeline is never available', () {
      final dto = LifelineCatalogueDto.fromJson(const {
        'enabled': true,
        'walletBalance': 0,
        'lifelines': [
          {
            'slug': 'double_xp',
            'name': 'Double XP',
            'costCoins': 100,
            'effectType': 'double_xp',
            'canUse': true,
            'lockedByMode': true,
            'lockReason': 'Not available in exam mode',
          },
        ],
      });
      final lifeline = dto.lifelines.first;
      // canUse alone is not enough — lockedByMode wins.
      expect(lifeline.canUse, isTrue);
      expect(lifeline.isAvailable, isFalse);
      expect(lifeline.lockReason, 'Not available in exam mode');
    });

    test('bySlug finds a lifeline and returns null for an unknown one', () {
      final dto = LifelineCatalogueDto.fromJson(const {
        'enabled': true,
        'walletBalance': 0,
        'lifelines': [
          {'slug': 'hint', 'name': 'Hint', 'costCoins': 30, 'canUse': true},
        ],
      });
      expect(dto.bySlug('hint')?.name, 'Hint');
      expect(dto.bySlug('fifty_fifty'), isNull);
    });

    test('accepts the snake_case spelling too', () {
      // purchase/use return snake_case; a tolerant parser costs nothing and
      // keeps one DTO usable for both shapes.
      final dto = LifelineCatalogueDto.fromJson(const {
        'enabled': true,
        'wallet_balance': 77,
        'lifelines': [
          {
            'slug': 'skip',
            'name': 'Skip',
            'cost_coins': 75,
            'effect_type': 'skip',
            'max_uses_per_attempt': 1,
            'remaining_uses': 1,
            'can_purchase': true,
            'can_use': true,
          },
        ],
      });
      expect(dto.walletBalance, 77);
      expect(dto.lifelines.first.costCoins, 75);
      expect(dto.lifelines.first.remainingUses, 1);
      expect(dto.lifelines.first.isAvailable, isTrue);
    });
  });

  group('LifelineEffectDto', () {
    test('fifty_fifty returns hidden_option_keys', () {
      final effect = LifelineEffectDto.fromJson(const {
        'question_id': 4211,
        'effect_type': 'fifty_fifty',
        'hidden_option_keys': ['b', 'd'],
      });
      expect(effect.effectType, 'fifty_fifty');
      expect(effect.questionId, 4211);
      expect(effect.hiddenOptionKeys, ['b', 'd']);
      expect(effect.hasVisibleOutcome, isTrue);
    });

    test('hint returns the trimmed explanation', () {
      final effect = LifelineEffectDto.fromJson(const {
        'effect_type': 'hint',
        'hint': 'Recall that the allowable stress is 0.45 fck.',
      });
      expect(effect.hint, contains('allowable stress'));
      expect(effect.hasVisibleOutcome, isTrue);
    });

    test('explanation returns the full text', () {
      final effect = LifelineEffectDto.fromJson(const {
        'effect_type': 'explanation',
        'explanation': 'Because Pu = 1.5fck for short columns.',
      });
      expect(effect.explanation, contains('1.5fck'));
      expect(effect.hasVisibleOutcome, isTrue);
    });

    test('reveal_correct returns the answer', () {
      final effect = LifelineEffectDto.fromJson(const {
        'effect_type': 'reveal_correct',
        'correct_answer': 'c',
      });
      expect(effect.correctAnswer, 'c');
      expect(effect.hasVisibleOutcome, isTrue);
    });

    test('time_freeze returns seconds and an absolute until', () {
      final effect = LifelineEffectDto.fromJson(const {
        'effect_type': 'time_freeze',
        'freeze_seconds': 30,
        'frozen_until': '2026-09-27T18:00:30+05:45',
      });
      expect(effect.freezeSeconds, 30);
      expect(effect.frozenUntil, isNotNull);
      expect(effect.hasVisibleOutcome, isTrue);
    });

    test('extra_time, shield, double_xp and second_chance all read back', () {
      expect(
        LifelineEffectDto.fromJson(const {'effect_type': 'extra_time', 'extra_seconds': 20}).extraSeconds,
        20,
      );
      expect(
        LifelineEffectDto.fromJson(const {'effect_type': 'shield', 'shield_active': true}).shieldActive,
        isTrue,
      );
      expect(
        LifelineEffectDto.fromJson(const {'effect_type': 'double_xp', 'double_xp_active': true}).doubleXpActive,
        isTrue,
      );
      expect(
        LifelineEffectDto.fromJson(const {'effect_type': 'second_chance', 'retry_question_id': 99}).retryQuestionId,
        99,
      );
    });

    test('eliminate_one also uses hidden_option_keys', () {
      // The server reuses the 50/50 shape for eliminate-one and question swap.
      final effect = LifelineEffectDto.fromJson(const {
        'effect_type': 'question_swap',
        'hidden_option_keys': ['a'],
      });
      expect(effect.effectType, 'question_swap');
      expect(effect.hiddenOptionKeys, ['a']);
    });

    test('an unrecognised effect reports no visible outcome', () {
      // The client must be able to tell "nothing to show" from "show this".
      final effect = LifelineEffectDto.fromJson(const {'effect_type': 'brand_new_effect'});
      expect(effect.hasVisibleOutcome, isFalse);
    });
  });

  group('availability gate', () {
    // Captured verbatim from GET /api/v1/quiz/attempts/6115/lifelines
    // (bisaas, probed 2026-09-27). A player with 130 coins and no banked
    // tokens: canUse is false because nothing is in inventory, but canPurchase
    // is true. Gating the chip on canUse alone disabled every lifeline in the
    // app for every player who had not pre-bought tokens.
    final freshAttempt = LifelineDto.fromJson(const {
      'slug': 'fifty_fifty',
      'name': '50/50',
      'iconUrl': '/icons/svg/powerup-5050.svg',
      'costCoins': 38,
      'baseCostCoins': 50,
      'discountPct': 25,
      'effectType': 'fifty_fifty',
      'maxUsesPerAttempt': 1,
      'purchasedUses': 0,
      'usedUses': 0,
      'remainingUses': 0,
      'inventoryUses': 0,
      'canPurchase': true,
      'canUse': false,
      'lockedByMode': false,
      'lockReason': null,
      'adUnlockEnabled': false,
      'lastPayload': null,
    });

    test('an affordable, purchasable lifeline is available even if canUse is false', () {
      expect(freshAttempt.canUse, isFalse);
      expect(freshAttempt.canPurchase, isTrue);
      expect(freshAttempt.isAvailable, isTrue);
    });

    test('the real server applies a discount (38 not 50) and is read as sent', () {
      expect(freshAttempt.costCoins, 38);
      expect(freshAttempt.iconUrl, '/icons/svg/powerup-5050.svg');
      expect(freshAttempt.discountPct, 25);
    });

    test('hasBankedUse is false when only purchasable', () {
      expect(freshAttempt.hasBankedUse, isFalse);
    });

    test('hasBankedUse is true when a token is banked', () {
      final banked = LifelineDto.fromJson(const {
        'slug': 'hint',
        'name': 'Hint',
        'costCoins': 30,
        'canUse': true,
        'canPurchase': true,
        'inventoryUses': 1,
      });
      expect(banked.hasBankedUse, isTrue);
    });

    test('a mode lock overrides an affordable price', () {
      final locked = LifelineDto.fromJson(const {
        'slug': 'double_xp',
        'name': 'Double XP',
        'costCoins': 100,
        'canUse': true,
        'canPurchase': true,
        'lockedByMode': true,
        'lockReason': 'Not available in exam mode',
      });
      expect(locked.isAvailable, isFalse);
    });

    test('neither purchasable nor banked is not available', () {
      final neither = LifelineDto.fromJson(const {
        'slug': 'shield',
        'name': 'Shield',
        'costCoins': 125,
        'canUse': false,
        'canPurchase': false,
        'lockedByMode': false,
      });
      expect(neither.isAvailable, isFalse);
    });
  });

  group('hidden option keys', () {
    test('the server returns UPPERCASE keys and the client options are uppercase', () {
      // Live response from POST .../lifelines/fifty_fifty/purchase-and-use:
      //   "hidden_option_keys": ["C", "D"]
      // and GET /quiz/courses/32/questions returns options as
      //   [{key:"A"},{key:"B"},{key:"C"},{key:"D"}]
      // which quiz_remote_data_source maps to option ids "A".."D". A naive
      // Set.contains would work today but silently break if either side
      // changed case, so QuizState.isOptionHidden compares case-insensitively.
      final effect = LifelineEffectDto.fromJson(const {
        'question_id': 31105,
        'effect_type': 'fifty_fifty',
        'hidden_option_keys': ['C', 'D'],
      });
      expect(effect.hiddenOptionKeys, ['C', 'D']);
      expect(effect.hiddenOptionKeys.map((k) => k.toUpperCase()), contains('C'));
    });
  });

  group('LifelineUseResultDto', () {
    test('parses the snake_case use response with a nested effect', () {
      final result = LifelineUseResultDto.fromJson(const {
        'slug': 'fifty_fifty',
        'remaining_uses': 0,
        'effect': {
          'question_id': 7,
          'effect_type': 'fifty_fifty',
          'hidden_option_keys': ['a', 'c'],
        },
      });
      expect(result.slug, 'fifty_fifty');
      expect(result.remainingUses, 0);
      expect(result.effect.hiddenOptionKeys, ['a', 'c']);
    });

    test('an empty body does not throw', () {
      final result = LifelineUseResultDto.fromJson(const {});
      expect(result.slug, '');
      expect(result.remainingUses, 0);
      expect(result.effect.hasVisibleOutcome, isFalse);
    });
  });
}
