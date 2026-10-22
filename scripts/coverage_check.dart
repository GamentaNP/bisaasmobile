#!/usr/bin/env dart
// coverage_check.dart — enforce coverage threshold excluding generated files.
// Usage: dart scripts/coverage_check.dart [--min=70]
// Run after: flutter test --coverage

import 'dart:io';

void main(List<String> args) {
  final minPct = args
      .where((a) => a.startsWith('--min='))
      .map((a) => double.tryParse(a.substring(6)) ?? 70.0)
      .firstOrNull ?? 70.0;

  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'ERROR: coverage/lcov.info not found. Run flutter test --coverage first.',
    );
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  var totalFound = 0;
  var totalHit = 0;
  var skipFile = false;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      // The path separator differs by platform — lcov writes `lib/l10n/…`
      // on Linux and `lib\l10n\…` on Windows — so the path is normalised
      // before it is matched. Without that, the generated localisations are
      // counted as uncovered code on Windows and the measurement disagrees
      // with CI by several thousand lines.
      final path = line.substring(3).replaceAll('\\', '/');
      skipFile = path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart') ||
          path.endsWith('.drift.dart') ||
          path.contains('/l10n/') ||
          path.contains('/lib/l10n/') ||
          path.startsWith('l10n/') ||
          path.startsWith('lib/l10n/');
    }
    if (skipFile) continue;
    if (line.startsWith('LF:')) {
      totalFound += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      totalHit += int.parse(line.substring(3));
    }
  }

  if (totalFound == 0) {
    stderr.writeln('ERROR: No coverable lines found in lcov.info.');
    exit(1);
  }

  final pct = totalHit / totalFound * 100;
  final msg =
      'Coverage (excl. generated): $totalHit/$totalFound lines = ${pct.toStringAsFixed(1)}%';
  stderr.writeln(msg);

  if (pct < minPct) {
    stderr.writeln(
      'FAIL: Coverage ${pct.toStringAsFixed(1)}% < required ${minPct.toStringAsFixed(0)}%',
    );
    exit(1);
  }
  stderr.writeln(
    'PASS: Coverage meets the ${minPct.toStringAsFixed(0)}% threshold.',
  );
}
