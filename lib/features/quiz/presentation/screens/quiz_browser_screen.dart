import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';

/// Browses the server-side quiz catalog. Calls `GET /api/v1/quiz`
/// with `?filter[category]=&search=&sort=-created_at` and renders
/// domain-grouped cards + search bar.
class QuizBrowserScreen extends ConsumerStatefulWidget {
  const QuizBrowserScreen({super.key});

  @override
  ConsumerState<QuizBrowserScreen> createState() => _QuizBrowserScreenState();
}

class _QuizBrowserScreenState extends ConsumerState<QuizBrowserScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _activeCategory;
  late Future<List<QuizListEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _query = v.trim();
        _future = _load();
      });
    });
  }

  Future<List<QuizListEntry>> _load() async {
    final dio = DioClient.instance.dio;
    final qp = <String, dynamic>{'sort': '-created_at', 'per_page': 50};
    if (_query.isNotEmpty) qp['search'] = _query;
    if (_activeCategory != null) qp['filter[category]'] = _activeCategory;
    final res = await dio.get<Map<String, dynamic>>('/quiz', queryParameters: qp);
    final data = res.data?['data'] as List? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(QuizListEntry.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeAreaScaffold(
      appBar: CivilAppBar(title: 'Browse Quizzes'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search quizzes…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: AppRadii.mdAll),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(label: 'All', active: _activeCategory == null, onTap: () {
                  setState(() {
                    _activeCategory = null;
                    _future = _load();
                  });
                }),
                ..._kCategories.map((c) => _CategoryChip(
                      label: c,
                      active: _activeCategory == c,
                      onTap: () {
                        setState(() {
                          _activeCategory = c;
                          _future = _load();
                        });
                      },
                    )),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<QuizListEntry>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: snap.error.toString(),
                    onRetry: () => setState(() => _future = _load()),
                  );
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No quizzes found',
                    subtitle: 'Try a different search or category',
                    icon: Icons.search_off_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _QuizCard(entry: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuizListEntry {
  const QuizListEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.questionCount,
    required this.durationMinutes,
    this.difficulty = 2,
  });
  final String id;
  final String title;
  final String category;
  final int questionCount;
  final int durationMinutes;
  final int difficulty;

  factory QuizListEntry.fromJson(Map<String, dynamic> j) => QuizListEntry(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? j['name'] ?? 'Quiz').toString(),
        category: (j['category'] ?? j['subject'] ?? 'general').toString(),
        questionCount: (j['question_count'] as int?) ?? (j['total_questions'] as int?) ?? 10,
        durationMinutes: (j['duration_minutes'] as int?) ?? 15,
        difficulty: (j['difficulty'] as int?) ?? 2,
      );
}

const _kCategories = ['PSC Civil', 'GATE', 'IOE', 'Lok Sewa', 'Structural', 'Geotechnical', 'Survey', 'Highway', 'Fluid'];

/// Solid category fills + matching extrusion shadows (Duolongo style).
const _kCategoryColors = [
  Color(0xFF58CC02), // brand green
  Color(0xFF1CB0F6), // blue
  Color(0xFFCE82FF), // purple
  Color(0xFFFF9600), // orange
  Color(0xFFFF4B4B), // red
  Color(0xFFFFC800), // gold
];

const _kCategoryIcons = [
  Icons.quiz_rounded,
  Icons.calculate_rounded,
  Icons.architecture_rounded,
  Icons.construction_rounded,
  Icons.terrain_rounded,
  Icons.water_drop_rounded,
];

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.brand,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.surfaceSecondary,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: active ? Colors.white : AppColors.textSecondaryLight,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.entry});
  final QuizListEntry entry;

  @override
  Widget build(BuildContext context) {
    final tileColor = _kCategoryColors[
        entry.category.hashCode.abs() % _kCategoryColors.length];
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/quiz/intro/${entry.id}'),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.18),
                  width: 3,
                ),
              ),
            ),
            child: Icon(_kCategoryIcons[
                entry.category.hashCode.abs() % _kCategoryIcons.length],
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  '${entry.questionCount} Qs · ${entry.durationMinutes} min · ${entry.category}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
