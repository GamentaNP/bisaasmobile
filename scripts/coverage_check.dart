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
      skipFile = line.contains('.g.dart') ||
          line.contains('.freezed.dart') ||
          line.contains('.drift.dart') ||
          line.contains('l10n/') ||
          line.contains('lib/l10n');
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
