import 'package:flutter/material.dart';

import '../../domain/entities/question.dart';
import 'question_option_tile.dart';

/// Radio-style answer list. The submitted value is the option **key** — the
/// server grader never accepts a numeric id or a display letter.
class SingleChoiceInput extends StatelessWidget {
  const SingleChoiceInput({
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.hiddenKeys = const <String>{},
    this.correctKeys = const <String>{},
    this.isWrong = false,
    super.key,
  });

  final List<AnswerOption> options;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final Set<String> hiddenKeys;
  final Set<String> correctKeys;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (!_isHidden(options[index].id))
            QuestionOptionTile(
              badge: String.fromCharCode(65 + index),
              text: options[index].text,
              selected: value == options[index].id,
              enabled: enabled,
              correct: correctKeys.contains(options[index].id),
              wrong: isWrong && value == options[index].id,
              onTap: () => onChanged(options[index].id),
            ),
        ],
      ],
    );
  }

  bool _isHidden(String key) =>
      hiddenKeys.any((hidden) => hidden.toUpperCase() == key.toUpperCase());
}
