/// Social growth DTOs.
///
/// ## Key casing — read this before changing anything
///
/// `GET /social/referral-dashboard` returns **camelCase** because
/// `ReferralService::dashboardPayload()` builds a hand-written array rather than
/// going through a JsonResource. Every other endpoint in this API is snake_case.
/// Parsing this payload with snake_case keys would silently produce a dashboard
/// full of zeros, so both spellings are accepted below and normalised.
///
/// Do not "fix" the mapping to snake_case-only: the server sends camelCase.
library;

import '../../domain/entities/social.dart';

int _toInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String? _strOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String _str(Object? v, [String fallback = '']) => _strOrNull(v) ?? fallback;

class ReferralStatsDto {
  const ReferralStatsDto(this.stats);
  final ReferralStats stats;

  factory ReferralStatsDto.fromJson(Map<String, dynamic> json) {
    return ReferralStatsDto(ReferralStats(
      totalReferrals: _toInt(json['totalReferrals'] ?? json['total_referrals']),
      rewardedReferrals: _toInt(json['rewardedReferrals'] ?? json['rewarded_referrals']),
      pendingReferrals: _toInt(json['pendingReferrals'] ?? json['pending_referrals']),
      firstQuizRewardedReferrals:
          _toInt(json['firstQuizRewardedReferrals'] ?? json['first_quiz_rewarded_referrals']),
      secondDegreeRewardedReferrals:
          _toInt(json['secondDegreeRewardedReferrals'] ?? json['second_degree_rewarded_referrals']),
      secondDegreeBonusCoins:
          _toInt(json['secondDegreeBonusCoins'] ?? json['second_degree_bonus_coins']),
      coinsEarned: _toInt(json['coinsEarned'] ?? json['coins_earned']),
    ));
  }
}

class ReferralEntryDto {
  const ReferralEntryDto(this.entry);
  final ReferralEntry entry;

  factory ReferralEntryDto.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    return ReferralEntryDto(ReferralEntry(
      id: id,
      referredName: _strOrNull(json['referredName'] ?? json['referred_name']),
      status: _str(json['status'], 'unknown'),
      referrerRewardCoins:
          _toInt(json['referrerRewardCoins'] ?? json['referrer_reward_coins']),
      referredRewardCoins:
          _toInt(json['referredRewardCoins'] ?? json['referred_reward_coins']),
    ));
  }
}

class ReferralDashboardDto {
  const ReferralDashboardDto(this.domain);
  final ReferralDashboard domain;

  static ReferralDashboardDto? fromJson(Map<String, dynamic> json) {
    final referral = json['referral'];
    if (referral is! Map) return null;
    final map = referral.cast<String, dynamic>();

    // The code and the share URL are the two things the screen cannot work
    // without, so a payload missing either is rejected rather than rendered as
    // an empty share button.
    final code = _strOrNull(map['code']);
    final shareUrl = _strOrNull(map['shareUrl'] ?? map['share_url']);
    if (code == null || shareUrl == null) return null;

    final entries = <ReferralEntry>[];
    final referralsJson = map['referrals'];
    if (referralsJson is List) {
      for (final r in referralsJson) {
        if (r is! Map) continue;
        entries.add(ReferralEntryDto.fromJson(r.cast<String, dynamic>()).entry);
      }
    }

    final statsJson = map['stats'];
    final stats = statsJson is Map
        ? ReferralStatsDto.fromJson(statsJson.cast<String, dynamic>()).stats
        : const ReferralStats();

    return ReferralDashboardDto(ReferralDashboard(
      code: code,
      shareUrl: shareUrl,
      referrerRewardCoins: _toInt(map['referrerRewardCoins'] ?? map['referrer_reward_coins']),
      referredRewardCoins: _toInt(map['referredRewardCoins'] ?? map['referred_reward_coins']),
      firstQuizRewardCoins:
          _toInt(map['firstQuizRewardCoins'] ?? map['first_quiz_reward_coins']),
      stats: stats,
      referrals: entries,
    ));
  }
}

class ReferralClaimDto {
  const ReferralClaimDto(this.domain);
  final ReferralClaim domain;

  static ReferralClaimDto? fromJson(Map<String, dynamic> json) {
    final claimed = json['claimed'];
    if (claimed is! bool) return null;
    return ReferralClaimDto(ReferralClaim(
      claimed: claimed,
      status: _str(json['status'], 'unknown'),
      referrerRewardCoins:
          _toInt(json['referrer_reward_coins'] ?? json['referrerRewardCoins']),
      referredRewardCoins:
          _toInt(json['referred_reward_coins'] ?? json['referredRewardCoins']),
    ));
  }
}

class ShareMomentDto {
  const ShareMomentDto(this.moment);
  final ShareMoment moment;

  static ShareMomentDto? fromJson(Map<String, dynamic> json) {
    final id = _strOrNull(json['id'] ?? json['key'] ?? json['moment_key']);
    final kind = _strOrNull(json['kind'] ?? json['type']);
    if (id == null || kind == null) return null;
    return ShareMomentDto(ShareMoment(
      id: id,
      kind: kind,
      ctaLabel: _str(json['ctaLabel'] ?? json['cta_label'] ?? json['label'], 'Share'),
      title: _strOrNull(json['title']),
      rewardCoins: _toInt(json['rewardCoins'] ?? json['reward_coins']),
      dismissed: json['dismissed'] == true,
    ));
  }
}

class SocialProofDto {
  const SocialProofDto(this.proof);
  final SocialProof proof;

  static SocialProofDto? fromJson(Map<String, dynamic> json) {
    final headline = _strOrNull(json['headline'] ?? json['title']);
    if (headline == null) return null;
    return SocialProofDto(SocialProof(
      subject: _str(json['subject'], 'unknown'),
      headline: headline,
      statLabel: _strOrNull(json['statLabel'] ?? json['stat_label']),
      statValue: _strOrNull(json['statValue'] ?? json['stat_value']),
      shareText: _strOrNull(json['shareText'] ?? json['share_text']),
    ));
  }
}
