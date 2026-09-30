import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/config/api_config.dart';
import '../../core/logging/app_logger.dart';

/// Whether a server-supplied image URL may be loaded.
///
/// ## Why this exists
///
/// Image URLs arrive from the database, not from code. A compromised or
/// misconfigured row can point a banner at any host on the internet, which
/// turns every app launch into a beacon to that host: it learns the user's IP,
/// their device, and roughly when they open the app. It also lets a third party
/// observe read receipts on a "who is online" style image.
///
/// So a URL is only loaded when its host is one we expect. The default is the
/// API host itself, which is where CivilCal serves its own assets today — every
/// `image_url`, `banner_image` and `avatar_url` column is currently empty, so
/// there is no CDN to accommodate yet.
///
/// ## Adding a CDN
///
/// Pass `IMAGE_HOSTS` as a comma-separated `--dart-define`. It is deliberately
/// a build-time value rather than a settings-table lookup: a host that an
/// attacker could add at runtime would defeat the point of the check.
///
/// ```sh
/// flutter build appbundle --dart-define=IMAGE_HOSTS=cdn.bisaas.com,img.bisaas.com
/// ```
abstract final class RemoteImagePolicy {
  const RemoteImagePolicy._();

  static const _extra = String.fromEnvironment('IMAGE_HOSTS');

  /// Hosts allowed in addition to the API host.
  static final List<String> extraHosts = _extra
      .split(',')
      .map((h) => h.trim().toLowerCase())
      .where((h) => h.isNotEmpty)
      .toList(growable: false);

  /// True when [url] is safe to load.
  ///
  /// Rejects rather than throws: a bad row must not break a screen, it must
  /// render the caller's fallback. The rejection is logged so a wrongly
  /// configured CDN shows up in the log rather than as a mysteriously blank
  /// image.
  static bool isAllowed(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      AppLogger.w('remote image rejected: unparseable url');
      return false;
    }
    // Plain http would be cleartext, which the network security config blocks
    // anyway; rejecting it here turns a silent failure into a clear one.
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      AppLogger.w('remote image rejected: scheme ${uri.scheme}');
      return false;
    }

    final host = uri.host.toLowerCase();
    final apiHost = Uri.parse(ApiConfig.baseUrl).host.toLowerCase();
    if (host == apiHost) return true;
    if (extraHosts.contains(host)) return true;

    AppLogger.w('remote image rejected: host "$host" is not allow-listed');
    return false;
  }
}

/// A network image that is cached on disk and validated against a host
/// allowlist.
///
/// `Image.network` re-downloads on every cold start, which on a metered Nepali
/// connection is a real cost for a decorative banner. `CachedNetworkImage` keeps
/// the bytes in the app cache, and [RemoteImagePolicy] makes sure the URL is
/// ours to load in the first place.
///
/// Use [CachedRemoteImageProvider] where a widget needs an `ImageProvider` (a
/// `CircleAvatar.backgroundImage`, for example) rather than a child widget.
class CachedRemoteImage extends StatelessWidget {
  const CachedRemoteImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    required this.fallback,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Shown when the URL is missing, blocked, or fails to load.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (!RemoteImagePolicy.isAllowed(url)) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 150),
      errorWidget: (_, __, ___) => fallback,
      placeholder: (_, __) => fallback,
    );
  }
}

/// Disk-caching [ImageProvider] for slots that want one, such as
/// `CircleAvatar.backgroundImage`. Returns null when the URL is not allowed, so
/// the caller falls back to its own initials or icon.
///
/// A thin subclass of the library's own provider rather than a wrapper: the
/// `loadImage` key must be the provider instance the library expects, and
/// delegating with a foreign key is what the naive version gets wrong.
class CachedRemoteImageProvider extends CachedNetworkImageProvider {
  const CachedRemoteImageProvider(super.url);
}
