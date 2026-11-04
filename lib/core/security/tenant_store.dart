/// The organization ("tenant") a user has explicitly selected on this device.
///
/// ## What this is, and what it is not
///
/// The server treats the tenant as a property of the **credential**
/// (`App\Http\Middleware\EnforceTenantScope`): login and refresh stamp the
/// token with the user's single active membership, or with nothing when the
/// user belongs to several organizations. `X-Tenant` is only an **assertion**
/// — the server 403s `TENANT_MISMATCH` when it disagrees with the credential,
/// and resolves it only for a bearer client whose membership backs the value.
///
/// So the client never *chooses* a scope. It remembers a scope the user
/// selected, sends it as an assertion, and treats a mismatch as "this session
/// no longer matches the organization you picked" — never as a hint to retry
/// without the header.
///
/// ## Storage rules (same as `TokenManager`)
///
/// * `flutter_secure_storage` only — never `SharedPreferences`. A tenant id is
///   not a secret, but it is session state, and splitting session state across
///   two stores means logout can clear one and leave the other.
/// * Never logged, never sent to analytics. The id itself is harmless; the
///   association between a device and an organization is not.
/// * Cleared on logout, account deletion, and on `TENANT_MISMATCH`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Why the last request was refused in tenant terms.
///
/// The app distinguishes these from a generic 403 because the remedy is
/// different: a mismatch means "sign in again", an inactive organization means
/// "this workspace is closed" and re-authenticating changes nothing.
enum TenantFailure {
  /// The credential and the assertion disagree, or the asserted membership is
  /// gone. Only a fresh login can resolve it.
  mismatch,

  /// The organization exists but is no longer active.
  inactive,
}

class TenantStore extends ChangeNotifier {
  TenantStore({FlutterSecureStorage? storage})
      : _s = storage ?? const FlutterSecureStorage();

  /// Process-wide instance, mirroring `TokenManager.shared`. One secure
  /// storage, one selection, one source for every request in the Dio chain.
  static final TenantStore shared = TenantStore();

  static const _kTenantId = 'selected_tenant_id';

  final FlutterSecureStorage _s;

  /// The last decoded value, so the interceptor does not hit the platform
  /// channel on every request. Kept in lockstep with the persisted value by
  /// [select] and [clear]; the first read after a cold start still goes to the
  /// store.
  int? _cached;
  bool _loaded = false;

  /// The failure the server last reported, or null.
  ///
  /// In memory only: a mismatch that is not acted on before the app is killed
  /// simply re-surfaces on the next request, because the selection is gone and
  /// a multi-organization user still has no credential stamp. Persisting it
  /// would make a one-off refusal sticky across launches.
  TenantFailure? get failure => _failure;
  TenantFailure? _failure;

  /// The selected organization id, or null when the user has not selected one.
  ///
  /// A stored value that is not a positive integer is treated as absent
  /// rather than forwarded: the server answers 400 for a non-numeric assertion
  /// (`EnforceTenantScope`), which would turn a corrupt local value into a
  /// permanently broken session.
  Future<int?> read() async {
    if (_loaded) return _cached;
    final raw = await _s.read(key: _kTenantId);
    final parsed = int.tryParse(raw ?? '');
    _cached = (parsed != null && parsed > 0) ? parsed : null;
    _loaded = true;
    return _cached;
  }

  /// Records an explicit selection.
  ///
  /// Persisted before it is announced, so a listener that navigates
  /// immediately cannot race a write that has not landed.
  Future<void> select(int tenantId) async {
    if (tenantId <= 0) {
      throw ArgumentError.value(
        tenantId,
        'tenantId',
        'a tenant id must be a positive integer',
      );
    }
    await _s.write(key: _kTenantId, value: '$tenantId');
    _cached = tenantId;
    _loaded = true;
    _failure = null;
    notifyListeners();
  }

  /// Forgets the selection. Called on logout, account deletion, and whenever
  /// the server says the assertion no longer matches the credential.
  Future<void> clear() async {
    await _s.delete(key: _kTenantId);
    _cached = null;
    _loaded = true;
    notifyListeners();
  }

  /// Records a server refusal and clears the selection.
  ///
  /// The selection is cleared because it is the thing the server just refused;
  /// keeping it would make every subsequent request fail the same way. What is
  /// kept is [failure], so the UI can offer re-authentication instead of
  /// rendering a generic error or an empty screen.
  Future<void> reportFailure(TenantFailure kind) async {
    await clear();
    _failure = kind;
    notifyListeners();
  }

  /// Dismisses the failure once the user has acted on it (or signed in again).
  void acknowledgeFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }
}
