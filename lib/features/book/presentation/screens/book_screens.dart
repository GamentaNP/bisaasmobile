import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/script_fonts.dart';
import '../../domain/entities/book.dart';
import '../controllers/book_controller.dart';

/// Book catalog. Public server-side, so it must render signed out.
class BookCatalogScreen extends ConsumerStatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  ConsumerState<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends ConsumerState<BookCatalogScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookCatalogControllerProvider);
    final notifier = ref.read(bookCatalogControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search books',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: notifier.search,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: _body(context, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, BookCatalogState state, BookCatalogController notifier) {
    if (state.isLoading && state.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.books.isEmpty) {
      return _Message(
        text: state.error!,
        actionLabel: 'Retry',
        onAction: notifier.refresh,
      );
    }
    if (state.isEmpty) {
      return _Message(
        text: state.query.isEmpty
            ? 'No books have been published yet.'
            : 'No books match "${state.query}".',
        actionLabel: state.query.isEmpty ? 'Retry' : 'Clear search',
        onAction: state.query.isEmpty ? notifier.refresh : () => notifier.search(''),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _BookCard(book: state.books[i]),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = book.title;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/books/${book.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ScriptFonts.forText(theme.textTheme.titleMedium ?? const TextStyle(), title)),
              if (book.subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(book.subtitle!, style: theme.textTheme.bodySmall),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (book.disciplineLabel != null) _Meta(book.disciplineLabel!),
                  if (book.totalPages > 0) _Meta('${book.totalPages} pages'),
                  if (book.totalChapters > 0) _Meta('${book.totalChapters} chapters'),
                  if (book.estimatedReadHours > 0)
                    _Meta('${book.estimatedReadHours.toStringAsFixed(0)} h'),
                  if (book.costsCoins) _Meta('${book.coinUnlockPrice} coins'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One book: metadata, progress, and the chapter list with its access state.
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookDetailControllerProvider(slug));
    final notifier = ref.read(bookDetailControllerProvider(slug).notifier);
    final theme = Theme.of(context);
    final preferNative =
        (ref.watch(localeProvider)?.languageCode ?? 'en') != 'en';

    if (state.isLoading && state.book == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && state.book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _Message(text: state.error!, actionLabel: 'Retry', onAction: notifier.load),
      );
    }

    final book = state.book;
    if (book == null) return const SizedBox.shrink();

    final progress = state.progress;
    return Scaffold(
      appBar: AppBar(title: Text(book.title, overflow: TextOverflow.ellipsis)),
      body: RefreshIndicator(
        onRefresh: () => notifier.load(force: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              book.title,
              style: ScriptFonts.forText(theme.textTheme.headlineSmall ?? const TextStyle(), book.title),
            ),
            if (book.authorName != null)
              Text(book.authorName!, style: theme.textTheme.bodyMedium),
            if (book.publisherName != null)
              Text(book.publisherName!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (book.disciplineLabel != null) _Meta(book.disciplineLabel!),
                if (book.targetExam != null) _Meta(book.targetExam!),
                if (book.totalPages > 0) _Meta('${book.totalPages} pages'),
                if (book.totalFormulas > 0) _Meta('${book.totalFormulas} formulas'),
                if (book.totalNumericals > 0) _Meta('${book.totalNumericals} numericals'),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress.completionPercentage.clamp(0, 1)),
              const SizedBox(height: 6),
              Text(
                '${progress.completionPercentage.toStringAsFixed(0)}% · page '
                '${progress.currentPageNumber ?? '—'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const Divider(height: 32),
            Text('Chapters', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (book.chapters.isEmpty)
              Text('No chapters published yet.', style: theme.textTheme.bodySmall)
            else
              ...book.chapters.map(
                (c) => _ChapterTile(
                  chapter: c,
                  preferNative: preferNative,
                  unlocking: state.unlockingChapterId == c.id,
                  onOpen: () => _openChapter(context, ref, book, c),
                  onUnlock: () => notifier.unlockChapter(c.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Enters the reader at the server's saved position when there is one, so a
  /// returning reader lands where they left off rather than at page 1.
  void _openChapter(BuildContext context, WidgetRef ref, Book book, BookChapter chapter) {
    final progress = ref.read(bookDetailControllerProvider(slug)).progress;
    final page = progress?.currentPageNumber ?? chapter.startPage ?? 1;
    final topicId = progress?.currentTopicId ?? chapter.topics.firstOrNull?.id;
    if (topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This chapter has no topics to open yet.')),
      );
      return;
    }
    context.push(
      '/books/${book.slug}/read?book=${book.id}&topic=$topicId&page=$page',
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.preferNative,
    required this.unlocking,
    required this.onOpen,
    required this.onUnlock,
  });

  final BookChapter chapter;
  final bool preferNative;
  final bool unlocking;
  final VoidCallback onOpen;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = chapter.titleFor(preferNative: preferNative);
    final range = chapter.pageRangeLabel;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: ScriptFonts.forText(theme.textTheme.bodyLarge ?? const TextStyle(), title)),
      subtitle: Text(
        [
          ?range,
          if (chapter.estimatedReadMinutes != null) '${chapter.estimatedReadMinutes} min',
          if (chapter.isFreePreview) 'Free preview',
        ].join('  ·  '),
        style: theme.textTheme.labelSmall,
      ),
      trailing: unlocking
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : chapter.costsCoins
              ? TextButton(
                  onPressed: onUnlock,
                  child: Text('${chapter.coinUnlockPrice} coins'),
                )
              : const Icon(Icons.chevron_right),
      onTap: chapter.costsCoins ? onUnlock : onOpen,
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.actionLabel, required this.onAction});

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.menu_book_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}
