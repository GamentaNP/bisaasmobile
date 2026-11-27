import 'package:bisaasmobile/core/notifications/notification_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationHandler.safeRoute', () {
    test('allows first-party locations with ordinary query values', () {
      expect(NotificationHandler.safeRoute('/quiz'), '/quiz');
      expect(
        NotificationHandler.safeRoute('/quiz/attempt/12?mode=official'),
        '/quiz/attempt/12?mode=official',
      );
    });

    test('rejects reset-password and any credential-bearing payload', () {
      expect(
        NotificationHandler.safeRoute(
          '/reset-password?token=abc&email=victim@example.com',
        ),
        isNull,
      );
      expect(NotificationHandler.safeRoute('/quiz?token=abc'), isNull);
      expect(NotificationHandler.safeRoute('/battle?email=a@b.com'), isNull);
      expect(NotificationHandler.safeRoute('/quiz#token=abc'), isNull);
    });

    test('rejects foreign schemes, hosts and arbitrary paths', () {
      expect(NotificationHandler.safeRoute('javascript:alert(1)'), isNull);
      expect(
        NotificationHandler.safeRoute('https://evil.example/reset-password'),
        isNull,
      );
      expect(NotificationHandler.safeRoute('/admin/secret'), isNull);
      expect(NotificationHandler.safeRoute('https://lovemcq.com/quiz'), isNotNull);
      expect(NotificationHandler.safeRoute('lovemcq://quiz'), isNotNull);
      // Deprecated alias stays accepted for old push payloads.
      expect(NotificationHandler.safeRoute('civilcal://quiz'), isNotNull);
    });

    test('null and empty payloads stay null', () {
      expect(NotificationHandler.safeRoute(null), isNull);
      expect(NotificationHandler.safeRoute(''), isNull);
    });
  });
}
