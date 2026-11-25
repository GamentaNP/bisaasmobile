/// Coercion of loosely typed JSON wire values, shared by every DTO.
library;

/// `int` from an `int`, any other `num`, a numeric `String`, or a numeric
/// `toString()` (some legacy endpoints send boxed values). `null` for anything
/// else — a failure to parse is never silently turned into zero here.
int? wireInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return int.tryParse(value.toString());
}

/// Zero-defaulting flavour, for DTO fields that are non-nullable `int`.
int wireIntOrZero(Object? value) => wireInt(value) ?? 0;

/// `double` from a `double`, any other `num`, or a numeric `String`.
double? wireDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// `DateTime` from an already-decoded `DateTime` or an ISO-8601 `String`.
///
/// Both shapes appear on the wire: most DTOs accepted either, a couple only
/// accepted strings. The union is safe for all of them.
DateTime? wireDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
