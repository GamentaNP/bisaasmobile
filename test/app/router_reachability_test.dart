import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against screens that exist but can never be reached.
///
/// Three screens shipped orphaned before this test existed: `QuizResultScreen`
/// (its route was bound to `QuizReviewScreen` instead, so the post-quiz result
/// moment never rendered), `GameWorldMapScreen` (no route at all) and
/// `AiTutorScreen` (reachable only by a raw `Navigator.push`, which the repo's
/// own comment says renders nothing on web). A full-feature build silently
/// showing none of them.
///
/// **The rule:** every public `*Screen` / `*Page` widget under
/// `lib/features/**/presentation/` must be reachable from
/// `lib/app/router/app_router.dart` or `lib/app/router/shell_router.dart`.
///
/// Reachability is resolved as a *transitive import closure* from the router,
/// so a screen reached through a thin wrapper widget (e.g. `QuizResultRoute`
/// picking between the result and review screens) still counts as wired.
///
/// Deliberately a source scan rather than a widget pump: pumping the whole
/// router needs a live Dio client, secure storage and auth state, which is
/// exactly the coupling that let the orphans slip through. Scanning the router
/// source is cheap, dependency-free, and fails loudly in CI.
void main() {
  late Directory libDir;
  late Set<String> reachableClasses;

  /// Resolve a relative import target against the importing file.
  String resolve(String importerPath, String target) {
    final importer = File(importerPath);
    var base = importer.parent;
    for (final segment in target.split('/')) {
      if (segment == '..') {
        base = base.parent;
      } else if (segment != '.') {
        base = Directory('${base.path}/$segment');
      }
    }
    return base.path.replaceAll('\\', '/');
  }

  /// Transitive import closure from [roots].
  Set<String> importClosure(List<String> roots) {
    final seen = <String>{};
    final queue = <String>[...roots];
    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      if (seen.contains(path)) continue;
      final file = File(path);
      if (!file.existsSync()) continue;
      seen.add(path);
      final source = file.readAsStringSync();
      for (final m in RegExp(
        r"^import\s+'([^']+)'",
        multiLine: true,
      ).allMatches(source)) {
        final target = m.group(1)!;
        // Only follow project-local relative imports; package:/dart: are opaque.
        if (target.startsWith('package:') || target.startsWith('dart:')) continue;
        queue.add(resolve(path, target));
      }
    }
    return seen;
  }

  Set<String> declaredClasses(String source) {
    final names = <String>{};
    for (final m in RegExp(r'^(?:abstract\s+)?class\s+([A-Z][A-Za-z0-9]*)', multiLine: true)
        .allMatches(source)) {
      names.add(m.group(1)!);
    }
    return names;
  }

  setUpAll(() {
    libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the package root');

    const roots = ['lib/app/router/app_router.dart', 'lib/app/router/shell_router.dart'];
    for (final root in roots) {
      expect(File(root).existsSync(), isTrue, reason: 'missing $root');
    }

    reachableClasses = <String>{};
    for (final path in importClosure(roots)) {
      reachableClasses.addAll(declaredClasses(File(path).readAsStringSync()));
    }
  });

  List<File> screenFiles() {
    final files = <File>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (!path.startsWith('lib/features/')) continue;
      if (!path.contains('/presentation/')) continue;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
      files.add(entity);
    }
    return files;
  }

  test('the router import closure is non-trivial (guards the scan itself)', () {
    // If the regex or path handling ever broke, the orphan test would vacuously
    // pass with an empty closure. Fail loudly instead.
    expect(
      reachableClasses.length,
      greaterThan(40),
      reason: 'only found ${reachableClasses.length} classes reachable from the router',
    );
  });

  test('every public screen widget is reachable from the router', () {
    final orphans = <String>[];

    for (final file in screenFiles()) {
      final path = file.path.replaceAll('\\', '/');
      final source = file.readAsStringSync();
      for (final m in RegExp(
        r'^class\s+([A-Z][A-Za-z0-9]*(?:Screen|Page|View))\b',
        multiLine: true,
      ).allMatches(source)) {
        final className = m.group(1)!;
        if (!reachableClasses.contains(className)) {
          orphans.add('$className  ($path)');
        }
      }
    }

    expect(
      orphans,
      isEmpty,
      reason: 'These screens are declared but never reachable from '
          'app_router.dart / shell_router.dart, so no user can ever reach them. '
          'Wire a route (or delete the screen):\n${orphans.join('\n')}',
    );
  });

  test('no screen uses a raw Navigator.push (renders nothing on web)', () {
    // The repo hit exactly this: learning_home_screen.dart pushed a screen
    // in-memory through Navigator, which does not render inside the
    // go_router shell branch on web. go_router `go` is the supported path.
    final offenders = <String>[];
    for (final file in screenFiles()) {
      final path = file.path.replaceAll('\\', '/');
      for (final m in RegExp(
        r'Navigator(?:\.of\([^)]*\))?\.(?:push|pushReplacement|pushNamed)\(',
      ).allMatches(file.readAsStringSync())) {
        offenders.add('$path  (offset ${m.start})');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Use go_router (context.go) instead of raw Navigator pushes:\n'
          '${offenders.join('\n')}',
    );
  });
}
