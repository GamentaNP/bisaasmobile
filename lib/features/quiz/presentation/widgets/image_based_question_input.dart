import 'package:flutter/material.dart';

import '../../domain/entities/question.dart';
import 'question_image.dart';
import 'single_choice_input.dart';

/// Image-based question: the server's figure rendered through the existing
/// allow-listed [QuestionImage], then the same single-key choice list as an
/// ordinary MCQ. The image URL comes from `metadata.image_url`, never from a
/// hardcoded placeholder.
class ImageBasedQuestionInput extends StatelessWidget {
  const ImageBasedQuestionInput({
    required this.question,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.hiddenKeys = const <String>{},
    this.correctKeys = const <String>{},
    this.isWrong = false,
    super.key,
  });

  final Question question;
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
        QuestionImage(
          imageUrl: question.imageUrl,
          heroTag: 'q-${question.id}',
        ),
        const SizedBox(height: 12),
        SingleChoiceInput(
          options: question.options,
          value: value,
          enabled: enabled,
          onChanged: onChanged,
          hiddenKeys: hiddenKeys,
          correctKeys: correctKeys,
          isWrong: isWrong,
        ),
      ],
    );
  }
}
