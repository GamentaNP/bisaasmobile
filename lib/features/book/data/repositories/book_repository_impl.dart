import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._remote);
  final BookRemoteDataSource _remote;

  @override
  Future<List<Book>> getBooks({String? query, String? discipline, String? subjectCode}) =>
      _remote.getBooks(query: query, discipline: discipline, subjectCode: subjectCode);

  @override
  Future<Book?> getBook(String slug) => _remote.getBook(slug);

  @override
  Future<List<BookChapter>> getChapters(String slug) => _remote.getChapters(slug);

  @override
  Future<BookChapter?> getChapter(String slug, int chapterId) => _remote.getChapter(slug, chapterId);

  @override
  Future<BookPage?> getPage(String slug, int pageNumber) => _remote.getPage(slug, pageNumber);

  @override
  Future<ReadingProgress?> reportProgress({
    required int bookId,
    required int topicId,
    required int pageNumber,
    int? timeSpentSeconds,
    int? blockId,
    int? wordsRead,
  }) =>
      _remote.reportProgress(
        bookId: bookId,
        topicId: topicId,
        pageNumber: pageNumber,
        timeSpentSeconds: timeSpentSeconds,
        blockId: blockId,
        wordsRead: wordsRead,
      );

  @override
  Future<ReadingProgress?> getProgress(int bookId) => _remote.getProgress(bookId);

  @override
  Future<List<BookHighlight>> getMyHighlights() => _remote.getMyHighlights();

  @override
  Future<BookHighlight?> createHighlight({
    required int contentBlockId,
    required String highlightedText,
    required int startOffset,
    required int endOffset,
    String? colorCode,
    String? noteContent,
  }) =>
      _remote.createHighlight(
        contentBlockId: contentBlockId,
        highlightedText: highlightedText,
        startOffset: startOffset,
        endOffset: endOffset,
        colorCode: colorCode,
        noteContent: noteContent,
      );

  @override
  Future<BookNote?> createNote({required String body, int? contentBlockId, int? pageNumber}) =>
      _remote.createNote(body: body, contentBlockId: contentBlockId, pageNumber: pageNumber);

  @override
  Future<bool> unlockChapter(int chapterId) => _remote.unlockChapter(chapterId);
}
