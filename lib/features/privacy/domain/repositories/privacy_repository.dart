import '../entities/visitor_data.dart';

/// GDPR Art. 15/17 self-service for the anonymous visitor profile.
///
/// No method takes a visitor id: the server identifies the visitor from its
/// signed cookie, and asking the client for an id would be a forgery vector.
abstract class PrivacyRepository {
  /// `GET /visitor-data`. Null means the payload had no visitor id (not the
  /// same as "nothing stored"); a failure throws.
  Future<VisitorData?> getVisitorData();

  /// `PUT /visitor-consent` - an explicit choice, never a toggle.
  Future<VisitorConsentMode> setVisitorConsent({required bool analytics});

  /// `DELETE /visitor-data` - Art. 17 erasure (no idempotency key by contract).
  Future<void> eraseVisitorData();

  /// `POST /visitor-events` - returns whether the server actually stored it;
  /// a `recorded: false` answer is normal in the default consent mode.
  Future<bool> recordVisitorEvent({
    required String event,
    String? subject,
    int? subjectId,
  });
}
