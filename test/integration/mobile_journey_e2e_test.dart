/// P5-23 — the mobile journey: login → quiz → economy → battle → push.
///
/// One test, one client stack: real `Dio` → interceptors (`AuthInterceptor`,
/// `TenantInterceptor`) → `HttpClientAdapter` (`FakeApi`) → envelope → DTO →
/// domain → repository → controller. Nothing is stubbed between the repository
/// and the wire, because the bugs this journey exists to catch live exactly
/// there (a header lost between layers, a response read as "empty", a retry
/// that mints a new idempotency key).
///
/// ## Server-authoritative ordering
///
/// * The answer endpoint returns **no grading**. The test asserts the DTO is
///   the neutral "submitted" marker; a correct/incorrect value on the client
///   before the results screen would be a local grade.
/// * The quiz result is built entirely from the completion response's
///   `correct_count`/`coins_earned` fields.
/// * The wallet balance is read from `GET /economy/wallet` before and after
///   completion. The client never adds the reward itself.
/// * A completion **replay** with the same Idempotency-Key returns the same
///   payload, and the wallet is unchanged — the credit happened once, on the
///   server.
///
/// ## One key per logical operation (not one key for the journey)
///
/// The acceptance text says "start/answer/complete reusing ONE
/// Idempotency-Key". It cannot mean one key for all three requests: the server
/// stores the request hash (`method|path|body`) with the key and answers
/// `409 IDEMPOTENCY_CONFLICT` when the same key arrives with a different
/// request. So the journey proves the meaningful property: each operation's
/// key is **stable across retries** of that operation, and operations never
/// share a key. This is called out in the final report.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/network/auth_interceptor.dart';
import 'package:bisaasmobile/core/network/tenant_interceptor.dart';
import 'package:bisaasmobile/core/security/tenant_providers.dart';
import 'package:bisaasmobile/core/security/tenant_store.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';
import 'package:bisaasmobile/core/notifications/push_notification_service.dart';
import 'package:bisaasmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bisaasmobile/features/auth/data/datasources/social_sign_in_gateway.dart';
import 'package:bisaasmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bisaasmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bisaasmobile/features/battle/data/datasources/battle_remote_data_source.dart';
import 'package:bisaasmobile/features/battle/data/repositories/battle_repository_impl.dart';
import 'package:bisaasmobile/features/economy/data/datasources/economy_remote_data_source.dart';
import 'package:bisaasmobile/features/organization/data/organization_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_api.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockGateway extends Mock implements SocialSignInGateway {}

Map<String, dynamic> _user() => <String, dynamic>{
  'id': 7,
  'name': 'Bishwo',
  'email': 'a@b.test',
};

Map<String, dynamic> _session(String token, {required int days}) =>
    <String, dynamic>{
      'token': token,
      'token_type': 'Bearer',
      'expires_at': DateTime.now()
          .toUtc()
          .add(Duration(days: days))
          .toIso8601String(),
      'user': _user(),
    };

Map<String, dynamic> _completion({String message = 'completed'}) =>
    <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'attempt_id': 77,
        'score': 1,
        'correct_count': 1,
        'wrong_count': 0,
        'skipped_count': 0,
        'total_xp_earned': 10,
        'total_coins_earned': 5,
      },
      'message': message,
      'timestamp': '2026-11-04T00:00:00+00:00',
      'api_version': 'v1',
    };

void main() {
  late FakeApi api;
  late _MockSecureStorage storage;
  late _MockMessaging messaging;
  late Map<String, String> stored;
  late TokenManager tokens;
  late TenantStore tenants;
  late ProviderContainer container;
  late PushNotificationService push;

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    storage = _MockSecureStorage();
    messaging = _MockMessaging();
    stored = <String, String>{};

    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (inv) async => stored[inv.namedArguments[#key] as String],
    );
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((inv) async {
      stored[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((inv) async {
      stored.remove(inv.namedArguments[#key]);
    });

    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-1');
    when(() => messaging.deleteToken()).thenAnswer((_) async {});

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    tokens = TokenManager(storage: storage);
    tenants = TenantStore(storage: storage);
    final dio = dioFor(api)
      ..interceptors.addAll([
        AuthInterceptor(tokens),
        TenantInterceptor(tenants),
      ]);

    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(dio),
      tokenManager: tokens,
      socialSignInGateway: _MockGateway(),
      tenantStore: tenants,
    );
    push = PushNotificationService(messaging, dio);

    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        tokenManagerProvider.overrideWithValue(tokens),
        tenantStoreProvider.overrideWithValue(tenants),
        authRepositoryProvider.overrideWithValue(authRepository),
        pushServiceProvider.overrideWithValue(push),
      ],
    );
    addTearDown(container.dispose);
  });

  List<int> indicesOf(String method, String pathSuffix) => [
    for (var i = 0; i < api.requests.length; i++)
      if (api.requests[i].method == method &&
          api.requests[i].path.endsWith(pathSuffix))
        i,
  ];

  test('login → quiz → economy → battle → push', () async {
    // ── LEG 1 — login and refresh ────────────────────────────────────────────
    api
      ..on(
        'POST',
        '/auth/login',
        FakeRoute.ok(_session('pat-1', days: 1), message: 'Login successful'),
      )
      ..on(
        'POST',
        '/auth/refresh',
        FakeRoute.ok(_session('pat-2', days: 30), message: 'refreshed'),
      )
      ..on('GET', '/me', FakeRoute.ok(_user()))
      ..on(
        'POST',
        '/device-tokens',
        FakeRoute.ok(<String, dynamic>{'registered': true}),
      );

    final authController = container.read(authControllerProvider.notifier);
    await container.read(authControllerProvider.future); // cold start: no token
    await authController.login(email: 'a@b.test', password: 'secret123');

    expect(stored['auth_token'], 'pat-1', reason: 'login must persist the PAT');
    expect(
      api.headerOf(api.indexOfRequest('POST', '/auth/login'), 'X-Tenant'),
      isNull,
      reason: 'no organization has been selected yet',
    );

    // Push registration follows login (`app.dart` does this on the auth
    // transition). The DELETE on logout is asserted at the end of the leg.
    await push.registerToken();
    final deviceTokenIndex = api.indexOfRequest('POST', '/device-tokens');
    expect(deviceTokenIndex, isNot(-1));
    expect(api.jsonBodyOf(deviceTokenIndex)['token'], 'fcm-token-1');
    expect(api.jsonBodyOf(deviceTokenIndex)['platform'], 'android');
    expect(
      api.headerOf(deviceTokenIndex, 'Authorization'),
      'Bearer pat-1',
      reason: 'the device token is registered for the signed-in session',
    );

    // Proactive rotation: the login token expires in a day, so a cold start
    // refreshes it before using it. This is `getCurrentUser`'s real path.
    container.invalidate(authControllerProvider);
    final refreshedUser = await container.read(authControllerProvider.future);

    expect(refreshedUser?.email, 'a@b.test');
    final refreshIndex = api.indexOfRequest('POST', '/auth/refresh');
    expect(refreshIndex, isNot(-1));
    expect(api.headerOf(refreshIndex, 'Authorization'), 'Bearer pat-1');
    expect(
      api.headerOf(refreshIndex, 'X-Device-Name'),
      isNotNull,
      reason: 'single-use rotation is bound to the device name',
    );
    expect(stored['auth_token'], 'pat-2', reason: 'rotation replaces the PAT');

    // TN-09/P5-22: the switcher's list is the server's, and the selection it
    // produces rides every later request.
    api.on(
      'GET',
      '/me/tenants',
      FakeRoute.ok(<String, dynamic>{
        'tenants': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7,
            'name': 'Acme Engineering',
            'slug': 'acme',
            'role': 'owner',
          },
        ],
      }),
    );
    final organizations = await OrganizationRemoteDataSource(
      container.read(dioProvider),
    ).fetchMemberships();
    expect(organizations.single.id, 7);
    final membershipsIndex = api.indexOfRequest('GET', '/me/tenants');
    expect(
      api.headerOf(membershipsIndex, 'Authorization'),
      'Bearer pat-2',
    );
    expect(
      api.headerOf(membershipsIndex, 'X-Tenant'),
      isNull,
      reason:
          'the list is how a user who cannot resolve a tenant finds one; '
          'asserting before knowing it would 403',
    );
    await tenants.select(organizations.single.id);

    // ── LEG 2 — quiz: start → answer → complete ──────────────────────────────
    api
      ..on(
        'POST',
        '/quiz/attempts',
        FakeRoute.ok(<String, dynamic>{
          'attempt_id': 77,
          'status': 'in_progress',
        }),
      )
      ..on(
        'POST',
        '/quiz/attempts/77/answers',
        FakeRoute.ok(<String, dynamic>{}),
      )
      ..onSequence('PUT', '/quiz/attempts/77/completion', <FakeRoute>[
        FakeRoute(200, _completion()),
        FakeRoute(
          200,
          _completion(message: 'replayed'),
          headers: const <String, String>{'X-Idempotent-Replay': 'true'},
        ),
      ]);

    // The journey's Dio — same interceptors, same adapter.
    final quizApi = QuizRemoteDataSource(container.read(dioProvider));
    final attemptId = await quizApi.startAttempt(
      quizId: '5',
      questionIds: const <int>[101],
      idempotencyKey: 'attempt-start-77',
    );
    expect(attemptId, '77');

    final startIndices = indicesOf('POST', '/quiz/attempts');
    expect(startIndices, hasLength(1));
    expect(
      api.headerOf(startIndices.single, 'Idempotency-Key'),
      'attempt-start-77',
    );
    expect(
      api.headerOf(startIndices.single, 'X-Tenant'),
      '7',
      reason: 'the selected organization is asserted on the journey traffic',
    );
    expect(
      api.headerOf(startIndices.single, 'Authorization'),
      'Bearer pat-2',
    );

    // A retry after a lost response: same logical operation, same key.
    final retriedAttemptId = await quizApi.startAttempt(
      quizId: '5',
      questionIds: const <int>[101],
      idempotencyKey: 'attempt-start-77',
    );
    expect(retriedAttemptId, '77');
    final retriedStartIndices = indicesOf('POST', '/quiz/attempts');
    expect(retriedStartIndices, hasLength(2));
    expect(
      api.headerOf(retriedStartIndices.last, 'Idempotency-Key'),
      'attempt-start-77',
      reason: 'a retry that minted a new key would start a second attempt',
    );

    final answer = await quizApi.submitAnswer(
      attemptId: attemptId,
      questionId: '101',
      selectedOptionId: 'opt_a',
      idempotencyKey: 'answer-77-101',
      timeTakenSeconds: 9,
    );
    final answerIndex = api.indexOfRequest('POST', '/quiz/attempts/77/answers');
    expect(api.jsonBodyOf(answerIndex)['question_id'], 101);
    expect(api.jsonBodyOf(answerIndex)['answer'], 'opt_a');
    expect(api.jsonBodyOf(answerIndex)['time_taken_seconds'], 9);
    expect(api.headerOf(answerIndex, 'Idempotency-Key'), 'answer-77-101');
    expect(
      answer.correctOptionId,
      isEmpty,
      reason: 'grading is withheld until the results screen — no local grade',
    );

    // ── LEG 3 — economy: the reward is the server's, applied once ────────────
    api.onSequence('GET', '/economy/wallet', <FakeRoute>[
      FakeRoute.ok(<String, dynamic>{'coins': 100}),
      FakeRoute.ok(<String, dynamic>{'coins': 105}),
      FakeRoute.ok(<String, dynamic>{'coins': 105}),
    ]);

    final economy = EconomyRemoteDataSource(container.read(dioProvider));
    final before = await economy.getWallet();
    expect(before.coins, 100);

    final result = await quizApi.finishAttempt(
      attemptId,
      idempotencyKey: 'quiz-complete-77',
    );
    expect(result.totalQuestions, 1);
    expect(result.correctAnswers, 1);
    expect(result.totalCoinsEarned, 5);

    final after = await economy.getWallet();
    expect(
      after.coins,
      105,
      reason: 'the balance is read from the server, never incremented locally',
    );

    // The response to the completion was "lost"; the client retries with the
    // same key. The server replays the stored response instead of crediting a
    // second time, and the wallet stays at 105.
    final replay = await quizApi.finishAttempt(
      attemptId,
      idempotencyKey: 'quiz-complete-77',
    );
    expect(replay.totalCoinsEarned, 5);
    final walletAfterReplay = await economy.getWallet();
    expect(walletAfterReplay.coins, 105, reason: 'credit applied exactly once');

    final completionIndices = indicesOf('PUT', '/quiz/attempts/77/completion');
    expect(completionIndices, hasLength(2));
    for (final index in completionIndices) {
      expect(
        api.headerOf(index, 'Idempotency-Key'),
        'quiz-complete-77',
        reason: 'the retry must present the original completion key',
      );
    }

    // ── LEG 4 — battle: lobby → invite → accept ──────────────────────────────
    api
      ..on(
        'POST',
        '/quiz/battle-rooms',
        FakeRoute.ok(<String, dynamic>{
          'id': 501,
          'code': 'ABC123',
          'status': 'waiting',
          'mode': '1v1',
        }),
      )
      ..on(
        'POST',
        '/quiz/battle-rooms/501/invitations',
        FakeRoute.ok(<String, dynamic>{
          'notification_id': 900,
          'invitee_id': 8,
          'invitee_name': 'Sita',
        }),
      )
      ..on(
        'PUT',
        '/quiz/invitations/900/acceptance',
        FakeRoute.ok(<String, dynamic>{
          'id': 501,
          'code': 'ABC123',
          'status': 'active',
        }),
      );

    final battle = BattleRepositoryImpl(
      BattleRemoteDataSource(container.read(dioProvider)),
    );
    final lobby = await battle.createLobby(
      mode: '1v1',
      idempotencyKey: 'lobby-create-1',
    );
    expect(lobby.id, 501);
    expect(lobby.code, 'ABC123');

    final lobbyIndex = api.indexOfRequest('POST', '/quiz/battle-rooms');
    expect(api.jsonBodyOf(lobbyIndex)['mode'], '1v1');
    expect(api.jsonBodyOf(lobbyIndex)['queue_type'], 'unranked');
    expect(api.jsonBodyOf(lobbyIndex)['wager_coins'], 0);
    expect(api.headerOf(lobbyIndex, 'Idempotency-Key'), 'lobby-create-1');

    final invitation = await battle.inviteToLobby(
      lobbyId: lobby.id,
      email: 'sita@b.test',
      idempotencyKey: 'invite-900',
    );
    expect(invitation.notificationId, 900);
    expect(invitation.inviteeName, 'Sita');
    final inviteIndex = api.indexOfRequest(
      'POST',
      '/quiz/battle-rooms/501/invitations',
    );
    expect(api.jsonBodyOf(inviteIndex)['email'], 'sita@b.test');
    expect(api.headerOf(inviteIndex, 'Idempotency-Key'), 'invite-900');

    final accepted = await battle.acceptLobbyInvitation(
      notificationId: invitation.notificationId,
      idempotencyKey: 'accept-900',
    );
    expect(accepted.id, 501);
    expect(
      accepted.status,
      'active',
      reason: 'the lobby state machine belongs to the server, not the client',
    );
    final acceptIndex = api.indexOfRequest(
      'PUT',
      '/quiz/invitations/900/acceptance',
    );
    expect(api.headerOf(acceptIndex, 'Idempotency-Key'), 'accept-900');

    // ── LEG 5 — push + logout ────────────────────────────────────────────────
    api
      ..on(
        'DELETE',
        '/device-tokens/fcm-token-1',
        FakeRoute.ok(<String, dynamic>{'deleted': true}),
      )
      ..on(
        'POST',
        '/auth/logout',
        FakeRoute.ok(<String, dynamic>{}, message: 'Logged out'),
      );

    await authController.logout();

    final unregisterIndex = api.indexOfRequest(
      'DELETE',
      '/device-tokens/fcm-token-1',
    );
    expect(unregisterIndex, isNot(-1), reason: 'logout must delete the token');
    expect(
      api.headerOf(unregisterIndex, 'Authorization'),
      'Bearer pat-2',
      reason:
          'the DELETE is authenticated — it must run before the PAT is '
          'cleared, or the server refuses it and the device stays registered',
    );

    final logoutIndex = api.indexOfRequest('POST', '/auth/logout');
    expect(api.headerOf(logoutIndex, 'Authorization'), 'Bearer pat-2');
    expect(
      unregisterIndex,
      lessThan(logoutIndex),
      reason: 'unregister precedes the credential being revoked',
    );

    expect(stored.containsKey('auth_token'), isFalse);
    expect(
      await tenants.read(),
      isNull,
      reason: 'the organization selection dies with the session',
    );
  });
}
