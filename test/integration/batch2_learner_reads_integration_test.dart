/// Cross-layer proof for the six Batch 2 learner reads (§9.5).
///
/// Real Dio → scripted adapter → envelope → DTO → domain is exercised here:
/// the two catalogs are cursor-walked with an opaque token and never a `page`,
/// the bounded snapshots send no query keys, and a transport error or a 2xx
/// drift stays an error instead of rendering "you have no data".
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/gamification/data/datasources/reward_center_remote_data_source.dart';
import 'package:bisaasmobile/features/gamification/presentation/controllers/reward_center_controller.dart';
import 'package:bisaasmobile/features/library/data/datasources/resource_hub_remote_data_source.dart';
import 'package:bisaasmobile/features/past_papers/data/datasources/past_papers_remote_data_source.dart';
import 'package:bisaasmobile/features/profile/data/datasources/public_profile_remote_data_source.dart';
import 'package:bisaasmobile/features/social/data/datasources/impact_leaders_remote_data_source.dart';
import 'package:bisaasmobile/features/word_bank/data/datasources/word_bank_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _cursorEnvelope(
  List<Map<String, dynamic>> items, {
  required bool hasMore,
  String? nextCursor,
  Map<String, dynamic>? extraData,
}) =>
    <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{...?extraData, 'items': items},
      'pagination': <String, dynamic>{
        'type': 'cursor',
        'per_page': 25,
        'count': items.length,
        'has_more': hasMore,
        'next_cursor': nextCursor,
      },
      'message': 'ok',
    };

Map<String, dynamic> _paper(int id) => <String, dynamic>{
      'id': id,
      'label': '2078 Paper $id',
      'country': 'NP',
      'year_bs': 2078,
      'year_ad': 2022,
      'paper_number': id,
      'total_questions': 100,
      'verified': true,
      'has_key': false,
      'redistribution_allowed': false,
      'detail_url': '/api/v1/quiz/past-papers/$id',
      'exam_name': 'Civil',
      'authority': 'PSC',
    };

Map<String, dynamic> _word(int id) => <String, dynamic>{
      'id': id,
      'term': 'Term $id',
      'definition': 'Meaning $id',
      'example': 'Example $id',
      'difficulty': 'medium',
      'tags': <dynamic>[],
      'mastery': null,
    };

Map<String, dynamic> _resourceHub() => <String, dynamic>{
      'sections': <String, dynamic>{
        'recommended': <dynamic>[
          <String, dynamic>{
            'id': 1,
            'slug': 'notes',
            'title': 'Notes',
            'coin_price': 0,
            'detail_url': '/api/v1/library/files/notes',
          },
        ],
        'trending': <dynamic>[],
        'top_rated': <dynamic>[],
        'recently_added': <dynamic>[],
      },
      'library_url': '/api/v1/library/files',
      'my_library_url': '/api/v1/library/me/unlocks',
      'upload_url': null,
    };

Map<String, dynamic> _profile() => <String, dynamic>{
      'profile': <String, dynamic>{
        'username': 'engineer',
        'name': 'Engineer',
        'level': 5,
      },
      'stats': <String, dynamic>{
        'total_quizzes': 10,
        'completed_quizzes': 8,
        'total_battles': 2,
        'average_score': 80,
        'accuracy_percent': 75,
      },
      'reputation': <String, dynamic>{'score': 4, 'tier': 'bronze'},
      'recent_achievements': <dynamic>[],
    };

Map<String, dynamic> _compare() => <String, dynamic>{
      'viewer': <String, dynamic>{'username': 'me', 'name': 'Me', 'level': 2, 'total_xp': 10},
      'target': <String, dynamic>{'username': 'engineer', 'name': 'Engineer', 'level': 5, 'total_xp': 90},
      'comparison': <String, dynamic>{
        'rows': <dynamic>[
          <String, dynamic>{'label': 'Accuracy', 'viewer': 70, 'target': 80, 'suffix': '%'},
        ],
      },
    };

Map<String, dynamic> _rewardCenter() => <String, dynamic>{
      'check_in': <String, dynamic>{
        'claimed_today': false,
        'streak_day': 2,
        'today_reward': 15,
        'next_reward': 20,
      },
      'spin': <String, dynamic>{
        'can_spin': true,
        'prizes': <dynamic>[],
        'next_spin_at': null,
      },
      'balance': 120,
      'recent_achievements': <dynamic>[],
    };

void main() {
  late FakeApi api;
  ProviderContainer? container;

  ProviderContainer boot() => ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dioFor(api))],
      );

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    container = null;
  });
  tearDown(() => container?.dispose());

  test('past papers walk next_cursor with filters and never send page', () async {
    api.onSequence('GET', '/quiz/past-papers', [
      FakeRoute.envelope(_cursorEnvelope(
        [_paper(1)],
        hasMore: true,
        nextCursor: 'opaque-2',
        extraData: <String, dynamic>{
          'filters': <String, dynamic>{'country': 'NP'},
          'facets': <String, dynamic>{'years': <dynamic>[2078]},
          'courses': <dynamic>[],
        },
      )),
      FakeRoute.envelope(_cursorEnvelope(
        [_paper(2)],
        hasMore: false,
        extraData: <String, dynamic>{
          'filters': <String, dynamic>{'country': 'NP'},
          'facets': <String, dynamic>{'years': <dynamic>[2078]},
          'courses': <dynamic>[],
        },
      )),
    ]);

    final ds = PastPapersRemoteDataSource(dioFor(api));
    final first = await ds.getPapers(search: 'civil', year: '2078');
    final second = await ds.getPapers(search: 'civil', year: '2078', cursor: first.nextCursor);

    expect([...first.items, ...second.items].map((p) => p.id), [1, 2]);
    expect(api.queryOf(0)['filter[search]'], 'civil');
    expect(api.queryOf(0)['filter[year]'], '2078');
    expect(api.queryOf(0)['page'], isNull);
    expect(api.queryOf(1)['cursor'], 'opaque-2');
    expect(api.misses, isEmpty);
  });

  test('past paper detail never exposes an answer key or unauthorised scans', () async {
    api.on('GET', '/quiz/past-papers/7', FakeRoute.ok(<String, dynamic>{
      'paper': <String, dynamic>{
        'id': 7,
        'label': '2078 Paper 7',
        'can_show_scans': false,
        'total_questions': 1,
      },
      'pages': <dynamic>[
        <String, dynamic>{
          'page_number': 1,
          'url': 'https://example.test/scan.png',
          'has_question_text': true,
          'has_answer_key': true,
        },
      ],
      'questions': <dynamic>[
        <String, dynamic>{'id': 9, 'number': '1', 'text': 'Question one'},
      ],
    }));

    final detail = await PastPapersRemoteDataSource(dioFor(api)).getPaper(7);
    expect(detail.pages, isEmpty);
    expect(detail.questions.single.text, 'Question one');
    expect(detail.questions.single.number, '1');
  });

  test('word bank walks cursors and sends only the documented filters', () async {
    api.onSequence('GET', '/quiz/word-bank', [
      FakeRoute.envelope(_cursorEnvelope(
        [_word(1)],
        hasMore: true,
        nextCursor: 'word-2',
        extraData: <String, dynamic>{
          'filters': <String, dynamic>{'difficulty': 'easy'},
          'all_tags': <dynamic>[],
          'all_courses': <dynamic>[],
          'all_difficulties': <dynamic>['easy', 'medium'],
        },
      )),
      FakeRoute.envelope(_cursorEnvelope(
        [_word(2)],
        hasMore: false,
        extraData: <String, dynamic>{
          'filters': <String, dynamic>{'difficulty': 'easy'},
          'all_tags': <dynamic>[],
          'all_courses': <dynamic>[],
          'all_difficulties': <dynamic>['easy', 'medium'],
        },
      )),
    ]);

    final ds = WordBankRemoteDataSource(dioFor(api));
    final first = await ds.getWords(difficulty: 'easy');
    final second = await ds.getWords(difficulty: 'easy', cursor: first.nextCursor);

    expect(second.items.single.term, 'Term 2');
    expect(api.queryOf(0)['filter[difficulty]'], 'easy');
    expect(api.queryOf(0)['page'], isNull);
    expect(api.queryOf(1)['cursor'], 'word-2');
    expect(api.queryOf(0).keys, isNot(contains('filter[tag]')));
  });

  test('bounded snapshots send no query keys', () async {
    api
      ..on('GET', '/quiz/resources', FakeRoute.ok(_resourceHub()))
      ..on('GET', '/social/impact-leaders', FakeRoute.ok(<String, dynamic>{
        'leaders': <dynamic>[
          <String, dynamic>{
            'user_id': 7,
            'name': 'Leader',
            'score': 130,
            'qualified_referrals': 3,
          },
        ],
        'viewer_rank': 2,
      }))
      ..on('GET', '/reward-center', FakeRoute.ok(_rewardCenter()));

    final hub = await ResourceHubRemoteDataSource(dioFor(api)).getHub();
    final leaders = await ImpactLeadersRemoteDataSource(dioFor(api)).getLeaders();
    final rewards = await RewardCenterRemoteDataSource(dioFor(api)).getSnapshot();

    expect(hub.sections['recommended']!.single.slug, 'notes');
    expect(leaders.leaders.single.score, 130);
    expect(leaders.viewerRank, 2);
    expect(rewards.balance, 120);
    for (final request in api.requests) {
      expect(request.queryParameters, isEmpty);
    }
  });

  test('profiles send no query keys on show and only username on compare', () async {
    api
      ..on('GET', '/quiz/profiles/engineer', FakeRoute.ok(_profile()))
      ..on('GET', '/quiz/profiles/compare', FakeRoute.ok(_compare()));

    final ds = PublicProfileRemoteDataSource(dioFor(api));
    final profile = await ds.getProfile('engineer');
    final comparison = await ds.compare('engineer');

    expect(profile.profile.username, 'engineer');
    expect(profile.stats.completedQuizzes, 8);
    expect(comparison.rows.single.suffix, '%');
    expect(api.queryOf(0), isEmpty);
    expect(api.queryOf(1)['username'], 'engineer');
    expect(api.queryOf(1).keys, hasLength(1));
  });

  test('a transport error throws and is never rendered as an empty snapshot', () async {
    api.on('GET', '/reward-center', FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'));
    await expectLater(
      RewardCenterRemoteDataSource(dioFor(api)).getSnapshot(),
      throwsA(isA<DioException>()),
    );
  });

  test('a 2xx drift throws ContractViolation', () async {
    api.on('GET', '/social/impact-leaders', FakeRoute.raw(<String, dynamic>{'data': <String, dynamic>{}}));
    await expectLater(
      ImpactLeadersRemoteDataSource(dioFor(api)).getLeaders(),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('the reward-center provider is wired through the overridden Dio', () async {
    api.on('GET', '/reward-center', FakeRoute.ok(_rewardCenter()));
    container = boot();

    final snapshot = await container!.read(rewardCenterProvider.future);
    expect(snapshot.balance, 120);
    expect(snapshot.checkIn.streakDay, 2);
  });
}
