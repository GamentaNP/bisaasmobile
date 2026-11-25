/// Presentation-only date formats shared by the feature screens.
///
/// These are the exact strings the screens used to build inline, kept here so
/// a date rendered in two places cannot drift apart.
library;

String _two(int n) => n.toString().padLeft(2, '0');

/// `2026-11-25` — the date-only form used by library cards.
String formatIsoDate(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// `2026-11-25 14:07` — used by download and calculator history rows.
///
/// Callers that want local time convert before calling; the value is rendered
/// exactly as handed in, preserving the previous screen output.
String formatIsoDateTime(DateTime d) =>
    '${formatIsoDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

/// `25/11 14:07` — compact local form used by contest and live-event chips.
String formatShortDateTime(DateTime d) {
  final local = d.toLocal();
  return '${local.day}/${local.month} ${local.hour}:${_two(local.minute)}';
}
