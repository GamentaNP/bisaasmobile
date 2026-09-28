/// Consent state — GDPR/ePrivacy.
///
/// Bisaas operates worldwide, so consent is a legal requirement, not a nicety.
/// The important property is not the banner: it is that **non-essential
/// collection does not happen until the user has agreed**. A banner that records
/// a choice after analytics has already been sending events is decoration.
///
/// [ConsentCategory.necessary] is always granted. It covers what the app cannot
/// function without — auth tokens, the local database, crash handling — and is
/// deliberately not switchable, because a user who refused it could not use the
/// product and the UI would only be lying about what happens next.
library;

import 'package:flutter/foundation.dart';

enum ConsentCategory {
  /// Cannot be refused. Auth, local storage, crash diagnostics.
  necessary,

  /// Preferences that are not needed for the core product: reduced motion,
  /// remembered filters, language choice.
  functional,

  /// Usage analytics: Firebase Analytics events, funnel tracking.
  analytics,

  /// Advertising and cross-context promotion.
  marketing;

  static ConsentCategory? byName(String name) {
    for (final c in ConsentCategory.values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// The user's recorded choices.
///
/// [decided] separates "the user said no" from "we have not asked yet". Both
/// block non-essential collection, but only one may be reported to the server,
/// and only one should show the banner.
@immutable
class ConsentState {
  const ConsentState({
    this.decided = false,
    this.functional = false,
    this.analytics = false,
    this.marketing = false,
  });

  /// No choice recorded yet. Non-essential categories are treated as refused.
  final bool decided;
  final bool functional;
  final bool analytics;
  final bool marketing;

  /// Defaults to the most restrictive state: nothing granted, not yet decided.
  ///
  /// This is the whole point. If a read of this class happens before the banner
  /// is shown, the answer is still "no".
  const ConsentState.unknown()
      : decided = false,
        functional = false,
        analytics = false,
        marketing = false;

  bool granted(ConsentCategory category) => switch (category) {
        ConsentCategory.necessary => true,
        ConsentCategory.functional => functional,
        ConsentCategory.analytics => analytics,
        ConsentCategory.marketing => marketing,
      };

  /// Payload for `PUT /api/v1/public/cookie-consent`.
  ///
  /// The server's request class requires `analytics` and accepts `marketing` and
  /// `functional` as `sometimes`. Sending all three explicitly means a retry
  /// re-affirms the same choice rather than toggling it, which is why the route
  /// is a PUT with a target and not a toggle.
  Map<String, bool> toRequestBody() => {
        'analytics': analytics,
        'marketing': marketing,
        'functional': functional,
      };

  ConsentState copyWith({
    bool? decided,
    bool? functional,
    bool? analytics,
    bool? marketing,
  }) {
    return ConsentState(
      decided: decided ?? this.decided,
      functional: functional ?? this.functional,
      analytics: analytics ?? this.analytics,
      marketing: marketing ?? this.marketing,
    );
  }

  Map<String, dynamic> toStorage() => {
        'decided': decided,
        'functional': functional,
        'analytics': analytics,
        'marketing': marketing,
      };

  /// Tolerant of a partial or corrupt stored value: an unparseable entry falls
  /// back to "not granted" rather than to granted.
  factory ConsentState.fromStorage(Map<String, Object?>? raw) {
    if (raw == null) return const ConsentState.unknown();
    bool flag(String key) => raw[key] == true;
    return ConsentState(
      decided: flag('decided'),
      functional: flag('functional'),
      analytics: flag('analytics'),
      marketing: flag('marketing'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConsentState &&
      other.decided == decided &&
      other.functional == functional &&
      other.analytics == analytics &&
      other.marketing == marketing;

  @override
  int get hashCode => Object.hash(decided, functional, analytics, marketing);
}
