import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Renders the optional question image with a max 400px constraint,
/// shimmer placeholder, and tap-to-zoom.
/// Pass `imageUrl == null` → returns `SizedBox.shrink()`.
class QuestionImage extends StatelessWidget {
  const QuestionImage({required this.imageUrl, this.heroTag, this.maxWidth = 400, super.key});

  final String? imageUrl;
  final Object? heroTag;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxWidth * 0.75),
        child: GestureDetector(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.all(8),
                backgroundColor: Colors.transparent,
                child: Hero(
                  tag: heroTag ?? imageUrl!,
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Hero(
            tag: heroTag ?? imageUrl!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: AppColors.surfaceDark,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.surfaceDark,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
