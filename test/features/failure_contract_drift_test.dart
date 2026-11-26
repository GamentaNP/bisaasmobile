/// §2.5 failure-contract drift regression tests.
///
/// A 2xx body the client cannot parse is contract drift: it throws, it never
/// becomes an empty collection or a fabricated "success". The counterpart of
/// every assertion is a test proving a genuinely empty server payload still
/// produces an empty result — the two states must stay distinguishable.
library;

import 'package:bisaasmobile/app/providers.dart' as app_providers;
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/battle/data/datasources/battle_remote_data_source.dart';
import 'package:bisaasmobile/features/book/data/datasources/book_remote_data_source.dart';
import 'package:bisaasmobile/features/calculator/data/datasources/calculator_remote_data_source.dart';
import 'package:bisaasmobile/features/contests/data/datasources/contests_remote_data_source.dart';
import 'package:bisaasmobile/features/economy/data/datasources/economy_remote_data_source.dart';
import 'package:bisaasmobile/features/eice/data/eice_remote_data_source.dart';
import 'package:bisaasmobile/features/learning/data/datasources/learning_remote_data_source.dart';
import 'package:bisaasmobile/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:bisaasmobile/features/live_events/data/datasources/live_events_remote_data_source.dart';
import 'package:bisaasmobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/presentation/screens/quiz_intro_screen.dart';
import 'package:bisaasmobile/features/social/data/datasources/social_remote_data_source.dart';
import 'package:bisaasmobile/features/syllabus/data/datasources/syllabus_remote_data_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration/support/fake_api.dart';
import '../support/localized_app.dart';

/// A drifted 2xx shape: the envelope parsed but its `data` is unreadable.
FakeRoute drift(Object? data) =>
    FakeRoute.envelope({'success': true, 'data': data});

void main() {
  group('economy donation lists', () {
    test('unreadable payloads throw; published zero rows stays empty', () async {
      final bad = FakeApi({
        'GET /donations/leaderboard': FakeRoute.ok({'unexpected': true}),
        'GET /donations/feed': FakeRoute.ok({'unexpected': true}),
      });
      final ds = EconomyRemoteDataSource(dioFor(bad));
      await expectLater(
        ds.getDonationLeaderboard(),
        throwsA(isA<ContractViolation>()),
      );
      await expectLater(ds.getDonationFeed(), throwsA(isA<ContractViolation>()));

      final empty = FakeApi({
        'GET /donations/leaderboard': FakeRoute.ok({'topDonors': []}),
        'GET /donations/feed': FakeRoute.ok({'feed': []}),
      });
      final emptyDs = EconomyRemoteDataSource(dioFor(empty));
      expect(await emptyDs.getDonationLeaderboard(), isEmpty);
      expect(await emptyDs.getDonationFeed(), isEmpty);
    });
  });

  group('book catalog', () {
    test('a non-list payload throws; an empty items list is empty', () async {
      final ds = BookRemoteDataSource(
        dioFor(FakeApi({
          'GET /books': FakeRoute.ok({'unexpected': true}),
          'GET /books/slug': drift('not-a-book'),
        })),
      );
      await expectLater(ds.getBooks(), throwsA(isA<ContractViolation>()));
      await expectLater(ds.getBook('slug'), throwsA(isA<ContractViolation>()));

      final empty = BookRemoteDataSource(
        dioFor(FakeApi({
          'GET /books': FakeRoute.ok({'items': []}),
        })),
      );
      expect(await empty.getBooks(), isEmpty);
    });
  });

  group('syllabus catalog', () {
    test('tree and node detail reject unreadable bodies', () async {
      final ds = SyllabusRemoteDataSource(
        dioFor(FakeApi({
          'GET /syllabi': FakeRoute.ok({'unexpected': true}),
          'GET /syllabi/ULID/tree': drift(['not', 'an', 'object']),
          'GET /syllabi/ULID/nodes/1': FakeRoute.ok({}),
        })),
      );
      await expectLater(ds.getVersions(), throwsA(isA<ContractViolation>()));
      await expectLater(
        ds.getTree('ULID'),
        throwsA(isA<ContractViolation>()),
      );
      await expectLater(
        ds.getNodeDetail('ULID', 1),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('a published empty list is still empty', () async {
      final ds = SyllabusRemoteDataSource(
        dioFor(FakeApi({
          'GET /syllabi': FakeRoute.ok({'items': []}),
        })),
      );
      expect(await ds.getVersions(), isEmpty);
    });
  });

  group('learning collections', () {
    test('tracks, goals and due reviews reject unreadable bodies', () async {
      final ds = LearningRemoteDataSource(
        dioFor(FakeApi({
          'GET /learning/tracks': FakeRoute.ok({'unexpected': []}),
          'GET /learning/goals': FakeRoute.ok({'unexpected': []}),
          'GET /learning/reviews/due': FakeRoute.ok({'unexpected': []}),
        })),
      );
      await expectLater(ds.getTracks(), throwsA(isA<ContractViolation>()));
      await expectLater(ds.getGoals(), throwsA(isA<ContractViolation>()));
      await expectLater(ds.getReviewsDue(), throwsA(isA<ContractViolation>()));
    });

    test('a published bare empty list is still empty', () async {
      final ds = LearningRemoteDataSource(
        dioFor(FakeApi({
          'GET /learning/reviews/due': drift([]),
        })),
      );
      expect(await ds.getReviewsDue(), isEmpty);
    });
  });

  group('eice triage', () {
    test('a non-object payload throws', () async {
      final ds = EiceRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/study-planner/1/triage': drift('not-a-plan'),
        })),
      );
      await expectLater(ds.getTriage(1), throwsA(isA<ContractViolation>()));
    });
  });

  group('live events', () {
    test('unreadable list and snapshot bodies throw', () async {
      final ds = LiveEventsRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/live-events': FakeRoute.ok({'unexpected': true}),
          'GET /quiz/live-events/1/snapshot': drift('not-a-snapshot'),
        })),
      );
      await expectLater(ds.getLiveEvents(), throwsA(isA<ContractViolation>()));
      await expectLater(
        ds.getSnapshot(1),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('a published empty event list is still empty', () async {
      final ds = LiveEventsRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/live-events': FakeRoute.ok({'events': []}),
        })),
      );
      expect(await ds.getLiveEvents(), isEmpty);
    });
  });

  group('social', () {
    test('an unusable claim payload throws instead of claiming failure',
        () async {
      final ds = SocialRemoteDataSource(
        dioFor(FakeApi({
          'PUT /social/referral-code/claim': FakeRoute.ok({'status': 'ok'}),
        })),
      );
      await expectLater(
        ds.claimReferralCode('FRIEND'),
        throwsA(isA<ContractViolation>()),
      );

      final malformed = SocialRemoteDataSource(
        dioFor(FakeApi({
          'PUT /social/referral-code/claim': drift('not-a-claim'),
        })),
      );
      await expectLater(
        malformed.claimReferralCode('FRIEND'),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('profile', () {
    test('missing axes throw; a published empty axes list is empty', () async {
      final ds = ProfileRemoteDataSource(
        dioFor(FakeApi({
          'GET /profile/skills': FakeRoute.ok({'unexpected': true}),
        })),
      );
      await expectLater(ds.getSkills(), throwsA(isA<ContractViolation>()));

      final empty = ProfileRemoteDataSource(
        dioFor(FakeApi({
          'GET /profile/skills': FakeRoute.ok({'axes': []}),
        })),
      );
      expect(await empty.getSkills(), isEmpty);
    });
  });

  group('calculator', () {
    test('an unreadable history payload throws; empty history is empty',
        () async {
      final ds = CalculatorRemoteDataSource(
        dioFor(FakeApi({
          'GET /civil/earthwork/history': FakeRoute.ok({'unexpected': true}),
        })),
      );
      await expectLater(
        ds.getHistory('civil', 'earthwork'),
        throwsA(isA<ContractViolation>()),
      );

      final empty = CalculatorRemoteDataSource(
        dioFor(FakeApi({
          'GET /civil/earthwork/history': drift([]),
        })),
      );
      expect(await empty.getHistory('civil', 'earthwork'), isEmpty);
    });
  });

  group('battle', () {
    test('an unreadable leaderboard throws; an empty list is empty', () async {
      final ds = BattleRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/leaderboards/l1': FakeRoute.ok({'unexpected': true}),
        })),
      );
      await expectLater(
        ds.getLeaderboard('l1'),
        throwsA(isA<ContractViolation>()),
      );

      final empty = BattleRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/leaderboards/l1': drift([]),
        })),
      );
      expect(await empty.getLeaderboard('l1'), isEmpty);
    });
  });

  group('leaderboard', () {
    test('submit with an unreadable body throws instead of echoing it',
        () async {
      final ds = LeaderboardRemoteDataSource(
        dioFor(FakeApi({
          'POST /quiz/leaderboard': drift('not-a-result'),
        })),
      );
      await expectLater(
        ds.submitScore(mode: 'quiz'),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('contests', () {
    test('join intent and join result reject unreadable bodies', () async {
      final ds = ContestsRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/contests/1/join-intent': drift('not-an-intent'),
          'PUT /quiz/contests/1/participation': FakeRoute.ok({'unexpected': true}),
        })),
      );
      await expectLater(ds.getJoinIntent(1), throwsA(isA<ContractViolation>()));
      await expectLater(ds.joinContest(1), throwsA(isA<ContractViolation>()));
    });

    test('a published empty contest list is still empty', () async {
      final ds = ContestsRemoteDataSource(
        dioFor(FakeApi({
          'GET /quiz/contests': FakeRoute.ok({'items': []}),
        })),
      );
      final page = await ds.getContests();
      expect(page.items, isEmpty);
    });
  });

  group('quiz intro', () {
    testWidgets('an unreadable question page is an error, not 0 questions',
        (tester) async {
      final api = FakeApi({
        'GET /quiz/courses': FakeRoute.ok({'items': []}),
        'GET /quiz/courses/7/questions': drift('not-a-page'),
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            app_providers.dioProvider.overrideWithValue(dioFor(api)),
          ],
          child: localizedApp(child: const QuizIntroScreen(quizId: '7')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ContractViolation'), findsOneWidget);
    });
  });
}
