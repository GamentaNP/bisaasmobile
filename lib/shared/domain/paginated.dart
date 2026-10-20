import '../../core/network/api_response.dart';

/// Simple paginated wrapper — supports both offset and cursor shapes.
/// Server returns pagination.type == 'offset' | 'cursor'.
class Paginated<T> {
  const Paginated({
    required this.items,
    this.pagination,
  });

  final List<T> items;
  final Pagination? pagination;

  bool get hasMore => pagination?.hasMore ?? false;
  int get total => pagination?.total ?? items.length;

  /// The opaque cursor for the next page, when the endpoint is cursor-paginated.
  ///
  /// Callers pass this back verbatim; it is never parsed or constructed.
  String? get nextCursor => pagination?.nextCursor;
}
