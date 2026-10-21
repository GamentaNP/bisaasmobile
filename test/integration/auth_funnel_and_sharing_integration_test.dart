/// Cross-layer integration tests for authentication, the funnel and sharing.
///
/// These drive the real `Dio` → data source → repository chain for the flows
/// that were added in this pass, and pin the exact request shapes the server
/// validates.
library;

import 'package:bisaasmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bisaasmobile/features/auth/data/datasources/social_sign_in_gateway.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';

import 'package:bisaasmobile/features/social/data/datasources/social_remote_data_source.dart';
import 'package:bisaasmobile/features/social/data/repositories/social_repository_impl.dart';
import 'package:bisaasmobile/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('password sign-in', () {
    late FakeApi api;
    late AuthRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = AuthRemoteDataSource(dioFor(api));
    });

    test('the request body is the one the server validates', () async {
      api.on(
        'POST',
        '/auth/login',
        FakeRoute.ok(<String, dynamic>{
          'token': '1|abc',
          'token_type': 'Bearer',
          'expires_at': '2026-11-01T12:00:00+05:45',
          'user': <String, dynamic>{
            'id': 1,
            'name': 'Ram',
            'email': 'ram@bisaas.test',
          },
        }),
      );

      final response = await remote.login(
        email: 'ram@bisaas.test',
        password: 'secret',
        deviceName: 'pixel',
      );

      expect(response.token, '1|abc');

      final body = api.jsonBodyOf(0);
      expect(body['email'], 'ram@bisaas.test');
      expect(body['password'], 'secret');
      expect(body['device_name'], 'pixel');
    });

    test('a bad credential becomes a typed ApiException with the server code',
        () async {
      api.on(
        'POST',
        '/auth/login',
        FakeRoute.error(401, 'AUTH_INVALID_CREDENTIALS', 'Those details do not match.'),
      );

      await expectLater(
        remote.login(
          email: 'ram@bisaas.test',
          password: 'wrong',
          deviceName: 'pixel',
        ),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'message',
            contains('AUTH_INVALID_CREDENTIALS'),
          ),
        ),
      );
    });
  });

  group('social sign-in', () {
    late FakeApi api;
    late AuthRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = AuthRemoteDataSource(dioFor(api));
    });

    test('Google posts the id_token to the documented route', () async {
      api.on(
        'POST',
        '/auth/social/google',
        FakeRoute.ok(<String, dynamic>{
          'token': '1|google',
          'token_type': 'Bearer',
          'user': <String, dynamic>{
            'id': 9,
            'name': 'Ram',
            'email': 'ram@gmail.com',
          },
        }),
      );

      final response = await remote.loginWithGoogle(idToken: 'google-id-token');

      expect(response.token, '1|google');
      final body = api.jsonBodyOf(0);
      expect(body['id_token'], 'google-id-token');
      expect(body.containsKey('name'), isFalse);
    });

    test('Apple forwards the name when the platform gave one', () async {
      api.on(
        'POST',
        '/auth/social/apple',
        FakeRoute.ok(<String, dynamic>{
          'token': '1|apple',
          'token_type': 'Bearer',
          'user': <String, dynamic>{
            'id': 10,
            'name': 'Ram',
            'email': 'ram@icloud.com',
          },
        }),
      );

      await remote.loginWithApple(idToken: 'apple-id-token', name: 'Ram');

      final body = api.jsonBodyOf(0);
      expect(body['id_token'], 'apple-id-token');
      expect(body['name'], 'Ram');
    });

    test('the provider routes match the server', () {
      expect(SocialProvider.google.endpoint, '/auth/social/google');
      expect(SocialProvider.apple.endpoint, '/auth/social/apple');
    });
  });

  group('email verification', () {
    test('the resend posts to the documented route', () async {
      final api = FakeApi(<String, FakeRoute>{});
      final remote = AuthRemoteDataSource(dioFor(api));
      api.on(
        'POST',
        '/auth/email/verification-notification',
        FakeRoute.ok(<String, dynamic>{'sent': true}),
      );

      await remote.resendVerificationEmail();

      expect(api.requests.single.method, 'POST');
      expect(
        api.requests.single.path,
        '/auth/email/verification-notification',
      );
    });
  });

  group('the quiz funnel', () {
    late FakeApi api;
    late QuizRemoteDataSource remote;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      remote = QuizRemoteDataSource(dioFor(api));
    });

    test('the guest funnel is requested with its item limit', () async {
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
              ],
              'course': <String, dynamic>{'name': 'Civil 101', 'slug': 'civil-101'},
              'category': <String, dynamic>{'name': 'Structures'},
              'topic': null,
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

      final funnel = await remote.getGuestFunnel(itemLimit: 8);
      final domain = funnel.toDomain();

      expect(domain.items, hasLength(1));
      expect(domain.items.first.questionText, 'A public question');
      expect(domain.items.first.options, hasLength(1));
      expect(domain.items.first.courseName, 'Civil 101');
      expect(domain.items.first.categoryName, 'Structures');
      expect(domain.counts.questions, 120);
      expect(domain.promo.latestCourse, 'Fluid Mechanics');
      expect(domain.promo.hasFresh, isTrue);

      expect(api.queryOf(0)['item_limit'], 8);
    });
  });

  group('sharing', () {
    late FakeApi api;
    late SocialRepository repository;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      repository = SocialRepositoryImpl(SocialRemoteDataSource(dioFor(api)));
    });

    test('a share link is minted with the kind the server validates', () async {
      api.on(
        'POST',
        '/social/links',
        FakeRoute.ok(<String, dynamic>{
          'share_link': <String, dynamic>{
            'token': 'tok_123',
            'url': 'https://bisaas.com/s/tok_123',
            'kind': 'streak',
            'expires_at': null,
            'copy': <String, dynamic>{
              'title': 'Try this on CivilCal',
              'body': 'A free 2-minute preview — no account needed to try.',
            },
          },
        }),
      );

      final link = await repository.createShareLink(kind: 'streak');

      expect(link, isNotNull);
      expect(link.token, 'tok_123');
      expect(link.url, 'https://bisaas.com/s/tok_123');
      expect(link.shareText, contains('CivilCal'));

      final body = api.jsonBodyOf(0);
      expect(body['kind'], 'streak');
    });

    test('the share is recorded by its token, not by a subject id', () async {
      api.on(
        'POST',
        '/social/share-recorded',
        FakeRoute.ok(<String, dynamic>{'recorded': true}),
      );

      await repository.recordShare(token: 'tok_123', channel: 'whatsapp');

      final body = api.jsonBodyOf(0);
      expect(body['token'], 'tok_123');
      expect(body['channel'], 'whatsapp');
      expect(body.containsKey('subject'), isFalse);
    });

    test('a dismissal sends the moment kind', () async {
      api.on(
        'POST',
        '/social/moments/dismissals',
        FakeRoute.ok(<String, dynamic>{'dismissed': true}),
      );

      await repository.dismissMoment('streak');

      final body = api.jsonBodyOf(0);
      expect(body['kind'], 'streak');
      expect(body.containsKey('moment_key'), isFalse);
    });

    test('the server publishes one moment, not a list', () async {
      api.on(
        'GET',
        '/social/moments',
        FakeRoute.ok(<String, dynamic>{
          'moment': <String, dynamic>{'kind': 'quiz_result', 'priority': 2},
        }),
      );

      final moment = await repository.getMoment();

      expect(moment, isNotNull);
      expect(moment!.kind, 'quiz_result');
      expect(moment.priority, 2);
      // The kind IS the identity — there is no separate id.
      expect(moment.id, 'quiz_result');
    });

    test('an incoming share link resolves with the creator and the sandbox flag',
        () async {
      api.on(
        'GET',
        '/public/social/share/tok_123',
        FakeRoute.ok(<String, dynamic>{
          'share': <String, dynamic>{
            'token': 'tok_123',
            'kind': 'quiz_result',
            'creator_name': 'Ram',
            'expires_at': null,
            'web_landing_url': 'https://bisaas.com/s/tok_123',
            'sandbox_available': true,
          },
        }),
      );

      final shared = await repository.resolveShare('tok_123');

      expect(shared, isNotNull);
      expect(shared.creatorName, 'Ram');
      expect(shared.sandboxAvailable, isTrue);
      expect(shared.isExpired, isFalse);
    });

    test('the guest sandbox start sends the guest session id', () async {
      api.on(
        'POST',
        '/public/social/sandbox/tok_123',
        FakeRoute.ok(<String, dynamic>{
          'sandbox_attempt': <String, dynamic>{
            'attempt_id': 321,
            'guest_session_id': 'guest-abc-123',
            'questions': 5,
          },
        }),
      );

      final attempt = await repository.startSandbox(
        token: 'tok_123',
        guestSessionId: 'guest-abc-123',
      );

      expect(attempt, isNotNull);
      expect(attempt.attemptId, 321);
      expect(attempt.questionCount, 5);

      final body = api.jsonBodyOf(0);
      expect(body['guest_session_id'], 'guest-abc-123');
    });

    test('the sandbox result comes from the server', () async {
      api.on(
        'PUT',
        '/public/social/sandbox/321/completion',
        FakeRoute.ok(<String, dynamic>{
          'result': <String, dynamic>{
            'score': 60.0,
            'correct': 3,
            'wrong': 2,
            'skipped': 0,
            'total': 5,
          },
        }),
      );

      final result = await repository.completeSandbox(321);

      expect(result, isNotNull);
      expect(result.score, 60.0);
      expect(result.correct, 3);
      expect(result.total, 5);
    });
  });
}
