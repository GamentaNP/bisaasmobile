import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the architecture rule that a feature's presentation code never
/// imports a sibling feature directly.
///
/// The root `AGENTS.md` says it plainly — "features/ never import each other
/// directly — communicate via Riverpod providers or router" — but a rule in a
/// markdown file is not a rule in CI. This is the cheap, dependency-free source
/// scan that makes it one. It is modelled on `router_reachability_test.dart`:
/// reading source is enough, so no Dio client, secure storage or widget pump is
/// needed, and it fails loudly in CI the moment the boundary is crossed.
///
/// The composition root (`lib/app/feature_bridges.dart` and `providers.dart`)
/// and `lib/shared/` are the escape hatches: importing either is allowed, and
/// deliberately not checked here. Only a *direct* import of `lib/features/B/**`
/// from `lib/features/A/presentation/**` (A != B) is an offence.
void main() {
  late Directory libDir;
  late List<File> presentationFiles;

  /// Documented exceptions. Keep this empty: every case found so far was
  /// resolvable through an app-level provider seam or a shared UI façade.
  /// An entry here must name the file and say what redesign it is waiting on.
  const allowlist = <String>{};

  /// Resolve a relative import target against the importing file, mirroring
  /// `router_reachability_test.dart` so both scans agree on paths (Windows
  /// separators included).
  String resolve(String importerPath, String target) {
    var base = File(importerPath).parent;
    for (final segment in target.split('/')) {
      if (segment == '..') {
        base = base.parent;
      } else if (segment != '.') {
        base = Directory('${base.path}/$segment');
      }
    }
    return base.path.replaceAll('\\', '/');
  }

  /// The first path segment after `/features/`, or `null` for app/core/shared.
  String? featureOf(String normalizedPath) {
    const marker = '/features/';
    final i = normalizedPath.indexOf(marker);
    if (i < 0) return null;
    final rest = normalizedPath.substring(i + marker.length);
    if (rest.isEmpty) return null;
    return rest.split('/').first;
  }

  /// Direct cross-feature imports in one source file.
  List<String> violationsIn(String importerPath, String source) {
    final from = featureOf(importerPath.replaceAll('\\', '/'));
    if (from == null) return const [];

    final found = <String>[];
    for (final m in RegExp(
      r"^import\s+'([^']+)'",
      multiLine: true,
    ).allMatches(source)) {
      final target = m.group(1)!;
      // package:/dart: are opaque to a relative path scan.
      if (target.startsWith('package:') || target.startsWith('dart:')) continue;
      final resolved = resolve(importerPath, target);
      final to = featureOf(resolved);
      if (to == null || to == from) continue;
      final entry =
          '${importerPath.replaceAll('\\', '/')}: $target  ($from -> $to)';
      if (allowlist.contains(entry)) continue;
      found.add(entry);
    }
    return found;
  }

  setUpAll(() {
    libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the package root');

    presentationFiles = <File>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (!path.startsWith('lib/features/')) continue;
      if (!path.contains('/presentation/')) continue;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
      presentationFiles.add(entity);
    }
  });

  test('the scan actually inspects presentation code', () {
    // Guard against a broken path filter: an empty file list would make the
    // boundary test below vacuously pass.
    expect(
      presentationFiles.length,
      greaterThan(40),
      reason: 'only found ${presentationFiles.length} presentation files',
    );
  });

  test('the detector flags a sibling import but not a safe one', () {
    // Same guard from the other direction: prove the regex and path maths
    // really find a cross-feature import rather than just reporting nothing.
    const importer = 'lib/features/home/presentation/screens/home_screen.dart';
    expect(
      violationsIn(
        importer,
        "import '../../../quiz/presentation/screens/quiz_result_screen.dart';\n",
      ),
      isNotEmpty,
    );
    expect(
      violationsIn(
        importer,
        "import '../../domain/entities/dashboard_data.dart';\n"
        "import '../../../../shared/widgets/glassmorphic_card.dart';\n"
        "import '../../../../app/feature_bridges.dart';\n",
      ),
      isEmpty,
    );
  });

  test('no presentation file imports another feature directly', () {
    final offenders = <String>[];
    for (final file in presentationFiles) {
      offenders.addAll(violationsIn(file.path, file.readAsStringSync()));
    }

    expect(
      offenders,
      isEmpty,
      reason: 'A feature must not import a sibling feature directly. '
          'Expose the signal through lib/app/providers.dart (or the app-level '
          'feature_bridges.dart seam), route through go_router, or move '
          'genuinely shared UI into lib/shared/widgets/ instead:\n'
          '${offenders.join('\n')}',
    );
  });
}
