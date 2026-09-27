import 'package:bisaasmobile/features/home/data/models/dashboard_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the **real** `GET /api/v1/quiz/daily` shape, verified live against
/// `QuizDailyApiController@today` (bisaas, probed 2026-09-27):
///
/// ```json
/// { "schedule": { "id":1, "scheduled_date":"…", "title":"…",
///                 "question_count":10, "time_limit_minutes":8,
///                 "is_published":true, "quiz_category_id":null,
///                 "quiz_course_id":null, … } | null,
///   "has_completed": false }
/// ```
///
/// Three things the old mapper got wrong, all asserted below:
///   1. The schedule nests under `schedule`; reading a top-level `title` meant
///      the card never showed the real quiz name.
///   2. The only completion flag is `has_completed`; the old code looked for
///      `completed`, so `isDailyCompleted` was permanently false.
///   3. The schedule carries **no** XP or coin reward. Those fields are
///      therefore nullable, and a null must stay null rather than defaulting to
///      a number the user would read as a promise.
void main() {
  group('DashboardDto — real /quiz/daily payload', () {
    test('reads the nested schedule and reports it as scheduled', () {
      final dto = DashboardDto.fromJson({
        'daily_quiz': {
          'scheduled': true,
          'title': 'Daily Quiz — 2026-09-27',
          'questions_count': 10,
          'time_limit_minutes': 8,
          'completed': false,
        },
      });

      expect(dto.dailyQuizScheduled, isTrue);
      expect(dto.dailyQuizTitle, 'Daily Quiz — 2026-09-27');
      expect(dto.dailyQuizQuestionsCount, 10);
      expect(dto.isDailyCompleted, isFalse);
    });

    test('a null schedule is reported as not scheduled, not as a quiz', () {
      final dto = DashboardDto.fromJson({
        'daily_quiz': {
          'scheduled': false,
          'title': null,
          'questions_count': null,
          'completed': false,
        },
      });

      expect(dto.dailyQuizScheduled, isFalse);
      expect(dto.dailyQuizTitle, isNull);
      expect(dto.dailyQuizQuestionsCount, 0);
    });

    test('has_completed drives isDailyCompleted', () {
      final done = DashboardDto.fromJson({
        'daily_quiz': {'scheduled': true, 'title': 'T', 'completed': true},
      });
      final notDone = DashboardDto.fromJson({
        'daily_quiz': {'scheduled': true, 'title': 'T', 'completed': false},
      });
      expect(done.isDailyCompleted, isTrue);
      expect(notDone.isDailyCompleted, isFalse);
    });

    test('a reward the server never sent stays null (no invented XP)', () {
      final dto = DashboardDto.fromJson({
        'daily_quiz': {'scheduled': true, 'title': 'T', 'questions_count': 10},
      });
      // The card must hide the figure rather than print "+0 XP" or a guess.
      expect(dto.dailyQuizXpReward, isNull);
      expect(dto.dailyQuizCoinsReward, isNull);
    });

    test('a reward the server DID send is surfaced', () {
      final dto = DashboardDto.fromJson({
        'daily_quiz': {'scheduled': true, 'title': 'T', 'xp_reward': 200, 'coins_reward': 30},
      });
      expect(dto.dailyQuizXpReward, 200);
      expect(dto.dailyQuizCoinsReward, 30);
    });
  });

  group('DashboardDto — no fabricated fallbacks', () {
    test('an unstated level threshold is null, not 1000 or 100', () {
      final dto = DashboardDto.fromJson({'user': {'level': 3, 'xp': 40}});
      // The old code hardcoded 1000 here while the offline fallback used 100,
      // so the two screens disagreed about the same player's progress.
      expect(dto.nextLevelXp, isNull);
    });

    test('a server-published threshold is honoured', () {
      final dto = DashboardDto.fromJson({'user': {'level': 3, 'xp': 40, 'next_level_xp': 500}});
      expect(dto.nextLevelXp, 500);
    });

    test('an empty payload invents nothing', () {
      final dto = DashboardDto.fromJson({});
      expect(dto.dailyQuizTitle, isNull);
      expect(dto.dailyQuizXpReward, isNull);
      expect(dto.dailyQuizCoinsReward, isNull);
      expect(dto.nextLevelXp, isNull);
      expect(dto.dailyQuizScheduled, isFalse);
      expect(dto.isDailyCompleted, isFalse);
      // Honest zeros for the counters we genuinely cannot know.
      expect(dto.streakDays, 0);
      expect(dto.coinsBalance, 0);
    });

    test('string-encoded numerics still parse', () {
      final dto = DashboardDto.fromJson({
        'user': {'level': '4', 'xp': '250', 'coins': '10', 'next_level_xp': '900'},
        'streak': {'current_streak': '6'},
      });
      expect(dto.level, 4);
      expect(dto.currentXp, 250);
      expect(dto.coinsBalance, 10);
      expect(dto.nextLevelXp, 900);
      expect(dto.streakDays, 6);
    });
  });
}
