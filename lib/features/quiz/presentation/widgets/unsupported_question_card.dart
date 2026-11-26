import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Fails loudly when the server sends a question family this build cannot
/// render. Never an empty card and never a fabricated MCQ: the learner gets a
/// localised explanation and a retry that re-reads the attempt from the
/// server, so a newly supported type can be picked up on the next attempt.
class UnsupportedQuestionCard extends StatelessWidget {
  const UnsupportedQuestionCard({
    required this.type,
    required this.onRetry,
    super.key,
  });

  final String type;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wrongRedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wrongRed, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.wrongRed, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.quizQuestionUnsupportedType(type),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
