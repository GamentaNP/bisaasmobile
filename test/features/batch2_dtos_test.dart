/// Unit-level wire checks for the six Batch 2 DTO families.
///
/// A 2xx body that does not match §9.5 is contract drift and must throw; an
/// empty server list is the only shape allowed to become an empty collection.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/gamification/data/models/reward_center_dto.dart';
import 'package:bisaasmobile/features/library/data/models/resource_hub_dto.dart';
import 'package:bisaasmobile/features/past_papers/data/models/past_paper_dto.dart';
import 'package:bisaasmobile/features/profile/data/models/public_profile_dto.dart';
import 'package:bisaasmobile/features/social/data/models/impact_leaders_dto.dart';
import 'package:bisaasmobile/features/word_bank/data/models/word_bank_dto.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _paper({int id = 1, bool hasKey = false}) => <String, dynamic>{
      'id': id,
      'label': '2078 Loksewa Paper 1',
      'country': 'NP',
      'province': 'Bagmati',
      'post': 'Civil Engineer',
      'board': 'Loksewa',
      'year_bs': 2078,
      'year_ad': 2022,
      'paper_number': 1,
      'total_questions': 100,
      'total_marks': 100,
      'duration_minutes': 120,
      'verified': true,
      'has_key': hasKey,
      'redistribution_allowed': true,
      'source_url': null,
      'exam_name': 'Civil',
      'authority': 'PSC',
      'detail_url': '/api/v1/quiz/past-papers/$id',
    };

void main() {
  group('past papers', () {
    test('catalog parses items, filters, facets and courses', () {
      final catalog = PastPaperCatalogDto.fromJson(<String, dynamic>{
        'items': <dynamic>[_paper()],
        'filters': <String, dynamic>{'country': 'NP'},
        'facets': <String, dynamic>{'years': <dynamic>[2078]},
        'courses': <dynamic>[
          <String, dynamic>{'id': 3, 'name': 'Civil'},
        ],
      }).toDomain();

      expect(catalog.items.single.id, 1);
      expect(catalog.items.single.hasKey, isFalse);
      expect(catalog.filters['country'], 'NP');
      expect(catalog.courses.single.name, 'Civil');
    });

    test('detail with redistributed scans drops answer-key pages', () {
      final detail = PastPaperDetailDto.fromJson(<String, dynamic>{
        'paper': <String, dynamic>{
          'id': 1,
          'label': '2078 Paper 1',
          'can_show_scans': true,
          'total_questions': 2,
          'verified': true,
        },
        'pages': <dynamic>[
          <String, dynamic>{
            'page_number': 1,
            'url': 'https://example.test/1.png',
            'has_question_text': true,
            'has_answer_key': false,
          },
          <String, dynamic>{
            'page_number': 2,
            'url': 'https://example.test/2.png',
            'has_question_text': false,
            'has_answer_key': true,
          },
        ],
        'questions': <dynamic>[
          <String, dynamic>{'id': 9, 'number': '1', 'text': 'Question one', 'marks': '2'},
        ],
      }).toDomain();

      expect(detail.pages, hasLength(1));
      expect(detail.pages.single.hasAnswerKey, isFalse);
      expect(detail.questions.single.text, 'Question one');
      expect(detail.questions.single.number, '1');
    });

    test('detail with redistribution denied publishes no scan URLs', () {
      final detail = PastPaperDetailDto.fromJson(<String, dynamic>{
        'paper': <String, dynamic>{'label': 'Locked', 'can_show_scans': false},
        'pages': <dynamic>[
          <String, dynamic>{'page_number': 1, 'url': 'secret'},
        ],
        'questions': <dynamic>[],
      }).toDomain();

      expect(detail.pages, isEmpty);
      expect(detail.questions, isEmpty);
    });

    test('a missing items list is drift', () {
      expect(
        () => PastPaperCatalogDto.fromJson(<String, dynamic>{
          'filters': <String, dynamic>{},
          'facets': <String, dynamic>{},
          'courses': <dynamic>[],
        }),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('word bank', () {
    test('server mastery is copied, never recomputed', () {
      final page = WordBankDto.fromJson(<String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{
            'id': 4,
            'term': 'Levelling',
            'definition': 'Height difference',
            'example': 'Run a levelling survey',
            'difficulty': 'easy',
            'tags': <dynamic>['survey'],
            'course': <String, dynamic>{'id': 3, 'name': 'Civil'},
            'topic': <String, dynamic>{'id': 7, 'name': 'Surveying'},
            'mastery': 0.75,
          },
        ],
        'filters': <String, dynamic>{'difficulty': 'all'},
        'all_tags': <dynamic>['survey'],
        'all_courses': <dynamic>[
          <String, dynamic>{'id': 3, 'name': 'Civil', 'slug': 'civil'},
        ],
        'all_difficulties': <dynamic>['easy', 'medium'],
      }).toDomain();

      expect(page.items.single.mastery, 0.75);
      expect(page.items.single.courseName, 'Civil');
      expect(page.allDifficulties, hasLength(2));
    });

    test('a missing all_difficulties list is drift', () {
      expect(
        () => WordBankDto.fromJson(<String, dynamic>{
          'items': <dynamic>[],
          'filters': <String, dynamic>{},
          'all_tags': <dynamic>[],
          'all_courses': <dynamic>[],
        }),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('profiles', () {
    test('public profile parses the published aggregates', () {
      final snapshot = PublicProfileDto.fromJson(<String, dynamic>{
        'profile': <String, dynamic>{
          'username': 'engineer',
          'name': 'Engineer',
          'level': 5,
          'avatar_url': null,
        },
        'stats': <String, dynamic>{
          'total_quizzes': 10,
          'completed_quizzes': 8,
          'total_battles': 3,
          'average_score': 81.5,
          'accuracy_percent': 72.2,
        },
        'reputation': <String, dynamic>{'score': 12, 'tier': 'bronze'},
        'recent_achievements': <dynamic>[
          <String, dynamic>{'key': 'first', 'name': 'First quiz', 'reward_coins': 5},
        ],
      }).toDomain();

      expect(snapshot.profile.level, 5);
      expect(snapshot.stats.completedQuizzes, 8);
      expect(snapshot.reputationTier, 'bronze');
      expect(snapshot.recentAchievements.single.name, 'First quiz');
    });

    test('comparison rows are taken verbatim from the server', () {
      final comparison = ProfileComparisonDto.fromJson(<String, dynamic>{
        'viewer': <String, dynamic>{'username': 'me', 'name': 'Me', 'level': 3, 'total_xp': 100},
        'target': <String, dynamic>{'username': 'you', 'name': 'You', 'level': 4, 'total_xp': 200},
        'comparison': <String, dynamic>{
          'rows': <dynamic>[
            <String, dynamic>{'label': 'Accuracy', 'viewer': 70, 'target': 80, 'suffix': '%'},
          ],
        },
      }).toDomain();

      expect(comparison.viewer.username, 'me');
      expect(comparison.rows.single.label, 'Accuracy');
      expect(comparison.rows.single.suffix, '%');
    });

    test('a missing profile object is drift', () {
      expect(
        () => PublicProfileDto.fromJson(<String, dynamic>{
          'stats': <String, dynamic>{},
        }),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('resource hub', () {
    test('four server sections parse into card lists', () {
      final hub = ResourceHubDto.fromJson(<String, dynamic>{
        'sections': <String, dynamic>{
          'recommended': <dynamic>[
            <String, dynamic>{
              'id': 2,
              'slug': 'notes',
              'title': 'Notes',
              'coin_price': 0,
              'detail_url': '/api/v1/library/files/notes',
              'category': <String, dynamic>{'id': 1, 'name': 'Civil'},
            },
          ],
          'trending': <dynamic>[],
          'top_rated': <dynamic>[],
          'recently_added': <dynamic>[],
        },
        'library_url': '/api/v1/library/files',
        'my_library_url': '/api/v1/library/me/unlocks',
        'upload_url': null,
      }).toDomain();

      expect(hub.sections.keys, hasLength(4));
      expect(hub.sections['recommended']!.single.slug, 'notes');
      expect(hub.uploadUrl, isNull);
    });

    test('a malformed section is drift', () {
      expect(
        () => ResourceHubDto.fromJson(<String, dynamic>{
          'sections': <String, dynamic>{'trending': 'not-a-list'},
        }).toDomain(),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('impact leaders', () {
    test('server score and viewer rank are preserved', () {
      final snapshot = ImpactLeadersDto.fromJson(<String, dynamic>{
        'leaders': <dynamic>[
          <String, dynamic>{
            'user_id': 7,
            'name': 'Leader',
            'score': 130,
            'qualified_referrals': 3,
          },
        ],
        'viewer_rank': 2,
      }).toDomain();

      expect(snapshot.leaders.single.score, 130);
      expect(snapshot.viewerRank, 2);
    });

    test('a missing leaders list is drift', () {
      expect(
        () => ImpactLeadersDto.fromJson(<String, dynamic>{'viewer_rank': null}),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('reward center', () {
    test('balance, check-in and spin stay server-computed', () {
      final snapshot = RewardCenterDto.fromJson(<String, dynamic>{
        'check_in': <String, dynamic>{
          'claimed_today': true,
          'streak_day': 4,
          'today_reward': 20,
          'next_reward': 25,
        },
        'spin': <String, dynamic>{
          'can_spin': false,
          'prizes': <dynamic>[
            <String, dynamic>{'type': 'coins', 'coins': 10, 'label': 'Coins', 'rarity': 'common'},
          ],
          'next_spin_at': '2026-11-28T00:00:00+05:45',
        },
        'balance': 450,
        'recent_achievements': <dynamic>[
          <String, dynamic>{'key': 'k', 'name': 'Badge', 'reward_coins': 5},
        ],
      }).toDomain();

      expect(snapshot.balance, 450);
      expect(snapshot.checkIn.claimedToday, isTrue);
      expect(snapshot.spin.canSpin, isFalse);
      expect(snapshot.spin.prizes.single.coins, 10);
    });

    test('a missing check_in object is drift', () {
      expect(
        () => RewardCenterDto.fromJson(<String, dynamic>{
          'spin': <String, dynamic>{},
          'balance': 0,
        }),
        throwsA(isA<ContractViolation>()),
      );
    });
  });
}
