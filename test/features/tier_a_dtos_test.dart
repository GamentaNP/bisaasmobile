/// Layer-local parsing proof for the five Tier A wire shapes.
///
/// The integration test proves the transport and the queries; this file pins
/// the DTO boundary itself. An unreadable 2xx body must throw
/// [ContractViolation] — a DTO that quietly fabricates zeros would turn a
/// server drift into a blank screen that looks like "no data".
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/analytics/data/models/analytics_dto.dart';
import 'package:bisaasmobile/features/feed/data/models/feed_dto.dart';
import 'package:bisaasmobile/features/hall_of_fame/data/models/hall_of_fame_dto.dart';
import 'package:bisaasmobile/features/review/data/models/review_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed card parses nested snake_case payloads', () {
    final card = FeedCardDto.fromJson(<String, dynamic>{
      'id': 5,
      'activity_type': 'quiz_completed',
      'message': 'Completed a quiz.',
      'actor': <String, dynamic>{'id': 9, 'name': 'Learner', 'is_current_user': true},
      'actions': <String, dynamic>{
        'can_share': true,
        'share_url': '/api/v1/quiz/feed/items/5/shares',
        'visibility_options': <dynamic>[
          <String, dynamic>{'value': 'global', 'label': 'Global'},
        ],
      },
      'reactions': <String, dynamic>{
        'counts': <String, dynamic>{'like': 2, 'fire': 1, 'genius': 0},
        'total': 3,
        'viewer_types': <dynamic>['like'],
      },
      'comments': <String, dynamic>{
        'count': 1,
        'recent': <dynamic>[
          <String, dynamic>{
            'id': 3,
            'body': 'Nice',
            'author': <String, dynamic>{'id': 4, 'name': 'Friend'},
          },
        ],
      },
      'attempt': <String, dynamic>{'id': 12, 'score': 88.5},
      'relative_time': '2 hours ago',
    }).toDomain();

    expect(card.id, '5');
    expect(card.actor.isCurrentUser, isTrue);
    expect(card.actions.shareUrl, '/api/v1/quiz/feed/items/5/shares');
    expect(card.actions.visibilityOptions.single.value, 'global');
    expect(card.reactions.total, 3);
    expect(card.comments.recent.single.body, 'Nice');
    expect(card.attempt?.score, 88.5);
    expect(card.relativeTime, '2 hours ago');
  });

  test('feed card without an id is drift', () {
    expect(
      () => FeedCardDto.fromJson(<String, dynamic>{'activity_type': 'quiz_completed'}),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('hall of fame parses the composed snapshot', () {
    final snapshot = HallOfFameDto.fromJson(<String, dynamic>{
      'filters': <String, dynamic>{'record_type': 'global', 'period': 'month', 'search': null},
      'summary': <String, dynamic>{
        'record_count': 4,
        'hall_of_famers': 2,
        'featured_count': 1,
      },
      'featured_records': <dynamic>[],
      'records': <dynamic>[
        <String, dynamic>{
          'id': 1,
          'title': 'Top score',
          'value_label': '990 pts',
          'is_featured': true,
        },
      ],
      'record_type_options': <dynamic>[
        <String, dynamic>{'value': 'all', 'label': 'All records'},
      ],
      'period_options': <dynamic>[
        <String, dynamic>{'value': 'month', 'label': 'Month'},
      ],
    }).toDomain();

    expect(snapshot.summary.recordCount, 4);
    expect(snapshot.records.single.isFeatured, isTrue);
    expect(snapshot.periodOptions.single.value, 'month');
  });

  test('hall of fame without a records list is drift', () {
    expect(
      () => HallOfFameDto.fromJson(<String, dynamic>{
        'filters': <String, dynamic>{},
        'summary': <String, dynamic>{},
        'featured_records': <dynamic>[],
        'record_type_options': <dynamic>[],
        'period_options': <dynamic>[],
      }),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('analytics uses server-computed figures without recomputing them', () {
    final overview = AnalyticsOverviewDto.fromJson(<String, dynamic>{
      'user_stats': <String, dynamic>{
        'total_attempts': 3,
        'accuracy_percent': 66.67,
        'average_score': 70.5,
      },
      'category_performance': <dynamic>[
        <String, dynamic>{
          'category_id': 1,
          'category_name': 'Civil',
          'accuracy_percent': 60,
          'total_answered': 10,
        },
      ],
      'weak_topic_heatmap': <String, dynamic>{
        'summary': <String, dynamic>{'topics_count': 1, 'weak_count': 1},
        'topics': <dynamic>[
          <String, dynamic>{
            'topic_key': 'soil',
            'topic_name': 'Soil',
            'accuracy_percent': 40,
            'band': 'weak',
          },
        ],
      },
    }).toDomain();

    expect(overview.userStats.accuracyPercent, 66.67);
    expect(overview.userStats.averageScore, 70.5);
    expect(overview.categoryPerformance.single.categoryName, 'Civil');
    expect(overview.heatmap.topics.single.band, 'weak');
  });

  test('analytics missing a section is drift', () {
    expect(
      () => AnalyticsOverviewDto.fromJson(<String, dynamic>{
        'user_stats': <String, dynamic>{},
      }),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('review cards keep the progress id and withhold any answer key', () {
    final question = ReviewCardDto.fromJson(<String, dynamic>{
      'type': 'question',
      'id': 41,
      'question_id': 8,
      'content': 'Question',
      'options': <dynamic>[
        <String, dynamic>{'key': 'A', 'text': 'Choice A'},
      ],
      'due_at': '2026-11-20T00:00:00+00:00',
    }).toDomain();
    final word = ReviewCardDto.fromJson(<String, dynamic>{
      'type': 'word',
      'id': 42,
      'word_id': 9,
      'content': 'Term',
      'definition': 'Meaning',
      'due_at': '2026-11-20T00:00:00+00:00',
    }).toDomain();

    expect(question.id, '41');
    expect(question.isQuestion, isTrue);
    expect(question.options.single.label, 'A');
    expect(word.isWord, isTrue);
    expect(word.definition, 'Meaning');
  });

  test('unknown review card type is drift', () {
    expect(
      () => ReviewCardDto.fromJson(<String, dynamic>{
        'type': 'learning-atom',
        'id': 1,
        'due_at': '2026-11-20T00:00:00+00:00',
      }),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('grade result accepts only a server quality in 0..5', () {
    final grade = ReviewGradeResultDto.fromJson(<String, dynamic>{
      'id': 41,
      'type': 'question',
      'grade': 5,
      'interval_days': 10,
    });
    expect(grade.quality, 5);
    expect(grade.intervalDays, 10);
    expect(
      () => ReviewGradeResultDto.fromJson(<String, dynamic>{
        'id': 41,
        'type': 'question',
        'quality': 9,
      }),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('attempt review mirrors the locked release policy', () {
    final review = AttemptReviewDto.fromJson(<String, dynamic>{
      'attempt_id': 77,
      'status': 'completed',
      'review_policy': <String, dynamic>{
        'answers_visible': false,
        'locked': true,
        'is_high_stakes': true,
        'release_mode': 'manual',
        'released': false,
      },
      'items': <dynamic>[
        <String, dynamic>{
          'question_id': 1,
          'given_answer': 'A',
          'is_skipped': false,
        },
      ],
    }).toDomain();

    expect(review.policy.locked, isTrue);
    expect(review.policy.answersVisible, isFalse);
    expect(review.items.single.isCorrect, isNull);
    expect(review.items.single.verdict, isNull);
    expect(review.items.single.explanation, isNull);
  });
}
