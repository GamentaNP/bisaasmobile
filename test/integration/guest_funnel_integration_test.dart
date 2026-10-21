/// Cross-layer tests for the guest acquisition funnel.
///
/// The two things this pass had to get right:
///  * "Continue as Guest" must land on a route a signed-out visitor can
///    actually reach, and
///  * a signed-out share-link recipient must not be bounced to the sign-in
///    form — they are the person the share link exists for.
library;

import 'package:bisaasmobile/app/router/deep_link_handler.dart';
import 'package:bisaasmobile/app/router/route_guards.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/quiz_funnel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('the guest routes', () {
    test('the guest sampler and the share flow are browsable without a token',
        () {
      // These are the two routes a signed-out visitor must be able to reach.
      // `_isGuestAllowed` is the predicate the auth guard uses.
      for (final route in const ['/quiz/funnel', '/social/share']) {
        expect(
          RouteGuards.guestRoutes.any(
            (p) => route == p || route.startsWith('$p/'),
          ),
          isTrue,
          reason: '$route must be guest-reachable',
        );
      }
    });

    test('the share route with a token is guest-reachable', () {
      expect(
        RouteGuards.guestRoutes.any(
          (p) => '/social/share/tok_123' == p ||
              '/social/share/tok_123'.startsWith('$p/'),
        ),
        isTrue,
      );
    });
  });

  group('the deep link the server mints', () {
    test('https://bisaas.com/s/{token} routes into the app', () {
      expect(
        DeepLinkHandler.parse(Uri.parse('https://bisaas.com/s/tok_123')),
        '/social/share/tok_123',
      );
    });

    test('the civilcal:// scheme routes into the app', () {
      expect(
        DeepLinkHandler.parse(Uri.parse('civilcal://s/tok_123')),
        '/social/share/tok_123',
      );
    });
  });

  group('the funnel bundle', () {
    late FakeApi api;
    late QuizRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = QuizRemoteDataSource(dioFor(api));
    });

    test('the guest bundle is read with its item limit', () async {
      api.on(
        'GET',
        '/quiz/guest-funnel',
        FakeRoute.ok(<String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 5,
              'question_text': 'A public question',
              'type': 'mcq',
              'type_label': 'Multiple choice',
              'difficulty': 'easy',
              'points': 2,
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'key': 'A', 'text': 'One'},
                <String, dynamic>{'key': 'B', 'text': 'Two'},
              ],
              'course': <String, dynamic>{'name': 'Civil 101', 'slug': 'civil-101'},
              'category': <String, dynamic>{'name': 'Structures'},
              'sub_category': null,
              'topic': <String, dynamic>{'name': 'Beams'},
            },
          ],
          'counts': <String, dynamic>{
            'questions': 120,
            'courses': 6,
            'categories': 18,
            'sub_categories': 40,
            'topics': 90,
            'public_types': 3,
          },
          'promo': <String, dynamic>{
            'latest_course': 'Fluid Mechanics',
            'latest_category': null,
            'has_fresh': true,
          },
        }),
      );

      final bundle = (await remote.getGuestFunnel(itemLimit: 8)).toDomain();

      expect(bundle.items, hasLength(1));
      expect(bundle.items.first.questionText, 'A public question');
      expect(bundle.items.first.options, hasLength(2));
      expect(bundle.items.first.courseName, 'Civil 101');
      expect(bundle.items.first.topicName, 'Beams');
      expect(bundle.counts.questions, 120);
      expect(bundle.promo.latestCourse, 'Fluid Mechanics');
      expect(bundle.promo.hasFresh, isTrue);

      expect(api.queryOf(0)['item_limit'], 8);
    });

    test('the authenticated bundle is read from its own route', () async {
      api.on(
        'GET',
        '/quiz/funnel',
        FakeRoute.ok(<String, dynamic>{
          'items': <Map<String, dynamic>>[],
          'counts': <String, dynamic>{'questions': 5},
          'promo': <String, dynamic>{'has_fresh': false},
        }),
      );

      final bundle = (await remote.getFunnel(itemLimit: 8)).toDomain();

      expect(bundle.items, isEmpty);
      expect(bundle.counts.questions, 5);
      expect(bundle.promo.hasFresh, isFalse);
    });

    test('a drifted bundle is an error, not an empty catalogue', () async {
      api.on(
        'GET',
        '/quiz/guest-funnel',
        FakeRoute.ok(<String, dynamic>{'unexpected': 'shape'}),
      );

      await expectLater(
        remote.getGuestFunnel(),
        throwsA(isA<Object>()),
      );
    });
  });

  group('the funnel entity', () {
    test('an empty bundle is empty, not fabricated', () {
      const bundle = QuizFunnel();
      expect(bundle.items, isEmpty);
      expect(bundle.counts.hasContent, isFalse);
      expect(bundle.isEmpty, isTrue);
    });

    test('counts report whether there is content', () {
      const bundle = QuizFunnel(counts: FunnelCounts(questions: 1));
      expect(bundle.counts.hasContent, isTrue);
      expect(bundle.isEmpty, isFalse);
    });
  });
}
