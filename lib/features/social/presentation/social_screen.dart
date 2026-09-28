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
      appBar: AppBar(title: const Text('Invite friends')),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: _body(context, state, notifier),
      ),
    );
  }

  Widget _body(BuildContext context, SocialState state, SocialController notifier) {
    if (state.isLoading && !state.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasLoaded) {
      return _Message(
        icon: Icons.cloud_off,
        text: state.error!,
        actionLabel: 'Retry',
        onAction: notifier.refresh,
      );
    }

    final dash = state.dashboard;
    if (dash == null) {
      // Deliberately not "you have no referrals". A null dashboard means the
      // payload was not understood, which is not the same as an empty one.
      return _Message(
        icon: Icons.help_outline,
        text: 'Referral information is unavailable right now.',
        actionLabel: 'Retry',
        onAction: notifier.refresh,
      );
    }

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.moments.isNotEmpty) ...[
          ...state.moments.map(
            (m) => Card(
              child: ListTile(
                title: Text(m.title ?? m.ctaLabel),
                subtitle: m.hasReward ? Text('Earn ${m.rewardCoins} coins') : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () => notifier.dismiss(m), child: const Text('No')),
                    FilledButton(
                      onPressed: () => _share(context, dash, message: m.title),
                      child: Text(m.ctaLabel),
                    ),
                  ],
                ),
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
                Text('Your invite code', style: theme.textTheme.titleMedium),
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
                    label: const Text('Share invite link'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, dash.code),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy code'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Rewards', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _RewardRow(
          label: 'You earn per friend who signs up',
          value: dash.referrerRewardCoins,
        ),
        _RewardRow(
          label: 'They earn when they sign up',
          value: dash.referredRewardCoins,
        ),
        _RewardRow(
          label: 'Bonus when they finish their first quiz',
          value: dash.firstQuizRewardCoins,
        ),
        const Divider(height: 24),
        Text('Your referrals', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _Stat(value: '${dash.stats.totalReferrals}', label: 'invited'),
            const SizedBox(width: 20),
            _Stat(value: '${dash.stats.rewardedReferrals}', label: 'rewarded'),
            const SizedBox(width: 20),
            _Stat(value: '${dash.stats.coinsEarned}', label: 'coins earned'),
          ],
        ),
        if (dash.referrals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No one has used your code yet.',
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
                    ? 'Reward paid: ${r.referrerRewardCoins} coins'
                    // The server distinguishes pending states; do not collapse
                    // them into one word it did not use.
                    : 'Status: ${r.status}',
              ),
            ),
          ),
        const Divider(height: 24),
        Text('Got a code from a friend?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Referral code',
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
                : const Text('Apply code'),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, ReferralDashboard dash, {String? message}) async {
    final text = message == null
        ? 'Use my code ${dash.code} on CivilCal — civil engineering calculators and Loksewa MCQs.'
        : '$message\n\nUse my code ${dash.code}: ${dash.shareUrl}';
    try {
      // The URL is server-built, so it already points at the right host.
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'CivilCal'),
      );
      // Confirming a share happened is a courtesy to the server, not something to
      // block the user on, so the result is ignored.
      unawaited(
        ref.read(socialRepositoryProvider).recordShare(subject: 'referral'),
      );
    } catch (e) {
      AppLogger.w('share failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the share sheet')),
        );
      }
    }
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied')),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value coins', style: Theme.of(context).textTheme.bodyMedium),
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
