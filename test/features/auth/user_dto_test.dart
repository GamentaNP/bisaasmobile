import 'package:flutter_test/flutter_test.dart';
import 'package:bisaasmobile/features/auth/data/models/user_dto.dart';

void main() {
  group('UserDto', () {
    test('fromJson deserializes snake_case backend JSON to camelCase entity fields', () {
      final json = {
        'id': 42,
        'name': 'Bishwo Engineer',
        'email': 'bishwo@bisaas.test',
        'avatar_url': 'https://bisaas.test/storage/avatars/42.jpg',
        'level': 5,
        'xp': 2450,
        'coins': 120,
        'streak_days': 7,
        'email_verified_at': '2026-08-15T10:00:00Z',
        'created_at': '2026-08-01T08:00:00Z',
      };

      final dto = UserDto.fromJson(json);
      expect(dto.id, equals(42));
      expect(dto.name, equals('Bishwo Engineer'));
      expect(dto.email, equals('bishwo@bisaas.test'));
      expect(dto.level, equals(5));
      expect(dto.xp, equals(2450));
      expect(dto.coins, equals(120));
      expect(dto.streakDays, equals(7));

      final domain = dto.toDomain();
      expect(domain.id, equals(42));
      expect(domain.name, equals('Bishwo Engineer'));
      expect(domain.streakDays, equals(7));
    });
  });
}
