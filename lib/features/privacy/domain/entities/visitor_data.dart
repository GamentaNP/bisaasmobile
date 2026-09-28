/// Anonymous visitor data — GDPR Art. 15/17 self-service.
///
/// ## Why the client never sends a visitor id
///
/// The server identifies an anonymous visitor by an HMAC-signed `_bs_vid` /
/// `_bs_ctx` cookie attached by the `personalization.context` middleware, and
/// the route comment is explicit: identity is "never by a request value the
/// client could forge". So there is deliberately **no visitor id parameter** on
/// any call below. Adding one would be both wrong and a forgery vector.
///
/// The consequence for a mobile client is that the cookie has to actually reach
/// the server, which is why the datasource documents the
/// `Set-Cookie`/cookie-jar requirement rather than pretending a header will do.
library;

import 'package:flutter/foundation.dart';

/// The consent mode the server holds for this anonymous visitor.
enum VisitorConsentMode {
  /// Default for a visitor who has not opted in. Intent events are accepted but
  /// answered `recorded: false` — not dropped silently, not an error.
  functional,

  /// The visitor opted in to analytics.
  analytics,

  /// The visitor withdrew consent. The affinity graph and stored event rows are
  /// deleted by the server on withdrawal.
  none;

  static VisitorConsentMode byName(String? name) {
    switch (name?.toLowerCase()) {
      case 'analytics':
        return VisitorConsentMode.analytics;
      case 'none':
        return VisitorConsentMode.none;
      case 'functional':
      default:
        // Unknown modes read as the most restrictive known state rather than as
        // an error: an unrecognised consent value must not be treated as opt-in.
        return VisitorConsentMode.functional;
    }
  }

  String get wireValue => switch (this) {
        VisitorConsentMode.analytics => 'analytics',
        VisitorConsentMode.functional => 'functional',
        VisitorConsentMode.none => 'none',
      };

  bool get grantsAnalytics => this == VisitorConsentMode.analytics;
}

/// What the server holds about this anonymous visitor.
@immutable
class VisitorData {
  const VisitorData({
    required this.visitorId,
    required this.consentMode,
    required this.eventCount,
    this.stitched = false,
  });

  /// Opaque server-issued identifier. Shown so a user can quote it in a privacy
  /// request; never sent back to the server.
  final String visitorId;
  final VisitorConsentMode consentMode;

  /// How many stored intent events exist. Zero with consent granted is a valid
  /// state and must not read as "nothing stored".
  final int eventCount;

  /// True when this anonymous profile has been stitched to a real account.
  ///
  /// When set, `DELETE /visitor-data` is refused with `ERASURE_REQUIRES_ACCOUNT`
  /// because the erasure then belongs to the account-level flow. The UI says so
  /// rather than offering a delete button that will 4xx.
  final bool stitched;

  bool get hasStoredData => eventCount > 0;

  bool get canEraseHere => !stitched;
}
