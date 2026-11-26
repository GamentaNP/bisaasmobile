import 'package:flutter/material.dart';

import '../../domain/entities/question.dart';
import 'question_option_tile.dart';

/// Checkbox list for `multi_select` / `mcq_multiple`.
///
/// Selections are accumulated locally by the parent answer input and submitted
/// as one comma-joined string of option keys in server option order — e.g.
/// `a,c,d` — which is the wire format `ScoringService::scoreMultiSelect()`
/// parses. The order of the taps never changes the payload.
class MultiChoiceInput extends StatelessWidget {
  const MultiChoiceInput({
    required this.options,
    required this.value,
    required this.enabled,
    required this.onDraftChanged,
    this.hiddenKeys = const <String>{},
    this.correctKeys = const <String>{},
    this.isWrong = false,
    super.key,
  });

  final List<AnswerOption> options;
  final String value;
  final bool enabled;
  final ValueChanged<String> onDraftChanged;
  final Set<String> hiddenKeys;
  final Set<String> correctKeys;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    final selected = value
        .split(',')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (!_isHidden(options[index].id))
            QuestionOptionTile(
              badge: String.fromCharCode(65 + index),
              text: options[index].text,
              selected: selected.contains(options[index].id),
              multi: true,
              enabled: enabled,
              correct: correctKeys.contains(options[index].id),
              wrong: isWrong && selected.contains(options[index].id),
              onTap: () {
                final next = Set<String>.from(selected);
                if (next.contains(options[index].id)) {
                  next.remove(options[index].id);
                } else {
                  next.add(options[index].id);
                }
                onDraftChanged(
                  options
                      .map((option) => option.id)
                      .where(next.contains)
                      .join(','),
                );
              },
            ),
        ],
      ],
    );
  }

  bool _isHidden(String key) =>
      hiddenKeys.any((hidden) => hidden.toUpperCase() == key.toUpperCase());
}
