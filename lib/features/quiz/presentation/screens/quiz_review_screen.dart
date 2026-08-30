import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/difficulty_badge.dart';

/// Post-quiz review. Calls `GET /api/v1/quiz/attempts/{id}` and renders
/// all questions with the user's answer vs the correct answer and the
/// explanation in expandable cards.
class QuizReviewScreen extends ConsumerStatefulWidget {
  const QuizReviewScreen({required this.attemptId, super.key});
  final String attemptId;

  @override
  ConsumerState<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends ConsumerState<QuizReviewScreen> {
  late Future<AttemptReviewDto> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AttemptReviewDto> _load() async {
    final dio = DioClient.instance.dio;
    final res = await dio.get<Map<String, dynamic>>('/quiz/attempts/${widget.attemptId}');
    return AttemptReviewDto.fromJson((res.data?['data'] as Map?)?.cast<String, dynamic>() ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: FutureBuilder<AttemptReviewDto>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load review: ${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final data = snap.data!;
          final entries = data.entries;
          if (entries.isEmpty) {
            return const Center(child: Text('No answers to review'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = entries[i];
              final isCorrect = e.userOptionId != null && e.userOptionId == e.correctOptionId;
              return _ReviewCard(index: i + 1, entry: e, isCorrect: isCorrect);
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.entry, required this.isCorrect});
  final int index;
  final AttemptReviewEntry entry;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.correctGreen : AppColors.wrongRed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(isCorrect ? Icons.check : Icons.close, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text('Q$index', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (entry.difficulty != null) DifficultyBadge(difficulty: entry.difficulty!, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.body, style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 10),
          if (entry.userOptionId != null)
            _OptionRow(
              label: 'Your answer',
              text: entry.userOptionText ?? entry.userOptionId!,
              color: color,
            ),
          _OptionRow(
            label: 'Correct',
            text: entry.correctOptionText ?? entry.correctOptionId ?? '—',
            color: AppColors.correctGreen,
          ),
          if (entry.explanation != null && entry.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.brand, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(entry.explanation!, style: const TextStyle(fontSize: 12, height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.text, required this.color});
  final String label;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

/// DTO for review payload. Tolerant of multiple server field names.
class AttemptReviewDto {
  AttemptReviewDto(this.entries);
  final List<AttemptReviewEntry> entries;
  factory AttemptReviewDto.fromJson(Map<String, dynamic> j) {
    final list = (j['entries'] ?? j['items'] ?? j['questions'] ?? const []) as List;
    return AttemptReviewDto(
      list.cast<Map<String, dynamic>>().map(AttemptReviewEntry.fromJson).toList(),
    );
  }
}

class AttemptReviewEntry {
  AttemptReviewEntry({
    required this.body,
    this.userOptionId,
    this.correctOptionId,
    this.userOptionText,
    this.correctOptionText,
    this.explanation,
    this.difficulty,
  });
  final String body;
  final String? userOptionId;
  final String? correctOptionId;
  final String? userOptionText;
  final String? correctOptionText;
  final String? explanation;
  final int? difficulty;

  factory AttemptReviewEntry.fromJson(Map<String, dynamic> j) => AttemptReviewEntry(
        body: (j['body'] ?? j['question'] ?? '').toString(),
        userOptionId: j['user_option_id']?.toString() ?? j['selected_option_id']?.toString(),
        correctOptionId: j['correct_option_id']?.toString(),
        userOptionText: j['user_option_text']?.toString() ?? j['selected_option_text']?.toString(),
        correctOptionText: j['correct_option_text']?.toString(),
        explanation: j['explanation']?.toString(),
        difficulty: j['difficulty'] as int?,
      );
}
