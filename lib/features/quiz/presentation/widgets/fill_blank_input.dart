import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Single free-text answer (`fill_blank`, `fill_blank_single`, `short_answer`).
///
/// The draft is held here so typing never submits; the parent submits the
/// string once the learner taps its Submit button. The server grader compares
/// the plain string case-insensitively.
class FillBlankInput extends StatefulWidget {
  const FillBlankInput({
    required this.value,
    required this.enabled,
    required this.onDraftChanged,
    super.key,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onDraftChanged;

  @override
  State<FillBlankInput> createState() => _FillBlankInputState();
}

class _FillBlankInputState extends State<FillBlankInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(FillBlankInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A retry or a different question replaces the submitted answer. Never
    // overwrite what the learner is typing on an unrelated rebuild.
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      onChanged: widget.onDraftChanged,
      decoration: InputDecoration(
        labelText: l10n.quizQuestionYourAnswer,
        hintText: l10n.quizQuestionTypeAnswer,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
