/// Book Engine domain entities.
///
/// The reader is the one part of the app where **server-authoritative** has a
/// sharp edge: reading time is credited, and credited time can be **voided** by
/// the fraud detector. So a progress response carries both a `credit` block and
/// a void reason, and this model keeps them separate. A reader that showed the
/// awarded XP while the server voided it would be telling the user something
/// false.
library;

/// A book in the catalog.
class Book {
  const Book({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle,
    this.subjectCode,
    this.discipline,
    this.disciplineLabel,
    this.targetExam,
    this.coverImageUrl,
    this.authorName,
    this.publisherName,
    this.primaryLanguage,
    this.supportedLanguages = const [],
    this.totalPages = 0,
    this.totalChapters = 0,
    this.totalTopics = 0,
    this.totalNumericals = 0,
    this.totalFormulas = 0,
    this.estimatedReadHours = 0,
    this.isPublished = false,
    this.isPremium = false,
    this.coinUnlockPrice,
    this.realCurrencyPriceCents,
    this.currency,
    this.difficultyLevel,
    this.chapters = const [],
  });

  final int id;
  final String slug;
  final String title;
  final String? subtitle;
  final String? subjectCode;
  final String? discipline;
  final String? disciplineLabel;
  final String? targetExam;
  final String? coverImageUrl;
  final String? authorName;
  final String? publisherName;
  final String? primaryLanguage;
  final List<String> supportedLanguages;
  final int totalPages;
  final int totalChapters;
  final int totalTopics;
  final int totalNumericals;
  final int totalFormulas;
  final double estimatedReadHours;
  final bool isPublished;
  final bool isPremium;
  final int? coinUnlockPrice;
  final int? realCurrencyPriceCents;
  final String? currency;
  final String? difficultyLevel;
  final List<BookChapter> chapters;

  /// True only when the server sent a real price. A book with no price and a
  /// book priced at zero are different things, and showing "Free" for the second
  /// would be wrong.
  bool get costsCoins => (coinUnlockPrice ?? 0) > 0;

  /// Real money price in minor units (cents/paisa). Null means the book is not
  /// sold for fiat.
  int? get realPriceMajorUnits {
    final cents = realCurrencyPriceCents;
    if (cents == null || cents <= 0) return null;
    return cents ~/ 100;
  }
}

class BookChapter {
  const BookChapter({
    required this.id,
    required this.title,
    this.chapterNumber,
    this.displayNumber,
    this.slug,
    this.titleNe,
    this.learningObjectives = const [],
    this.startPage,
    this.endPage,
    this.estimatedReadMinutes,
    this.isFreePreview = false,
    this.isPublished = false,
    this.coinUnlockPrice,
    this.topics = const [],
  });

  final int id;
  final String title;
  final int? chapterNumber;
  final String? displayNumber;
  final String? slug;
  final String? titleNe;
  final List<String> learningObjectives;

  /// Null when the end is unknown.
  ///
  /// The server maps its internal `9999` placeholder sentinel to null, so a
  /// missing end page here is meaningful, not a parse failure. It must be
  /// rendered as "page 12 onwards", never as "p. 12–9999".
  final int? endPage;
  final int? startPage;
  final int? estimatedReadMinutes;
  final bool isFreePreview;
  final bool isPublished;
  final int? coinUnlockPrice;
  final List<BookTopic> topics;

  bool get costsCoins => (coinUnlockPrice ?? 0) > 0;

  /// A readable page range, or null when the end is unknown.
  String? get pageRangeLabel {
    final start = startPage;
    if (start == null) return null;
    final end = endPage;
    if (end == null) return 'p. $start+';
    if (end <= start) return 'p. $start';
    return 'p. $start–$end';
  }

  /// The title in the reader's language, falling back to English.
  String titleFor({required bool preferNative}) {
    if (preferNative && titleNe != null && titleNe!.trim().isNotEmpty) return titleNe!;
    return title;
  }
}

class BookTopic {
  const BookTopic({
    required this.id,
    required this.title,
    this.pageNumber,
    this.contentBlockCount = 0,
  });

  final int id;
  final String title;
  final int? pageNumber;
  final int contentBlockCount;
}

/// The learner's reading position, plus what the server decided to credit.
class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    this.currentChapterId,
    this.currentTopicId,
    this.currentPageNumber,
    this.highestPageReached,
    this.completionPercentage = 0,
    this.totalTimeSpentSeconds = 0,
    this.credit,
  });

  final int bookId;
  final int? currentChapterId;
  final int? currentTopicId;
  final int? currentPageNumber;
  final int? highestPageReached;

  /// Server-computed 0..100. Never recomputed from pages read on the client:
  /// a local percentage would disagree with the server the moment they diverge,
  /// and the user would see the number move backwards.
  final double completionPercentage;
  final int totalTimeSpentSeconds;
  final ReadingCredit? credit;

  bool get isStarted => currentPageNumber != null;
}

/// What the server credited for the reading session just reported.
class ReadingCredit {
  const ReadingCredit({
    this.verifiedSeconds = 0,
    this.voided = false,
    this.voidReason,
    this.xpAwarded = 0,
    this.coinsAwarded = 0,
    this.topicCompleted = false,
    this.chapterCompleted = false,
  });

  /// Seconds the fraud detector accepted.
  final int verifiedSeconds;

  /// True when the session was rejected. When this is true the awarded amounts
  /// below are zero and the reason must be shown to the user.
  final bool voided;
  final String? voidReason;
  final int xpAwarded;
  final int coinsAwarded;
  final bool topicCompleted;
  final bool chapterCompleted;

  /// True when there is something worth telling the user about.
  bool get hasAward =>
      xpAwarded > 0 || coinsAwarded > 0 || topicCompleted || chapterCompleted;

  /// A sentence that never claims a reward the server did not award.
  String? get outcomeMessage {
    if (voided) {
      final reason = voidReason?.trim();
      return reason == null || reason.isEmpty
          ? 'This reading session was not counted.'
          : 'This reading session was not counted: $reason';
    }
    if (xpAwarded > 0 || coinsAwarded > 0) {
      final parts = <String>[];
      if (xpAwarded > 0) parts.add('+$xpAwarded XP');
      if (coinsAwarded > 0) parts.add('+$coinsAwarded coins');
      if (topicCompleted) parts.add('topic complete');
      if (chapterCompleted) parts.add('chapter complete');
      return parts.join(' · ');
    }
    return null;
  }
}

/// A highlight the user made on a content block.
class BookHighlight {
  const BookHighlight({
    required this.id,
    required this.contentBlockId,
    required this.highlightedText,
    this.startOffset = 0,
    this.endOffset = 0,
    this.colorCode = 'yellow',
    this.noteContent,
    this.createdAt,
  });

  final int id;
  final int contentBlockId;
  final String highlightedText;
  final int startOffset;
  final int endOffset;

  /// One of the server's allowed values: yellow, green, blue, pink, purple.
  /// An unknown value is not sent back — the request validates `in:`.
  final String colorCode;
  final String? noteContent;
  final DateTime? createdAt;
}

/// A free-text note the user wrote against a book.
class BookNote {
  const BookNote({
    required this.id,
    required this.body,
    this.contentBlockId,
    this.pageNumber,
    this.createdAt,
  });

  final int id;
  final String body;
  final int? contentBlockId;
  final int? pageNumber;
  final DateTime? createdAt;
}

/// A rendered source page, or its JSON facsimile.
///
/// The endpoint negotiates on `Accept`: the same URI returns positioned blocks
/// by default and a PNG under `Accept: image/png`. The client uses the JSON
/// form so it can lay text out itself rather than only showing a scan.
class BookPage {
  const BookPage({
    required this.pageNumber,
    this.blocks = const [],
    this.imageUrl,
    this.width,
    this.height,
  });

  final int pageNumber;
  final List<BookPageBlock> blocks;
  final String? imageUrl;
  final int? width;
  final int? height;

  bool get hasBlocks => blocks.isNotEmpty;
}

class BookPageBlock {
  const BookPageBlock({
    required this.id,
    this.type,
    this.text,
    this.x,
    this.y,
    this.width,
    this.height,
  });

  final int id;

  /// Server block type, e.g. `text`, `image`, `formula`, `table`.
  final String? type;
  final String? text;
  final num? x;
  final num? y;
  final num? width;
  final num? height;

  /// True when the block carries readable text. A block with none is rendered
  /// as a placeholder rather than as an empty gap the reader cannot explain.
  bool get isTextual => (text ?? '').trim().isNotEmpty;

  /// True when the block is positioned, so the client can lay it out on the
  /// page canvas rather than as a plain vertical list.
  bool get isPositioned =>
      x != null && y != null && width != null && height != null;
}
