/// The server publishes notification actions as `action_url`; the client used
/// to read only `deep_link` / `route`, so every server-authored action fell
/// back to `/home`. These tests pin the key precedence and, crucially, route
/// every candidate through `NotificationHandler.safeRoute` before navigation.
library;

import 'dart:io';

import 'package:bisaasmobile/core/notifications/push_notification_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

void main() {
  group('safePushRoute', () {
    test('reads action_url first', () {
      expect(
        safePushRoute(<String, dynamic>{
          'action_url': '/quiz/attempt/12',
          'deep_link': '/home',
        }),
        '/quiz/attempt/12',
      );
    });

    test('falls back to deep_link, then route, for older payloads', () {
      expect(safePushRoute(<String, dynamic>{'deep_link': '/battle'}), '/battle');
      expect(safePushRoute(<String, dynamic>{'route': '/leaderboard'}), '/leaderboard');
      expect(safePushRoute(<String, dynamic>{}), isNull);
    });

    test('a rejected action_url is never replaced by a second candidate', () {
      // The first non-empty key wins. Try-later keys must not become a way
      // around the allowlist.
      expect(
        safePushRoute(<String, dynamic>{
          'action_url': '/reset-password?token=abc&email=victim@example.com',
          'deep_link': '/home',
        }),
        isNull,
      );
    });

    test('an unsafe host or foreign scheme is rejected', () {
      expect(
        safePushRoute(<String, dynamic>{
          'action_url': 'https://evil.example/quiz',
        }),
        isNull,
      );
      expect(
        safePushRoute(<String, dynamic>{'action_url': 'javascript:alert(1)'}),
        isNull,
      );
    });

    test('a non-string value is not treated as a route', () {
      expect(
        safePushRoute(<String, dynamic>{'action_url': 42}),
        isNull,
      );
    });
  });

  group('pushNavigationTarget', () {
    test('a validated action_url beats the type-based fallback', () {
      expect(
        pushNavigationTarget(<String, dynamic>{
          'type': 'quiz_reminder',
          'action_url': '/quiz/attempt/12',
        }),
        '/quiz/attempt/12',
      );
    });

    test('server-only types still fall back to a safe route', () {
      expect(
        pushNavigationTarget(<String, dynamic>{
          'type': 'achievement_unlocked',
        }),
        '/profile',
      );
      expect(
        pushNavigationTarget(<String, dynamic>{'type': 'streak_at_risk'}),
        '/home',
      );
    });

    test('a credential-bearing action_url cannot open the reset screen', () {
      // Even with a quiz type on the payload, the fallback must not become a
      // channel for the rejected URL.
      expect(
        pushNavigationTarget(<String, dynamic>{
          'type': 'quiz_reminder',
          'action_url': '/reset-password?token=abc&email=victim@example.com',
        }),
        '/quiz',
      );
    });
  });

  group('the service routes through the resolver', () {
    test('cold-start tap emits the validated action_url', () async {
      final messaging = _MockMessaging();
      // `requestPermission` and the static FCM streams are plugin-backed;
      // init() swallows any failure from them by design. Only the mocked
      // cold-start message matters here.
      when(messaging.getInitialMessage).thenAnswer(
        (_) async => const RemoteMessage(
          data: <String, dynamic>{'action_url': '/live-events'},
        ),
      );

      final service = PushNotificationService(messaging, Dio());
      final target = service.navigationRequests.first;
      await service.init();

      expect(await target, '/live-events');
    });

    test('both call sites use pushNavigationTarget', () {
      final source = File('lib/core/notifications/push_notification_service.dart')
          .readAsStringSync();
      expect(source, contains('payload: pushNavigationTarget(message.data)'));
      expect(source, contains('_nav.add(pushNavigationTarget(m.data))'));
    });
  });
}
