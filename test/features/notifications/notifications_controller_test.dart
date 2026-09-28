import 'package:bisaasmobile/features/notifications/domain/notification_item.dart';
import 'package:bisaasmobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationsRemote extends Mock
    implements NotificationsRemoteDataSource {}

void main() {
  group('NotificationItem', () {
    test('parses the server envelope, reading title/body out of data', () {
      // Shape from NotificationController::$mapNotification.
      final item = NotificationItem.fromJson(const {
        'id': '7',
        'type': 'streak_risk',
        'data': {'title': 'Streak at risk', 'body': 'Answer today to keep it.'},
        'read_at': null,
        'created_at': '2026-09-28T10:00:00+00:00',
      });

      expect(item.id, '7');
      expect(item.type, 'streak_risk');
      expect(item.title, 'Streak at risk');
      expect(item.body, 'Answer today to keep it.');
      expect(item.isUnread, isTrue);
      expect(item.createdAt, isNotNull);
    });

    test('a read_at timestamp means read', () {
      final item = NotificationItem.fromJson(const {
        'id': '1',
        'type': 'x',
        'data': <String, dynamic>{},
        'read_at': '2026-09-28T11:00:00+00:00',
      });
      expect(item.isUnread, isFalse);
    });

    test('tolerates a missing data object instead of rendering blanks', () {
      final item = NotificationItem.fromJson(const {'id': '2', 'type': 'y'});
      expect(item.title, 'Notification');
      expect(item.body, isEmpty);
      expect(item.createdAt, isNull);
    });

    test('tolerates an unparseable timestamp', () {
      final item = NotificationItem.fromJson(const {
        'id': '3',
        'type': 'z',
        'created_at': 'not-a-date',
      });
      expect(item.createdAt, isNull);
      expect(item.isUnread, isTrue);
    });

    test('copyWith(markRead) stamps a read time', () {
      final item = NotificationItem.fromJson(const {'id': '4', 'type': 'a'});
      final read = item.copyWith(markRead: true);
      expect(read.isUnread, isFalse);
      expect(read.id, item.id);
      expect(read.title, item.title);
    });
  });

  group('NotificationsController', () {
    late MockNotificationsRemote remote;

    setUp(() => remote = MockNotificationsRemote());

    ProviderContainer containerWith(
      List<NotificationItem> items, {
      bool failMark = false,
    }) {
      when(remote.fetch).thenAnswer((_) async => items);
      if (failMark) {
        when(() => remote.markRead(any())).thenThrow(StateError('boom'));
        when(remote.markAllRead).thenThrow(StateError('boom'));
      } else {
        when(() => remote.markRead(any())).thenAnswer((_) async {});
        when(remote.markAllRead).thenAnswer((_) async {});
      }
      final c = ProviderContainer(
        overrides: [notificationsRemoteProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      return c;
    }

    NotificationItem unread(String id) => NotificationItem.fromJson({
          'id': id,
          'type': 't',
          'data': {'title': 'n$id'},
        });
    NotificationItem read(String id) => NotificationItem.fromJson({
          'id': id,
          'type': 't',
          'data': {'title': 'n$id'},
          'read_at': '2026-09-28T10:00:00+00:00',
        });

    test('loads the inbox', () async {
      final c = containerWith([unread('1'), read('2')]);
      final items = await c.read(notificationsControllerProvider.future);
      expect(items, hasLength(2));
      expect(items.where((n) => n.isUnread), hasLength(1));
    });

    test('markRead calls the server and updates the row', () async {
      final c = containerWith([unread('1'), read('2')]);
      await c.read(notificationsControllerProvider.future);

      await c.read(notificationsControllerProvider.notifier).markRead('1');

      verify(() => remote.markRead('1')).called(1);
      final after = c.read(notificationsControllerProvider).value!;
      expect(after.every((n) => !n.isUnread), isTrue);
    });

    test('markRead does not call the server for an already-read row', () async {
      final c = containerWith([read('2')]);
      await c.read(notificationsControllerProvider.future);

      await c.read(notificationsControllerProvider.notifier).markRead('2');

      verifyNever(() => remote.markRead(any()));
    });

    test('a failed markRead rolls the row back rather than lying', () async {
      final c = containerWith([unread('1')], failMark: true);
      await c.read(notificationsControllerProvider.future);

      await expectLater(
        c.read(notificationsControllerProvider.notifier).markRead('1'),
        throwsStateError,
      );

      // The optimistic update is reverted, so the inbox cannot claim a
      // notification was seen when the server still has it unread — which
      // would leave the /me badge permanently stuck.
      final after = c.read(notificationsControllerProvider).value!;
      expect(after.first.isUnread, isTrue);
    });

    test('markAllRead clears every row and calls the server once', () async {
      final c = containerWith([unread('1'), unread('2'), unread('3')]);
      await c.read(notificationsControllerProvider.future);

      await c.read(notificationsControllerProvider.notifier).markAllRead();

      verify(remote.markAllRead).called(1);
      final after = c.read(notificationsControllerProvider).value!;
      expect(after.every((n) => !n.isUnread), isTrue);
    });

    test('markAllRead is a no-op when nothing is unread', () async {
      final c = containerWith([read('1')]);
      await c.read(notificationsControllerProvider.future);

      await c.read(notificationsControllerProvider.notifier).markAllRead();

      verifyNever(remote.markAllRead);
    });

    test('a failed markAllRead rolls the whole list back', () async {
      final c = containerWith([unread('1'), unread('2')], failMark: true);
      await c.read(notificationsControllerProvider.future);

      await expectLater(
        c.read(notificationsControllerProvider.notifier).markAllRead(),
        throwsStateError,
      );

      final after = c.read(notificationsControllerProvider).value!;
      expect(after.every((n) => n.isUnread), isTrue);
    });
  });
}
