import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/visitor_data.dart';

/// Anonymous personalization routes, verified against
/// `routes/api/v1/personalization.php` in `C:\laragon\www\bisaas`.
///
/// Deliberately OUTSIDE `auth:sanctum` — the whole point is a first-time
/// visitor with no account. The group carries
/// `personalization.context`, which attaches the HMAC-signed `_bs_vid` / `_bs_ctx`
/// cookies that identify the visitor.
///
/// - GET    /recommendations        ranked calculators for an anonymous visitor
/// - POST   /visitor-events         one intent interaction (Idempotency-Key)
/// - PUT    /visitor-consent        grant or withdraw analytics consent
/// - GET    /visitor-data           Art. 15 access
/// - DELETE /visitor-data           Art. 17 erasure (no key; idempotent by design)
///
/// Two contract details that are easy to get wrong:
///
/// **No visitor id is ever sent.** Identity comes from the signed cookie, not
/// from a request value, so every method here takes no identity parameter. Adding
/// one would be a forgery vector the server deliberately avoids.
///
/// **`DELETE /visitor-data` takes no Idempotency-Key.** Erasure is already
/// idempotent by construction, and the route comment is explicit that a retry
/// must re-read the same outcome rather than error. Sending a key would be
/// harmless but the omission is the contract.
class PrivacyRemoteDataSource {
  const PrivacyRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  /// Reads what the server holds about this anonymous visitor.
  ///
  /// Returns null when the response had no visitor id, which means "not
  /// understood" rather than "nothing stored" — the two are shown differently.
  Future<VisitorData?> getVisitorData() async {
    final res = await _dio.get<Map<String, dynamic>>('/visitor-data');
    final body = res.data;
    if (body == null) return null;
    final data = body['data'];
    final map = data is Map<String, dynamic> ? data : body;
    final id = map['visitor_id'];
    if (id is! String || id.isEmpty) return null;
    final events = map['events'];
    return VisitorData(
      visitorId: id,
      consentMode: VisitorConsentMode.byName(map['consent_mode'] as String?),
      eventCount: events is List ? events.length : 0,
      stitched: map['stitched'] == true,
    );
  }

  /// Grants or withdraws analytics consent for the anonymous profile.
  ///
  /// PUT with an explicit boolean, never a toggle, so a retry re-affirms the same
  /// choice. Withdrawal also deletes the affinity graph and the stored event rows
  /// server-side.
  Future<VisitorConsentMode> setVisitorConsent({required bool analytics}) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/visitor-consent',
      data: {'analytics': analytics},
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final body = res.data;
    final data = body?['data'];
    if (data is Map && data['consent_mode'] is String) {
      return VisitorConsentMode.byName(data['consent_mode'] as String);
    }
    return analytics ? VisitorConsentMode.analytics : VisitorConsentMode.none;
  }

  /// Erases the anonymous profile (Art. 17).
  ///
  /// Throws [ErasureRequiresAccount] when the profile is stitched to a real
  /// account, because that erasure belongs to the account-level flow. Callers
  /// check [VisitorData.canEraseHere] first so the button is not offered, but
  /// the state can change server-side between the read and the delete.
  Future<void> eraseVisitorData() async {
    await DioClient.instance.dio.delete<void>('/visitor-data');
  }

  /// Records one anonymous intent interaction.
  ///
  /// Returns true when the server actually stored it. A visitor in the default
  /// FUNCTIONAL mode is answered `202 recorded: false` — not an error and not a
  /// silent drop — so a client that treats false as failure would be wrong.
  Future<bool> recordVisitorEvent({
    required String event,
    String? subject,
    int? subjectId,
  }) async {
    try {
      final res = await DioClient.instance.dio.post<Map<String, dynamic>>(
        '/visitor-events',
        data: {
          'event': event,
          'subject': ?subject,
          'subject_id': ?subjectId,
        },
        options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
      );
      final body = res.data;
      final data = body?['data'];
      if (data is Map && data.containsKey('recorded')) {
        return data['recorded'] == true;
      }
      // A 202 with no flag is treated as not stored. Defaulting to true would
      // claim a record the server did not confirm.
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Thrown when the server refuses an anonymous erasure because the profile is
/// stitched to an account.
class ErasureRequiresAccount implements Exception {
  const ErasureRequiresAccount();
  @override
  String toString() => 'Erasure requires the account-level flow.';
}
