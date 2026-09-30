import 'package:bisaasmobile/app/config/api_config.dart';
import 'package:bisaasmobile/shared/widgets/cached_remote_image.dart';
import 'package:flutter_test/flutter_test.dart';

/// Image URLs come from the database, not from code.
///
/// A row can name any host on the internet. Left unchecked, every app launch
/// becomes a beacon to that host — it learns the user's IP, device and roughly
/// when they open the app, and a third party can read "who opened the app" off
/// request logs. That is a privacy leak the app does not currently have, and
/// the check is the reason it does not.
void main() {
  final apiHost = Uri.parse(ApiConfig.baseUrl).host;

  group('allowed', () {
    test('the API host itself', () {
      expect(
        RemoteImagePolicy.isAllowed('https://$apiHost/storage/banner.png'),
        isTrue,
      );
    });

    test('http on the API host, for local dev against Laragon', () {
      expect(
        RemoteImagePolicy.isAllowed('http://$apiHost/banner.png'),
        isTrue,
        reason: 'the dev backend is plain http and cleartext is already gated by '
            'the network security config',
      );
    });
  });

  group('blocked', () {
    test('a third-party host', () {
      expect(
        RemoteImagePolicy.isAllowed('https://evil.example.com/track.gif'),
        isFalse,
      );
    });

    test('a host that merely contains the api host as a prefix', () {
      // The classic allowlist bypass: "bisaas.com.attacker.net".
      expect(
        RemoteImagePolicy.isAllowed('https://$apiHost.attacker.net/x.png'),
        isFalse,
      );
      expect(
        RemoteImagePolicy.isAllowed('https://not$apiHost/x.png'),
        isFalse,
      );
    });

    test('a look-alike host', () {
      expect(
        RemoteImagePolicy.isAllowed('https://$apiHost.co/x.png'),
        isFalse,
      );
    });

    test('non-http schemes', () {
      expect(RemoteImagePolicy.isAllowed('file:///etc/passwd'), isFalse);
      expect(RemoteImagePolicy.isAllowed('javascript:alert(1)'), isFalse);
      expect(RemoteImagePolicy.isAllowed('data:image/png;base64,AAAA'), isFalse);
    });

    test('malformed and empty input', () {
      expect(RemoteImagePolicy.isAllowed(null), isFalse);
      expect(RemoteImagePolicy.isAllowed(''), isFalse);
      expect(RemoteImagePolicy.isAllowed('not a url at all'), isFalse);
    });
  });

  group('extra hosts', () {
    test('are empty unless the build opts in', () {
      // Nothing is populated in the database today, so there is no CDN to
      // accommodate. The override is a --dart-define so a host cannot be added
      // at runtime by whoever controls the settings table.
      expect(RemoteImagePolicy.extraHosts, isEmpty);
    });
  });
}
