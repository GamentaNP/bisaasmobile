import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An icon-only `IconButton` has no visible name. TalkBack announces the icon's
/// semantic label, and on an unlabelled button that is usually nothing at all —
/// so an exit, a send or a password toggle is a mystery to a screen-reader user.
///
/// This is the cheap, dependency-free source scan that keeps the rule in CI.
/// It is modelled on `feature_boundary_test.dart` and `router_reachability_test.dart`:
/// reading source is enough, no widget pump is needed.
///
/// A button counts as labelled when its own argument list contains `tooltip:`
/// or a `Semantics` ancestor *inside that list*. A parent higher up the tree
/// can also label a button, but only when it really does; those are listed in
/// the allowlist below with the file, line and the parent that supplies it.
void main() {
  late Directory libDir;
  late List<File> presentationFiles;

  /// Documented exemptions, keyed as `path:line`.
  ///
  /// Keep this empty. Every icon-only button in presentation code now carries
  /// its own localized tooltip; an entry here must name the button and the
  /// parent that labels it, and must not be a button that could simply carry a
  /// tooltip.
  const allowlist = <String>{};

  /// Blanks out comments and quoted strings, preserving length and newlines so
  /// line numbers still match the original source. This keeps a `tooltip:`
  /// inside a comment (or a bracket inside a label) from fooling the scan.
  String codeOnly(String source) {
    final chars = source.split('');
    final end = chars.length;
    void blank(int from, int to) {
      for (var i = from; i < to && i < end; i++) {
        if (chars[i] != '\n') chars[i] = ' ';
      }
    }

    var i = 0;
    while (i < end) {
      final c = chars[i];
      if (c == '/' && i + 1 < end && chars[i + 1] == '/') {
        var j = i;
        while (j < end && chars[j] != '\n') j++;
        blank(i, j);
        i = j;
      } else if (c == '/' && i + 1 < end && chars[i + 1] == '*') {
        var j = i + 2;
        while (j + 1 < end && !(chars[j] == '*' && chars[j + 1] == '/')) j++;
        final stop = j + 2 < end ? j + 2 : end;
        blank(i, stop);
        i = stop;
      } else if (c == "'" || c == '"') {
        final quote = c;
        var j = i + 1;
        while (j < end) {
          if (chars[j] == '\\') {
            j += 2;
            continue;
          }
          if (chars[j] == quote) {
            j++;
            break;
          }
          j++;
        }
        blank(i, j);
        i = j;
      } else {
        i++;
      }
    }
    return chars.join();
  }

  /// One entry per `IconButton(`: its 1-based line and its argument list.
  List<({int line, String block})> iconButtons(String source) {
    final code = codeOnly(source);
    final found = <({int line, String block})>[];
    for (final m in RegExp(r'IconButton\s*\(').allMatches(code)) {
      var depth = 1;
      var at = m.end;
      for (; at < code.length && depth > 0; at++) {
        final c = code[at];
        if (c == '(') {
          depth++;
        } else if (c == ')') {
          depth--;
        }
      }
      final line = source.substring(0, m.start).split('\n').length;
      found.add((line: line, block: code.substring(m.start, at)));
    }
    return found;
  }

  List<String> violationsIn(String path, String source) {
    final normalized = path.replaceAll('\\', '/');
    final offenders = <String>[];
    for (final b in iconButtons(source)) {
      if (b.block.contains('tooltip:') || b.block.contains('Semantics')) {
        continue;
      }
      final key = '$normalized:${b.line}';
      if (!allowlist.contains(key)) offenders.add(key);
    }
    return offenders;
  }

  setUpAll(() {
    libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the package root');

    presentationFiles = <File>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (!path.startsWith('lib/features/')) continue;
      // Files directly in `presentation/` have no trailing slash.
      if (!path.contains('/presentation/') &&
          !path.endsWith('/presentation')) {
        continue;
      }
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
      presentationFiles.add(entity);
    }
  });

  test('the scan actually inspects icon buttons in presentation code', () {
    expect(
      presentationFiles.length,
      greaterThan(40),
      reason: 'only found ${presentationFiles.length} presentation files',
    );
    var count = 0;
    for (final file in presentationFiles) {
      count += iconButtons(file.readAsStringSync()).length;
    }
    expect(
      count,
      greaterThan(35),
      reason: 'only found $count IconButtons — the detector is not seeing them',
    );
  });

  test('the detector flags a bare button but not a labelled one', () {
    expect(
      violationsIn(
        'lib/features/x/presentation/x.dart',
        'Widget build(BuildContext context) {\n'
        '  return IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {});\n'
        '}\n',
      ),
      isNotEmpty,
    );
    expect(
      violationsIn(
        'lib/features/x/presentation/x.dart',
        'Widget build(BuildContext context) {\n'
        '  return IconButton(tooltip: "Close", icon: const Icon(Icons.close_rounded), onPressed: () {});\n'
        '}\n',
      ),
      isEmpty,
    );
    expect(
      violationsIn(
        'lib/features/x/presentation/x.dart',
        'Widget build(BuildContext context) {\n'
        '  return IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {}); // tooltip: Close\n'
        '}\n',
      ),
      isNotEmpty,
      reason: 'a tooltip in a comment is not an accessibility label',
    );
  });

  test('every icon-only button in presentation code is labelled', () {
    final offenders = <String>[];
    for (final file in presentationFiles) {
      offenders.addAll(violationsIn(file.path, file.readAsStringSync()));
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Add a localized `tooltip:` (or a Semantics label) to each of '
          'these buttons. Use an existing ARB key where one matches; otherwise '
          'add English, Nepali and Hindi on one add(...) line in '
          'tool/generate_arb.py, then run '
          '`python tool/generate_arb.py && flutter gen-l10n`:\n'
          '${offenders.join('\n')}',
    );
  });
}
