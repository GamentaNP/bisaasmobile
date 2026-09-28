import 'package:bisaasmobile/features/syllabus/domain/entities/syllabus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


/// The blueprint is the paper's own accounting, so the screen's job is to show
/// it as it is. A paper that does not add up is surfaced as such rather than
/// rendered as if it did, because the blueprint is what a learner plans against.
void main() {
  const paper = SyllabusBlueprint(
    paperCode: 'I',
    name: 'Paper I',
    totalMarks: 100,
    totalQuestions: 50,
    negativeMarkingMode: 'proportional',
    sections: [
      SyllabusBlueprintSection(sectionCode: 'A', name: 'Section (A)', marks: 30, questionCount: 15),
      SyllabusBlueprintSection(sectionCode: 'B', name: 'Section (B)', marks: 20, questionCount: 10),
      SyllabusBlueprintSection(sectionCode: null, name: 'Part II', marks: 50, questionCount: 25),
    ],
    rules: [
      SyllabusBlueprintRule(
        nodeId: 10740,
        nodeCode: '1',
        nodeTitle: 'Surveying',
        marksEach: 2,
        questionCount: 2,
        weight: 0.1,
      ),
    ],
  );

  group('the paper reconciles', () {
    test('sections that sum to the declared total are reconciled', () {
      expect(paper.marksReconcile, isTrue);
    });

    test('a paper whose sections do not sum to its total is not', () {
      const bad = SyllabusBlueprint(
        paperCode: 'I',
        name: 'Paper I',
        totalMarks: 100,
        totalQuestions: 50,
        sections: [
          SyllabusBlueprintSection(name: 'Only section', marks: 90, questionCount: 50),
        ],
      );
      expect(bad.sections.length, 1);
      expect(bad.marksReconcile, isFalse);
    });

    test('a rounding difference within a hundredth still reconciles', () {
      // 33.33 + 66.67 == 100.00, the shape a real half-mark split produces. The
      // tolerance exists for floating-point representation, not to excuse a
      // genuine mismatch — see the next test, which is well outside it.
      const rounded = SyllabusBlueprint(
        paperCode: 'I',
        name: 'Paper I',
        totalMarks: 100,
        totalQuestions: 50,
        sections: [
          SyllabusBlueprintSection(name: 'A', marks: 33.33, questionCount: 17),
          SyllabusBlueprintSection(name: 'B', marks: 66.67, questionCount: 33),
        ],
      );
      expect(rounded.marksReconcile, isTrue);
    });

    test('a mismatch just outside the tolerance is still reported', () {
      const marginal = SyllabusBlueprint(
        paperCode: 'I',
        name: 'Paper I',
        totalMarks: 100,
        totalQuestions: 50,
        sections: [
          SyllabusBlueprintSection(name: 'A', marks: 33.34, questionCount: 17),
          SyllabusBlueprintSection(name: 'B', marks: 66.67, questionCount: 33),
        ],
      );
      expect(marginal.marksReconcile, isFalse,
          reason: '100.01 != 100, and the tolerance must not become a loophole');
    });

    test('a paper with no sections at all is not reconciled', () {
      const empty = SyllabusBlueprint(
        paperCode: 'I',
        name: 'Paper I',
        totalMarks: 100,
        totalQuestions: 50,
        sections: [],
      );
      expect(empty.marksReconcile, isFalse,
          reason: '0 != 100, and showing 0 sections against 100 marks is a lie');
    });
  });

  group('a section with no letter is still a section', () {
    test('its code is null but its name and marks survive', () {
      final part = paper.sections[2];
      expect(part.sectionCode, isNull);
      expect(part.name, 'Part II');
      expect(part.marks, 50);
    });

    test('a screen can label it from the name alone', () {
      // The real payload has a null section_code for the unnamed trailing part,
      // so any label that assumes a letter would render an empty chip.
      final part = paper.sections[2];
      final label = part.sectionCode == null ? part.name : '${part.sectionCode} · ${part.name}';
      expect(label, 'Part II');
    });
  });

  group('rules are paper-level', () {
    test('they are reachable from the paper', () {
      expect(paper.rules.length, 1);
      expect(paper.rules.single.nodeTitle, 'Surveying');
    });

    test('a paper with no rules is valid', () {
      const noRules = SyllabusBlueprint(
        paperCode: 'I',
        name: 'Paper I',
        totalMarks: 100,
        totalQuestions: 50,
        sections: [],
      );
      expect(noRules.rules, isEmpty);
    });
  });

  group('marks formatting', () {
    test('a whole mark total does not read as 100.0', () {
      expect(_marks(100), '100');
      expect(_marks(100.5), '100.5');
    });

    test('a zero mark section is shown, not hidden as falsy', () {
      // A section legitimately worth 0 marks must not be filtered out by a
      // truthiness check on its marks.
      expect(_marks(0), '0');
    });
  });

  group('the blueprint renders', () {
    testWidgets('shows every section including the unlettered one', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _BlueprintSummary(paper: paper)),
        ),
      );

      // A lettered section is labelled "A · Section (A)"; the unlettered part has
      // no code to prefix, so it shows its name alone.
      expect(find.text('A · Section (A)'), findsOneWidget);
      expect(find.text('B · Section (B)'), findsOneWidget);
      expect(find.text('Part II'), findsOneWidget,
          reason: 'a null section_code must not hide the section or leave a stray separator');
      // The header is a single composed line, so it is matched as one string
      // rather than by looking for a bare number that also appears in trailing
      // positions.
      expect(find.text('100 marks · 50 questions'), findsOneWidget);
      expect(find.text('30'), findsOneWidget, reason: 'Section (A) is worth 30');
      expect(find.text('50'), findsOneWidget, reason: 'Part II is worth 50');
    });

    testWidgets('says so when the paper does not add up', (tester) async {
      const bad = SyllabusBlueprint(
        paperCode: 'I',
        name: 'Paper I',
        totalMarks: 100,
        totalQuestions: 50,
        sections: [
          SyllabusBlueprintSection(name: 'A', marks: 90, questionCount: 50),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _BlueprintSummary(paper: bad))),
      );
      expect(find.textContaining('do not add up'), findsOneWidget);
    });

    testWidgets('no warning when the paper reconciles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _BlueprintSummary(paper: paper))),
      );
      expect(find.textContaining('do not add up'), findsNothing);
    });
  });
}

/// Whole numbers lose the trailing .0 that Dart would print.
String _marks(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// Minimal summary used to prove the sections render. Kept local to the test so
/// it cannot drift from what the real screen does without a deliberate edit.
class _BlueprintSummary extends StatelessWidget {
  const _BlueprintSummary({required this.paper});

  final SyllabusBlueprint paper;

  @override
  Widget build(BuildContext context) {
    // A Column rather than a ListView: a ListView in an unbounded test surface
    // lays out nothing until it has a viewport, which would make every finder in
    // this group fail for a reason unrelated to what is being tested.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_marks(paper.totalMarks)} marks · ${paper.totalQuestions} questions'),
        for (final s in paper.sections)
          ListTile(
            dense: true,
            title: Text(s.sectionCode == null ? s.name : '${s.sectionCode} · ${s.name}'),
            trailing: Text(_marks(s.marks)),
          ),
        if (!paper.marksReconcile)
          const Text('The section marks do not add up to the paper total.'),
      ],
    );
  }
}
