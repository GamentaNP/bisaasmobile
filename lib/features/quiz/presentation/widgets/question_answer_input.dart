import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/question.dart';
import 'fill_blank_input.dart';
import 'fill_blank_multiple_input.dart';
import 'image_based_question_input.dart';
import 'multi_choice_input.dart';
import 'single_choice_input.dart';
import 'true_false_input.dart';
import 'unsupported_question_card.dart';

/// Picks the answer control from the question's server `type`.
///
/// Choice families submit on tap. Draft families (multi-select and both blank
/// flavours) accumulate locally and submit only when the learner confirms —
/// otherwise the controller's "tap submits immediately" path would fire on
/// the first checkbox or keystroke.
class QuestionAnswerInput extends StatefulWidget {
  const QuestionAnswerInput({
    required this.question,
    required this.value,
    required this.enabled,
    required this.hiddenKeys,
    required this.correctKeys,
    required this.isWrong,
    required this.onSubmit,
    required this.onRetry,
    super.key,
  });

  final Question question;
  final String value;
  final bool enabled;
  final Set<String> hiddenKeys;
  final Set<String> correctKeys;
  final bool isWrong;
  final ValueChanged<String> onSubmit;
  final VoidCallback onRetry;

  @override
  State<QuestionAnswerInput> createState() => _QuestionAnswerInputState();
}

class _QuestionAnswerInputState extends State<QuestionAnswerInput> {
  late String _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.value;
  }

  @override
  void didUpdateWidget(QuestionAnswerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _draft) {
      setState(() => _draft = widget.value);
    }
  }

  void _submitImmediately(String value) {
    if (!widget.enabled) return;
    setState(() => _draft = value);
    widget.onSubmit(value);
  }

  void _updateDraft(String value) {
    if (!widget.enabled) return;
    setState(() => _draft = value);
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.question.inputKind;
    if (kind == null) {
      return UnsupportedQuestionCard(
        type: widget.question.type,
        onRetry: widget.onRetry,
      );
    }

    switch (kind) {
      case QuizQuestionType.singleChoice:
        return SingleChoiceInput(
          options: widget.question.options,
          value: widget.value,
          enabled: widget.enabled,
          onChanged: _submitImmediately,
          hiddenKeys: widget.hiddenKeys,
          correctKeys: widget.correctKeys,
          isWrong: widget.isWrong,
        );
      case QuizQuestionType.imageBased:
        return ImageBasedQuestionInput(
          question: widget.question,
          value: widget.value,
          enabled: widget.enabled,
          onChanged: _submitImmediately,
          hiddenKeys: widget.hiddenKeys,
          correctKeys: widget.correctKeys,
          isWrong: widget.isWrong,
        );
      case QuizQuestionType.trueFalse:
        return TrueFalseInput(
          options: widget.question.options,
          value: widget.value,
          enabled: widget.enabled,
          onChanged: _submitImmediately,
          correctKeys: widget.correctKeys,
          isWrong: widget.isWrong,
        );
      case QuizQuestionType.multipleChoice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MultiChoiceInput(
              options: widget.question.options,
              value: _draft,
              enabled: widget.enabled,
              onDraftChanged: _updateDraft,
              hiddenKeys: widget.hiddenKeys,
              correctKeys: widget.correctKeys,
              isWrong: widget.isWrong,
            ),
            if (widget.enabled) _submitButton(context),
          ],
        );
      case QuizQuestionType.fillBlank:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FillBlankInput(
              value: _draft,
              enabled: widget.enabled,
              onDraftChanged: _updateDraft,
            ),
            if (widget.enabled) _submitButton(context),
          ],
        );
      case QuizQuestionType.fillBlankMultiple:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FillBlankMultipleInput(
              keys: widget.question.blankKeys,
              value: _draft,
              enabled: widget.enabled,
              onDraftChanged: _updateDraft,
            ),
            if (widget.enabled) _submitButton(context),
          ],
        );
    }
  }

  Widget _submitButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FilledButton(
        onPressed: _draft.trim().isEmpty ? null : () => widget.onSubmit(_draft),
        child: Text(l10n.quizQuestionSubmitAnswer),
      ),
    );
  }
}
