import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/tutor.dart';

/// Reusable bubble for tutor chat — extracted for reuse and testing.
/// Tolerant to long markdown.
class TutorMessageBubble extends StatelessWidget {
  const TutorMessageBubble({super.key, required this.message});

  final TutorMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brand.withValues(alpha: 0.14) : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: SelectableText(message.content, style: TextStyle(fontSize: 13, height: 1.45, color: theme.colorScheme.onSurface)),
      ),
    );
  }
}
