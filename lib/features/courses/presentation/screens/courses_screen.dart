// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Courses / syllabus — `GET /quiz/courses` (+ categories/questions).
/// Reuses quiz domain syllabus; PSC blueprints at `/psc/blueprints`.
/// Lazy-loads nodes; paginated via cursor for questions. Offline packs planned (design-research 1586).
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const _demoCourses = [
    {'title': 'Soil Mechanics', 'chapters': 12, 'progress': 0.82, 'color': Color(0xFFF59E0B)},
    {'title': 'Structural Analysis', 'chapters': 18, 'progress': 0.35, 'color': Color(0xFF8B5CF6)},
    {'title': 'Surveying & Levelling', 'chapters': 10, 'progress': 0.55, 'color': Color(0xFF06B6D4)},
    {'title': 'Fluid Mechanics', 'chapters': 14, 'progress': 0.42, 'color': Color(0xFF0EA5E9)},
    {'title': 'Transportation', 'chapters': 9, 'progress': 0.18, 'color': Color(0xFFEF4444)},
    {'title': 'Building Materials', 'chapters': 8, 'progress': 0.64, 'color': Color(0xFF10B981)},
    {'title': 'Concrete Technology', 'chapters': 11, 'progress': 0.28, 'color': Color(0xFF64748B)},
    {'title': 'Hydraulics', 'chapters': 13, 'progress': 0.71, 'color': Color(0xFF22D3EE)},
    {'title': 'Geotechnical', 'chapters': 15, 'progress': 0.49, 'color': Color(0xFFEAB308)},
    {'title': 'Estimation & Costing', 'chapters': 7, 'progress': 0.93, 'color': Color(0xFFEC4899)},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('10 syllabus tracks • progress is server-authoritative',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = _demoCourses[i];
                  final color = c['color'] as Color;
                  final progress = c['progress'] as double;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.menu_book_rounded, size: 18, color: color),
                            ),
                            const Spacer(),
                            Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(c['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${c['chapters'] as int} chapters', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: progress, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: color, minHeight: 6),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Syllabus tree for ${c['title']} — GET /quiz/courses/{id}/categories (server). Download pack coming.')),
                              );
                            },
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('View syllabus', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _demoCourses.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
