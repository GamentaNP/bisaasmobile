import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Keeps one key for a calculator request while its caller retries it.
/// A changed request or a completed calculation starts a new operation.
class CalculatorRequestIdempotency {
  String? _requestFingerprint;
  String? _key;

  String keyFor({
    required String domain,
    required String slug,
    required Map<String, dynamic> inputs,
  }) {
    final fingerprint = jsonEncode({
      'domain': domain,
      'slug': slug,
      'inputs': _canonicalize(inputs),
    });

    if (_requestFingerprint != fingerprint || _key == null) {
      _requestFingerprint = fingerprint;
      _key = const Uuid().v4();
    }

    return _key!;
  }

  void complete() {
    _requestFingerprint = null;
    _key = null;
  }

  Object? _canonicalize(Object? value) {
    if (value is Map<String, dynamic>) {
      final keys = value.keys.toList()..sort();

      return <String, dynamic>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }

    if (value is List<dynamic>) {
      return value.map(_canonicalize).toList();
    }

    return value;
  }
}
