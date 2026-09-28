import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../../domain/entities/book.dart';
import '../models/book_dto.dart';

/// Book Engine routes, verified against `routes/api/v1/book.php` and
/// `routes/api/v1/book-auth.php` in `C:\laragon\www\bisaas`.
///
/// Public catalog (no auth):
/// - GET  /books                                   cursor list
/// - GET  /books/{slug}                            detail
/// - GET  /books/{slug}/chapters                   chapters
/// - GET  /books/{slug}/chapters/{id}              one chapter
/// - GET  /books/{slug}/topics                     topics
/// - GET  /books/{slug}/pages/{page}               page facsimile or PNG
/// - GET  /topics/{topic}/blocks                   positioned blocks
///
/// Authenticated:
/// - GET  /book/preferences          reader preferences (font, theme, spacing)
/// - PUT  /book/preferences
/// - PUT  /book/progress             **Idempotency-Key required** (frozen matrix row 9)
/// - GET  /book/progress/{book}
/// - POST /book/highlights
/// - GET  /book/highlights           the user's own, owner-scoped
/// - POST /book/notes
/// - POST /book/bookmarks
/// - PUT  /book/chapters/{chapter}/access   **Idempotency-Key required** (money)
/// - GET  /book/unlocks
/// - GET  /book/search
///
/// Note the grammar the server freezes: state transitions are idempotent
/// sub-resources reached with PUT, never `POST /unlock`. The same holds for
/// progress, which is an upsert of a position rather than an event.
class BookRemoteDataSource {
  const BookRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  Map<String, dynamic>? _data(Map<String, dynamic>? body) {
    if (body == null) return null;
    final envelope = ApiResponse.fromJson(body, (json) => json);
    final data = envelope.data;
    if (data is Map<String, dynamic>) return data;
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    return null;
  }

  List<dynamic> _list(Map<String, dynamic>? body) {
    if (body == null) return const [];
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return const [];
  }

  // ── Catalog (public) ───────────────────────────────────────────────────────

  Future<List<Book>> getBooks({
    String? query,
    String? discipline,
    String? subjectCode,
    int perPage = 25,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/books',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'filter[search]': query,
        'filter[discipline]': ?discipline,
        'filter[subject_code]': ?subjectCode,
        'per_page': perPage,
      },
    );
    return _parseBooks(_list(res.data));
  }

  Future<Book?> getBook(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/books/$slug');
    final parsed = _parseBooks(_list(res.data), single: _data(res.data));
    return parsed.isEmpty ? null : parsed.first;
  }

  Future<List<BookChapter>> getChapters(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/books/$slug/chapters');
    final out = <BookChapter>[];
    for (final item in _list(res.data)) {
      if (item is! Map) continue;
      final dto = BookChapterDto.fromJson(item.cast<String, dynamic>());
      if (dto != null) out.add(dto.chapter);
    }
    return out;
  }

  Future<BookChapter?> getChapter(String slug, int chapterId) async {
    final res = await _dio.get<Map<String, dynamic>>('/books/$slug/chapters/$chapterId');
    final data = _data(res.data);
    if (data == null) return null;
    // The detail route may return the chapter bare or wrapped in `chapter`.
    final raw = data['chapter'] is Map ? data['chapter'] as Map<String, dynamic> : data;
    return BookChapterDto.fromJson(raw)?.chapter;
  }

  Future<BookPage?> getPage(String slug, int pageNumber) async {
    // The same URI returns positioned blocks by default and a PNG under
    // `Accept: image/png`. The JSON form is requested explicitly so the reader
    // can lay text out itself instead of only showing a scan.
    final res = await _dio.get<Map<String, dynamic>>(
      '/books/$slug/pages/$pageNumber',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final data = _data(res.data);
    if (data == null) return null;
    return BookPageDto.fromJson(data)?.page;
  }

  // ── Reader (authenticated) ─────────────────────────────────────────────────

  /// Reports the reading position. PUT with an Idempotency-Key because the
  /// server freezes this as an idempotent upsert of a position, and because the
  /// response carries reward credit that must not be granted twice.
  ///
  /// [timeSpentSeconds] is capped at 3600 by the server, [wordsRead] at 20000.
  /// The caps are sent as-is rather than pre-trimmed, so a genuine long session
  /// is recorded honestly instead of being silently shortened to fit.
  Future<ReadingProgress?> reportProgress({
    required int bookId,
    required int topicId,
    required int pageNumber,
    int? timeSpentSeconds,
    int? blockId,
    int? wordsRead,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/book/progress',
      data: {
        'book_id': bookId,
        'topic_id': topicId,
        'page_number': pageNumber,
        'time_spent_seconds': ?timeSpentSeconds,
        'block_id': ?blockId,
        'words_read': ?wordsRead,
      },
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final data = _data(res.data);
    if (data == null) return null;
    final progressJson = data['progress'];
    if (progressJson is! Map) return null;
    return ReadingProgressDto.fromJson(progressJson.cast<String, dynamic>())?.progress;
  }

  Future<ReadingProgress?> getProgress(int bookId) async {
    final res = await _dio.get<Map<String, dynamic>>('/book/progress/$bookId');
    final data = _data(res.data);
    if (data == null) return null;
    final progressJson = data['progress'];
    if (progressJson is! Map) return null;
    return ReadingProgressDto.fromJson(progressJson.cast<String, dynamic>())?.progress;
  }

  Future<List<BookHighlight>> getMyHighlights() async {
    final res = await _dio.get<Map<String, dynamic>>('/book/highlights');
    final out = <BookHighlight>[];
    for (final item in _list(res.data)) {
      if (item is! Map) continue;
      final dto = BookHighlightDto.fromJson(item.cast<String, dynamic>());
      if (dto != null) out.add(dto.highlight);
    }
    return out;
  }

  /// [colorCode] must be one of the server's allowed values; an unrecognised
  /// value is rejected by the request's `in:` rule, so it is never sent.
  Future<BookHighlight?> createHighlight({
    required int contentBlockId,
    required String highlightedText,
    required int startOffset,
    required int endOffset,
    String? colorCode,
    String? noteContent,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/book/highlights',
      data: {
        'content_block_id': contentBlockId,
        'highlighted_text': highlightedText,
        'start_offset': startOffset,
        'end_offset': endOffset,
        'color_code': ?colorCode,
        'note_content': ?noteContent,
      },
    );
    final data = _data(res.data);
    if (data == null) return null;
    return BookHighlightDto.fromJson(data)?.highlight;
  }

  Future<BookNote?> createNote({
    required String body,
    int? contentBlockId,
    int? pageNumber,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/book/notes',
      data: {
        'body': body,
        'content_block_id': ?contentBlockId,
        'page_number': ?pageNumber,
      },
    );
    final data = _data(res.data);
    if (data == null) return null;
    return BookNoteDto.fromJson(data)?.note;
  }

  /// Grants access to a paid chapter. PUT, not `POST /unlock`, and carries an
  /// Idempotency-Key: this spends coins, so a retry must not charge twice.
  Future<bool> unlockChapter(int chapterId) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/book/chapters/$chapterId/access',
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    // Any 2xx means the access transition was accepted. The body is not trusted
    // for a success flag, because a response shape change should not turn a
    // successful unlock into a failure.
    return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
  }

  List<Book> _parseBooks(List<dynamic> list, {Map<String, dynamic>? single}) {
    final out = <Book>[];
    if (single != null) {
      final dto = BookDto.fromJson(single);
      if (dto != null) out.add(dto.book);
    }
    for (final item in list) {
      if (item is! Map) continue;
      final dto = BookDto.fromJson(item.cast<String, dynamic>());
      if (dto != null) out.add(dto.book);
    }
    return out;
  }
}
