import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/word_bank.dart';
import '../controllers/word_bank_controller.dart';

/// Vocabulary catalog from `GET /quiz/word-bank`.
///
/// Difficulty chips come from the server's own `all_difficulties` list; no
/// filter value is invented on-device. Mastery is displayed as received —
/// never recomputed from rows.
class WordBankScreen extends ConsumerStatefulWidget {
  const WordBankScreen({super.key});

  @override
  ConsumerState<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends ConsumerState<WordBankScreen> {
  final TextEditingController _search = TextEditingController();
  List<WordBankEntry> _items = const [];
  List<String> _difficulties = const [];
  String _difficulty = 'all';
  String? _cursor;
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

  String? get _searchTerm =>
      _search.text.trim().isEmpty ? null : _search.text.trim();

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await ref.read(wordBankRepositoryProvider).getWords(
            search: _searchTerm,
            difficulty: _difficulty,
          );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _difficulties = page.allDifficulties;
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || cursor.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await ref.read(wordBankRepositoryProvider).getWords(
            search: _searchTerm,
            difficulty: _difficulty,
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
      appBar: AppBar(title: Text(l10n.wordBankTitle)),
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
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final value in _difficulties)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: _difficulty == value,
                      onSelected: (_) {
                        setState(() => _difficulty = value);
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
                        itemCount: _items.length +
                            (_hasMore ? 1 : 0) +
                            (_error != null ? 1 : 0) +
                            (_items.isEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _items.length) {
                            final item = _items[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.term,
                                        style: Theme.of(context).textTheme.titleSmall),
                                    Text(l10n.quizSrsDefinition(item.definition)),
                                    if (item.example != null)
                                      Text(l10n.quizSrsExample(item.example!)),
                                    Text(l10n.practiceDifficultyLabel(item.difficulty)),
                                    if (item.mastery != null)
                                      Text(l10n.commonPercent(item.mastery!)),
                                  ],
                                ),
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
                              title: l10n.wordBankEmpty,
                              icon: Icons.translate_outlined,
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
