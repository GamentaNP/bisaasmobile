import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/script_fonts.dart';
import '../../domain/entities/book.dart';
import '../controllers/book_controller.dart';

/// The reader.
///
/// Two things this screen deliberately does not do:
///
/// It does not compute completion from pages read. The percentage is the
/// server's, because a local figure would disagree with the server the moment
/// their definitions diverged and the user would watch the number move
/// backwards.
///
/// It does not claim a reward the server did not award. `PUT /book/progress`
/// returns a `credit` block that can be **voided** with a reason; that reason is
/// shown as-is.
class BookReaderScreen extends ConsumerWidget {
  const BookReaderScreen({
    required this.slug,
    required this.bookId,
    required this.topicId,
    required this.startPage,
    super.key,
  });

  final String slug;
  final int bookId;
  final int topicId;
  final int startPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = (slug: slug, bookId: bookId, topicId: topicId);
    final state = ref.watch(readerControllerProvider(target));
    final notifier = ref.read(readerControllerProvider(target).notifier);

    return PopScope(
      // Leaving the reader is the natural moment to report the session, so the
      // time is credited rather than lost.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) notifier.syncProgress();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Page ${state.pageNumber}'),
          actions: [
            IconButton(
              tooltip: 'My highlights',
              onPressed: () {
                notifier.loadHighlights();
                _showHighlights(context, state.highlights);
              },
              icon: const Icon(Icons.bookmark_border),
            ),
          ],
        ),
        body: _body(context, state, notifier),
        bottomNavigationBar: _controls(context, state, notifier),
      ),
    );
  }

  Widget _body(BuildContext context, ReaderState state, ReaderController notifier) {
    if (state.isLoading && state.page == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.page == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: notifier.retry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final page = state.page;
    if (page == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (state.lastCreditMessage != null) ...[
          _CreditBanner(message: state.lastCreditMessage!),
          const SizedBox(height: 16),
        ],
        if (page.blocks.isEmpty)
          Text(
            'This page has no extractable text. It may be an image-only scan.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          // Blocks are ordered by the server. Positioned blocks are not laid out
          // on a canvas here because the facsimile is lost the moment the text is
          // reflowed for a phone; a vertical reading order is more honest than a
          // broken approximation of the print layout.
          for (final block in page.blocks) _BlockView(block: block),
      ],
    );
  }

  Widget _controls(BuildContext context, ReaderState state, ReaderController notifier) {
    final progress = state.progress;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed: state.pageNumber <= 1 ? null : notifier.previousPage,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: progress == null
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: progress.completionPercentage.clamp(0, 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress.completionPercentage.toStringAsFixed(0)}% complete',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: notifier.nextPage,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  void _showHighlights(BuildContext context, List<BookHighlight> highlights) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Your highlights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (highlights.isEmpty)
              const Text('You have not highlighted anything yet.')
            else
              for (final h in highlights)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.bookmark, color: _highlightColor(h.colorCode)),
                  title: Text(h.highlightedText),
                  subtitle: h.noteContent == null ? null : Text(h.noteContent!),
                ),
          ],
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});

  final BookPageBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A block with no extractable text is a picture or a table the extractor
    // could not read. Saying so beats rendering an unexplained gap.
    if (!block.isTextual) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.image_outlined, size: 18, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                block.type == null
                    ? 'Image or diagram (not available as text)'
                    : '${block.type} (not available as text)',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final text = block.text!;
    final style = switch (block.type) {
      'heading' || 'title' => theme.textTheme.titleLarge,
      'formula' || 'equation' => theme.textTheme.bodyLarge?.copyWith(
          fontFamily: 'monospace',
        ),
      _ => theme.textTheme.bodyLarge,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        // Book content is the single most likely place for mixed-script text in
        // the app — a Nepali edition of an English textbook — so the font is
        // resolved from the string rather than the app's language.
        style: ScriptFonts.forText(style ?? const TextStyle(), text),
      ),
    );
  }
}

class _CreditBanner extends StatelessWidget {
  const _CreditBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A voided session reads differently from an award, so it is styled as a
    // notice rather than as a reward.
    final isVoid = message.startsWith('This reading session was not counted');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVoid ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isVoid
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Server-allowed highlight colours. Anything else is rejected by the request's
/// `in:` rule, so this map is the full set rather than a guess.
Color _highlightColor(String code) => switch (code) {
      'green' => const Color(0xFF2E7D32),
      'blue' => const Color(0xFF1565C0),
      'pink' => const Color(0xFFAD1457),
      'purple' => const Color(0xFF6A1B9A),
      _ => const Color(0xFFF9A825),
    };
