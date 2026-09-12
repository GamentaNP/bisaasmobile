import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../game_providers.dart';
import '../../data/models/game_models.dart';
import 'game_level_intro_sheet.dart';

/// Duolingo-style zig-zag world map screen.
///
/// Fetches `GET /api/v1/quiz/game/world/{slug}/map` and renders
/// a vertical, scrollable path of level nodes organized by chapter.
class GameWorldMapScreen extends ConsumerWidget {
  const GameWorldMapScreen({required this.worldSlug, super.key});
  final String worldSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(gameWorldMapProvider(worldSlug));

    return Scaffold(
      body: mapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e, onRetry: () => ref.invalidate(gameWorldMapProvider(worldSlug))),
        data: (map) {
          if (map == null) {
            return const Center(child: Text('World not found'));
          }
          return _WorldMapBody(map: map);
        },
      ),
    );
  }
}

class _WorldMapBody extends StatelessWidget {
  const _WorldMapBody({required this.map});
  final GameWorldMapDto map;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapters = map.chapters;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(map.world.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (map.world.bannerImage != null)
                  Image.network(map.world.bannerImage!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.brand))
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.brand, AppColors.brand.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  )),
                ),
              ],
            ),
          ),
        ),
        // Star progress banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.22)),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: AppColors.xpGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${map.totalStarsEarned} / ${map.totalMaxStars} stars',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: map.totalMaxStars > 0 ? map.totalStarsEarned / map.totalMaxStars : 0,
                      minHeight: 6,
                      color: AppColors.xpGold,
                      backgroundColor: AppColors.xpGold.withValues(alpha: 0.12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Text('${map.completionPercent}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold, fontSize: 14)),
            ]),
          ),
        ),
        // Chapters
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, chapterIndex) {
              final chapter = chapters[chapterIndex];
              return _ChapterSection(chapter: chapter, worldSlug: '');
            },
            childCount: chapters.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({required this.chapter, required this.worldSlug});
  final GameChapterDto chapter;
  final String worldSlug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = !chapter.isUnlocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Opacity(
                opacity: locked ? 0.4 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: locked
                        ? null
                        : const LinearGradient(colors: [AppColors.brand, Color(0xFF8B5CF6)]),
                    color: locked ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    if (locked) const Icon(Icons.lock_rounded, size: 14, color: Colors.grey)
                    else const Icon(Icons.map_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      chapter.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: locked ? Colors.grey : Colors.white,
                      ),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              if (!locked)
                Row(children: [
                  Icon(Icons.star_rounded, size: 14, color: AppColors.xpGold),
                  const SizedBox(width: 2),
                  Text('${chapter.userStars}/${chapter.maxStars}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.xpGold)),
                ]),
            ],
          ),
        ),
        // Level nodes in zig-zag
        _ZigZagPath(levels: chapter.levels, chapterId: chapter.id),
      ],
    );
  }
}

/// Duolingo-style zig-zag path of level nodes.
class _ZigZagPath extends StatelessWidget {
  const _ZigZagPath({required this.levels, required this.chapterId});
  final List<GameLevelDto> levels;
  final int chapterId;

  @override
  Widget build(BuildContext context) {
    const nodeSize = 64.0;
    const hPadding = 32.0;
    final width = MediaQuery.sizeOf(context).width;

    // Zig-zag: alternate between 2 columns
    // Position: left column 25%, right column 65%
    final leftX = width * 0.22;
    final centerX = width * 0.5 - nodeSize / 2;
    final rightX = width * 0.68;

    final positions = <double>[];
    for (var i = 0; i < levels.length; i++) {
      // Pattern: center, right, center, left, center, right...
      switch (i % 4) {
        case 0:
          positions.add(centerX);
        case 1:
          positions.add(rightX);
        case 2:
          positions.add(centerX);
        case 3:
          positions.add(leftX);
      }
    }

    const rowHeight = 90.0;
    final totalHeight = levels.length * rowHeight + 20;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Draw connector lines
          for (var i = 0; i < levels.length - 1; i++)
            Positioned(
              top: i * rowHeight + nodeSize / 2,
              left: 0,
              right: 0,
              height: rowHeight,
              child: CustomPaint(
                painter: _PathLinePainter(
                  fromX: positions[i] + nodeSize / 2,
                  toX: positions[i + 1] + nodeSize / 2,
                  fromY: 0,
                  toY: rowHeight,
                  color: levels[i].isCompleted ? AppColors.correctGreen : Colors.grey.shade300,
                ),
              ),
            ),
          // Draw level nodes
          for (var i = 0; i < levels.length; i++)
            Positioned(
              top: i * rowHeight,
              left: positions[i],
              child: _LevelNode(level: levels[i], nodeSize: nodeSize),
            ),
        ],
      ),
    );
  }
}

class _PathLinePainter extends CustomPainter {
  _PathLinePainter({
    required this.fromX,
    required this.toX,
    required this.fromY,
    required this.toY,
    required this.color,
  });
  final double fromX, toX, fromY, toY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(fromX, fromY)
      ..quadraticBezierTo(
        (fromX + toX) / 2,
        (fromY + toY) / 2,
        toX,
        toY,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PathLinePainter old) =>
      old.fromX != fromX || old.toX != toX || old.color != color;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.nodeSize});
  final GameLevelDto level;
  final double nodeSize;

  Color get _bgColor {
    if (level.isCompleted) return AppColors.correctGreen;
    if (level.isLocked) return Colors.grey.shade300;
    if (level.isCurrent) return AppColors.brand;
    return AppColors.brand.withValues(alpha: 0.75);
  }

  @override
  Widget build(BuildContext context) {
    final locked = level.isLocked;

    return GestureDetector(
      onTap: locked ? null : () => _showLevelIntro(context),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              color: _bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: level.isCurrent
                    ? Colors.white
                    : _bgColor.withValues(alpha: 0.4),
                width: level.isCurrent ? 4 : 2,
              ),
              boxShadow: level.isCurrent
                  ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
                  : level.isCompleted
                      ? [BoxShadow(color: AppColors.correctGreen.withValues(alpha: 0.3), blurRadius: 8)]
                      : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (level.isBoss)
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28)
                else if (locked)
                  const Icon(Icons.lock_rounded, color: Colors.grey, size: 22)
                else
                  Text(
                    '${level.levelNumber}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
              ],
            ),
          ),
          if (!locked)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Icon(
                  i < level.starsEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 12,
                  color: i < level.starsEarned ? AppColors.xpGold : Colors.grey.shade300,
                )),
              ),
            ),
        ],
      ),
    );
  }

  void _showLevelIntro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameLevelIntroSheet(level: level),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load world map', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$error', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
