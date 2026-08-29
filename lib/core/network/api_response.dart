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
class Pagination {
  const Pagination({
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
        total: j['total'] as int?,
        perPage: j['per_page'] as int?,
        currentPage: j['current_page'] as int?,
        totalPages: j['total_pages'] as int?,
        hasMore: j['has_more'] as bool?,
        count: j['count'] as int?,
        nextCursor: j['next_cursor'] as String?,
        prevCursor: j['prev_cursor'] as String?,
      );

  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;
  final bool? hasMore;
  final int? count;
  final String? nextCursor;
  final String? prevCursor;
}
