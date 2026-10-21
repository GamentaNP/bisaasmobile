/// Cross-layer test for the authentication contract.
///
/// Every route in this file is named in the API guide, and the shapes are
/// the ones the server actually accepts:
///
///   * `POST /api/v1/auth/login`
///   * `POST /api/v1/auth/register`
///   * `POST /api/v1/auth/refresh`            (single-use rotation)
///   * `POST /api/v1/auth/social/{google,apple}`
///   * `POST /api/v1/auth/forgot-password`
///   * `POST /api/v1/auth/reset-password`
///   * `POST /api/v1/auth/change-password`
///   * `POST /api/v1/auth/email/verification-notification`
///   * `GET  /api/v1/me`
///
/// Two details in here are the ones that break silently:
///
///   * `password_confirmation` is snake_case on the wire, and a client that
///     sends `passwordConfirmation` gets a 422 that reads like a password
///     rule violation.
///   * a 401 on `GET /me` means *signed out*, but a 500 or a dropped
///     connection does not — reporting those as "signed out" dumps the user
///     on the login screen every time the network hiccups.
library;

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _authPayload({String token = 'pat-123'}) => <String, dynamic>{
      'token': token,
      'token_type': 'Bearer',
      'expires_at': '2026-11-01T00:00:00+00:00',
      'user': <String, dynamic>{
        'id': 7,
        'name': 'Bishwo',
        'email': 'a@b.test',
      },
    };

void main() {
  group('the login contract', () {
    test('the credentials and the device name reach the server', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/login', FakeRoute.ok(_authPayload()));

      final remote = AuthRemoteDataSource(dioFor(api));
      final response = await remote.login(
        email: 'a@b.test',
        password: 'secret123',
        deviceName: 'Redmi 6A',
      );

      expect(response.token, 'pat-123');
      expect(response.user?.email, 'a@b.test');

      final body = api.jsonBodyOf(0);
      expect(body['email'], 'a@b.test');
      expect(body['password'], 'secret123');
      // The device name is what the server binds the session to, so a
      // refresh can tell "this phone" from "another phone".
      expect(body['device_name'], 'Redmi 6A');
    });

    test('a rejected password carries the server error, not a generic one', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/auth/login',
        FakeRoute.error(422, 'VALIDATION_ERROR', 'The email is not valid.'),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      await expectLater(
        remote.login(email: 'nope', password: 'x', deviceName: 'd'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.code, 'code', ApiErrorCode.validationError),
        ),
      );
    });

    test('a 2xx with no data is a failure, not an empty session', () async {
      // The envelope says `success: true` but carries no session. Treating
      // that as "signed in with nothing" would leave the app in a state it
      // cannot use.
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/auth/login',
        FakeRoute.envelope(<String, dynamic>{
          'success': true,
          'data': null,
          'message': 'no session',
        }),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      await expectLater(
        remote.login(email: 'a@b.test', password: 'x', deviceName: 'd'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('the registration contract', () {
    test('the confirmation is sent snake_case', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/register', FakeRoute.ok(_authPayload()));

      final remote = AuthRemoteDataSource(dioFor(api));
      await remote.register(
        name: 'Bishwo',
        email: 'a@b.test',
        password: 'secret123',
        passwordConfirmation: 'secret123',
        deviceName: 'Redmi 6A',
      );

      final body = api.jsonBodyOf(0);
      expect(body['name'], 'Bishwo');
      expect(body['email'], 'a@b.test');
      expect(body['password'], 'secret123');
      // The server's `confirmed` rule reads `password_confirmation`. A client
      // that sends the Dart spelling gets a 422 that looks like a password
      // policy error.
      expect(body['password_confirmation'], 'secret123');
      expect(body['device_name'], 'Redmi 6A');
    });
  });

  group('the refresh contract', () {
    test('the device name travels in the header', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/refresh', FakeRoute.ok(_authPayload(token: 'pat-rotated')));

      final remote = AuthRemoteDataSource(dioFor(api));
      final response = await remote.refresh(deviceName: 'Redmi 6A');

      // The rotation is single-use: the server hands back a new PAT and
      // invalidates the old one.
      expect(response.token, 'pat-rotated');
      expect(
        api.requests.first.headers['X-Device-Name'],
        'Redmi 6A',
      );
    });

    test('a used-up token is a failure the app can act on', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/auth/refresh',
        FakeRoute.error(401, 'UNAUTHENTICATED', 'Token already used.'),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      await expectLater(
        remote.refresh(deviceName: 'Redmi 6A'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('the current-user contract', () {
    test('a 401 means signed out', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'GET',
        '/me',
        FakeRoute.error(401, 'UNAUTHENTICATED', 'Unauthenticated.'),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      expect(await remote.getCurrentUser(), isNull);
    });

    test('a server error is not a sign-out', () async {
      // This is the distinction the code documents: an *unknown* failure must
      // not be reported as "nobody is signed in", or the user is dumped on
      // the login screen every time the network hiccups.
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'GET',
        '/me',
        FakeRoute.error(500, 'SERVER_ERROR', 'Boom.'),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      await expectLater(
        remote.getCurrentUser(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('the social sign-in contract', () {
    test('the Google id_token is posted to the google route', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/social/google', FakeRoute.ok(_authPayload()));

      final remote = AuthRemoteDataSource(dioFor(api));
      final response = await remote.loginWithGoogle(idToken: 'goog-id-token');

      expect(response.token, 'pat-123');
      expect(api.jsonBodyOf(0)['id_token'], 'goog-id-token');
    });

    test('the Apple name is forwarded only when the platform gave one', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/social/apple', FakeRoute.ok(_authPayload()));

      final remote = AuthRemoteDataSource(dioFor(api));

      await remote.loginWithApple(idToken: 'apple-id-token', name: 'Bishwo K');
      expect(api.jsonBodyOf(0)['name'], 'Bishwo K');

      // Apple returns the name only on the very first authorisation, so the
      // field is usually absent.
      await remote.loginWithApple(idToken: 'apple-id-token');
      expect(api.jsonBodyOf(1).containsKey('name'), isFalse);

      // A blank name is not a name.
      await remote.loginWithApple(idToken: 'apple-id-token', name: '   ');
      expect(api.jsonBodyOf(2).containsKey('name'), isFalse);
    });

    test('a rejected social token is reported as a social failure', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/auth/social/google',
        FakeRoute.error(401, 'AUTH_SOCIAL_FAILED', 'Token rejected.'),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      await expectLater(
        remote.loginWithGoogle(idToken: 'bad'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('the password-recovery contract', () {
    test('the forgot-password request carries the email', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/forgot-password', FakeRoute.ok(<String, dynamic>{}));

      final remote = AuthRemoteDataSource(dioFor(api));
      await remote.forgotPassword(email: 'a@b.test');

      expect(api.jsonBodyOf(0)['email'], 'a@b.test');
    });

    test('a reset sends the token, the email and both password fields', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/reset-password', FakeRoute.ok(<String, dynamic>{}));

      final remote = AuthRemoteDataSource(dioFor(api));
      await remote.resetPassword(
        token: 'tok-123',
        email: 'a@b.test',
        password: 'secret123',
        passwordConfirmation: 'secret123',
      );

      final body = api.jsonBodyOf(0);
      expect(body['token'], 'tok-123');
      expect(body['email'], 'a@b.test');
      expect(body['password'], 'secret123');
      expect(body['password_confirmation'], 'secret123');
    });

    test('a bad reset token is a 422, not a 401', () async {
      // The broker reports `passwords.user` that way, and the client must
      // not turn a bad token into "you are signed out".
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/auth/reset-password',
        FakeRoute.error(422, 'VALIDATION_ERROR', 'The token is invalid.'),
      );

      final remote = AuthRemoteDataSource(dioFor(api));

      await expectLater(
        remote.resetPassword(
          token: 'bad',
          email: 'a@b.test',
          password: 'secret123',
          passwordConfirmation: 'secret123',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('a change carries the current password as well', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on('POST', '/auth/change-password', FakeRoute.ok(<String, dynamic>{}));

      final remote = AuthRemoteDataSource(dioFor(api));
      await remote.changePassword(
        currentPassword: 'old-secret',
        password: 'new-secret',
        passwordConfirmation: 'new-secret',
      );

      final body = api.jsonBodyOf(0);
      expect(body['current_password'], 'old-secret');
      expect(body['password'], 'new-secret');
      expect(body['password_confirmation'], 'new-secret');
    });
  });

  group('the email-verification contract', () {
    test('the resend is a POST to the named route', () async {
      final api = FakeApi(<String, FakeRoute>{});
      api.on(
        'POST',
        '/auth/email/verification-notification',
        FakeRoute.ok(<String, dynamic>{}),
      );

      final remote = AuthRemoteDataSource(dioFor(api));
      await remote.resendVerificationEmail();

      expect(
        api.indexOfRequest('POST', '/auth/email/verification-notification'),
        isNot(-1),
      );
    });
  });
}
