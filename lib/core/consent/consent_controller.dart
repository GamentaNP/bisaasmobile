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
  ///
  /// The in-progress build is awaited first. `build()` is async, so a decision
  /// recorded before it lands would be overwritten when it does — the local
  /// write and the report would both be for a choice the user had already
  /// moved on from.
  Future<void> decide({
    required bool functional,
    required bool analytics,
    required bool marketing,
  }) async {
    await _awaitBuild();
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
    await _awaitBuild();
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

  /// Waits for `build()` to finish if it is still in flight, without deadlocking
  /// when it is not.
  Future<void> _awaitBuild() async {
    if (state.isLoading) {
      await future;
    }
  }

  Future<void> _report(ConsentState consent) async {
    // The report is best-effort. Recording the choice locally is what actually
    // gates collection; the server copy is an audit artefact, so a failure here
    // is logged and dropped rather than surfaced as an error the user cannot act
    // on. It is also skipped entirely before bootstrap has built the client,
    // which is the case in tests and in any early-boot caller.
    if (!DioClient.isInitialized) {
      AppLogger.w('cookie-consent not reported: the network layer is not up yet');
      return;
    }
    try {
      await DioClient.instance.dio.put<Map<String, dynamic>>(
        '/public/cookie-consent',
        data: consent.toRequestBody(),
      );
    } on ApiException catch (e) {
      AppLogger.w('cookie-consent report failed: ${e.message}');
    } catch (e) {
      AppLogger.w('cookie-consent report failed: $e');
    }
  }
}

final consentProvider = AsyncNotifierProvider<ConsentController, ConsentState>(
  ConsentController.new,
);
