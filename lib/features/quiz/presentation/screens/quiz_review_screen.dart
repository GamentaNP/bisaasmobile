import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../widgets/difficulty_badge.dart';
import '../../../../l10n/app_localizations.dart';

/// Post-quiz review. Calls `GET /api/v1/quiz/attempts/{id}/results` (the
/// bare `GET /quiz/attempts/{id}` route does not exist) and renders every
/// server-graded answer row. The server withholds answer keys/explanations
/// even here, so cards show the user's pick + verdict only.
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
    final res =
        await dio.get<Map<String, dynamic>>('/quiz/attempts/${widget.attemptId}/results');
    final data = (res.data?['data'] as Map?)?.cast<String, dynamic>() ?? {};
    return AttemptReviewDto.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeAreaScaffold(
      appBar: CivilAppBar(
        title: l10n.quizReviewTitle,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: FutureBuilder<AttemptReviewDto>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            // A failed review must offer a way back in — the user used to have
            // to leave the screen and come back to try again.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      l10n.quizReviewLoadFailed(snap.error.toString()),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(() => _future = _load()),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snap.data!;
          final entries = data.entries;
          if (entries.isEmpty) {
            return Center(child: Text(l10n.quizReviewEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = entries[i];
              final isCorrect = e.isCorrect ?? false;
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
    final l10n = AppLocalizations.of(context)!;
    final color = isCorrect ? AppColors.correctGreen : AppColors.wrongRed;
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      color: color.withValues(alpha: 0.05),
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
              Text(l10n.quizReviewQuestionNumber(index), style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (entry.difficulty != null) DifficultyBadge(difficulty: entry.difficulty!, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.body, style: AppTypography.bodyMedium.copyWith(height: 1.5)),
          const SizedBox(height: 10),
          if (entry.userOptionId != null)
            _OptionRow(
              label: l10n.quizReviewYourAnswer,
              text: entry.userOptionText ?? entry.userOptionId!,
              color: color,
            )
          else
            _OptionRow(
              label: l10n.quizReviewYourAnswer,
              text: l10n.quizReviewNotAnswered,
              color: Colors.grey,
            ),
          // The results endpoint withholds answer keys — show the key row
          // only when the server actually sent one.
          if (entry.correctOptionText != null || entry.correctOptionId != null)
            _OptionRow(
              label: l10n.quizResultCorrect,
              text: entry.correctOptionText ?? entry.correctOptionId ?? '—',
              color: AppColors.correctGreen,
            ),
          if (entry.explanation != null && entry.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: AppRadii.smAll,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.brand, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(entry.explanation!, style: AppTypography.bodySmall.copyWith(height: 1.4))),
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

/// DTO for the results payload: data.answers[] rows shaped
/// {question_id, question_text, given_answer, is_correct, is_skipped,
/// score_awarded, time_taken_seconds}. Tolerant of other field names.
class AttemptReviewDto {
  AttemptReviewDto(this.entries);
  final List<AttemptReviewEntry> entries;
  factory AttemptReviewDto.fromJson(Map<String, dynamic> j) {
    final list = (j['answers'] ?? j['entries'] ?? j['items'] ?? j['questions'] ?? const []) as List;
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
    this.isCorrect,
    this.isSkipped,
  });
  final String body;
  final String? userOptionId;
  final String? correctOptionId;
  final String? userOptionText;
  final String? correctOptionText;
  final String? explanation;
  final int? difficulty;
  final bool? isCorrect;
  final bool? isSkipped;

  factory AttemptReviewEntry.fromJson(Map<String, dynamic> j) => AttemptReviewEntry(
        body: (j['body'] ?? j['question'] ?? j['question_text'] ?? '').toString(),
        userOptionId: j['user_option_id']?.toString() ?? j['given_answer']?.toString() ?? j['selected_option_id']?.toString(),
        correctOptionId: j['correct_option_id']?.toString(),
        userOptionText: j['user_option_text']?.toString() ?? j['selected_option_text']?.toString(),
        correctOptionText: j['correct_option_text']?.toString(),
        explanation: j['explanation']?.toString(),
        difficulty: j['difficulty'] as int?,
        isCorrect: j['is_correct'] as bool?,
        isSkipped: j['is_skipped'] as bool?,
      );
}
