import 'package:bisaasmobile/shared/utils/wire_coercion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wireInt', () {
    test('accepts ints, other nums, numeric strings and numeric toString()', () {
      expect(wireInt(7), 7);
      expect(wireInt(7.9), 7);
      expect(wireInt(8.0), 8);
      expect(wireInt('42'), 42);
      // Legacy boxed values only expose a numeric toString().
      expect(wireInt(_NumericToString(19)), 19);
    });

    test('returns null instead of inventing a value', () {
      expect(wireInt(null), isNull);
      expect(wireInt('nope'), isNull);
      expect(wireInt(true), isNull);
      expect(wireInt(Object()), isNull);
      expect(wireIntOrZero('nope'), 0);
      expect(wireIntOrZero(null), 0);
    });
  });

  group('wireDouble', () {
    test('accepts doubles, ints and numeric strings', () {
      expect(wireDouble(1.5), 1.5);
      expect(wireDouble(2), 2.0);
      expect(wireDouble('3.25'), 3.25);
    });

    test('returns null for missing or unparseable values', () {
      expect(wireDouble(null), isNull);
      expect(wireDouble('nope'), isNull);
      expect(wireDouble(true), isNull);
    });
  });

  group('wireDate', () {
    test('accepts both DateTime and ISO-8601 strings', () {
      final date = DateTime.utc(2026, 11, 25, 8, 30);
      expect(wireDate(date), same(date));
      expect(wireDate('2026-11-25T08:30:00Z'),
          DateTime.utc(2026, 11, 25, 8, 30));
    });

    test('returns null for missing or unparseable values', () {
      expect(wireDate(null), isNull);
      expect(wireDate('not-a-date'), isNull);
      expect(wireDate(123), isNull);
    });
  });
}

class _NumericToString {
  const _NumericToString(this.value);
  final int value;

  @override
  String toString() => '$value';
}
