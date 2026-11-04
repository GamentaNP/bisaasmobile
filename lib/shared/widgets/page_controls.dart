import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A compact [current]/[total] page footer with Previous / Next.
///
/// The catalog screens render large server lists; the founder's verdict on
/// infinite scroll was that a player cannot see how much is left. Every
/// paginated list uses this one footer, so paging behaves identically
/// everywhere.
class PageControls extends StatelessWidget {
  const PageControls({
    super.key,
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
  })  : assert(current >= 1, 'pages are 1-based'),
        assert(total >= 1, 'a list always has at least one page');

  final int current;
  final int total;

  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: onPrev,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.previousPage, style: const TextStyle(fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              l10n.pageOf(current, total),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.nextPage, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
