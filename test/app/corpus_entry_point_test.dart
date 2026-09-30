import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locates a file inside a sibling bisaas Laravel checkout, or returns null.
///
/// Resolution order: `BISAAS_ROOT`, then the Laragon sibling-directory default.
/// Returns null instead of throwing so the caller can skip the cross-repo
/// assertion on machines (and CI runners) without the backend.
File? _resolveBackendFile(String relativePath) {
  final candidates = <String>[
    if (Platform.environment['BISAAS_ROOT'] case final String root?
        when root.isNotEmpty)
      root,
    'C:/laragon/www/bisaas',
    '../bisaas',
  ];
  for (final root in candidates) {
    final file = File('$root/$relativePath');
    if (file.existsSync()) return file;
  }
  return null;
}

/// Guards the entry points for the corpora that have their own readers.
///
/// ## Why this exists
///
/// `/syllabus` and `/books` were both correctly registered, both screens
/// existed, both had passing DTO, controller and widget tests, and
/// `router_reachability_test` passed — and no user could reach either one,
/// because nothing in the UI ever navigated to those routes. An import is not
/// an entry point.
///
/// A whole-app "is this route navigated to anywhere" scan was tried and
/// discarded: it cannot tell a shell branch from a dead route, it misses deep
/// links and paths built at runtime, and it produced 20 false positives. A test
/// that cries wolf gets switched off, which is worse than no test. So this
/// asserts the specific contract instead: the Library screen must offer both
/// corpora, and those offers must point at the real registered paths.
///
/// If a third reader corpus is added, add it here too.
void main() {
  final routerSource = File('lib/app/router/app_router.dart')
      .readAsStringSync();

  group('the Courses screen is the entry point for the three content corpora', () {
    final courses = File(
      'lib/features/courses/presentation/screens/courses_screen.dart',
    ).readAsStringSync();

    // These three are separate resources on the server and are NOT
    // interchangeable, so each needs its own correctly named entry:
    //   Library  - /library/files, PDFs and notes as soft form
    //   Books    - /books, the Book Engine with a real reader
    //   Syllabus - /syllabi, the exam tree
    //
    // The tiles are declared as records in `_CorpusTiles._tiles` rather than as
    // inline widgets, so assert on that table. A literal `push('/books')` in the
    // screen body would mean the tile is no longer gated on having content,
    // which is the bug this file was rewritten for.
    for (final (code, label, route) in const [
      ('library', 'Library', '/library'),
      ('books', 'Books', '/books'),
      ('syllabus', 'Syllabus', '/syllabus'),
    ]) {
      test('it offers $label as a distinct, correctly named entry', () {
        expect(
          courses,
          contains("code: '$code'"),
          reason: 'the $label corpus must be declared as its own tile',
        );
        expect(
          courses,
          contains("label: '$label'"),
          reason:
              'on Bisaas "$label" must name the $label resource, not something else',
        );
        expect(
          courses,
          contains("route: '$route'"),
          reason: 'the $label tile must point at the real registered path',
        );
      });
    }

    test('every corpus tile is gated on the server actually having content', () {
      // Without this the app ships a Books tab that can only ever render
      // "No books have been published yet", because all eight book_engine
      // rollout flags are off and nothing has been ingested.
      expect(courses, contains('corpusStatusProvider'));
      expect(
        courses,
        contains('CorpusAvailability.empty'),
        reason: 'an empty corpus must be dropped from the entry points',
      );
    });

    test('the bottom-nav branch is not labelled "Library"', () {
      // It routes to /courses, so calling it Library was wrong: a user looking
      // for the PDF library found this tab with no route to it.
      final nav = File('lib/shared/widgets/bottom_nav.dart').readAsStringSync();
      expect(nav, isNot(contains("'Library', 3)")));
      expect(nav, contains("'Courses', 3)"));
    });
  });

  group('those entry points are real routes', () {
    test('/library, /books and /syllabus are all registered', () {
      expect(routerSource, contains("path: '/library',"));
      expect(routerSource, contains("path: '/books',"));
      expect(routerSource, contains("path: '/syllabus',"));
    });

    // The server exposes the syllabus catalog outside auth:sanctum. If it ever
    // becomes authenticated, this entry point would 401 for a guest.
    //
    // This is a cross-repo contract check, so it only runs when a bisaas
    // checkout is actually reachable. CI has no sibling Laravel app, and a test
    // that cannot run there must skip rather than fail.
    final syllabusRoutes = _resolveBackendFile('routes/api/v1/syllabus.php');

    test(
      'the catalogs are public, so they work signed out',
      () {
        expect(
          syllabusRoutes!.readAsStringSync(),
          contains("withoutMiddleware('auth:sanctum')"),
        );
      },
      skip: syllabusRoutes == null
          ? 'no bisaas checkout found; set BISAAS_ROOT to run this check'
          : null,
    );
  });
}
