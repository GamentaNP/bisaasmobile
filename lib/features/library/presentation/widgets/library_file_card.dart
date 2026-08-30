import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/library.dart';

/// Reusable card for library files — used by browser + detail + unlocks list.
class LibraryFileCard extends StatelessWidget {
  const LibraryFileCard({super.key, required this.file, required this.onTap, this.compact = false});
  final LibraryFile file;
  final VoidCallback onTap;
  final bool compact;

  Color _colorForType(String type) {
    return switch (type.toLowerCase()) {
      'pdf' => const Color(0xFFEF4444),
      'video' => const Color(0xFF8B5CF6),
      'audio' => const Color(0xFF06B6D4),
      'image' => const Color(0xFF10B981),
      'doc' || 'docx' => const Color(0xFF0EA5E9),
      'zip' => const Color(0xFFF59E0B),
      _ => AppColors.brand,
    };
  }

  IconData _iconForType(String type) {
    return switch (type.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'video' => Icons.play_circle_rounded,
      'audio' => Icons.audiotrack_rounded,
      'image' => Icons.image_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'zip' => Icons.folder_zip_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(file.fileType);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_iconForType(file.fileType), size: 16, color: color),
                ),
                const Spacer(),
                if (file.isFeatured) const Icon(Icons.star_rounded, size: 16, color: AppColors.xpGold),
                if (file.isFeatured) const SizedBox(width: 4),
                if (!file.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.monetization_on_rounded, size: 12, color: AppColors.coinYellow),
                      const SizedBox(width: 2),
                      Text('${file.coinPrice}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coinYellow)),
                    ]),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: const Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(file.title, maxLines: compact ? 2 : 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2)),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 12, color: AppColors.xpGold),
                const SizedBox(width: 2),
                Text(file.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('(${file.reviewCount})', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                const Spacer(),
                Icon(Icons.download_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 2),
                Text('${file.downloadCount}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
