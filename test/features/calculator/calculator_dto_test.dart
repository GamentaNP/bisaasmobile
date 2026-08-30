import 'package:bisaasmobile/features/calculator/data/models/calculator_dto.dart';
import 'package:bisaasmobile/features/calculator/domain/entities/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorDto', () {
    test('fromJson snake_case tolerant', () {
      final dto = CalculatorDto.fromJson({'slug': 'beam-deflection', 'domain': 'civil', 'label': 'Beam Deflection'});
      expect(dto.slug, 'beam-deflection');
      expect(dto.domain, 'civil');
      expect(dto.label, 'Beam Deflection');
      expect(dto.toDomain(), isA<Calculator>());
      expect(dto.toDomain().path, '/civil/beam-deflection');
    });

    test('label fallback to slug spaced', () {
      final dto = CalculatorDto.fromJson({'slug': 'soil-compaction', 'domain': 'civil'});
      expect(dto.label, 'soil compaction');
    });
  });

  group('CalculatorCatalogDto', () {
    test('fromJson aggregates domains and total', () {
      final dto = CalculatorCatalogDto.fromJson({
        'total_calculators': 3,
        'domains': [
          {
            'domain': 'civil',
            'label': 'Civil',
            'calculators': [
              {'slug': 'a', 'domain': 'civil', 'label': 'A'},
              {'slug': 'b', 'domain': 'civil', 'label': 'B'},
            ],
          },
          {'domain': 'electrical', 'label': 'Elec', 'calculators': [{'slug': 'c', 'domain': 'electrical', 'label': 'C'}]},
        ],
      });
      expect(dto.totalCalculators, 3);
      expect(dto.domains.length, 2);
      expect(dto.toDomainsFlat().length, 3);
    });

    test('empty catalog fallback', () {
      final dto = CalculatorCatalogDto.fromJson({});
      expect(dto.totalCalculators, 0);
      expect(dto.domains, isEmpty);
    });
  });

  group('CalculatorConfigDto', () {
    test('fromJson with endpoints', () {
      final dto = CalculatorConfigDto.fromJson({
        'domain': 'civil',
        'slug': 'beam-deflection',
        'label': 'Beam Deflection',
        'domain_label': 'Civil Engineering',
        'endpoints': {'calculate': '/api/v1/civil/beam-deflection/calculate'},
      });
      expect(dto.domain, 'civil');
      final cfg = dto.toDomain();
      expect(cfg.calculateEndpoint, contains('calculate'));
      expect(cfg.domainLabel, 'Civil Engineering');
    });
  });

  group('CalculationResult', () {
    test('holds inputs and data', () {
      const r = CalculationResult(inputs: {'length': 5}, data: {'result': 25}, message: 'ok');
      expect(r.inputs['length'], 5);
      expect(r.data['result'], 25);
    });
  });
}
