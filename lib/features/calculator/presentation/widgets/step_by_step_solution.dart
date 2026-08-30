import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../app/theme/app_colors.dart';

/// Renders a list of step objects `{label, formula, result}` as
/// expandable cards. The formula field, if present, is rendered with
/// `flutter_math_fork`; missing formulas show the result value as a
/// large bold line.
class StepByStepSolution extends StatelessWidget {
  const StepByStepSolution({required this.steps, super.key});

  final List<Map<String, dynamic>> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.list_alt_rounded, size: 18, color: AppColors.brand),
              SizedBox(width: 6),
              Text('Step-by-step', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return _StepTile(index: i + 1, step: step);
          }),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});
  final int index;
  final Map<String, dynamic> step;

  @override
  Widget build(BuildContext context) {
    final label = (step['label'] as String?) ?? 'Step $index';
    final formula = step['formula'] as String?;
    final result = (step['result'] as String?) ?? (step['value']?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.brand.withValues(alpha: 0.15),
            child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (formula != null && formula.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Math.tex(
                        formula,
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                        onErrorFallback: (err) => Text(formula, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ),
                  ),
                if (result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(result, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
