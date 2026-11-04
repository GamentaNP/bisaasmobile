/// Presentation-only display-name helpers for server strings.
library;

/// Turns a slug-shaped server name into a human title.
///
/// The course catalog mixes curated names ("Sub Engineer") with bulk-imported
/// slugs ("public-service-commission"). Rendering a slug verbatim reads as a
/// bug to a player. Words that are already proper (spaces, dots, ALL-CAPS)
/// pass through untouched, so "B.A. (Journalism and Mass Communication)" is
/// returned as-is while "public-service-commission" becomes
/// "Public service commission".
String humanizeName(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.contains('-') && !trimmed.contains('_')) return trimmed;
  final words = trimmed
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) {
        // Leave tokens that carry their own casing alone (acronyms, "B.A.").
        if (w.length > 1 && w == w.toUpperCase()) return w;
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
  return words.isEmpty ? trimmed : words;
}
