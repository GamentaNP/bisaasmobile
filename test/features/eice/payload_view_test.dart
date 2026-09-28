import 'package:bisaasmobile/features/eice/presentation/widgets/payload_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Object? data) => MaterialApp(
        home: Scaffold(body: PayloadView(data: data)),
      );

  group('humaniseKey', () {
    test('turns snake_case into a sentence-cased label', () {
      expect(humaniseKey('total_due'), 'Total due');
    });

    test('splits camelCase', () {
      expect(humaniseKey('totalDue'), 'Total due');
    });

    test('treats hyphens and underscores the same', () {
      expect(humaniseKey('exam-name'), 'Exam name');
    });

    test('leaves an unparseable key alone rather than returning empty', () {
      expect(humaniseKey('___'), '___');
    });
  });

  group('formatScalar', () {
    test('renders null as a dash, not "null"', () {
      expect(formatScalar(null), '—');
    });

    test('drops the float tail a JSON round-trip introduces', () {
      expect(formatScalar(3.0), '3');
    });

    test('keeps a genuine fractional value', () {
      expect(formatScalar(0.75), '0.75');
    });

    test('speaks booleans as yes/no', () {
      expect(formatScalar(true), 'Yes');
      expect(formatScalar(false), 'No');
    });

    test('summarises collections rather than dumping them', () {
      expect(formatScalar([1, 2, 3]), '3 items');
      expect(formatScalar([1]), '1 item');
      expect(formatScalar({'a': 1}), '1 field');
    });
  });

  group('PayloadView', () {
    testWidgets('renders a label and value pair', (tester) async {
      await tester.pumpWidget(host({'total_due': 4}));
      expect(find.text('Total due'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('never shows raw JSON', (tester) async {
      // The regression this widget exists for: the EICE screen used to render
      // `data.toString()` straight into a Text widget.
      await tester.pumpWidget(host({'total_due': 4}));
      expect(find.textContaining('{total_due: 4}'), findsNothing);
    });

    testWidgets('hides debug keys', (tester) async {
      await tester.pumpWidget(host({'total_due': 4, '_debug': 'raw envelope'}));
      expect(find.text('Total due'), findsOneWidget);
      expect(find.text('raw envelope'), findsNothing);
      expect(find.textContaining('Debug'), findsNothing);
    });

    testWidgets('says so when the payload is null', (tester) async {
      await tester.pumpWidget(host(null));
      expect(find.text('No data available yet.'), findsOneWidget);
    });

    testWidgets('nests a map value instead of flattening it', (tester) async {
      await tester.pumpWidget(host({
        'summary': {'due': 2, 'new': 1},
      }));
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders a list of maps as rows', (tester) async {
      await tester.pumpWidget(host([
        {'topic': 'Soil Mechanics'},
        {'topic': 'Concrete'},
      ]));
      expect(find.text('Soil Mechanics'), findsOneWidget);
      expect(find.text('Concrete'), findsOneWidget);
    });

    testWidgets('handles an empty list and an empty map', (tester) async {
      final emptyList = <dynamic>[];
      final emptyMap = <String, dynamic>{};
      await tester.pumpWidget(host(emptyList));
      expect(find.text('Nothing here yet.'), findsOneWidget);

      await tester.pumpWidget(host(emptyMap));
      expect(find.text('No details available yet.'), findsOneWidget);
    });

    testWidgets('caps a long list and states how many are hidden', (
      tester,
    ) async {
      final long = List<Map<String, dynamic>>.generate(
        12,
        (i) => <String, dynamic>{'n': i},
      );
      await tester.pumpWidget(host(long));
      expect(find.text('and 4 more…'), findsOneWidget);
    });
  });
}
