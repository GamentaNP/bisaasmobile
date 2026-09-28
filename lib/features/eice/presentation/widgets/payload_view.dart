import 'package:flutter/material.dart';

/// Renders an API payload as readable label/value rows.
///
/// The EICE screen used to show `Text(data.toString())` in monospace, which
/// dumped raw JSON — including nested maps and lists — at the user. A key like
/// `total_due` is a contract, not a label, so keys are humanised for display
/// while the values stay exactly as the server sent them.
class PayloadView extends StatelessWidget {
  const PayloadView({super.key, required this.data, this.depth = 0});

  final Object? data;
  final int depth;

  /// Keys that are diagnostics rather than content. Filtered so an internal
  /// debug blob is never rendered as a user-facing field.
  static const skipKeys = {'_debug', 'debug', 'meta_raw'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = data;

    if (payload == null) {
      return Text('No data available yet.', style: theme.textTheme.bodySmall);
    }

    if (payload is Map) {
      final entries =
          payload.entries.where((e) => !skipKeys.contains(e.key.toString())).toList();
      if (entries.isEmpty) {
        return Text('No details available yet.', style: theme.textTheme.bodySmall);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in entries)
            Padding(
              padding: EdgeInsets.only(bottom: depth == 0 ? 10 : 4),
              child: PayloadRow(
                label: humaniseKey(e.key.toString()),
                value: e.value,
                depth: depth,
              ),
            ),
        ],
      );
    }

    if (payload is List) {
      final list = payload;
      if (list.isEmpty) {
        return Text('Nothing here yet.', style: theme.textTheme.bodySmall);
      }
      const maxShown = 8;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in list.take(maxShown))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 7),
                    child: Icon(Icons.circle, size: 5),
                  ),
                  Expanded(
                    child: item is Map
                        ? PayloadView(data: item, depth: depth + 1)
                        : Text(formatScalar(item), style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          if (list.length > maxShown)
            Text(
              'and ${list.length - maxShown} more…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
        ],
      );
    }

    return Text(formatScalar(payload), style: theme.textTheme.bodyMedium);
  }
}

/// One label/value pair. A map or list value nests rather than being flattened
/// to a string, so a `{total: 4, due: [{...}]}` payload stays readable.
class PayloadRow extends StatelessWidget {
  const PayloadRow({super.key, required this.label, required this.value, this.depth = 0});

  final String label;
  final Object? value;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplex = value is Map || value is List;

    if (isComplex) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          PayloadView(data: value, depth: depth + 1),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            formatScalar(value),
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// `total_due` / `totalDue` / `total-due` all render as "Total due".
String humaniseKey(String key) {
  final words = key
      .replaceAll(RegExp('[_-]+'), ' ')
      .replaceAll(RegExp('(?<=[a-z0-9])(?=[A-Z])'), ' ')
      .trim()
      .toLowerCase();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}

/// Formats a leaf value for display. Never throws on an unexpected type.
String formatScalar(Object? v) {
  if (v == null) return '—';
  if (v is num) {
    // Avoid "0" for a whole-valued double, and the long float tails that a
    // JSON round-trip can introduce (0.30000000000000004).
    if (v is double && v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    return v.toString();
  }
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is List) return '${v.length} item${v.length == 1 ? '' : 's'}';
  if (v is Map) return '${v.length} field${v.length == 1 ? '' : 's'}';
  return v.toString();
}
