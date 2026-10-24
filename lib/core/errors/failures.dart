library;

import '../network/api_exception.dart';

sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.code});
  final ApiErrorCode? code;
  factory NetworkFailure.fromApi(ApiException e) =>
      NetworkFailure(e.message, code: e.code);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors});
  final Map<String, dynamic>? fieldErrors;

  /// Server field errors flattened to one display string per field.
  ///
  /// The contract serialises them as `error.details` — an object of field →
  /// error list (`{"email": ["The email has already been taken."]}`). Values
  /// may also be a bare string from older envelopes; both are tolerated.
  /// Empty lists collapse to nothing so a field never renders a blank line.
  Map<String, String> get fieldErrorTexts {
    final raw = fieldErrors;
    if (raw == null || raw.isEmpty) return const {};

    final out = <String, String>{};
    raw.forEach((field, value) {
      final text = switch (value) {
        final List<dynamic> list => list
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .join('\n'),
        final String s => s.trim(),
        _ => value.toString().trim(),
      };
      if (text.isNotEmpty) out[field] = text;
    });

    return out;
  }
}

/// The server answered `MAINTENANCE_MODE` (503) — the mobile kill switch is
/// engaged. Distinct from a network failure so surfaces can route the user to
/// the maintenance screen instead of offering a Retry that cannot succeed.
class MaintenanceFailure extends Failure {
  const MaintenanceFailure(super.message);
}
