import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import 'chunky_button.dart';

/// Full-width bottom feedback banner that slides up after "Check" —
/// solid green (correct) or red (incorrect), white text, chunky CTA.
/// Mirrors the sample's quiz feedback sheet.
class QuizFeedbackSheet extends StatelessWidget {
  const QuizFeedbackSheet({
    super.key,
    required this.correct,
    required this.title,
    this.explanation,
    required this.ctaLabel,
    required this.onContinue,
    this.ctaLoading = false,
  });

  final bool correct;
  final String title;
  final String? explanation;
  final String ctaLabel;
  final VoidCallback onContinue;
  final bool ctaLoading;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final face = correct ? AppColors.correctGreenBg : AppColors.wrongRedBg;
    final side = correct ? AppColors.brand : AppColors.wrongRed;
    final sideShadow = correct ? AppColors.brandShadow : AppColors.errorShadow;

    return Container(
      decoration: BoxDecoration(
        color: face,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: side, width: 3)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: side,
                  shape: BoxShape.circle,
                  border: Border(bottom: BorderSide(color: sideShadow, width: 3)),
                ),
                child: Icon(
                  correct ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: sideShadow,
                        fontSize: 20,
                      ),
                    ),
                    if (explanation != null && explanation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          explanation!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: double.infinity, height: 12),
          ChunkyButton(
            label: ctaLabel,
            variant: correct ? ChunkyVariant.primary : ChunkyVariant.error,
            loading: ctaLoading,
            onPressed: ctaLoading ? null : onContinue,
          ),
        ],
      ),
    );
  }
}
