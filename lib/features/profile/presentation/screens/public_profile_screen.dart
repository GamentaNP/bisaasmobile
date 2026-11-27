import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/public_profile_controller.dart';

/// Public profile card from `GET /quiz/profiles/{username}`.
///
/// Aggregates, privacy and equipped titles are server-owned. The PNG card
/// endpoint is deliberately not mirrored; the card is rendered here from the
/// published profile data. A GET never records a profile view locally.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(publicProfileProvider(username));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.publicProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: l10n.compareProfiles,
            onPressed: () => context.go(
              '/profiles/compare?username=${Uri.encodeComponent(username)}',
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(publicProfileProvider(username)),
        ),
        data: (snapshot) {
          final profile = snapshot.profile;
          final stats = snapshot.stats;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profile.avatarUrl!),
                      )
                    : const CircleAvatar(child: Icon(Icons.person_outlined)),
                title: Text(profile.name),
                subtitle: Text('@${profile.username}'),
                trailing: Text(l10n.profileLevel(profile.level)),
              ),
              if (profile.headline != null && profile.headline!.isNotEmpty)
                Text(profile.headline!, style: Theme.of(context).textTheme.bodyMedium),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(profile.bio!),
              ],
              const SizedBox(height: 16),
              _Stat(
                icon: Icons.quiz_outlined,
                label: l10n.syllabusPapersCount(stats.completedQuizzes),
                value: l10n.commonPoints(stats.totalQuizzes),
              ),
              _Stat(
                icon: Icons.sports_esports_outlined,
                label: l10n.profileStreak,
                value: l10n.commonPoints(stats.totalBattles),
              ),
              _Stat(
                icon: Icons.track_changes_outlined,
                label: l10n.leaderboardScore(l10n.commonPercent(stats.averageScore)),
                value: l10n.commonPercent(stats.accuracyPercent),
              ),
              if (snapshot.reputationTier != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.leaderboardRankIn(
                    snapshot.reputationScore ?? 0,
                    snapshot.reputationTier!,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.profileAchievements,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (snapshot.recentAchievements.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.achievementsNone,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final achievement in snapshot.recentAchievements)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(achievement.name),
                    trailing: Text(l10n.commonPoints(achievement.rewardCoins)),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value),
      ),
    );
  }
}
