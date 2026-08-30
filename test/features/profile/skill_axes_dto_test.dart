import 'package:flutter_test/flutter_test.dart';
import 'package:bisaasmobile/features/profile/data/models/skill_axes_dto.dart';

void main() {
  group('SkillAxis', () {
    test('parses the /profile/skills axis payload tolerantly', () {
      final axis = SkillAxis.fromJson(const {
        'key': 7,
        'label': 'Structural Analysis',
        'answered': 12,
        'correct': 9,
        'accuracy': 0.75,
      });

      expect(axis.key, 7);
      expect(axis.label, 'Structural Analysis');
      expect(axis.answered, 12);
      expect(axis.correct, 9);
      expect(axis.accuracy, 0.75);
    });

    test('defaults missing fields instead of throwing', () {
      final axis = SkillAxis.fromJson(const {});

      expect(axis.key, 0);
      expect(axis.label, '');
      expect(axis.answered, 0);
      expect(axis.correct, 0);
      expect(axis.accuracy, 0.0);
    });

    test('coerces numeric accuracy sent as int to double', () {
      final axis = SkillAxis.fromJson(const {'accuracy': 1});

      expect(axis.accuracy, 1.0);
    });
  });
}
