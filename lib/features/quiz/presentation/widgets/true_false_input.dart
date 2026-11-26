import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/question.dart';

/// Two large cards for `true_false`.
///
/// The server may omit options for this family (the web renderer supplies the
/// same `true` / `false` fallback). When it does publish two options, their
/// keys are used verbatim — the answer value is always the option key.
class TrueFalseInput extends StatelessWidget {
  const TrueFalseInput({
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.correctKeys = const <String>{},
    this.isWrong = false,
    super.key,
  });

  final List<AnswerOption> options;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final Set<String> correctKeys;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final display = options.length >= 2
        ? options.take(2).toList()
        : <AnswerOption>[
            AnswerOption(id: 'true', text: l10n.quizQuestionTrue, position: 0),
            AnswerOption(id: 'false', text: l10n.quizQuestionFalse, position: 1),
          ];

    return Row(
      children: [
        for (var index = 0; index < display.length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(
            child: _TrueFalseCard(
              option: display[index],
              selected: value == display[index].id,
              enabled: enabled,
              correct: correctKeys.contains(display[index].id),
              wrong: isWrong && value == display[index].id,
              onTap: () => onChanged(display[index].id),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrueFalseCard extends StatelessWidget {
  const _TrueFalseCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  final AnswerOption option;
  final bool selected;
  final bool enabled;
  final bool correct;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct
        ? AppColors.brand
        : wrong
            ? AppColors.wrongRed
            : selected
                ? AppColors.brandAccent
                : AppColors.dividerLight;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: correct
              ? AppColors.correctGreenBg
              : wrong
                  ? AppColors.wrongRedBg
                  : selected
                      ? AppColors.selectedBlueBg
                      : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: selected || correct || wrong ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              correct
                  ? Icons.check_circle_rounded
                  : wrong
                      ? Icons.cancel_rounded
                      : selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              option.text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
