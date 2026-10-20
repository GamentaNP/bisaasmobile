/// Canonical envelope mirrored from `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md:72`.
library;

/// Every `GET/POST /api/v1/*` success body.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.pagination,
    this.timestamp,
    this.apiVersion,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String?,
      apiVersion: json['api_version'] as String?,
    );
  }

  final bool success;
  final T? data;
  final String? message;
  final Pagination? pagination;
  final String? timestamp;
  final String? apiVersion;
}

/// Offset-or-cursor pagination — check endpoint's OpenAPI entry.
///
/// The discriminator is the `type` key the server publishes (`"offset"` /
/// `"cursor"`); when it is absent the shape is inferred from which fields are
/// present. See `MOBILE_API_INTEGRATION_GUIDE.md` §4.
class Pagination {
  const Pagination({
    this.type,
    this.total,
    this.perPage,
    this.currentPage,
    this.totalPages,
    this.hasMore,
    this.count,
    this.nextCursor,
    this.prevCursor,
  });

  factory Pagination.fromJson(Map<String, dynamic> j) => Pagination(
        type: j['type'] as String?,
        total: _asInt(j['total']),
        perPage: _asInt(j['per_page']),
        currentPage: _asInt(j['current_page']),
        totalPages: _asInt(j['total_pages']),
        hasMore: j['has_more'] as bool?,
        count: _asInt(j['count']),
        // `next_cursor` is opaque for the cursor-paginated endpoints (a base64
        // blob) but a plain integer id on the coin-ledger endpoint, which
        // declares `cursor` as an integer parameter. Both are round-tripped
        // verbatim; nothing here parses them.
        nextCursor: _asCursor(j['next_cursor']),
        prevCursor: _asCursor(j['prev_cursor']),
      );

  final String? type;
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;
  final bool? hasMore;
  final int? count;
  final String? nextCursor;
  final String? prevCursor;

  /// True when the server described this page as cursor-shaped.
  bool get isCursor => type == 'cursor' || nextCursor != null;

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static String? _asCursor(Object? v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is int) return '$v';
    if (v is num) return v.toString();
    return null;
  }
}
