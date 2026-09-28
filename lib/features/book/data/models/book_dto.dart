/// Book Engine DTOs.
///
/// Shapes verified against:
/// - `app/Http/Resources/Api/V1/Book/BookResource.php`
/// - `app/Http/Resources/Api/V1/Book/BookChapterResource.php`
/// - `app/Http/Resources/Api/V1/Book/BookPageResource.php`
/// - `app/Http/Controllers/Api/V1/Book/ReaderController.php` (progress + credit)
library;

import '../../domain/entities/book.dart';

int _toInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? _toIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double _toDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

String? _strOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _dateOrNull(Object? v) {
  final s = _strOrNull(v);
  return s == null ? null : DateTime.tryParse(s);
}

List<String> _stringList(Object? v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
}

/// Highlight colours the server accepts.
///
/// `ReaderController::highlight()` validates `color_code` with
/// `in:yellow,green,blue,pink,purple`. A value outside that set is rejected on
/// write, so an unrecognised colour read from a response is normalised here
/// rather than echoed back on a later save.
const _highlightColors = {'yellow', 'green', 'blue', 'pink', 'purple'};

String _highlightColorOrDefault(Object? v) {
  final s = _strOrNull(v)?.toLowerCase();
  return (s != null && _highlightColors.contains(s)) ? s : 'yellow';
}

class BookTopicDto {
  const BookTopicDto(this.topic);
  final BookTopic topic;

  static BookTopicDto? fromJson(Map<String, dynamic> json) {
    final id = _toIntOrNull(json['id']);
    final title = _strOrNull(json['title']);
    if (id == null || title == null) return null;
    return BookTopicDto(BookTopic(
      id: id,
      title: title,
      pageNumber: _toIntOrNull(json['page_number'] ?? json['start_page']),
      contentBlockCount: _toInt(json['content_blocks_count'] ?? json['contentBlockCount']),
    ));
  }
}

class BookChapterDto {
  const BookChapterDto(this.chapter);
  final BookChapter chapter;

  /// `end_page` is already null server-side when the stored value is the 9999
  /// sentinel, so a null here is the server saying "unknown", not a parse error.
  /// Guarding for the sentinel anyway costs nothing and protects against a
  /// second code path that forgets to map it.
  static BookChapterDto? fromJson(Map<String, dynamic> json) {
    final id = _toIntOrNull(json['id']);
    final title = _strOrNull(json['title']);
    if (id == null || title == null) return null;

    final topics = <BookTopic>[];
    final topicsJson = json['topics'];
    if (topicsJson is List) {
      for (final t in topicsJson) {
        if (t is! Map) continue;
        final parsed = BookTopicDto.fromJson(t.cast<String, dynamic>());
        if (parsed != null) topics.add(parsed.topic);
      }
    }

    var endPage = _toIntOrNull(json['end_page']);
    if (endPage != null && endPage >= 9999) endPage = null;

    return BookChapterDto(BookChapter(
      id: id,
      title: title,
      chapterNumber: _toIntOrNull(json['chapter_number']),
      displayNumber: _strOrNull(json['display_number']),
      slug: _strOrNull(json['slug']),
      titleNe: _strOrNull(json['title_ne']),
      learningObjectives: _stringList(json['learning_objectives']),
      startPage: _toIntOrNull(json['start_page']),
      endPage: endPage,
      estimatedReadMinutes: _toIntOrNull(json['estimated_read_minutes']),
      isFreePreview: json['is_free_preview'] == true,
      isPublished: json['is_published'] != false,
      coinUnlockPrice: _toIntOrNull(json['coin_unlock_price']),
      topics: topics,
    ));
  }
}

class BookDto {
  const BookDto(this.book);
  final Book book;

  static BookDto? fromJson(Map<String, dynamic> json) {
    final id = _toIntOrNull(json['id']);
    final slug = _strOrNull(json['slug']);
    final title = _strOrNull(json['title']);
    // A catalog card cannot be rendered without an id, a slug (every detail
    // route is keyed on it) or a title.
    if (id == null || slug == null || title == null) return null;

    final chapters = <BookChapter>[];
    final chaptersJson = json['chapters'];
    if (chaptersJson is List) {
      for (final c in chaptersJson) {
        if (c is! Map) continue;
        final parsed = BookChapterDto.fromJson(c.cast<String, dynamic>());
        if (parsed != null) chapters.add(parsed.chapter);
      }
    }

    return BookDto(Book(
      id: id,
      slug: slug,
      title: title,
      subtitle: _strOrNull(json['subtitle']),
      subjectCode: _strOrNull(json['subject_code']),
      discipline: _strOrNull(json['discipline']),
      disciplineLabel: _strOrNull(json['discipline_label']),
      targetExam: _strOrNull(json['target_exam']),
      coverImageUrl: _strOrNull(json['cover_image_url']),
      authorName: _strOrNull(json['author_name']),
      publisherName: _strOrNull(json['publisher_name']),
      primaryLanguage: _strOrNull(json['primary_language']),
      supportedLanguages: _stringList(json['supported_languages']),
      totalPages: _toInt(json['total_pages']),
      totalChapters: _toInt(json['total_chapters']),
      totalTopics: _toInt(json['total_topics']),
      totalNumericals: _toInt(json['total_numericals']),
      totalFormulas: _toInt(json['total_formulas']),
      estimatedReadHours: _toDouble(json['estimated_read_hours']),
      isPublished: json['is_published'] == true,
      isPremium: json['is_premium'] == true,
      coinUnlockPrice: _toIntOrNull(json['coin_unlock_price']),
      realCurrencyPriceCents: _toIntOrNull(json['real_currency_price_cents']),
      currency: _strOrNull(json['currency']),
      difficultyLevel: _strOrNull(json['difficulty_level']),
      chapters: chapters,
    ));
  }
}

class ReadingCreditDto {
  const ReadingCreditDto(this.credit);
  final ReadingCredit credit;

  /// The controller returns a `credit` block alongside `progress`. `voided` and
  /// the awarded amounts are read independently so a voided session can never
  /// render as an award.
  static ReadingCreditDto? fromJson(Map<String, dynamic> json) {
    if (json['verified_seconds'] == null &&
        json['voided'] == null &&
        json['void_reason'] == null) {
      return null;
    }
    return ReadingCreditDto(ReadingCredit(
      verifiedSeconds: _toInt(json['verified_seconds']),
      voided: json['voided'] == true || json['credit_voided'] == true,
      voidReason: _strOrNull(json['void_reason']),
      xpAwarded: _toInt(json['xp_awarded']),
      coinsAwarded: _toInt(json['coins_awarded']),
      topicCompleted: json['topic_completed'] == true,
      chapterCompleted: json['chapter_completed'] == true,
    ));
  }
}

class ReadingProgressDto {
  const ReadingProgressDto(this.progress);
  final ReadingProgress progress;

  static ReadingProgressDto? fromJson(Map<String, dynamic> json) {
    final bookId = _toIntOrNull(json['book_id']);
    if (bookId == null) return null;
    final creditJson = json['credit'];
    return ReadingProgressDto(ReadingProgress(
      bookId: bookId,
      currentChapterId: _toIntOrNull(json['current_chapter_id']),
      currentTopicId: _toIntOrNull(json['current_topic_id']),
      currentPageNumber: _toIntOrNull(json['current_page_number']),
      highestPageReached: _toIntOrNull(json['highest_page_reached']),
      completionPercentage: _toDouble(json['completion_percentage']),
      totalTimeSpentSeconds: _toInt(json['total_time_spent_seconds']),
      credit: creditJson is Map
          ? ReadingCreditDto.fromJson(creditJson.cast<String, dynamic>())?.credit
          : null,
    ));
  }
}

class BookHighlightDto {
  const BookHighlightDto(this.highlight);
  final BookHighlight highlight;

  static BookHighlightDto? fromJson(Map<String, dynamic> json) {
    final id = _toIntOrNull(json['id']);
    if (id == null) return null;
    return BookHighlightDto(BookHighlight(
      id: id,
      contentBlockId: _toInt(json['content_block_id']),
      highlightedText: _strOrNull(json['highlighted_text']) ?? '',
      startOffset: _toInt(json['start_offset']),
      endOffset: _toInt(json['end_offset']),
      colorCode: _highlightColorOrDefault(json['color_code']),
      noteContent: _strOrNull(json['note_content']),
      createdAt: _dateOrNull(json['created_at']),
    ));
  }
}

class BookNoteDto {
  const BookNoteDto(this.note);
  final BookNote note;

  static BookNoteDto? fromJson(Map<String, dynamic> json) {
    final id = _toIntOrNull(json['id']);
    if (id == null) return null;
    return BookNoteDto(BookNote(
      id: id,
      body: _strOrNull(json['body'] ?? json['note_content'] ?? json['content']) ?? '',
      contentBlockId: _toIntOrNull(json['content_block_id']),
      pageNumber: _toIntOrNull(json['page_number']),
      createdAt: _dateOrNull(json['created_at']),
    ));
  }
}

class BookPageBlockDto {
  const BookPageBlockDto(this.block);
  final BookPageBlock block;

  static BookPageBlockDto? fromJson(Map<String, dynamic> json) {
    final id = _toIntOrNull(json['id']);
    if (id == null) return null;
    return BookPageBlockDto(BookPageBlock(
      id: id,
      type: _strOrNull(json['type'] ?? json['block_type']),
      text: _strOrNull(json['text'] ?? json['content']),
      x: json['x'] is num ? json['x'] as num : double.tryParse('${json['x']}'),
      y: json['y'] is num ? json['y'] as num : double.tryParse('${json['y']}'),
      width: json['width'] is num ? json['width'] as num : double.tryParse('${json['width']}'),
      height:
          json['height'] is num ? json['height'] as num : double.tryParse('${json['height']}'),
    ));
  }
}

class BookPageDto {
  const BookPageDto(this.page);
  final BookPage page;

  static BookPageDto? fromJson(Map<String, dynamic> json) {
    final pageNumber = _toIntOrNull(json['page_number'] ?? json['number']);
    if (pageNumber == null) return null;
    final blocks = <BookPageBlock>[];
    final blocksJson = json['blocks'];
    if (blocksJson is List) {
      for (final b in blocksJson) {
        if (b is! Map) continue;
        final parsed = BookPageBlockDto.fromJson(b.cast<String, dynamic>());
        if (parsed != null) blocks.add(parsed.block);
      }
    }
    return BookPageDto(BookPage(
      pageNumber: pageNumber,
      blocks: blocks,
      imageUrl: _strOrNull(json['image_url']),
      width: _toIntOrNull(json['width']),
      height: _toIntOrNull(json['height']),
    ));
  }
}
