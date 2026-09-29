import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  final libraryScreen =
      File('lib/features/library/presentation/screens/library_browser_screen.dart')
          .readAsStringSync();
  final routerSource =
      File('lib/app/router/app_router.dart').readAsStringSync();

  group('the Library screen is the entry point for the reader corpora', () {
    test('it navigates to the book catalog', () {
      expect(libraryScreen, contains("push('/books')"),
          reason: 'the Book Engine reader is unreachable without this');
    });

    test('it navigates to the syllabus', () {
      expect(libraryScreen, contains("push('/syllabus')"),
          reason: 'the Syllabus Engine is unreachable without this');
    });

    test('it labels both, so the entries are not mystery buttons', () {
      expect(libraryScreen, contains("label: 'Books'"));
      expect(libraryScreen, contains("label: 'Syllabus'"));
    });
  });

  group('those entry points are real routes', () {
    test('/books is registered at the top level', () {
      expect(routerSource, contains("path: '/books',"));
    });

    test('/syllabus is registered at the top level', () {
      expect(routerSource, contains("path: '/syllabus',"));
    });

    test('the catalog routes are public, so they work signed out', () {
      // The server exposes both catalog groups outside auth:sanctum. If either
      // were ever authenticated, this entry point would 401 for a guest.
      expect(
        File('C:/laragon/www/bisaas/routes/api/v1/syllabus.php')
            .readAsStringSync(),
        contains("withoutMiddleware('auth:sanctum')"),
      );
      expect(
        File('C:/laragon/www/bisaas/routes/api/v1/book.php')
            .readAsStringSync(),
        isNot(contains("withoutMiddleware('auth:sanctum')")),
        reason: 'book.php is outside the auth group by file location; if this '
            'starts failing, the catalog is no longer public',
      );
    });
  });
}
