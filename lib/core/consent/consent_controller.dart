import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import '../storage/preferences.dart';
import 'consent_state.dart';

/// Owns the user's consent choices.
///
/// The local record is the one that gates collection, because the decision has
/// to be available on the very first frame, before any network call could
/// return. The server copy is reported for the audit trail and is allowed to
/// fail: refusing to record the choice locally because the network was down
/// would be the wrong trade, whereas losing the audit row is recoverable.
class ConsentController extends AsyncNotifier<ConsentState> {
  static const _storageKey = 'consent_state';

  @override
  Future<ConsentState> build() async {
    final raw = Preferences.instance.getString(_storageKey);
    if (raw == null) return const ConsentState.unknown();
    try {
      return ConsentState.fromStorage(jsonDecode(raw) as Map<String, Object?>);
    } catch (e) {
      // A corrupt record must not be read as consent. Fall back to unknown,
      // which blocks non-essential collection and re-shows the banner.
      AppLogger.w('consent record unreadable, treating as undecided: $e');
      return const ConsentState.unknown();
    }
  }

  /// Records the choice, persists it, then reports it.
  ///
  /// Order matters: persistence first so a network failure cannot lose the
  /// decision the user just made, and the banner does not reappear on next
  /// launch.
  Future<void> decide({
    required bool functional,
    required bool analytics,
    required bool marketing,
  }) async {
    final next = ConsentState(
      decided: true,
      functional: functional,
      analytics: analytics,
      marketing: marketing,
    );
    state = AsyncData(next);
    await Preferences.instance.setString(_storageKey, jsonEncode(next.toStorage()));
    await _report(next);
  }

  /// Revokes a single category without disturbing the others.
  Future<void> revoke(ConsentCategory category) async {
    if (category == ConsentCategory.necessary) return;
    final current = state.value ?? const ConsentState.unknown();
    final next = current.copyWith(
      functional: category != ConsentCategory.functional && current.functional,
      analytics: category != ConsentCategory.analytics && current.analytics,
      marketing: category != ConsentCategory.marketing && current.marketing,
    );
    state = AsyncData(next);
    await Preferences.instance.setString(_storageKey, jsonEncode(next.toStorage()));
    await _report(next);
  }

  Future<void> _report(ConsentState consent) async {
    try {
      await DioClient.instance.dio.put<Map<String, dynamic>>(
        '/public/cookie-consent',
        data: consent.toRequestBody(),
      );
    } on ApiException catch (e) {
      // Recorded locally, which is what actually gates collection. The server
      // copy is an audit artefact, so a failure here is logged and dropped
      // rather than surfaced as an error the user cannot act on.
      AppLogger.w('cookie-consent report failed: ${e.message}');
    } catch (e) {
      AppLogger.w('cookie-consent report failed: $e');
    }
  }
}

final consentProvider = AsyncNotifierProvider<ConsentController, ConsentState>(
  ConsentController.new,
);
