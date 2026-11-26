import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// One input per blank (`fill_blank_multiple`).
///
/// Wire format is the server grader's `"slot:answer"` segments joined by
/// commas — `a:cat,b:dog`. Every slot must be filled; the client never decides
/// whether any answer is correct.
class FillBlankMultipleInput extends StatefulWidget {
  const FillBlankMultipleInput({
    required this.keys,
    required this.value,
    required this.enabled,
    required this.onDraftChanged,
    super.key,
  });

  final List<String> keys;
  final String value;
  final bool enabled;
  final ValueChanged<String> onDraftChanged;

  @override
  State<FillBlankMultipleInput> createState() =>
      _FillBlankMultipleInputState();
}

class _FillBlankMultipleInputState extends State<FillBlankMultipleInput> {
  late final Map<String, String> _answers;
  late final Map<String, TextEditingController> _controllers;

  static Map<String, String> _parse(String raw) {
    final parsed = <String, String>{};
    for (final segment in raw.split(',')) {
      final separator = segment.indexOf(':');
      if (separator < 1) continue;
      final key = segment.substring(0, separator).trim();
      if (key.isNotEmpty) parsed[key] = segment.substring(separator + 1).trim();
    }
    return parsed;
  }

  @override
  void initState() {
    super.initState();
    _answers = _parse(widget.value);
    _controllers = <String, TextEditingController>{
      for (final key in widget.keys)
        key: TextEditingController(text: _answers[key] ?? ''),
    };
  }

  @override
  void didUpdateWidget(FillBlankMultipleInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    final parsed = _parse(widget.value);
    for (final entry in _controllers.entries) {
      final next = parsed[entry.key] ?? '';
      if (entry.value.text != next) entry.value.text = next;
    }
    _answers
      ..clear()
      ..addAll(parsed);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String key, String text) {
    if (text.trim().isEmpty) {
      _answers.remove(key);
    } else {
      _answers[key] = text;
    }
    widget.onDraftChanged(_serialize());
  }

  String _serialize() => widget.keys
      .map((key) => _answers.containsKey(key) ? '$key:${_answers[key]}' : '')
      .where((segment) => segment.isNotEmpty)
      .join(',');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < widget.keys.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  l10n.quizQuestionBlankNumber(index + 1),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controllers[widget.keys[index]],
                  enabled: widget.enabled,
                  onChanged: (text) => _onChanged(widget.keys[index], text),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
