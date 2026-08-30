import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/difficulty_badge.dart';
import 'quiz_browser_screen.dart' show QuizListEntry;

/// Pre-quiz screen showing topic, duration, question count, difficulty.
/// CTA → start attempt with Idempotency-Key and navigate to attempt screen.
class QuizIntroScreen extends ConsumerStatefulWidget {
  const QuizIntroScreen({required this.quizId, super.key});
  final String quizId;

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
    final res = await dio.get<Map<String, dynamic>>('/quiz/${widget.quizId}');
    return QuizListEntry.fromJson((res.data?['data'] as Map?)?.cast<String, dynamic>() ?? {});
  }

  Future<void> _start() async {
    // The attempt screen itself calls startSession, so simply navigate.
    if (!mounted) return;
    context.go('/quiz/${widget.quizId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Details')),
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
                    gradient: const LinearGradient(
                      colors: [AppColors.brand, AppColors.brandDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
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
                    Expanded(child: _StatTile(icon: Icons.help_outline_rounded, label: '${q.questionCount} Qs')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(icon: Icons.timer_rounded, label: '${q.durationMinutes} min')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(icon: Icons.bolt_rounded, label: '+${q.questionCount * 10} XP')),
                  ],
                ),
                const SizedBox(height: 16),
                Center(child: DifficultyBadge(difficulty: q.difficulty)),
                const SizedBox(height: 24),
                const _InstructionsCard(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Quiz'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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
  const _StatTile({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brand, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
      ),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
