import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/app_update_gate.dart';
import 'package:bisaasmobile/core/network/install_identity_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

ApiException upgradeRequired({String min = '2.0.0', String? current = '1.4.0'}) {
  return ApiException(
    statusCode: 426,
    code: ApiErrorCode.upgradeRequired,
    message: 'This app version is no longer supported.',
    details: <String, dynamic>{
      'min_version': min,
      'platform': 'android',
      'current_version': current,
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('X-App-Version normalisation', () {
    // The server's EnforceAppVersion only judges /^\d+\.\d+\.\d+(-[\w.]+)?$/
    // and passes the request through when it does not match. An unparseable
    // header therefore disables the stale-client gate entirely.
    test('strips the leading v from a git tag', () {
      expect(InstallIdentityInterceptor.normaliseAppVersion('v1.2.3'), '1.2.3');
      expect(InstallIdentityInterceptor.normaliseAppVersion('V1.2.3'), '1.2.3');
    });

    test('drops the +build suffix the server regex rejects', () {
      expect(InstallIdentityInterceptor.normaliseAppVersion('1.2.3+45'), '1.2.3');
    });

    test('leaves a clean semver untouched', () {
      expect(InstallIdentityInterceptor.normaliseAppVersion('1.2.3'), '1.2.3');
    });

    test('preserves a prerelease suffix', () {
      expect(InstallIdentityInterceptor.normaliseAppVersion('v2.0.0-beta.1'), '2.0.0-beta.1');
    });

    test('trims surrounding whitespace', () {
      expect(InstallIdentityInterceptor.normaliseAppVersion(' 1.2.3 '), '1.2.3');
    });

    test('keeps an unparseable value rather than inventing one', () {
      // Empty means "no header", which the server deliberately allows through.
      // Anything better would be a guess.
      expect(InstallIdentityInterceptor.normaliseAppVersion(''), '');
      expect(InstallIdentityInterceptor.normaliseAppVersion('main'), 'main');
    });
  });

  group('ApiException 426', () {
    test('is recognised from the code', () {
      expect(upgradeRequired().isAppUpdateRequired, isTrue);
    });

    test('is recognised from the status even without the code', () {
      const e = ApiException(
        statusCode: 426,
        code: ApiErrorCode.unknown,
        message: 'nope',
      );
      expect(e.isAppUpdateRequired, isTrue);
    });

    test('a 403 is not a version problem', () {
      const e = ApiException(
        statusCode: 403,
        code: ApiErrorCode.unknown,
        message: 'forbidden',
      );
      expect(e.isAppUpdateRequired, isFalse);
    });

    test('exposes the minimum from details', () {
      expect(upgradeRequired(min: '3.1.4').minRequiredVersion, '3.1.4');
    });

    test('a missing minimum is null, not an empty string', () {
      const e = ApiException(
        statusCode: 426,
        code: ApiErrorCode.upgradeRequired,
        message: 'nope',
      );
      expect(e.minRequiredVersion, isNull);
    });

    test('parses the real server envelope', () {
      final e = ApiException.fromJson(426, {
        'error': {
          'code': 'UPGRADE_REQUIRED',
          'message': 'This app version is no longer supported.',
          'details': {'min_version': '2.5.0', 'platform': 'android'},
        },
      });
      expect(e.isAppUpdateRequired, isTrue);
      expect(e.minRequiredVersion, '2.5.0');
    });
  });

  group('AppUpdateGate', () {
    late AppUpdateGate gate;

    setUp(() => gate = AppUpdateGate());
    tearDown(() => gate.reset());

    test('starts unlocked', () {
      expect(gate.isBlocked, isFalse);
    });

    test('latches on a 426 and captures the details', () {
      gate.observe(upgradeRequired(min: '2.0.0', current: '1.4.0'));
      expect(gate.isBlocked, isTrue);
      expect(gate.minVersion, '2.0.0');
      expect(gate.currentVersion, '1.4.0');
      expect(gate.platform, 'android');
    });

    test('notifies listeners exactly once per distinct minimum', () {
      var notifications = 0;
      gate.addListener(() => notifications++);
      gate.observe(upgradeRequired(min: '2.0.0'));
      gate.observe(upgradeRequired(min: '2.0.0'));
      expect(notifications, 1);
    });

    test('ignores unrelated errors', () {
      const e = ApiException(
        statusCode: 500,
        code: ApiErrorCode.internalError,
        message: 'boom',
      );
      gate.observe(e);
      expect(gate.isBlocked, isFalse);
    });

    test('ignores a 426 with no usable minimum', () {
      // Without a minimum there is nothing to render, and blocking on an
      // unreadable payload would brick the app with no way forward.
      const e = ApiException(
        statusCode: 426,
        code: ApiErrorCode.upgradeRequired,
        message: 'nope',
      );
      gate.observe(e);
      expect(gate.isBlocked, isFalse);
    });

    test('stays latched — a later good response cannot unlock a bad build', () {
      gate.observe(upgradeRequired());
      gate.observe(
        const ApiException(
          statusCode: 200,
          code: ApiErrorCode.unknown,
          message: 'ok',
        ),
      );
      expect(gate.isBlocked, isTrue);
    });
  });

  group('StoreLinks', () {
    test('sends Android builds to Play', () {
      expect(
        StoreLinks.forPlatform(platform: 'android', fallback: TargetPlatform.android),
        contains('play.google.com'),
      );
    });

    test('sends iOS builds to the App Store', () {
      expect(
        StoreLinks.forPlatform(platform: 'ios', fallback: TargetPlatform.iOS),
        contains('apps.apple.com'),
      );
    });

    test('falls back to the running platform when the server sent none', () {
      expect(
        StoreLinks.forPlatform(fallback: TargetPlatform.iOS),
        contains('apps.apple.com'),
      );
    });
  });
}
