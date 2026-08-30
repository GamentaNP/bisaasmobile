import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../app/theme/app_colors.dart';

/// Renders a `flutter_math_fork` LaTeX formula inside a brand-tinted card.
class FormulaDisplay extends StatelessWidget {
  const FormulaDisplay({required this.latex, this.title, super.key});

  final String latex;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions_rounded, size: 18, color: AppColors.brand),
              const SizedBox(width: 6),
              Text(title ?? 'Formula', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              latex,
              mathStyle: MathStyle.display,
              textStyle: const TextStyle(fontSize: 16, color: Colors.white),
              onErrorFallback: (err) => Text(
                latex,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
