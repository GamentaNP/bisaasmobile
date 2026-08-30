import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import 'screens/quiz_attempt_screen.dart';

/// Quiz home — shows curated topic cards and a quick-start CTA.
class QuizHomePage extends ConsumerWidget {
  const QuizHomePage({super.key});

  static const _topics = [
    {
      'id': 'daily-sprint',
      'title': 'Daily Sprint',
      'desc': '10 calibrated questions — new every day',
      'icon': Icons.flash_on_rounded,
      'color': AppColors.brand,
      'tag': 'RECOMMENDED',
    },
    {
      'id': 'structural-analysis',
      'title': 'Structural Analysis',
      'desc': 'Bending moment, shear force, frames & trusses',
      'icon': Icons.account_tree_rounded,
      'color': Color(0xFF10B981),
      'tag': null,
    },
    {
      'id': 'geotechnical',
      'title': 'Geotechnical Engineering',
      'desc': 'Soil classification, bearing capacity, settlement',
      'icon': Icons.landscape_rounded,
      'color': Color(0xFFF59E0B),
      'tag': null,
    },
    {
      'id': 'surveying',
      'title': 'Surveying & Levelling',
      'desc': 'Traversing, contour, triangulation, curves',
      'icon': Icons.my_location_rounded,
      'color': Color(0xFFA855F7),
      'tag': null,
    },
    {
      'id': 'fluid-mechanics',
      'title': 'Fluid Mechanics',
      'desc': 'Bernoulli, pipe flow, open channels, pumps',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF06B6D4),
      'tag': null,
    },
    {
      'id': 'highway',
      'title': 'Transportation Engineering',
      'desc': 'Highway design, pavements, traffic engineering',
      'icon': Icons.route_rounded,
      'color': Color(0xFFEF4444),
      'tag': null,
    },
    {
      'id': 'loksewa-mock',
      'title': 'Loksewa Mock Exam',
      'desc': 'Full 100-question timed Loksewa simulation',
      'icon': Icons.assignment_rounded,
      'color': Color(0xFFEC4899),
      'tag': 'EXAM READY',
    },
  ];

  void _openQuiz(BuildContext context, String quizId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizAttemptScreen(quizId: quizId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice & Quiz',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Server-graded MCQs — instant XP & coins',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brand.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_rounded, size: 16, color: AppColors.brand),
                          SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.brand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Topic Cards ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final topic = _topics[index];
                    final color = topic['color']! as Color;
                    final tag = topic['tag'] as String?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openQuiz(context, topic['id']! as String),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  topic['icon']! as IconData,
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          topic['title']! as String,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (tag != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      topic['desc']! as String,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.play_circle_filled_rounded,
                                color: color,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _topics.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
