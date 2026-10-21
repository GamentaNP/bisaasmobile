import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rebuilds the **full** path of every route the router declares, and which
/// of them are redirect aliases.
///
/// A nested route's `path` is relative to its parent (`'browse'` under
/// `/quiz` is `/quiz/browse`). The parent is recovered from the
/// indentation, which the Dart formatter keeps consistent.
(List<String> paths, Set<String> redirects) _resolveRoutePaths(String source) {
  final paths = <String>[];
  final redirects = <String>{};
  // (indent, full path) of the enclosing routes, outermost first.
  final stack = <(int, String)>[];
  final lines = source.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final match = RegExp(r"^(\s*)path:\s*'([^']+)'").firstMatch(line);
    if (match == null) continue;

    final indent = match.group(1)!.length;
    final segment = match.group(2)!;

    // Pop the routes this one is not nested inside.
    while (stack.isNotEmpty && stack.last.$1 >= indent) {
      stack.removeLast();
    }

    final parent = stack.isEmpty ? '' : stack.last.$2;
    final full = segment.startsWith('/')
        ? segment
        : (parent.isEmpty ? '/$segment' : '$parent/$segment');
    stack.add((indent, full));
    paths.add(full);

    // A route with a `redirect:` is an alias for another location — it binds
    // no screen of its own, so it does not need a link of its own.
    for (var j = i + 1; j < lines.length && j < i + 12; j++) {
      if (RegExp(r"^\s*path:\s*'").hasMatch(lines[j])) break;
      if (lines[j].contains('redirect:')) {
        redirects.add(full);
        break;
      }
    }
  }

  return (paths, redirects);
}

/// Guards against the **other** direction of the router reachability problem.
///
/// `router_reachability_test.dart` proves that every screen is wired into the
/// router. This one proves the opposite, and it is the direction that was
/// actually broken: a route can exist, be bound to a perfectly good screen,
/// and still be **unreachable**, because no screen in the app ever links to
/// it.
///
/// Five shipped features were in that state — the practice drill, the
/// leaderboard, the contests, the live events and the coaching dashboard. The
/// practice drill was the expensive one: a whole server-graded drill flow
/// that no user could reach without typing the URL.
///
/// The rule: every route the router declares must be linked from somewhere in
/// `lib/`, except the app's entry points (`/`, `/login`, `/home`, `/register`,
/// `/forgot-password`, `/reset-password`, `/onboarding`) which are reached by
/// the splash screen and the auth guard rather than by a link.
void main() {
  /// The routes that are reached by the shell, the splash screen or the auth
  /// guard rather than by a link in a screen.
  const entryPoints = <String>{
    '/',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/onboarding',
    '/home',
  };

  late List<String> routePaths;
  late Set<String> redirectRoutes;
  late Map<String, String> libSources;

  setUpAll(() {
    expect(Directory('lib').existsSync(), isTrue, reason: 'run from the package root');

    // ── The router's paths ──────────────────────────────────────────────────
    final router = File('lib/app/router/app_router.dart');
    expect(router.existsSync(), isTrue);
    final resolved = _resolveRoutePaths(router.readAsStringSync());
    routePaths = resolved.$1;
    redirectRoutes = resolved.$2;

    // ── Every Dart source in lib/ ───────────────────────────────────────────
    libSources = <String, String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      // The router declares the routes; counting its own declarations as
      // "links" would make every route look reachable. The deep-link handler
      // is the exception — it *produces* navigable locations from an
      // external URL, which is a real entry point.
      if (path.startsWith('lib/app/router/') &&
          !path.endsWith('deep_link_handler.dart')) {
        continue;
      }
      libSources[path] = entity.readAsStringSync();
    }
  });

  test('the scan found the routes (guards the scan itself)', () {
    expect(routePaths.length, greaterThan(30),
        reason: 'only found ${routePaths.length} routes — the regex broke');
    expect(libSources.length, greaterThan(100),
        reason: 'only found ${libSources.length} sources — the walk broke');
  });

  test('every route is linked from somewhere in the app', () {
    final orphans = <String>[];

    for (final route in routePaths) {
      if (entryPoints.contains(route)) continue;
      // A redirect route is an alias for another location; it binds no screen
      // of its own, so it does not need a link of its own.
      if (redirectRoutes.contains(route)) continue;

      // A route with a path parameter is linked by its concrete value:
      // `/learning/goals/42` links to the `/learning/goals/:id` route, so the
      // link starts with the prefix **and** a separator.
      final segments = route.split('/');
      final firstParam = segments.indexWhere((s) => s.startsWith(':'));
      final hasParam = firstParam != -1;
      final prefix = hasParam
          ? segments.sublist(0, firstParam).join('/')
          : route;
      if (prefix.isEmpty) continue;

      // The link must be the route itself, not a longer route that merely
      // starts with the same characters: `'/practice/session'` is not a link
      // to `'/practice'`.
      final pattern = hasParam
          ? RegExp("'${RegExp.escape(prefix)}/[^']*'")
          : RegExp("'${RegExp.escape(route)}['\"?#)]");

      var linked = false;
      for (final source in libSources.values) {
        if (pattern.hasMatch(source)) {
          linked = true;
          break;
        }
      }

      if (!linked) orphans.add(route);
    }

    expect(
      orphans,
      isEmpty,
      reason: 'These routes exist and are bound to a screen, but no screen in '
          'lib/ links to them, so no user can reach them. Add a link (a tile, '
          'a button, a banner) or remove the route:\n${orphans.join('\n')}',
    );
  });
}
