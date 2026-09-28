import '../entities/book.dart';

/// Book Engine reads and reader actions.
///
/// Reading progress and reward credit are server-computed. `reportProgress`
/// returns the server's own credit verdict, including when it voided the
/// session, so the reader never has to infer whether time counted.
abstract class BookRepository {
  Future<List<Book>> getBooks({String? query, String? discipline, String? subjectCode});

  Future<Book?> getBook(String slug);

  Future<List<BookChapter>> getChapters(String slug);

  Future<BookChapter?> getChapter(String slug, int chapterId);

  Future<BookPage?> getPage(String slug, int pageNumber);

  /// Returns the server's verdict, including a voided credit. Null when the
  /// response was not understood, which the caller must not treat as success.
  Future<ReadingProgress?> reportProgress({
    required int bookId,
    required int topicId,
    required int pageNumber,
    int? timeSpentSeconds,
    int? blockId,
    int? wordsRead,
  });

  Future<ReadingProgress?> getProgress(int bookId);

  Future<List<BookHighlight>> getMyHighlights();

  Future<BookHighlight?> createHighlight({
    required int contentBlockId,
    required String highlightedText,
    required int startOffset,
    required int endOffset,
    String? colorCode,
    String? noteContent,
  });

  Future<BookNote?> createNote({required String body, int? contentBlockId, int? pageNumber});

  /// Spends coins. Idempotent server-side.
  Future<bool> unlockChapter(int chapterId);
}
