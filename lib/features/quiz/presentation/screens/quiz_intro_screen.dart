import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../widgets/difficulty_badge.dart';
import 'quiz_browser_screen.dart'
    show QuizCourseEntry, QuizListEntry;

/// Pre-quiz screen showing topic, duration, question count, difficulty.
/// CTA → start attempt with Idempotency-Key and navigate to attempt screen.
///
/// Loads course metadata from `GET /quiz/courses` and the live question
/// count from the paginated `GET /quiz/courses/{id}/questions` envelope
/// (there is no `GET /quiz/{id}` route on the server).
class QuizIntroScreen extends ConsumerStatefulWidget {
  const QuizIntroScreen({required this.quizId, this.categoryId, super.key});
  final String quizId;
  final String? categoryId;

  @override
  ConsumerState<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends ConsumerState<QuizIntroScreen> {
  late Future<QuizListEntry> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<QuizListEntry> _load() async {
    final dio = DioClient.instance.dio;
    // Course metadata: find the course in the active catalog.
    final coursesRes =
        await dio.get<Map<String, dynamic>>('/quiz/courses');
    final courses = (coursesRes.data?['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(QuizCourseEntry.fromJson)
        .toList();
    final course = courses.firstWhere(
      (c) => c.id == widget.quizId,
      orElse: () => QuizCourseEntry(
          id: widget.quizId, title: 'Quiz', description: ''),
    );

    // Live question count (and category name when drilling into one topic).
    //
    // The questions endpoint is cursor-paginated and publishes NO total
    // (verified 2026-09-27: top-level `pagination` with `type:"cursor"`,
    // `count`, `has_more`, `next_cursor`). The previous code read
    // `pagination.total`, which does not exist, so this screen always showed
    // "0 Qs" and "0 min" for every course. Read the page we actually got and
    // mark it as a lower bound when the server says more exist.
    final qp = <String, dynamic>{'per_page': 100};
    final catId = int.tryParse(widget.categoryId ?? '');
    if (catId != null) qp['category_id'] = catId;
    final qRes = await dio.get<Map<String, dynamic>>(
      '/quiz/courses/${widget.quizId}/questions',
      queryParameters: qp,
    );
    final body = qRes.data ?? const <String, dynamic>{};
    final data = body['data'];
    final items = data is Map<String, dynamic>
        ? (data['items'] as List? ?? const [])
        : (data is List ? data : const <dynamic>[]);
    final pagination = body['pagination'] is Map<String, dynamic>
        ? body['pagination'] as Map<String, dynamic>
        : (data is Map<String, dynamic> && data['pagination'] is Map<String, dynamic>
            ? data['pagination'] as Map<String, dynamic>
            : null);
    final hasMore = pagination?['has_more'] as bool? ?? false;
    final count = items.length;
    var topic = course.title;
    if (catId != null) {
      final first = items.isNotEmpty ? items.first : null;
      final cat = first is Map<String, dynamic> ? first['category'] : null;
      if (cat is Map<String, dynamic> && cat['name'] is String) {
        topic = cat['name'] as String;
      }
    }
    return QuizListEntry(
      id: course.id,
      title: topic,
      category: course.title,
      questionCount: count,
      hasMoreQuestions: hasMore,
      // Same 90s-per-question pacing the session builder uses.
      durationMinutes: (count * 90 / 60).round(),
    );
  }

  Future<void> _start() async {
    // The attempt screen itself calls startSession, so simply navigate.
    if (!mounted) return;
    final cat = widget.categoryId == null ? '' : '?category=${widget.categoryId}';
    context.go('/quiz/${widget.quizId}$cat');
  }

  @override
  Widget build(BuildContext context) {
    return SafeAreaScaffold(
      appBar: CivilAppBar(title: 'Quiz Details'),
      body: FutureBuilder<QuizListEntry>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load quiz: ${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final q = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: AppRadii.xlAll,
                    boxShadow: AppShadows.glowBrand,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.quiz_rounded, color: Colors.white, size: 36),
                      const SizedBox(height: 12),
                      Text(q.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(q.category, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.help_outline_rounded,
                        // "100+" when the page was truncated, never a fake total.
                        label: q.hasMoreQuestions ? '${q.questionCount}+' : '${q.questionCount}',
                        caption: 'Questions',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer_rounded,
                        label: '${q.durationMinutes}',
                        caption: 'min',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // Only offer an XP figure the server actually published.
                      // Otherwise say "Graded by server" rather than invent
                      // questionCount * 10.
                      child: _StatTile(
                        icon: Icons.bolt_rounded,
                        label: (q.xpReward ?? 0) > 0 ? '+${q.xpReward}' : 'Graded',
                        caption: (q.xpReward ?? 0) > 0 ? 'XP' : 'by server',
                        isMuted: (q.xpReward ?? 0) <= 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(child: DifficultyBadge(difficulty: 2)),
                const SizedBox(height: 24),
                const _InstructionsCard(),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Start Quiz',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _start,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, this.caption, this.isMuted = false});
  final IconData icon;
  final String label;
  final String? caption;

  /// Dims the tile when the label is a statement of fact rather than a figure
  /// the server published (e.g. "Server-graded" instead of a made-up XP value).
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: isMuted ? AppColors.textTertiaryLight : AppColors.brand, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: caption == null ? 15 : 13,
              color: isMuted ? AppColors.textSecondaryLight : null,
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryLight),
            ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard();
  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('How it works', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
          SizedBox(height: 8),
          _Bullet('Server grades your answer instantly.'),
          _Bullet('Correct: +10 XP, streak combo bonus.'),
          _Bullet('Wrong: -2 XP, streak resets.'),
          _Bullet('Tap the back button to exit (progress lost).'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 6, right: 6), child: Icon(Icons.circle, size: 5, color: AppColors.brand)),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
