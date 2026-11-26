import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// One selectable answer row, shared by the single-choice, multi-select and
/// image-based renderers so they colour feedback the same way.
class QuestionOptionTile extends StatelessWidget {
  const QuestionOptionTile({
    required this.badge,
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.multi = false,
    this.correct = false,
    this.wrong = false,
    super.key,
  });

  final String badge;
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final bool multi;
  final bool correct;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final sideColor = correct
        ? AppColors.brand
        : wrong
            ? AppColors.wrongRed
            : selected
                ? AppColors.brandAccent
                : null;
    final faceColor = correct
        ? AppColors.correctGreenBg
        : wrong
            ? AppColors.wrongRedBg
            : selected
                ? AppColors.selectedBlueBg
                : theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: faceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(color: sideColor ?? divider, width: 3),
              top: BorderSide(color: sideColor ?? divider, width: 1.5),
              left: BorderSide(color: sideColor ?? divider, width: 1.5),
              right: BorderSide(color: sideColor ?? divider, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sideColor ?? divider,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: multi
                      ? Icon(
                          selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 20,
                          color: sideColor ??
                              (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        )
                      : Text(
                          badge,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: sideColor ??
                                (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (correct)
                Icon(Icons.check_circle_rounded, color: sideColor, size: 22)
              else if (wrong)
                Icon(Icons.cancel_rounded, color: sideColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
