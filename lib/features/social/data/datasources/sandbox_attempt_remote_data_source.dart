/// Data source for the authenticated `GET /social/sandbox/attempts/{attempt}`
/// result read (§9.5).
///
/// Two independent proofs are required and both are enforced before a request
/// leaves the device: the bearer credential (all guests share one sentinel
/// user) and the `guest_session_id` minted by the public sandbox lifecycle.
/// This never calls a `/public/...` URL and never runs anonymously.
library;

import 'package:dio/dio.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/security/token_manager.dart';
import '../../domain/entities/sandbox_attempt.dart';
import '../models/sandbox_attempt_dto.dart';

class SandboxAttemptRemoteDataSource {
  const SandboxAttemptRemoteDataSource(
    this._dio, {
    this.hasCredential = storedTokenGuard,
  });

  final Dio _dio;

  /// Injected through a provider so the anonymous guard is provable without
  /// platform storage. Production reads the same token the auth interceptor
  /// uses.
  final Future<bool> Function() hasCredential;

  static Future<bool> storedTokenGuard() async {
    final token = await TokenManager.shared.readToken();
    return token != null && token.isNotEmpty;
  }

  static const endpoint = '/social/sandbox/attempts';

  Future<SandboxAttemptResults> getAttempt({
    required String attemptId,
    required String guestSessionId,
  }) async {
    if (int.tryParse(attemptId) == null) {
      throw ContractViolation(
        'A sandbox attempt id must be numeric',
        endpoint: endpoint,
      );
    }
    if (guestSessionId.trim().isEmpty) {
      throw ApiException(
        statusCode: 422,
        code: ApiErrorCode.validationError,
        message: appL10n().errValidationRejected,
      );
    }
    if (!await hasCredential()) {
      throw ApiException(
        statusCode: 401,
        code: ApiErrorCode.authUnauthenticated,
        message: appL10n().errSessionExpired,
      );
    }

    final path = '$endpoint/$attemptId';
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: <String, dynamic>{'guest_session_id': guestSessionId},
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: path);
    }
    return SandboxAttemptDto.fromJson(
      requireDataMap(body, endpoint: path),
      endpoint: path,
    ).toDomain(endpoint: path);
  }
}
