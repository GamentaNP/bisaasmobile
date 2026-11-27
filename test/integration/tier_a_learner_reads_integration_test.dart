/// Cross-layer proof for the five Tier A learner reads and the review grade.
///
/// These endpoints differ in ways that are invisible when a layer is mocked:
/// the feed and review queues are cursor-only, Hall of Fame and analytics are
/// bounded snapshots that reject bare paging keys, and a grade retry must
/// reuse one Idempotency-Key or apply SM-2 twice. This file drives the real
/// Dio → interceptor-free adapter → envelope → DTO → provider stack.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/analytics/presentation/controllers/analytics_controller.dart';
import 'package:bisaasmobile/features/feed/data/datasources/feed_remote_data_source.dart';
import 'package:bisaasmobile/features/feed/presentation/controllers/feed_controller.dart';
import 'package:bisaasmobile/features/hall_of_fame/data/datasources/hall_of_fame_remote_data_source.dart';
import 'package:bisaasmobile/features/hall_of_fame/presentation/controllers/hall_of_fame_controller.dart';
import 'package:bisaasmobile/features/review/data/datasources/review_remote_data_source.dart';
import 'package:bisaasmobile/features/review/presentation/controllers/review_controller.dart';
import 'package:bisaasmobile/features/review/domain/entities/review.dart';
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
      'data': <String, dynamic>{
        ...?extraData,
        'items': items,
      },
      'pagination': <String, dynamic>{
        'type': 'cursor',
        'per_page': 25,
        'count': items.length,
        'has_more': hasMore,
        'next_cursor': nextCursor,
        'prev_cursor': null,
      },
      'message': 'ok',
    };

Map<String, dynamic> _feedCard(int id) => <String, dynamic>{
      'id': id,
      'activity_type': 'quiz_completed',
      'visibility': 'global',
      'message': 'Learner completed a quiz with 80%.',
      'actor': <String, dynamic>{
        'id': 7,
        'name': 'Learner',
        'username': 'learner',
        'is_current_user': false,
        'is_friend_or_self': true,
      },
      'actions': <String, dynamic>{
        'can_challenge': true,
        'challenge_url': '/api/v1/quiz/friends/9/battles',
        'can_comment': true,
        'comment_url': '/api/v1/quiz/feed/items/$id/comments',
      },
      'reactions': <String, dynamic>{
        'counts': <String, dynamic>{'like': 2, 'fire': 1, 'genius': 0},
        'total': 3,
        'viewer_types': <String>['like'],
      },
      'comments': <String, dynamic>{
        'count': 1,
        'recent': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 4,
            'body': 'Nice',
            'author': <String, dynamic>{'id': 8, 'name': 'Friend'},
            'relative_time': '2 hours ago',
          },
        ],
      },
      'attempt': <String, dynamic>{
        'id': 101,
        'score': 80,
        'total_points': 100,
        'mode': 'graded',
      },
      'occurred_at': '2026-11-20T00:00:00+00:00',
      'relative_time': '1 day ago',
    };

Map<String, dynamic> _hallOfFame() => <String, dynamic>{
      'filters': <String, dynamic>{
        'record_type': 'all',
        'period': 'all_time',
        'search': null,
      },
      'summary': <String, dynamic>{
        'record_count': 12,
        'hall_of_famers': 5,
        'featured_count': 2,
        'latest_record_at': '2026-11-25T00:00:00+00:00',
      },
      'featured_records': <dynamic>[],
      'records': <dynamic>[
        <String, dynamic>{
          'id': 31,
          'record_key': 'top-score',
          'record_type': 'global',
          'metric': 'score',
          'title': 'Top score',
          'value_label': '980 pts',
          'name': 'Champion',
          'is_current_user': false,
          'is_featured': true,
          'achieved_at': '2026-11-24T00:00:00+00:00',
          'history': <dynamic>[],
        },
      ],
      'record_type_options': <dynamic>[
        <String, dynamic>{'value': 'all', 'label': 'All records'},
      ],
      'period_options': <dynamic>[
        <String, dynamic>{'value': 'all_time', 'label': 'All time'},
      ],
    };

Map<String, dynamic> _analytics() => <String, dynamic>{
      'user_stats': <String, dynamic>{
        'total_attempts': 10,
        'completed_attempts': 8,
        'total_questions_answered': 100,
        'correct_answers': 72,
        'accuracy_percent': 72.0,
        'average_score': 81.5,
      },
      'category_performance': <dynamic>[
        <String, dynamic>{
          'category_id': 3,
          'category_name': 'Civil',
          'accuracy_percent': 70,
          'total_answered': 40,
        },
      ],
      'weak_topic_heatmap': <String, dynamic>{
        'summary': <String, dynamic>{
          'topics_count': 1,
          'weak_count': 1,
          'developing_count': 0,
          'strong_count': 0,
          'total_answered': 10,
          'average_accuracy': 40.0,
        },
        'topics': <dynamic>[
          <String, dynamic>{
            'topic_key': 'soil',
            'topic_name': 'Soil mechanics',
            'category_name': 'Civil',
            'accuracy_percent': 40,
            'total_answered': 10,
            'band': 'weak',
          },
        ],
      },
    };

Map<String, dynamic> _reviewCard(int id, {required String type}) =>
    <String, dynamic>{
      'type': type,
      'id': id,
      if (type == 'question') 'question_id': id else 'word_id': id,
      'content': type == 'question' ? 'Question $id' : 'Term $id',
      if (type == 'question')
        'options': <dynamic>[
          <String, dynamic>{'key': 'A', 'text': 'Choice A'},
        ],
      if (type == 'word') ...<String, dynamic>{
        'definition': 'Meaning $id',
        'example': 'Sentence $id',
      },
      'item_type': 'mcq',
      'difficulty': 'medium',
      'due_reason': 'overdue',
      'due_at': '2026-11-20T00:00:00+00:00',
      'overdue_days': 6,
      'interval_days': 4,
      'repetitions': 3,
      'easiness_factor': 2.5,
    };

Map<String, dynamic> _reviewItem(int id, {required bool locked}) =>
    <String, dynamic>{
      'question_id': id,
      'question_text': 'Question $id',
      'given_answer': 'A',
      'is_correct': locked ? null : true,
      'is_skipped': false,
      'verdict': locked ? null : 'correct',
      'score_awarded': locked ? null : 1,
      'time_taken_seconds': 12,
      'explanation': locked ? null : 'Because A.',
    };

Map<String, dynamic> _attemptReview(int attemptId, {required bool locked}) =>
    <String, dynamic>{
      'attempt_id': attemptId,
      'status': 'completed',
      'review_policy': <String, dynamic>{
        'answers_visible': !locked,
        'locked': locked,
        'is_high_stakes': locked,
        'release_mode': locked ? 'manual' : 'immediate',
        'released': !locked,
      },
      'items': <dynamic>[_reviewItem(1, locked: locked)],
    };

void main() {
  late FakeApi api;
  late ProviderContainer container;

  ProviderContainer boot() => ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dioFor(api))],
      );

  setUp(() => api = FakeApi(<String, FakeRoute>{}));
  tearDown(() => container.dispose());

  test('feed walks cursors with filters and never sends page', () async {
    api.onSequence('GET', '/quiz/feed', [
      FakeRoute.envelope(_cursorEnvelope([_feedCard(1)], hasMore: true, nextCursor: 'opaque-2')),
      FakeRoute.envelope(_cursorEnvelope([_feedCard(2)], hasMore: false)),
    ]);
    container = boot();

    final cards = await container.read(feedProvider((scope: 'friends', activityType: 'all')).future);

    expect(cards, hasLength(2));
    expect(cards.first.id, '1');
    expect(cards.first.actions.challengeUrl, '/api/v1/quiz/friends/9/battles');
    expect(cards.first.reactions.total, 3);
    expect(cards.first.comments.recent.single.body, 'Nice');
    expect(cards.first.attempt?.score, 80);

    final gets = api.requests.where((r) => r.path == '/quiz/feed').toList();
    expect(gets, hasLength(2));
    final first = api.requests.indexOf(gets.first);
    final second = api.requests.indexOf(gets.last);
    expect(api.queryOf(first)['page'], isNull);
    expect(api.queryOf(first)['filter[scope]'], 'friends');
    expect(api.queryOf(first)['filter[activity_type]'], 'all');
    expect(api.queryOf(first)['per_page'], 25);
    expect(api.queryOf(first)['cursor'], isNull);
    expect(api.queryOf(second)['cursor'], 'opaque-2');
    expect(api.misses, isEmpty);
  });

  test('feed failure is an error, a published empty page is empty', () async {
    api.on('GET', '/quiz/feed', FakeRoute.envelope(_cursorEnvelope([], hasMore: false)));
    container = boot();
    expect(
      await container.read(feedProvider((scope: 'global', activityType: 'all')).future),
      isEmpty,
    );

    api = FakeApi(<String, FakeRoute>{
      'GET /quiz/feed': FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
    });
    await expectLater(
      FeedRemoteDataSource(dioFor(api)).getFeed(scope: 'global'),
      throwsA(isA<DioException>()),
    );
  });

  test('hall of fame sends only filter keys and parses the snapshot', () async {
    api.on('GET', '/quiz/hall-of-fame', FakeRoute.ok(_hallOfFame()));
    container = boot();

    final snapshot = await container.read(hallOfFameProvider((recordType: 'all', period: 'year', search: null)).future);

    expect(snapshot.summary.recordCount, 12);
    expect(snapshot.records.single.valueLabel, '980 pts');
    expect(snapshot.recordTypeOptions.single.label, 'All records');
    final index = api.indexOfRequest('GET', '/quiz/hall-of-fame');
    final query = api.queryOf(index);
    expect(query.keys, <String>{'filter[record_type]', 'filter[period]'});
    expect(query['filter[record_type]'], 'all');
    expect(query['filter[period]'], 'year');
    expect(query.containsKey('page'), isFalse);
    expect(query.containsKey('cursor'), isFalse);
  });

  test('hall of fame drift is contract drift, not zero records', () async {
    api.on('GET', '/quiz/hall-of-fame', FakeRoute.ok(<String, dynamic>{'filters': <String, dynamic>{}}));
    await expectLater(
      HallOfFameRemoteDataSource(dioFor(api)).getSnapshot(
        recordType: 'all',
        period: 'all_time',
      ),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('analytics takes no query parameters and uses server figures', () async {
    api.on('GET', '/quiz/analytics/overview', FakeRoute.ok(_analytics()));
    container = boot();

    final overview = await container.read(analyticsOverviewProvider.future);

    expect(overview.userStats.accuracyPercent, 72);
    expect(overview.userStats.averageScore, 81.5);
    expect(overview.heatmap.topics.single.topicName, 'Soil mechanics');
    expect(overview.heatmap.summary.weakCount, 1);
    expect(api.queryOf(api.indexOfRequest('GET', '/quiz/analytics/overview')), isEmpty);
  });

  test('review due walks cursors and grades with one stable key', () async {
    api.on('GET', '/quiz/review/due', FakeRoute.envelope(_cursorEnvelope([_reviewCard(41, type: 'question')], hasMore: false)));
    api.on('PUT', '/quiz/reviews/41/grade', FakeRoute.ok(<String, dynamic>{
      'id': 41,
      'type': 'question',
      'quality': 4,
      'interval_days': 9,
      'repetitions': 4,
      'easiness_factor': 2.6,
      'due_at': '2026-12-05T00:00:00+00:00',
    }));
    container = boot();
    final subscription = container.listen(reviewDueProvider, (_, __) {});
    final cards = await container.read(reviewDueProvider.future);
    expect(cards.single.isQuestion, isTrue);
    expect(cards.single.options.single.text, 'Choice A');
    expect(cards.single.id, '41');

    final result = await container.read(reviewGradeControllerProvider.notifier).grade(
          '41',
          quality: ReviewQuality.good,
          type: ReviewCardType.question,
        );
    expect(result?.intervalDays, 9);
    expect(container.read(reviewGradeControllerProvider).gradeError, isNull);

    final put = api.indexOfRequest('PUT', '/quiz/reviews/41/grade');
    expect(api.headerOf(put, 'Idempotency-Key'), isNotNull);
    expect(api.jsonBodyOf(put)['quality'], ReviewQuality.good);
    expect(api.jsonBodyOf(put)['type'], 'question');
    expect(api.jsonBodyOf(put).containsKey('interval_days'), isFalse);
    await container.read(reviewDueProvider.future);
    expect(api.countOf('GET', '/quiz/review/due'), 2, reason: 'success refreshes the queue');
    subscription.close();
  });

  test('a failed grade keeps its key, shows the error and does not refresh', () async {
    api.on('GET', '/quiz/review/due', FakeRoute.envelope(_cursorEnvelope([_reviewCard(42, type: 'word')], hasMore: false)));
    api.onSequence('PUT', '/quiz/reviews/42/grade', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(<String, dynamic>{
        'id': 42,
        'type': 'word',
        'quality': 5,
        'interval_days': 12,
        'repetitions': 2,
        'easiness_factor': 2.7,
      }),
    ]);
    container = boot();
    final subscription = container.listen(reviewDueProvider, (_, __) {});
    await container.read(reviewDueProvider.future);
    final controller = container.read(reviewGradeControllerProvider.notifier);

    expect(await controller.grade('42', quality: ReviewQuality.easy, type: ReviewCardType.word), isNull);
    expect(container.read(reviewGradeControllerProvider).gradeError, isNotNull);
    expect(api.countOf('GET', '/quiz/review/due'), 1, reason: 'a failed grade must not refresh');

    expect(await controller.grade('42', quality: ReviewQuality.easy, type: ReviewCardType.word), isNotNull);
    final puts = api.requests.where((r) => r.method == 'PUT').toList();
    final first = api.requests.indexOf(puts.first);
    final second = api.requests.indexOf(puts.last);
    expect(api.headerOf(first, 'Idempotency-Key'), api.headerOf(second, 'Idempotency-Key'));
    await container.read(reviewDueProvider.future);
    expect(api.countOf('GET', '/quiz/review/due'), 2);
    subscription.close();
  });

  test('attempt review walks cursors and withholds gated verdicts', () async {
    api.onSequence('GET', '/quiz/attempts/77/review', [
      FakeRoute.envelope(_cursorEnvelope(
        [_reviewItem(1, locked: true)],
        hasMore: true,
        nextCursor: 'opaque-3',
        extraData: _attemptReview(77, locked: true),
      )),
      FakeRoute.envelope(_cursorEnvelope(
        [_reviewItem(2, locked: true)],
        hasMore: false,
        extraData: _attemptReview(77, locked: true),
      )),
    ]);
    container = boot();

    final review = await container.read(attemptReviewProvider(77).future);

    expect(review.attemptId, 77);
    expect(review.items, hasLength(2));
    expect(review.policy.locked, isTrue);
    expect(review.items.first.isCorrect, isNull);
    expect(review.items.first.explanation, isNull);
    expect(review.items.first.verdict, isNull);
    final gets = api.requests.where((r) => r.path == '/quiz/attempts/77/review').toList();
    expect(gets, hasLength(2));
    expect(api.queryOf(api.requests.indexOf(gets.first)).containsKey('page'), isFalse);
    expect(api.queryOf(api.requests.indexOf(gets.last))['cursor'], 'opaque-3');
  });

  test('attempt review failure stays an error, not an empty verdict sheet', () async {
    api = FakeApi(<String, FakeRoute>{
      'GET /quiz/attempts/78/review': FakeRoute.error(422, 'UNPROCESSABLE_ENTITY', 'not completed'),
    });
    await expectLater(
      ReviewRemoteDataSource(dioFor(api)).getAttemptReview(78),
      throwsA(isA<DioException>()),
    );
  });
}
