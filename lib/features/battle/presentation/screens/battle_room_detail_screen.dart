import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/battle_room_detail_controller.dart';

/// Participant-only lobby snapshot from `GET /quiz/battle-rooms/{lobby}`.
///
/// Question ids and reward-settlement keys are not part of the entity, so they
/// cannot be rendered here. Scores and ranks are the server's values.
class BattleRoomDetailScreen extends ConsumerWidget {
  const BattleRoomDetailScreen({super.key, required this.lobbyId});

  final String lobbyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(battleRoomDetailProvider(lobbyId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.battleArena)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(battleRoomDetailProvider(lobbyId)),
        ),
        data: (detail) {
          final lobby = detail.lobby;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(lobby.code, style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.socialStatus(lobby.status ?? '')),
                subtitle: Text(lobby.mode ?? ''),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.libraryCoinsLabel(lobby.wagerCoins)),
              ),
              const SizedBox(height: 8),
              Text(l10n.battleYou, style: Theme.of(context).textTheme.titleSmall),
              ListTile(
                dense: true,
                title: Text(l10n.libraryByUploader(lobby.host.name ?? '')),
                trailing: Text('${lobby.host.id}'),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.battleOpponent,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (lobby.participants.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.battleNoActiveMatch,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final participant in lobby.participants)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline),
                    title: Text(participant.userName ?? ''),
                    trailing: Text(l10n.leaderboardScore('${participant.score}')),
                    subtitle: Text(l10n.socialStatus(
                      participant.rank == null
                          ? l10n.battleResultPending
                          : '${participant.rank}',
                    )),
                  ),
            ],
          );
        },
      ),
    );
  }
}
