import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/quiz_funnel.dart';
import '../controllers/quiz_funnel_controller.dart';


/// The quiz sampler.
///
/// `GET /quiz/guest-funnel` (public) or `GET /quiz/funnel` (authenticated) —
/// both publish the same guest-tier bundle: sampled public questions, live
/// taxonomy counts and a fresh-content promo. The bundle never contains
/// answer keys, so the screen never claims an answer was right or wrong.
///
/// The tier follows the session: a signed-in visitor gets the authenticated
/// bundle, a signed-out one gets the public one. This is where "Continue as
/// Guest" lands — a real sampler with real questions, not a dead-end route
/// into an app that needs an account.
class QuizFunnelScreen extends ConsumerStatefulWidget {
  const QuizFunnelScreen({super.key, this.tier});

  /// Forces a tier. Null (the default) means "follow the session".
  final QuizFunnelTier? tier;

  @override
  ConsumerState<QuizFunnelScreen> createState() => _QuizFunnelScreenState();
}

class _QuizFunnelScreenState extends ConsumerState<QuizFunnelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizFunnelControllerProvider.notifier).load(resolveTier());
    });
  }

  /// The tier to load: the forced one if there is one, otherwise the one the
  /// session earns.
  QuizFunnelTier resolveTier() {
    final forced = widget.tier;
    if (forced != null) return forced;
    final signedIn = ref.read(hasSessionProvider).value ?? false;
    return signedIn
        ? QuizFunnelTier.authenticated
        : QuizFunnelTier.guest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(quizFunnelControllerProvider);
    final theme = Theme.of(context);
    final funnel = state.funnel;
    final signedIn = ref.watch(hasSessionProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quizFunnelTryItOut),
        actions: [
          if (!signedIn)
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(l10n.signIn),
            ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => ref.read(quizFunnelControllerProvider.notifier).refresh(),
        child: state.isLoading && funnel == null
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && funnel == null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorView(
                      message: state.error!,
                      onRetry: () =>
                          ref.read(quizFunnelControllerProvider.notifier).refresh(),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Counts(counts: funnel?.counts ?? const FunnelCounts()),
                      if ((funnel?.promo.hasFresh ?? false) ||
                          funnel?.promo.latestCourse != null) ...[
                        const SizedBox(height: 12),
                        _Promo(promo: funnel?.promo ?? const FunnelPromo()),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            l10n.quizFunnelSampleTitle,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            l10n.quizFunnelShown(funnel?.items.length ?? 0),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signedIn
                            ? l10n.quizFunnelSampleBody
                            : l10n.quizFunnelPublicBody,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      if (funnel?.items.isEmpty ?? true)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            title: l10n.quizFunnelEmptyTitle,
                            subtitle:
                                l10n.quizFunnelEmptyBody,
                            icon: Icons.quiz_outlined,
                          ),
                        )
                      else
                        ...funnel!.items.map((i) => _FunnelCard(item: i)),
                      const SizedBox(height: 18),
                      if (!signedIn)
                        FilledButton.icon(
                          onPressed: () => context.go('/register'),
                          icon: const Icon(Icons.person_add_alt_rounded),
                          label: Text(l10n.quizFunnelCreateAccount),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => context.go('/quiz'),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.quizFunnelPlayGraded),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),

                      const SizedBox(height: 10),
                      Text(
                        l10n.quizFunnelPracticeNote,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.counts});
  final FunnelCounts counts;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, int)>[
      ('Questions', counts.questions),
      ('Courses', counts.courses),
      ('Categories', counts.categories),
      ('Topics', counts.topics),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.brand,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Promo extends StatelessWidget {
  const _Promo({required this.promo});
  final FunnelPromo promo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final latest = promo.latestCourse ?? promo.latestCategory;
    if (latest == null && !promo.hasFresh) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.correctGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.correctGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              latest == null
                  ? l10n.quizFreshQuestions
                  : l10n.quizNewIn(latest),
              style: const TextStyle(fontSize: 12, color: AppColors.correctGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.item});
  final FunnelItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.courseName != null || item.topicName != null)
              Row(
                children: [
                  if (item.courseName != null)
                    Flexible(
                      child: Text(
                        item.courseName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  if (item.courseName != null && item.topicName != null)
                    const Text(' • ', style: TextStyle(fontSize: 10)),
                  if (item.topicName != null)
                    Flexible(
                      child: Text(
                        item.topicName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              item.questionText.isEmpty
                  ? l10n.quizNoQuestionText
                  : item.questionText,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (item.hasOptions) ...[
              const SizedBox(height: 10),
              ...item.options.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          o.key,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          o.text,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.typeLabel != null)
                  Text(
                    item.typeLabel!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                if (item.difficulty != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    item.difficulty!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
                const Spacer(),
                Text(
                  l10n.commonPoints(item.points),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

