/// Small helpers every data source needs to talk to the canonical envelope.
///
/// The rules these helpers exist to enforce (AGENTS.md → API Contract):
///
///  * Read `data` from the envelope. Never read the raw body directly.
///  * A 2xx body that does not carry the expected shape is a **contract
///    drift**, not an empty result. It throws [ContractViolation].
///  * A non-2xx response becomes an [ApiException] carrying the server's
///    frozen `error.code` — never a bare empty list.
library;

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'api_exception.dart';
import 'api_failure.dart';

const _uuid = Uuid();

/// Header set for a write that must not double-fire.
///
/// `MOBILE_API_INTEGRATION_GUIDE.md` §7: the server returns
/// `422 IDEMPOTENCY_KEY_REQUIRED` on the endpoints that demand one, and a
/// replay with the same key returns the stored response
/// (`X-Idempotent-Replay: true`). Mint a fresh key once per logical
/// operation and reuse the same key across retries of that operation.
Map<String, String> idempotencyHeader([String? key]) =>
    {'Idempotency-Key': key ?? _uuid.v4()};

/// Header set for a token refresh (`X-Device-Name`, per §2.2).
Map<String, String> deviceNameHeader(String deviceName) =>
    {'X-Device-Name': deviceName};

/// Reads `data` as a JSON object out of the canonical envelope.
///
/// Throws [ContractViolation] when the envelope has no `data` object, so a
/// drifted server response can never be mistaken for "no content".
Map<String, dynamic> requireDataMap(
  Map<String, dynamic>? body, {
  String? endpoint,
}) {
  if (body == null) {
    throw ContractViolation('Empty response body', endpoint: endpoint);
  }
  final data = body['data'];
  if (data is Map<String, dynamic>) return data;
  throw ContractViolation(
    'Expected `data` to be an object, got ${data.runtimeType}',
    endpoint: endpoint,
  );
}

/// Reads `data` as a JSON array out of the canonical envelope.
///
/// An envelope whose `data` is `null` is an empty collection, which is
/// legitimate. A `data` of the wrong type is drift.
List<Map<String, dynamic>> requireDataList(
  Map<String, dynamic>? body, {
  String? endpoint,
}) {
  if (body == null) {
    throw ContractViolation('Empty response body', endpoint: endpoint);
  }
  final data = body['data'];
  if (data == null) return const [];
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  throw ContractViolation(
    'Expected `data` to be an array, got ${data.runtimeType}',
    endpoint: endpoint,
  );
}

/// Reads a **collection** endpoint's `data` as a JSON array.
///
/// Unlike [requireDataList], a `null` `data` is drift here rather than an
/// empty collection: the list endpoints this is used for always publish
/// their rows, so a `null` means the server said something the client does
/// not understand. Returning `[]` there would render "you have nothing" for
/// a response the client simply failed to parse.
List<Map<String, dynamic>> requireCollection(
  Map<String, dynamic>? body, {
  String? endpoint,
}) {
  if (body == null) {
    throw ContractViolation('Empty response body', endpoint: endpoint);
  }
  final data = body['data'];
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  throw ContractViolation(
    'Expected `data` to be an array, got ${data.runtimeType}',
    endpoint: endpoint,
  );
}

/// Converts a [DioException] into the canonical [ApiException].
///
/// Re-exported here so a data source only needs one import.
ApiException mapDioError(DioException e) => toApiException(e);
