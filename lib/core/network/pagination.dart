/// Shared pagination plumbing for the two sanctioned server shapes.
///
/// `MOBILE_API_INTEGRATION_GUIDE.md` §4 sanctions exactly two envelope shapes:
///
///  * **Offset** — `pagination = {total, per_page, current_page, total_pages,
///    has_more}`.
///  * **Cursor** — `pagination = {per_page, count, has_more, next_cursor,
///    prev_cursor}`.
///
/// §4.1 moves four question-family collections to cursor (deprecation started
/// 2026-09-08, sunset `Mon, 07 Mar 2027`):
///
///  * `GET /quiz/questions`
///  * `GET /quiz/courses/{course:id}/questions`
///  * `GET /quiz/attempts/history`
///  * `GET /library/files`
///
/// The server already defaults those four to the cursor shape
/// (`ServesQuestionCollections::wantsCursorPagination` → cursor unless
/// `?pagination=offset` is asked for), so a client that still sends
/// `?page=2` silently gets page one forever. This module is the single place
/// that knows how to walk either shape.
///
/// Two rules the module enforces:
///
///  * `next_cursor` is **opaque**. It is never parsed, constructed or
///    persisted — only round-tripped back to the server verbatim.
///  * A page that reports `has_more: true` but hands back no cursor is a
///    contract drift, and it throws [ContractViolation] rather than spinning
///    the user forever on the same first page.
library;

import 'api_failure.dart';
import 'api_response.dart';

/// One page of results plus the state needed to ask for the next one.
class Page<T> {
  const Page({
    required this.items,
    this.pagination,
    this.nextCursor,
    this.hasMore = false,
  });

  /// The rows of this page, in server order.
  final List<T> items;

  /// The raw pagination block, when the endpoint published one.
  final Pagination? pagination;

  /// The opaque cursor for the next page, or null when the walk is done.
  final String? nextCursor;

  /// Whether the server says another page exists.
  final bool hasMore;

  /// True when the server advertised another page but gave no cursor to fetch
  /// it with. Continuing would re-request the current page forever.
  bool get isStalled => hasMore && (nextCursor == null || nextCursor!.isEmpty);
}

/// Builds the query parameters for a cursor page.
///
/// [extra] carries the endpoint's own filters and is merged last so a filter
/// can never be shadowed by the pagination keys.
Map<String, dynamic> cursorQuery({
  String? cursor,
  int? perPage,
  Map<String, dynamic> extra = const {},
}) {
  final query = <String, dynamic>{...extra};
  if (perPage != null) query['per_page'] = perPage;
  if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
  return query;
}

/// Builds the query parameters for an offset page.
///
/// Kept for the endpoints that are *not* part of the §4.1 migration and have
/// no cursor shape.
Map<String, dynamic> offsetQuery({
  int? page,
  int? perPage,
  Map<String, dynamic> extra = const {},
}) {
  final query = <String, dynamic>{...extra};
  if (page != null) query['page'] = page;
  if (perPage != null) query['per_page'] = perPage;
  return query;
}

/// Extracts the row list from a canonical envelope body.
///
/// The canonical list shape is `data.items`. A handful of collections
/// published their rows under a different key before the cursor contract
/// existed (`data.entries`, `data.leaderboard`, `data.books`, …) and the
/// server keeps those keys frozen — `ApiResponse::cursorListWithPayload`
/// publishes the *pagination* block at the top level for exactly those
/// endpoints. [keys] lists the accepted row keys, in priority order.
///
/// Returns an empty list when the body genuinely carries no rows. A body that
/// carries neither a list nor any known key is a contract drift and throws.
List<Map<String, dynamic>> extractRows(
  Map<String, dynamic> body, {
  List<String> keys = const ['items'],
  String? endpoint,
}) {
  final data = body['data'];

  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }

  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().toList();
      }
    }
  }

  // `data` may itself be null for an empty collection.
  if (data == null) return const [];

  throw ContractViolation(
    'Expected a list under data${keys.isEmpty ? '' : '.$keys'}',
    endpoint: endpoint,
  );
}

/// Extracts the pagination block from a canonical envelope body.
///
/// The block lives at the top level (`pagination`), and some endpoints also
/// nest it inside `data` — both are read, top level first.
Pagination? extractPagination(Map<String, dynamic> body) {
  final top = body['pagination'];
  if (top is Map<String, dynamic>) return Pagination.fromJson(top);

  final data = body['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['pagination'];
    if (nested is Map<String, dynamic>) return Pagination.fromJson(nested);
  }

  return null;
}

/// Parses a response body into a [Page].
///
/// [rowKeys] lists the accepted row keys inside `data` for endpoints whose
/// rows are not published under the canonical `items`.
Page<T> parsePage<T>(
  Map<String, dynamic> body,
  T Function(Map<String, dynamic>) fromJson, {
  List<String> rowKeys = const ['items'],
  String? endpoint,
}) {
  final rows = extractRows(body, keys: rowKeys, endpoint: endpoint);
  final pagination = extractPagination(body);

  // `has_more` is authoritative when published; otherwise a published
  // `next_cursor` implies another page exists.
  final hasMore = pagination?.hasMore ?? (pagination?.nextCursor != null);
  final nextCursor = pagination?.nextCursor;

  return Page<T>(
    items: rows.map(fromJson).toList(),
    pagination: pagination,
    nextCursor: nextCursor,
    hasMore: hasMore,
  );
}

/// Walks a cursor-paginated collection and returns every row.
///
/// [fetch] receives the cursor to use (null for the first page) and must
/// return the parsed page. The walk stops when the server says there is no
/// more, when the page comes back empty, or when [maxPages] is reached —
/// the last one protects the device from a server that keeps claiming
/// `has_more` while handing back the same cursor forever.
Future<List<T>> collectAllPages<T>({
  required Future<Page<T>> Function(String? cursor) fetch,
  int maxPages = 25,
  String? endpoint,
}) async {
  final all = <T>[];
  String? cursor;
  final seenCursors = <String>{};

  for (var page = 0; page < maxPages; page++) {
    final result = await fetch(cursor);
    all.addAll(result.items);

    if (!result.hasMore || result.items.isEmpty) break;

    final next = result.nextCursor;
    if (next == null || next.isEmpty) {
      throw ContractViolation(
        'has_more was true but no next_cursor was published',
        endpoint: endpoint,
      );
    }
    if (!seenCursors.add(next)) {
      throw ContractViolation(
        'next_cursor repeated; refusing to loop',
        endpoint: endpoint,
      );
    }
    cursor = next;
  }

  return all;
}
