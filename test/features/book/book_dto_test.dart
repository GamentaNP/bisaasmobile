import 'package:bisaasmobile/features/book/data/models/book_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shapes verified against `app/Http/Resources/Api/V1/Book/*Resource.php` and
/// `app/Http/Controllers/Api/V1/Book/ReaderController.php`.
///
/// The credit tests are the important ones. Reading time can be **voided** by
/// the server's fraud detector, and the response carries both the void flag and
/// the awarded amounts. A client that rendered the award regardless of the void
/// would be telling the user they earned something the server refused.
void main() {
  group('BookDto', () {
    final row = <String, dynamic>{
      'id': 7,
      'slug': 'civil-engineering-2080',
      'title': 'Civil Engineering',
      'subtitle': 'A complete course',
      'subject_code': 'civil',
      'discipline': 'civil',
      'discipline_label': 'Civil',
      'target_exam': 'Loksewa Civil Engineer',
      'cover_image_url': 'https://cdn.example/cover.jpg',
      'author_name': 'A. Author',
      'publisher_name': 'B. Publisher',
      'primary_language': 'en',
      'supported_languages': ['en', 'ne'],
      'total_pages': 420,
      'total_chapters': 18,
      'total_topics': 96,
      'total_numericals': 240,
      'total_formulas': 180,
      'estimated_read_hours': 24.5,
      'is_published': true,
      'is_premium': true,
      'coin_unlock_price': 500,
      'real_currency_price_cents': 49900,
      'currency': 'NPR',
      'difficulty_level': 'intermediate',
    };

    test('parses the full resource', () {
      final b = BookDto.fromJson(row)!.book;
      expect(b.id, 7);
      expect(b.slug, 'civil-engineering-2080');
      expect(b.totalPages, 420);
      expect(b.totalFormulas, 180);
      expect(b.supportedLanguages, ['en', 'ne']);
      expect(b.estimatedReadHours, 24.5);
    });

    test('rejects a row with no id, no slug or no title', () {
      // Every detail route is keyed on the slug, so a book without one cannot be
      // opened at all.
      for (final key in ['id', 'slug', 'title']) {
        final broken = Map<String, dynamic>.from(row)..remove(key);
        expect(BookDto.fromJson(broken), isNull, reason: 'missing $key');
      }
    });

    test('costsCoins is false when the price is absent, not when it is zero', () {
      final noPrice = Map<String, dynamic>.from(row)..remove('coin_unlock_price');
      expect(BookDto.fromJson(noPrice)!.book.costsCoins, isFalse);

      final free = Map<String, dynamic>.from(row)..['coin_unlock_price'] = 0;
      expect(BookDto.fromJson(free)!.book.costsCoins, isFalse);
    });

    test('converts minor units to a major-unit price', () {
      expect(BookDto.fromJson(row)!.book.realPriceMajorUnits, 499);
    });

    test('a book with no real-currency price reports null, not 0', () {
      final noMoney = Map<String, dynamic>.from(row)
        ..remove('real_currency_price_cents')
        ..['real_currency_price_cents'] = null;
      expect(BookDto.fromJson(noMoney)!.book.realPriceMajorUnits, isNull);
    });

    test('a malformed chapter is skipped without losing the book', () {
      final withChapters = Map<String, dynamic>.from(row)
        ..['chapters'] = [
          <String, dynamic>{'title': 'no id'},
          'not a map',
          <String, dynamic>{'id': 1, 'title': 'Statics'},
        ];
      final b = BookDto.fromJson(withChapters)!.book;
      expect(b.chapters.length, 1);
      expect(b.chapters.single.title, 'Statics');
    });
  });

  group('BookChapterDto', () {
    test('parses a chapter with a page range', () {
      final c = BookChapterDto.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'Limit Analysis',
        'chapter_number': 3,
        'display_number': '3',
        'title_ne': 'सीमा विश्लेषण',
        'learning_objectives': ['Apply the three moment theorem'],
        'start_page': 41,
        'end_page': 68,
        'estimated_read_minutes': 45,
        'is_free_preview': false,
        'is_published': true,
        'coin_unlock_price': 120,
      })!.chapter;
      expect(c.id, 3);
      expect(c.learningObjectives, hasLength(1));
      expect(c.pageRangeLabel, 'p. 41–68');
      expect(c.costsCoins, isTrue);
      expect(c.titleFor(preferNative: true), 'सीमा विश्लेषण');
      expect(c.titleFor(preferNative: false), 'Limit Analysis');
    });

    test('the 9999 end-page sentinel is treated as unknown', () {
      // The server maps 9999 to null already; guarding here too means a second
      // code path that forgets the mapping cannot surface "p. 41–9999".
      final c = BookChapterDto.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'X',
        'start_page': 41,
        'end_page': 9999,
      })!.chapter;
      expect(c.endPage, isNull);
      expect(c.pageRangeLabel, 'p. 41+');
      expect(c.pageRangeLabel, isNot(contains('9999')));
    });

    test('a chapter with no start page has no range label at all', () {
      final c = BookChapterDto.fromJson(<String, dynamic>{'id': 1, 'title': 'X'})!.chapter;
      expect(c.pageRangeLabel, isNull);
    });

    test('a single-page chapter shows one page, not a backwards range', () {
      final c = BookChapterDto.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'X',
        'start_page': 10,
        'end_page': 10,
      })!.chapter;
      expect(c.pageRangeLabel, 'p. 10');
    });

    test('an end before the start is clamped to a single page', () {
      final c = BookChapterDto.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'X',
        'start_page': 50,
        'end_page': 10,
      })!.chapter;
      expect(c.pageRangeLabel, 'p. 50');
    });

    test('an empty title_ne falls back to English', () {
      final c = BookChapterDto.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Statics',
        'title_ne': '   ',
      })!.chapter;
      expect(c.titleFor(preferNative: true), 'Statics');
    });

    test('a chapter with no id is dropped', () {
      expect(BookChapterDto.fromJson(<String, dynamic>{'title': 'X'}), isNull);
    });
  });

  group('ReadingCredit — never claim a reward the server refused', () {
    test('an awarded session reports what was granted', () {
      final c = ReadingCreditDto.fromJson(<String, dynamic>{
        'verified_seconds': 600,
        'voided': false,
        'void_reason': null,
        'xp_awarded': 40,
        'coins_awarded': 5,
        'topic_completed': true,
        'chapter_completed': false,
      })!.credit;
      expect(c.voided, isFalse);
      expect(c.xpAwarded, 40);
      expect(c.hasAward, isTrue);
      expect(c.outcomeMessage, contains('+40 XP'));
      expect(c.outcomeMessage, contains('+5 coins'));
      expect(c.outcomeMessage, contains('topic complete'));
    });

    test('a voided session says so and does not read as an award', () {
      final c = ReadingCreditDto.fromJson(<String, dynamic>{
        'verified_seconds': 0,
        'voided': true,
        'void_reason': 'Reading too fast to count as study',
        'xp_awarded': 0,
        'coins_awarded': 0,
        'topic_completed': false,
        'chapter_completed': false,
      })!.credit;
      expect(c.voided, isTrue);
      expect(c.hasAward, isFalse);
      final message = c.outcomeMessage!;
      expect(message, contains('not counted'));
      expect(message, contains('too fast'));
      expect(message, isNot(contains('+')));
    });

    test('a voided session with no reason still does not read as an award', () {
      final c = ReadingCreditDto.fromJson(<String, dynamic>{
        'voided': true,
        'void_reason': null,
      })!.credit;
      final message = c.outcomeMessage!;
      expect(message, contains('not counted'));
      expect(message, isNot(contains('+')));
    });

    test('the credit_voided alias is honoured', () {
      final c = ReadingCreditDto.fromJson(<String, dynamic>{
        'verified_seconds': 30,
        'credit_voided': true,
      })!.credit;
      expect(c.voided, isTrue);
    });

    test('a void is reported even if the server still sent award amounts', () {
      // Deliberately inconsistent server payload. The client must trust the void
      // flag over the amounts, or a partial server change would show a reward
      // for a rejected session.
      final c = ReadingCreditDto.fromJson(<String, dynamic>{
        'voided': true,
        'void_reason': 'Duplicate session',
        'xp_awarded': 40,
        'coins_awarded': 5,
      })!.credit;
      expect(c.voided, isTrue);
      expect(c.outcomeMessage, contains('not counted'));
    });

    test('no award and no void means nothing to say', () {
      final c = ReadingCreditDto.fromJson(<String, dynamic>{
        'verified_seconds': 120,
        'xp_awarded': 0,
        'coins_awarded': 0,
      })!.credit;
      expect(c.hasAward, isFalse);
      expect(c.outcomeMessage, isNull);
    });

    test('a block with no recognisable keys is not a credit at all', () {
      expect(ReadingCreditDto.fromJson(<String, dynamic>{}), isNull);
      expect(ReadingCreditDto.fromJson(<String, dynamic>{'unrelated': 1}), isNull);
    });
  });

  group('ReadingProgressDto', () {
    test('parses progress with a nested credit block', () {
      final p = ReadingProgressDto.fromJson(<String, dynamic>{
        'book_id': 7,
        'current_chapter_id': 3,
        'current_topic_id': 22,
        'current_page_number': 44,
        'highest_page_reached': 51,
        'completion_percentage': 12.25,
        'total_time_spent_seconds': 3600,
        'credit': <String, dynamic>{'verified_seconds': 600, 'xp_awarded': 40},
      })!.progress;
      expect(p.bookId, 7);
      expect(p.completionPercentage, 12.25);
      expect(p.isStarted, isTrue);
      expect(p.credit!.verifiedSeconds, 600);
    });

    test('completion percentage is taken from the server, never recomputed', () {
      final p = ReadingProgressDto.fromJson(<String, dynamic>{
        'book_id': 7,
        'current_page_number': 420,
        'completion_percentage': 33.3,
      })!.progress;
      expect(p.completionPercentage, 33.3,
          reason: 'page 420 of 420 is 100% locally, but the server says 33.3%');
    });

    test('a null credit block is allowed', () {
      final p = ReadingProgressDto.fromJson(<String, dynamic>{
        'book_id': 7,
        'credit': null,
      })!.progress;
      expect(p.credit, isNull);
    });

    test('a progress row with no book id is rejected', () {
      expect(ReadingProgressDto.fromJson(<String, dynamic>{'current_page_number': 4}), isNull);
    });

    test('an unread book is not started', () {
      final p = ReadingProgressDto.fromJson(<String, dynamic>{'book_id': 7})!.progress;
      expect(p.isStarted, isFalse);
    });
  });

  group('BookPageDto', () {
    test('parses positioned and textual blocks', () {
      final page = BookPageDto.fromJson(<String, dynamic>{
        'page_number': 12,
        'width': 1700,
        'height': 2200,
        'blocks': [
          <String, dynamic>{
            'id': 1,
            'type': 'text',
            'text': 'Bending moment',
            'x': 120,
            'y': 340,
            'width': 900,
            'height': 60,
          },
          <String, dynamic>{'id': 2, 'type': 'image'},
        ],
      })!.page;
      expect(page.pageNumber, 12);
      expect(page.hasBlocks, isTrue);
      expect(page.blocks[0].isTextual, isTrue);
      expect(page.blocks[0].isPositioned, isTrue);
      expect(page.blocks[1].isTextual, isFalse);
    });

    test('string coordinates are coerced rather than dropped', () {
      final page = BookPageDto.fromJson(<String, dynamic>{
        'page_number': 1,
        'blocks': [
          <String, dynamic>{
            'id': 1,
            'text': 'x',
            'x': '120',
            'y': '340',
            'width': '900',
            'height': '60',
          },
        ],
      })!.page;
      expect(page.blocks.single.isPositioned, isTrue);
    });

    test('a whitespace-only block is not textual', () {
      final page = BookPageDto.fromJson(<String, dynamic>{
        'page_number': 1,
        'blocks': [
          <String, dynamic>{'id': 1, 'text': '   '},
        ],
      })!.page;
      expect(page.blocks.single.isTextual, isFalse);
    });

    test('a page with no page number is rejected', () {
      expect(BookPageDto.fromJson(<String, dynamic>{'blocks': <dynamic>[]}), isNull);
    });
  });

  group('highlight colours', () {
    test('an unrecognised colour falls back rather than being sent back', () {
      // The request validates color_code against an `in:` list, so echoing an
      // unknown value would 422. The DTO defaults to yellow instead.
      final h = BookHighlightDto.fromJson(<String, dynamic>{
        'id': 1,
        'content_block_id': 5,
        'highlighted_text': 'x',
        'color_code': 'chartreuse',
      })!.highlight;
      expect(h.colorCode, 'yellow');
    });

    test('a known colour is preserved', () {
      final h = BookHighlightDto.fromJson(<String, dynamic>{
        'id': 1,
        'content_block_id': 5,
        'highlighted_text': 'x',
        'color_code': 'purple',
      })!.highlight;
      expect(h.colorCode, 'purple');
    });
  });
}
