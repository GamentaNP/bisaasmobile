import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../../domain/entities/social.dart';
import '../models/social_dto.dart';

/// Social growth routes, verified against `routes/api/v1/social.php` in
/// `C:\laragon\www\bisaas`. Do not invent routes — re-check that file first.
///
/// Authenticated (`auth:sanctum` + `api.idempotency`):
/// - GET  /social/moments                        share prompts
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
/// - GET  /public/social/share/{token}
/// - POST /public/social/sandbox/{token}
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

  Map<String, dynamic>? _data(Map<String, dynamic>? body) {
    if (body == null) return null;
    final envelope = ApiResponse.fromJson(body, (json) => json);
    final data = envelope.data;
    if (data is Map<String, dynamic>) return data;
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    return null;
  }

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

  Future<List<ShareMoment>> getMoments() async {
    final res = await _dio.get<Map<String, dynamic>>('/social/moments');
    final data = res.data?['data'];
    final list = data is List
        ? data
        : (data is Map && data['items'] is List ? data['items'] as List : const []);
    final out = <ShareMoment>[];
    for (final m in list) {
      if (m is! Map) continue;
      final dto = ShareMomentDto.fromJson(m.cast<String, dynamic>());
      if (dto != null) out.add(dto.moment);
    }
    return out;
  }

  /// Dismissed prompts are filtered out rather than shown with a dismissed flag:
  /// a prompt the user already refused should not reappear.
  Future<List<ShareMoment>> getActiveMoments() async {
    final all = await getMoments();
    return all.where((m) => !m.dismissed).toList();
  }

  Future<void> dismissMoment(String momentId) async {
    await _dio.post<void>('/social/moments/dismissals', data: {'moment_key': momentId});
  }

  /// Tells the server a share actually happened.
  ///
  /// Fire-and-forget: the user sharing is not something to block them on, and a
  /// failure here must not surface as an error.
  Future<void> recordShare({String? subject, int? subjectId, String? channel}) async {
    try {
      await _dio.post<void>(
        '/social/share-recorded',
        data: {
          'subject': ?subject,
          'id': ?subjectId,
          'channel': ?channel,
        },
        options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
      );
    } catch (_) {
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
    return SocialProofDto.fromJson(data)?.proof;
  }

  // ── Share links ────────────────────────────────────────────────────────────

  /// Creates a tracked share link. Returns null when the server declines, in
  /// which case the caller should share the referral URL directly rather than
  /// fabricate a tracked one.
  Future<String?> createShareLink({String? subject, int? subjectId}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/social/links',
      data: {
        'subject': ?subject,
        'subject_id': ?subjectId,
      },
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final data = _data(res.data);
    final url = data?['url'] ?? data?['share_url'] ?? data?['shareUrl'];
    if (url is String && url.trim().isNotEmpty) return url.trim();
    return null;
  }
}
