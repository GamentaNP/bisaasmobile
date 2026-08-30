import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/battle_controller.dart';

/// Battle Arena — matchmaking + Firebase RTDB.
///
/// Contract per `MOBILE_API_INTEGRATION_GUIDE.md:8`:
/// - `GET /quiz/firebase-token` → short-lived custom token; connect via Firebase SDK
/// - Clients are **read-only on leaderboard nodes** — writes go through `POST /quiz/battles/match` (server-authoritative)
/// - Without `google-services.json` the screen shows guard + token fetch still works (Dio only)
class BattleArenaScreen extends ConsumerWidget {
  const BattleArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(battleControllerProvider);
    final ctrl = ref.read(battleControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Battle Arena')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Realtime 1v1 — server decides match, Firebase RTDB is transport only. '
              'Leaderboard nodes are read-only; XP/coins never minted on-device.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          // Token card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Text('Firebase custom token', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (state.phase == BattlePhase.fetchingToken)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      FilledButton(onPressed: ctrl.fetchToken, child: const Text('Fetch')),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  state.token == null
                      ? 'No token yet — tap Fetch to call GET /quiz/firebase-token (bearer PAT).'
                      : 'token: ${state.token!.token.length > 32 ? '${state.token!.token.substring(0, 32)}…' : state.token!.token} (len ${state.token!.token.length})${state.token!.expiresAt != null ? '\nexpires: ${state.token!.expiresAt}' : ''}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
                ),
                if (state.token != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Use this token with FirebaseAuth.signInWithCustomToken (Firebase installed). RTDB rules enforce read-only leaderboard.',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Matchmaking
          FilledButton.icon(
            onPressed: state.phase == BattlePhase.matchmaking ? null : ctrl.findMatch,
            icon: state.phase == BattlePhase.matchmaking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.flash_on_rounded),
            label: Text(state.phase == BattlePhase.matchmaking ? 'Matchmaking…' : 'Find Match (POST /quiz/battles/match)'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          if (state.match != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.correctGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_kabaddi_rounded, size: 18, color: AppColors.correctGreen),
                      const SizedBox(width: 8),
                      Text('Match ${state.match!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(state.match!.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Opponent: ${state.match!.opponentLabel}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text(state.error!, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Text('Live arena', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Arena renders RTDB stream when Firebase is configured; otherwise shows server-poll fallback. Chat writes go via POST /quiz/battles/{id}/chat (throttled).',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: const Center(child: Text('RTDB stream placeholder — connect with custom token to see live ticks', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey))),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: ctrl.reset, child: const Text('Reset')),
        ],
      ),
    );
  }
}
