import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/past_paper.dart';
import '../controllers/past_papers_controller.dart';

/// Past-paper catalog from `GET /quiz/past-papers`.
///
/// The server sorts by year with an id tiebreak and hands back an opaque
/// `next_cursor`; this screen walks that cursor and never sends `page`.
class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen> {
  final TextEditingController _search = TextEditingController();
  List<PastPaperListItem> _items = const [];
  List<dynamic> _years = const [];
  String? _cursor;
  String? _year;
  bool _hasMore = false;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  PastPaperQuery get _query => (
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
        country: null,
        province: null,
        year: _year,
        paper: null,
      );

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await ref.read(pastPapersRepositoryProvider).getPapers(
            search: _query.search,
            year: _query.year,
          );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _years = (page.facets['years'] as List?) ?? const [];
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Cursor walking only. A failure keeps the rows already loaded and shows a
  /// retry — it never turns into "you have no past papers".
  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || cursor.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await ref.read(pastPapersRepositoryProvider).getPapers(
            search: _query.search,
            year: _query.year,
            cursor: cursor,
          );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pastPapersTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: l10n.searchTitle,
                hintText: l10n.librarySearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          if (_years.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  for (final value in _years)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(value.toString()),
                        selected: _year == value.toString(),
                        onSelected: (_) {
                          setState(() => _year = value.toString());
                          _reload();
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _busy && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                    ? ErrorView(
                        message: ErrorHandler.handle(_error!).message,
                        onRetry: _reload,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length + (_hasMore ? 2 : 1) + (_error != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _items.length) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                title: Text(item.label),
                                subtitle: Text([
                                  if (item.authority != null) item.authority!,
                                  if (item.examName != null) item.examName!,
                                  l10n.syllabusPapersCount(item.totalQuestions),
                                ].join(' • ')),
                                trailing: item.verified
                                    ? const Icon(Icons.verified_rounded, size: 18)
                                    : null,
                                onTap: () => context.go('/quiz/past-papers/${item.id}'),
                              ),
                            );
                          }
                          final tail = index - _items.length;
                          if (tail == 0 && _error != null) {
                            return ErrorView(
                              message: ErrorHandler.handle(_error!).message,
                              onRetry: _cursor == null ? _reload : _loadMore,
                            );
                          }
                          if (_hasMore && !_busy) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: OutlinedButton(
                                onPressed: _loadMore,
                                child: Text(l10n.commonLoadMore),
                              ),
                            );
                          }
                          if (_items.isEmpty) {
                            return EmptyState(
                              title: l10n.pastPapersEmpty,
                              icon: Icons.description_outlined,
                              compact: true,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
