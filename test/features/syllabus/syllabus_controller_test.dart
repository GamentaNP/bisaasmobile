import 'package:bisaasmobile/features/syllabus/data/datasources/syllabus_remote_data_source.dart';
import 'package:bisaasmobile/features/syllabus/data/models/syllabus_dto.dart';
import 'package:bisaasmobile/features/syllabus/data/repositories/syllabus_repository_impl.dart';
import 'package:bisaasmobile/features/syllabus/domain/entities/syllabus.dart';
import 'package:bisaasmobile/features/syllabus/presentation/controllers/syllabus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyllabusRemote extends Mock implements SyllabusRemoteDataSource {}

/// Controller-level tests for the syllabus.
///
/// The DTO tests pin the parsing, including the two live-API surprises (the
/// empty-string `children` field and the 542-vs-33 depth skew). These pin the
/// state behaviour, where the user-facing lie would be: a "no syllabus" flash
/// while still loading, or a depth-scoped count presented as the total.
void main() {
  late MockSyllabusRemote remote;

  setUpAll(() {
    // The remote takes only positional `String`/`int` arguments, so a single
    // empty-list fallback is enough for every `any()` in this file.
    registerFallbackValue(<String>[]);
  });

  setUp(() => remote = MockSyllabusRemote());

  SyllabusVersion version({
    String id = 'V1',
    String code = 'loksewa-2082',
    bool effective = true,
    int nodeCount = 542,
  }) {
    // A closed effective window is how "not current" is actually expressed. A
    // version with no window at all is treated as current by the domain, so a
    // null `effective_from` would not be a valid way to build this fixture.
    return SyllabusVersion(
      publicId: id,
      versionCode: code,
      title: 'Lok Sewa Sub Engineer',
      status: effective ? 'published' : 'draft',
      effectiveFrom: DateTime(2020),
      effectiveTo: effective ? null : DateTime(2021),
      nodeCount: nodeCount,
      examinableNodeCount: 535,
    );
  }

  SyllabusTree tree({int nodes = 2, bool depthLimited = true}) => SyllabusTree(
        nodes: [
          SyllabusNode(
            id: 1,
            title: 'General Knowledge',
            nodeType: 'paper',
            depth: 0,
            questionCount: 0,
          ),
        ],
        nodeCount: nodes,
        examinableNodeCount: nodes,
        depthLimited: depthLimited,
      );

  ProviderContainer containerWith({
    List<SyllabusVersion>? versions,
    SyllabusTree? t,
    bool failVersions = false,
    bool failTree = false,
  }) {
    if (failVersions) {
      when(() => remote.getVersions()).thenThrow(StateError('boom'));
    } else {
      when(() => remote.getVersions())
          .thenAnswer((_) async => (versions ?? [version()]).map(SyllabusVersionDto.new).toList());
    }
    if (failTree) {
      when(() => remote.getTree(any(), depth: any(named: 'depth'))).thenThrow(StateError('boom'));
    } else {
      when(() => remote.getTree(any(), depth: any(named: 'depth'))).thenAnswer((_) async => SyllabusTreeDto(t ?? tree()));
    }
    when(() => remote.getMyPlans()).thenAnswer((_) async => <UserSyllabusPlanDto>[]);

    final c = ProviderContainer(
      overrides: [syllabusRemoteDataSourceProvider.overrideWithValue(remote)],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle(ProviderContainer c) async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('version list', () {
    test('loads the versions', () async {
      final c = containerWith();
      c.read(syllabusVersionsControllerProvider);
      await settle(c);
      final s = c.read(syllabusVersionsControllerProvider);
      expect(s.versions, hasLength(1));
      expect(s.versions.first.versionCode, 'loksewa-2082');
      expect(s.error, isNull);
    });

    test('an empty catalogue is empty, not an error', () async {
      final c = containerWith(versions: const []);
      c.read(syllabusVersionsControllerProvider);
      await settle(c);
      final s = c.read(syllabusVersionsControllerProvider);
      expect(s.isEmpty, isTrue);
      expect(s.error, isNull);
    });

    test('isEmpty is false while still loading, so no "no syllabus" flash', () async {
      // The distinction that matters: a user opening the screen should not be
      // told there is no syllabus before the request has come back.
      final c = containerWith();
      final s = c.read(syllabusVersionsControllerProvider);
      expect(s.isEmpty, isFalse);
      expect(s.isLoading, isTrue);
      await settle(c);
    });

    test('a failed load reports and is not mistaken for an empty catalogue', () async {
      final c = containerWith(failVersions: true);
      c.read(syllabusVersionsControllerProvider);
      await settle(c);
      final s = c.read(syllabusVersionsControllerProvider);
      expect(s.error, isNotNull);
      expect(s.isEmpty, isFalse, reason: 'a failure is not an empty catalogue');
    });

    test('effective prefers versions in force but never returns nothing', () async {
      // A closed effective window is not a reason to tell the user there is no
      // syllabus at all.
      final c = containerWith(versions: [version(effective: false)]);
      c.read(syllabusVersionsControllerProvider);
      await settle(c);
      final s = c.read(syllabusVersionsControllerProvider);
      expect(s.effective, isNotEmpty);
    });

    test('effective prefers the in-force ones when a mix exists', () async {
      final c = containerWith(
        versions: [version(id: 'A', effective: false), version(id: 'B')],
      );
      c.read(syllabusVersionsControllerProvider);
      await settle(c);
      final s = c.read(syllabusVersionsControllerProvider);
      expect(s.effective.map((v) => v.publicId), ['B']);
    });
  });

  group('tree', () {
    const id = 'V1';

    test('loads the tree for the version', () async {
      final c = containerWith();
      c.read(syllabusTreeControllerProvider(id));
      await settle(c);
      final s = c.read(syllabusTreeControllerProvider(id));
      expect(s.tree, isNotNull);
      expect(s.error, isNull);
    });

    test('a failed tree load reports rather than showing an empty syllabus', () async {
      final c = containerWith(failTree: true);
      c.read(syllabusTreeControllerProvider(id));
      await settle(c);
      final s = c.read(syllabusTreeControllerProvider(id));
      expect(s.error, isNotNull);
      expect(s.tree, isNull,
          reason: 'a failure must not render as "this syllabus has no topics"');
    });

    test('an empty tree is distinguishable from a failure', () async {
      final c = containerWith(
        t: const SyllabusTree(nodes: [], nodeCount: 0, examinableNodeCount: 0),
      );
      c.read(syllabusTreeControllerProvider(id));
      await settle(c);
      final s = c.read(syllabusTreeControllerProvider(id));
      expect(s.error, isNull);
      expect(s.isEmpty, isTrue);
    });

    test('a depth-scoped tree is flagged so the count is not read as the total', () async {
      // Live API: the version says 542 topics, /tree?depth=2 says 33. Showing both
      // as "topics" looks like a data bug.
      final c = containerWith(
        t: tree(nodes: 33, depthLimited: true),
      );
      c.read(syllabusTreeControllerProvider(id));
      await settle(c);
      expect(c.read(syllabusTreeControllerProvider(id)).tree!.depthLimited, isTrue);
    });

    test('a full tree is not flagged as scoped', () async {
      final c = containerWith(
        t: tree(nodes: 542, depthLimited: false),
      );
      c.read(syllabusTreeControllerProvider(id));
      await settle(c);
      expect(c.read(syllabusTreeControllerProvider(id)).tree!.depthLimited, isFalse);
    });
  });

  group('repository transparency', () {
    test('a null version is not substituted with a fabricated one', () async {
      when(() => remote.getVersion(any())).thenAnswer((_) async => null);
      final repo = SyllabusRepositoryImpl(remote);
      expect(await repo.getVersion('nope'), isNull);
    });

    test('the public id is what is sent, never the version code', () async {
      // The route binds on SyllabusVersion::getRouteKeyName() = public_id.
      when(() => remote.getTree(any(), depth: any(named: 'depth'))).thenAnswer((_) async => SyllabusTreeDto(tree()));
      final repo = SyllabusRepositoryImpl(remote);
      await repo.getTree('01HQ8S4T2V0000000000001');
      verify(() => remote.getTree('01HQ8S4T2V0000000000001',
          depth: any(named: 'depth'))).called(1);
    });
  });
}
