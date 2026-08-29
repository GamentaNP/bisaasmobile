import 'package:flutter/material.dart';

import '../../app/theme/app_radii.dart';
import '../../app/theme/app_shadows.dart';

class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0x1AFFFFFF) : Colors.white,
      borderRadius: AppRadii.card,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          border: Border.all(color: const Color(0x1AFFFFFF)),
          boxShadow: AppShadows.shadowMd,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
