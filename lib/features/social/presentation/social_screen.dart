import '../../../l10n/app_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/entities/social.dart';
import 'controllers/social_controller.dart';

/// Referrals and sharing.
///
/// Server-authoritative: the code, the share URL, the reward amounts and every
/// status come from `GET /social/referral-dashboard`. The client never decides a
/// referral counted and never mints a coin.
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(socialControllerProvider);
    final notifier = ref.read(socialControllerProvider.notifier);

    // A claim outcome is shown once and then cleared, so a stale success banner
    // cannot sit above a later failure and imply the failure worked.
    ref.listen<SocialState>(socialControllerProvider, (prev, next) {
      final msg = next.claimMessage;
      if (msg == null || msg == prev?.claimMessage) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      notifier.clearClaimMessage();
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialInviteFriends)),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: _body(context, state, notifier),
      ),
    );
  }

  Widget _body(BuildContext context, SocialState state, SocialController notifier) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading && !state.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasLoaded) {
      return _Message(
        icon: Icons.cloud_off,
        text: state.error!,
        actionLabel: l10n.retry,
        onAction: notifier.refresh,
      );
    }

    final dash = state.dashboard;
    if (dash == null) {
      // Deliberately not "you have no referrals". A null dashboard means the
      // payload was not understood, which is not the same as an empty one.
      return _Message(
        icon: Icons.help_outline,
        text: l10n.socialReferralUnavailable,
        actionLabel: l10n.retry,
        onAction: notifier.refresh,
      );
    }

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.moment != null) ...[
          Card(
            child: ListTile(
              title: Text(state.moment!.title ?? state.moment!.ctaLabel),
              subtitle: state.moment!.hasReward
                  ? Text(l10n.socialEarnCoins(state.moment!.rewardCoins))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => notifier.dismiss(state.moment!),
                    child: Text(l10n.socialNo),
                  ),
                  FilledButton(
                    onPressed: () => _shareMoment(context, state.moment!),
                    child: Text(state.moment!.ctaLabel),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.socialYourInviteCode, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(
                  dash.code,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _share(context, dash),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.socialShareInviteLink),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, dash.code),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(l10n.socialCopyCode),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.socialRewards, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _RewardRow(
          label: l10n.socialRewardPerSignup,
          value: dash.referrerRewardCoins,
        ),
        _RewardRow(
          label: l10n.socialTheyEarn,
          value: dash.referredRewardCoins,
        ),
        _RewardRow(
          label: l10n.socialBonusFirstQuiz,
          value: dash.firstQuizRewardCoins,
        ),
        const Divider(height: 24),
        Text(l10n.socialYourReferrals, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _Stat(value: '${dash.stats.totalReferrals}', label: l10n.socialInvited),
            const SizedBox(width: 20),
            _Stat(value: '${dash.stats.rewardedReferrals}', label: l10n.socialRewarded),
            const SizedBox(width: 20),
            _Stat(value: '${dash.stats.coinsEarned}', label: l10n.socialCoinsEarned),
          ],
        ),
        if (dash.referrals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.socialNoReferralsYet,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          ...dash.referrals.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                r.isRewarded ? Icons.check_circle_outline : Icons.schedule,
                color: r.isRewarded
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(r.displayName),
              subtitle: Text(
                r.isRewarded
                    ? l10n.socialRewardPaid(r.referrerRewardCoins)
                    // The server distinguishes pending states; do not collapse
                    // them into one word it did not use.
                    : l10n.socialStatus(r.status),
              ),
            ),
          ),
        const Divider(height: 24),
        Text(l10n.socialGotCode, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: l10n.socialReferralCode,
            isDense: true,
          ),
          onSubmitted: (v) => notifier.claimCode(v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: state.claimInFlight
                ? null
                : () => notifier.claimCode(_codeController.text),
            child: state.claimInFlight
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.socialApplyCode),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, ReferralDashboard dash) async {
    final l10n = AppLocalizations.of(context)!;
    // The URL is server-built, so it already points at the right host. The
    // referral URL is always included — the previous version omitted it for
    // the plain "share invite link" button, so the recipient got a bare code
    // with no way to reach the sign-up page.
    final text =
        l10n.socialShareInvite(dash.code, dash.shareUrl);
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'CivilCal'),
      );
    } catch (e) {
      AppLogger.w('share failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.socialShareSheetFailed)),
        );
      }
    }
  }

  /// Shares the moment the server picked.
  ///
  /// A **tracked** link is minted first (`POST /social/links`), so the server
  /// can attribute the share. When the server declines to mint one the
  /// referral URL is shared instead — never a fabricated tracked URL.
  Future<void> _shareMoment(BuildContext context, ShareMoment moment) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(socialControllerProvider.notifier);
    ShareLink? link;
    try {
      link = await notifier.createShareLink(kind: moment.kind);
    } catch (e) {
      AppLogger.w('share link mint failed: $e');
    }

    final text = link?.shareText ??
        'I just made progress on CivilCal — civil engineering calculators and Loksewa MCQs.';
    final url = link?.url;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: url == null ? text : '$text\n$url',
          subject: 'CivilCal',
        ),
      );
      if (link != null) {
        // Confirming a share happened is a courtesy to the server, not
        // something to block the user on.
        unawaited(notifier.recordShare(token: link.token));
      }
    } catch (e) {
      AppLogger.w('share failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.socialShareSheetFailed)),
        );
      }
    }
  }

  Future<void> _copy(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.socialCodeCopied)),
      );
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(l10n.coinsBalance(value), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}
