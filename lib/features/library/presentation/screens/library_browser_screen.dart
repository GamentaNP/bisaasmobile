import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/library_controller.dart';
import '../../domain/entities/library.dart';

/// Library browser — `GET /library/categories`, `/library/files` (paginated+search),
/// `/library/trending`, `/library/recommendations`.
///
/// Server-authoritative, tolerant to additive fields.
/// Features never import each other directly — only via providers/router.
class LibraryBrowserScreen extends ConsumerStatefulWidget {
  const LibraryBrowserScreen({super.key});

  @override
  ConsumerState<LibraryBrowserScreen> createState() => _LibraryBrowserScreenState();
}

class _LibraryBrowserScreenState extends ConsumerState<LibraryBrowserScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Initial load
    Future.microtask(() {
      final c = ref.read(libraryControllerProvider.notifier);
      c.fetchCategories();
      c.fetchFiles(page: 1, perPage: 20);
      c.trending();
      c.recommendations();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    final q = v.trim();
    setState(() => _query = q.toLowerCase());
    // Debounced fetch — immediate for now; could add Timer debouncer
    ref.read(libraryControllerProvider.notifier).fetchFiles(query: q, page: 1);
  }

  void _onCategoryTap(int? categoryId) {
    final notifier = ref.read(libraryControllerProvider.notifier);
    notifier.setCategory(categoryId);
    notifier.fetchFiles(categoryId: categoryId, page: 1, query: _query);
  }

  Future<void> _onRefresh() async {
    final n = ref.read(libraryControllerProvider.notifier);
    await Future.wait([
      n.fetchCategories(),
      n.fetchFiles(page: 1, query: _query.isEmpty ? null : _query),
      n.trending(),
      n.recommendations(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search files, categories…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Categories horizontal chips
            SliverToBoxAdapter(
              child: _CategoriesStrip(
                categories: state.categories,
                selectedId: state.selectedCategoryId,
                isLoading: state.isCategoriesLoading,
                error: state.categoriesError,
                onRetry: () => ref.read(libraryControllerProvider.notifier).fetchCategories(),
                onSelect: _onCategoryTap,
              ),
            ),

            // Trending horizontal
            if (state.trending.isNotEmpty || state.isTrendingLoading)
              SliverToBoxAdapter(
                child: _HorizontalFileSection(
                  title: 'Trending',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.streakOrange,
                  files: state.trending,
                  isLoading: state.isTrendingLoading,
                  onTap: (f) => context.push('/library/${f.slug}'),
                ),
              ),

            // Recommendations horizontal
            if (state.recommendations.isNotEmpty || state.isRecommendationsLoading)
              SliverToBoxAdapter(
                child: _HorizontalFileSection(
                  title: 'Recommended for you',
                  icon: Icons.recommend_rounded,
                  color: AppColors.brand,
                  files: state.recommendations,
                  isLoading: state.isRecommendationsLoading,
                  onTap: (f) => context.push('/library/${f.slug}'),
                ),
              ),

            // Files header + grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('Files', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (state.filesPagination != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('${state.filesPagination!.total ?? state.files.length} total',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
                      ),
                    const Spacer(),
                    if (state.isFilesLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),

            if (state.filesError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ErrorView(message: state.filesError!, onRetry: () => ref.read(libraryControllerProvider.notifier).fetchFiles(page: 1)),
                ),
              )
            else if (state.files.isEmpty && !state.isFilesLoading)
              SliverToBoxAdapter(
                child: EmptyState(
                  title: _query.isEmpty ? 'No files yet' : 'No results for "$_query"',
                  subtitle: _query.isEmpty
                      ? 'Library files will appear here once published and approved on the server.'
                      : 'Try a different search term or clear filters.',
                  icon: Icons.library_books_rounded,
                  action: _query.isNotEmpty
                      ? FilledButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                          child: const Text('Clear search'),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final file = state.files[i];
                      return _FileCard(file: file, onTap: () => context.push('/library/${file.slug}'));
                    },
                    childCount: state.files.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                ),
              ),

            // Load more / pagination hint
            if (state.filesPagination != null && (state.filesPagination!.hasMore ?? false))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: OutlinedButton.icon(
                    onPressed: state.isFilesLoading
                        ? null
                        : () {
                            final next = (state.filesPagination!.currentPage ?? 1) + 1;
                            ref.read(libraryControllerProvider.notifier).fetchFiles(page: next, append: true);
                          },
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('Load more'),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Categories strip ──────────────────────────────────────────────────────────

class _CategoriesStrip extends StatelessWidget {
  const _CategoriesStrip({
    required this.categories,
    required this.selectedId,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onSelect,
  });

  final List<LibraryCategory> categories;
  final int? selectedId;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(int? id) onSelect;

  @override
  Widget build(BuildContext context) {
    if (isLoading && categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (error != null && categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorView(message: error!, onRetry: onRetry),
      );
    }
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text('No categories published', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    // Flatten children for chip display: show parents + children count
    final chips = <(int? id, String label, int? count)>[
      (null, 'All', null),
      for (final c in categories) (c.id, c.name, c.fileCount),
      for (final c in categories)
        for (final child in c.children) (child.id, '${c.name} › ${child.name}', child.fileCount),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label, count) = chips[i];
          final selected = id == selectedId;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.brand)),
                  ),
                ],
              ],
            ),
            selected: selected,
            onSelected: (_) => onSelect(id),
          );
        },
      ),
    );
  }
}

// ── Horizontal file section (trending/recommendations) ─────────────────────

class _HorizontalFileSection extends StatelessWidget {
  const _HorizontalFileSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.files,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<LibraryFile> files;
  final bool isLoading;
  final void Function(LibraryFile) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        SizedBox(
          height: 132,
          child: isLoading && files.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final f = files[i];
                    return SizedBox(
                      width: 200,
                      child: _FileCard(file: f, onTap: () => onTap(f), compact: true),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── File card ───────────────────────────────────────────────────────────────

class _FileCard extends StatelessWidget {
  const _FileCard({required this.file, required this.onTap, this.compact = false});
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 12, color: AppColors.coinYellow),
                        const SizedBox(width: 2),
                        Text('${file.coinPrice}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coinYellow)),
                      ],
                    ),
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
            if (!compact && file.description != null && file.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(file.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
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
            if (file.category != null) ...[
              const SizedBox(height: 4),
              Text(file.category!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ],
        ),
      ),
    );
  }
}
