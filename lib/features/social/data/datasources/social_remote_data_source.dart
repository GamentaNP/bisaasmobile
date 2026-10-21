import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/social.dart';
import '../models/social_dto.dart';

/// Social growth routes, verified against `routes/api/v1/social.php` in
/// `C:\laragon\www\bisaas`. Do not invent routes — re-check that file first.
///
/// Authenticated (`auth:sanctum` + `api.idempotency`):
/// - GET  /social/moments                        the one prompt the server picked
/// - GET  /social/creative                       share copy variants
/// - POST /social/links                          create a tracked share link
/// - POST /social/moments/dismissals             stop showing a prompt
/// - POST /social/share-recorded                 confirm the user actually shared
/// - GET  /social/referral-dashboard             code, link, stats, referrals
/// - PUT  /social/referral-code/claim            deferred claim (**Idempotency-Key required**)
/// - GET  /social/proof?subject=&id=             server-computed shareable proof
/// - PUT  /social/sandbox/claim                  guest sandbox claim
///
/// Public, Pennant-gated on `social_engine_enabled`:
/// - GET  /public/social/share/{token}           resolve an incoming share
/// - POST /public/social/sandbox/{token}         start a guest sandbox attempt
/// - PUT  /public/social/sandbox/{attempt}/answer
/// - PUT  /public/social/sandbox/{attempt}/completion
///
/// The referral claim is coin-adjacent, so it carries an Idempotency-Key. A
/// retry of the same claim must reuse the same key, which is why the key is
/// generated once per claim attempt rather than per HTTP call.
class SocialRemoteDataSource {
  const SocialRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  // ── Referrals ──────────────────────────────────────────────────────────────

  /// Returns null when the payload has no `referral` object or no code — the
  /// dashboard is not renderable in that state, and an empty card would read as
  /// "you have no referrals" when the truth is "the response was not understood".
  Future<ReferralDashboard?> getReferralDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>('/social/referral-dashboard');
    final data = _data(res.data);
    if (data == null) return null;
    return ReferralDashboardDto.fromJson(data)?.domain;
  }

  /// Claims a friend's code after the fact.
  ///
  /// PUT (not POST) because the server treats it as an idempotent state-set: it
  /// compares the stored `referral_code` against the submitted one and returns
  /// 422 for a *different* code once already attributed. Requires an
  /// Idempotency-Key.
  Future<ReferralClaim> claimReferralCode(String code) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/social/referral-code/claim',
      data: {'code': code},
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final data = _data(res.data);
    if (data == null) {
      // The server returned 2xx without a parsable body. Do not claim success:
      // telling a user their referral was accepted when the payload said nothing
      // is exactly the kind of local optimism this project has been removing.
      return const ReferralClaim(claimed: false, status: 'unknown');
    }
    return ReferralClaimDto.fromJson(data)?.domain ??
        const ReferralClaim(claimed: false, status: 'unknown');
  }

  // ── Share moments and proof ────────────────────────────────────────────────

  /// The share prompt the server picked for this user.
  ///
  /// The endpoint publishes **one** moment, not a list:
  /// `data: {moment: null}` when there is nothing to prompt, otherwise
  /// `data: {moment: {kind, priority}}`. The previous client expected a list
  /// and therefore never rendered a single prompt.
  Future<ShareMoment?> getMoment() async {
    final res = await _dio.get<Map<String, dynamic>>('/social/moments');
    final data = _data(res.data);
    if (data == null) return null;
    final raw = data['moment'];
    if (raw is! Map) return null;
    final dto = ShareMomentDto.fromJson(raw.cast<String, dynamic>());
    return dto?.moment;
  }

  /// Tells the server the prompt was dismissed.
  ///
  /// The server validates `kind` — the same enum value the moment carried.
  /// Dismissal is idempotent, so a double-tap is harmless.
  Future<void> dismissMoment(String kind) async {
    await _dio.post<void>(
      '/social/moments/dismissals',
      data: {'kind': kind},
    );
  }

  /// Tells the server a share actually happened.
  ///
  /// The server identifies the share by its **token** (`share_link.token`),
  /// not by a subject id, and resolves it server-side. This is best-effort
  /// analytics only: the user sharing is not something to block them on, and a
  /// failure here must not surface as an error — the ledger never reads it.
  Future<void> recordShare({
    required String token,
    String? channel,
  }) async {
    try {
      await _dio.post<void>(
        '/social/share-recorded',
        data: <String, dynamic>{
          'token': token,
          if (channel != null && channel.isNotEmpty) 'channel': channel,
        },
        options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
      );
    } on Object {
      // Ignored on purpose — see the doc comment.
    }
  }

  Future<SocialProof?> getProof({required String subject, required int id}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/social/proof',
      queryParameters: {'subject': subject, 'id': id},
    );
    final data = _data(res.data);
    if (data == null) return null;
    // The payload nests the proof under `proof`.
    final proof = data['proof'];
    if (proof is! Map) return null;
    return SocialProofDto.fromJson(proof.cast<String, dynamic>())?.proof;
  }

  // ── Share links ────────────────────────────────────────────────────────────

  /// Creates a tracked share link.
  ///
  /// `POST /social/links` requires `kind` — one of the `ShareMomentKind`
  /// values (`achievement`, `quiz_result`, `streak`, `calculator`,
  /// `challenge`) — and returns `data.share_link.{token, url, kind,
  /// expires_at, copy}`.
  ///
  /// Throws when the server declines or answers a body the client cannot
  /// read — a share link is either minted or it is not, and "we could not
  /// parse it" must not become "no link, share the referral URL instead".
  Future<ShareLinkDto> createShareLink({
    required String kind,
    int? subjectId,
    String? channel,
  }) async {
    final payload = <String, dynamic>{'kind': kind};
    if (subjectId != null) payload['subject_id'] = subjectId;
    if (channel != null && channel.isNotEmpty) payload['channel'] = channel;

    final res = await _dio.post<Map<String, dynamic>>(
      '/social/links',
      data: payload,
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty share-link response',
        endpoint: '/social/links',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Share-link payload not understood',
        endpoint: '/social/links',
      );
    }
    final link = data['share_link'];
    if (link is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Share-link payload not understood',
        endpoint: '/social/links',
      );
    }
    return ShareLinkDto.fromJson(link);
  }

  // ── Public share resolution ────────────────────────────────────────────────

  /// Resolves an incoming share link.
  ///
  /// `GET /public/social/share/{token}` — public by design: the recipient of
  /// a share link is by definition not the sender. The response carries the
  /// creator's display name, the kind and whether a guest sandbox is available.
  Future<SharedLinkDto> resolveShare(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/public/social/share/$token',
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty share-link response',
        endpoint: '/public/social/share/{token}',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Share-link payload not understood',
        endpoint: '/public/social/share/{token}',
      );
    }
    final share = data['share'];
    if (share is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Share-link payload not understood',
        endpoint: '/public/social/share/{token}',
      );
    }
    return SharedLinkDto.fromJson(share);
  }

  // ── Guest sandbox ──────────────────────────────────────────────────────────

  /// Starts a guest sandbox attempt from a share token.
  ///
  /// `POST /public/social/sandbox/{token}` with a client-generated
  /// `guest_session_id` (8..64 characters). The attempt runs against a
  /// sentinel user and completes with **zero progression grants**
  /// (`AttemptService::completeSandboxed`), so a guest can play without
  /// touching anyone's balance.
  Future<SandboxStartDto> startSandbox({
    required String token,
    required String guestSessionId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/public/social/sandbox/$token',
      data: {'guest_session_id': guestSessionId},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty sandbox response',
        endpoint: '/public/social/sandbox/{token}',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Sandbox payload not understood',
        endpoint: '/public/social/sandbox/{token}',
      );
    }
    final attempt = data['sandbox_attempt'];
    if (attempt is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Sandbox payload not understood',
        endpoint: '/public/social/sandbox/{token}',
      );
    }
    return SandboxStartDto.fromJson(attempt);
  }

  /// Answers one sandbox question.
  ///
  /// `PUT /public/social/sandbox/{attempt}/answer` — the canonical state-set
  /// shape; the POST spelling is the transition alias.
  Future<SandboxAnswerDto> answerSandbox({
    required int attemptId,
    required int questionId,
    required String answer,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/public/social/sandbox/$attemptId/answer',
      data: {'question_id': questionId, 'answer': answer},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty sandbox answer response',
        endpoint: '/public/social/sandbox/{attempt}/answer',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Sandbox answer payload not understood',
        endpoint: '/public/social/sandbox/{attempt}/answer',
      );
    }
    final answerData = data['answer'];
    if (answerData is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Sandbox answer payload not understood',
        endpoint: '/public/social/sandbox/{attempt}/answer',
      );
    }
    return SandboxAnswerDto.fromJson(answerData);
  }

  /// Completes the sandbox attempt and returns the server's result.
  ///
  /// `PUT /public/social/sandbox/{attempt}/completion`.
  Future<SandboxResultDto> completeSandbox(int attemptId) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/public/social/sandbox/$attemptId/completion',
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty sandbox completion response',
        endpoint: '/public/social/sandbox/{attempt}/completion',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Sandbox completion payload not understood',
        endpoint: '/public/social/sandbox/{attempt}/completion',
      );
    }
    final result = data['result'];
    if (result is! Map<String, dynamic>) {
      throw const ContractViolation(
        'Sandbox completion payload not understood',
        endpoint: '/public/social/sandbox/{attempt}/completion',
      );
    }
    return SandboxResultDto.fromJson(result);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _data(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
