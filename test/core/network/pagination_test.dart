/// The shared pagination helpers.
///
/// The cursor migration is the one change that touches every list endpoint,
/// so the walk itself is pinned here: what goes on the wire, what comes
/// back, and what happens when the server says something impossible.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/core/network/api_response.dart';
import 'package:bisaasmobile/core/network/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _cursorBody({
  required List<int> ids,
  String? nextCursor,
  bool hasMore = false,
}) {
  return <String, dynamic>{
    'success': true,
    'data': <String, dynamic>{
      'items': <Map<String, dynamic>>[
        for (final id in ids) <String, dynamic>{'id': id},
      ],
    },
    'pagination': <String, dynamic>{
      'type': 'cursor',
      'per_page': 50,
      'count': ids.length,
      'has_more': hasMore,
      'next_cursor': nextCursor,
    },
  };
}

void main() {
  group('cursorQuery', () {
    test('carries the cursor and the page size', () {
      final query = cursorQuery(cursor: 'abc', perPage: 25);
      expect(query['cursor'], 'abc');
      expect(query['per_page'], 25);
    });

    test('omits an absent or empty cursor', () {
      expect(cursorQuery().containsKey('cursor'), isFalse);
      expect(cursorQuery(cursor: '').containsKey('cursor'), isFalse);
    });

    test('merges the endpoint filters without shadowing the pagination keys',
        () {
      final query = cursorQuery(
        cursor: 'abc',
        perPage: 10,
        extra: <String, dynamic>{'filter[search]': 'soil'},
      );
      expect(query['filter[search]'], 'soil');
      expect(query['cursor'], 'abc');
      expect(query['per_page'], 10);
    });
  });

  group('parsePage', () {
    test('reads the rows and the pagination block', () {
      final page = parsePage<Map<String, dynamic>>(
        _cursorBody(ids: <int>[1, 2], nextCursor: 'x', hasMore: true),
        (row) => row,
      );

      expect(page.items, hasLength(2));
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'x');
    });

    test('a page with no more rows is not "more"', () {
      final page = parsePage<Map<String, dynamic>>(
        _cursorBody(ids: <int>[1]),
        (row) => row,
      );

      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('the pagination block is read from the top level of the envelope', () {
      final page = parsePage<Map<String, dynamic>>(
        <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[<String, dynamic>{'id': 1}],
          },
          'pagination': <String, dynamic>{
            'type': 'cursor',
            'has_more': true,
            'next_cursor': 'zzz',
          },
        },
        (row) => row,
      );

      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'zzz');
    });

    test('a body that is not a list at all is drift, not an empty page', () {
      expect(
        () => parsePage<Map<String, dynamic>>(
          <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'unexpected': true},
          },
          (row) => row,
          endpoint: '/quiz/questions',
        ),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('Pagination', () {
    test('an integer next_cursor is carried as a string', () {
      // The coin ledger's cursor is the id of the last-seen entry, an integer,
      // while the other cursor collections use an opaque blob. Both round-trip.
      final pagination = Pagination.fromJson(<String, dynamic>{
        'type': 'cursor',
        'next_cursor': 55,
        'has_more': true,
      });

      expect(pagination.nextCursor, '55');
      expect(pagination.isCursor, isTrue);
    });

    test('an empty cursor is treated as no cursor', () {
      final pagination = Pagination.fromJson(<String, dynamic>{
        'next_cursor': '',
      });
      expect(pagination.nextCursor, isNull);
    });

    test('the offset shape is still read', () {
      final pagination = Pagination.fromJson(<String, dynamic>{
        'total': 120,
        'per_page': 20,
        'current_page': 2,
        'total_pages': 6,
        'has_more': true,
      });

      expect(pagination.total, 120);
      expect(pagination.currentPage, 2);
      expect(pagination.totalPages, 6);
      expect(pagination.isCursor, isFalse);
    });
  });

  group('collectAllPages', () {
    test('walks every page and returns the rows in order', () async {
      final pages = <String?, Page<int>>{
        null: Page<int>(
          items: <int>[1, 2],
          nextCursor: 'p2',
          hasMore: true,
        ),
        'p2': Page<int>(
          items: <int>[3],
          nextCursor: 'p3',
          hasMore: true,
        ),
        'p3': Page<int>(items: <int>[4], hasMore: false),
      };
      final seen = <String?>[];

      final all = await collectAllPages<int>(
      fetch: (cursor) async {
        seen.add(cursor);
        return pages[cursor]!;
      },
    );

      expect(all, <int>[1, 2, 3, 4]);
      expect(seen, <String?>[null, 'p2', 'p3']);
    });

    test('stops when the server says there is no more', () async {
      var calls = 0;
      final all = await collectAllPages<int>(
        fetch: (cursor) async {
          calls++;
          return Page<int>(items: <int>[1], hasMore: false);
        },
      );

      expect(all, <int>[1]);
      expect(calls, 1);
    });

    test('a repeated cursor is drift, not an infinite loop', () async {
      await expectLater(
        collectAllPages<int>(
          fetch: (cursor) async =>
              Page<int>(items: <int>[1], nextCursor: 'same', hasMore: true),
        ),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('has_more without a cursor is drift', () async {
      await expectLater(
        collectAllPages<int>(
          fetch: (cursor) async =>
              Page<int>(items: <int>[1], hasMore: true),
        ),
        throwsA(isA<ContractViolation>()),
      );
    });
  });
}
