/// Cross-layer test for the device-token contract.
///
/// `POST /api/v1/device-tokens` and `DELETE /api/v1/device-tokens/{token}`
/// are named in the API guide, and `PushNotificationService` is the only
/// thing that calls them. The service had no test at all — every one of its
/// 95 lines was uncovered — so a change to the request shape would have
/// shipped without anything noticing.
///
/// The failure mode it also pins is the one that shipped: on a device with
/// no working Play Services, `getToken()` throws a `PlatformException`,
/// and an uncaught one takes down the login flow. Observed live on a
/// Redmi 6A: "[firebase_messaging/unknown] java.io.IOException: FCM
/// Registration failed!".
library;

import 'package:bisaasmobile/core/notifications/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_api.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late _MockMessaging messaging;

  setUp(() {
    messaging = _MockMessaging();
  });

  group('the device-token contract', () {
    test('the token is registered with the platform the app runs on', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/device-tokens',
        FakeRoute.ok(<String, dynamic>{'registered': true}),
      );

      when(() => messaging.getToken()).thenAnswer((_) async => 'tok-abc');

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await PushNotificationService(messaging, dioFor(api)).registerToken();

      final body = api.jsonBodyOf(0);
      expect(body['token'], 'tok-abc');
      expect(body['platform'], 'android');
    });

    test('the platform follows the build, not the test host', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/device-tokens',
        FakeRoute.ok(<String, dynamic>{'registered': true}),
      );

      when(() => messaging.getToken()).thenAnswer((_) async => 'tok-abc');

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await PushNotificationService(messaging, dioFor(api)).registerToken();

      expect(api.jsonBodyOf(0)['platform'], 'ios');
    });

    test('a device without Play Services does not break the login flow', () async {
      // The bug this pins: `getToken()` throws, and an uncaught exception
      // escaped into the root zone on every login on a device with no
      // working Play Services.
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/device-tokens',
        FakeRoute.ok(<String, dynamic>{'registered': true}),
      );

      when(() => messaging.getToken()).thenThrow(
        PlatformException(code: 'unknown', message: 'FCM Registration failed!'),
      );

      // No exception must escape: push is optional, the rest of the app has
      // to carry on.
      await expectLater(
        PushNotificationService(messaging, dioFor(api)).registerToken(),
        completes,
      );

      // And nothing was registered, because there was no token to register.
      expect(api.requests, isEmpty);
    });

    test('an empty token is not registered', () async {
      final api = FakeApi(<String, FakeRoute>{});
      when(() => messaging.getToken()).thenAnswer((_) async => '');

      await PushNotificationService(messaging, dioFor(api)).registerToken();

      expect(api.requests, isEmpty);
    });

    test('signing out deletes the token by path', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'DELETE',
        '/device-tokens/tok-abc',
        FakeRoute.ok(<String, dynamic>{'deleted': true}),
      );

      when(() => messaging.getToken()).thenAnswer((_) async => 'tok-abc');
      when(() => messaging.deleteToken()).thenAnswer((_) async {});

      await PushNotificationService(messaging, dioFor(api)).unregisterToken();

      expect(
        api.indexOfRequest('DELETE', '/device-tokens/tok-abc'),
        isNot(-1),
        reason: 'the guide names DELETE /device-tokens/{token}',
      );
      // The FCM token itself is destroyed locally too, so the next login
      // gets a fresh one rather than a token the server no longer knows.
      verify(() => messaging.deleteToken()).called(1);
    });

    test('a server that does not know the path still gets the token', () async {
      // The fallback the guide allows: the body form of the same route.
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'DELETE',
        '/device-tokens',
        FakeRoute.ok(<String, dynamic>{'deleted': true}),
      );
      // The path form is deliberately not registered, so it answers 404.

      when(() => messaging.getToken()).thenAnswer((_) async => 'tok-abc');
      when(() => messaging.deleteToken()).thenAnswer((_) async {});

      await PushNotificationService(messaging, dioFor(api)).unregisterToken();

      final body = api.jsonBodyOf(api.indexOfRequest('DELETE', '/device-tokens'));
      expect(body['token'], 'tok-abc');
    });

    test('a token with URL-unsafe characters is encoded in the path', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'DELETE',
        '/device-tokens/a%2Fb%3Dc',
        FakeRoute.ok(<String, dynamic>{'deleted': true}),
      );

      when(() => messaging.getToken()).thenAnswer((_) async => 'a/b=c');
      when(() => messaging.deleteToken()).thenAnswer((_) async {});

      await PushNotificationService(messaging, dioFor(api)).unregisterToken();

      expect(api.indexOfRequest('DELETE', '/device-tokens/a%2Fb%3Dc'), isNot(-1));
    });
  });
}
