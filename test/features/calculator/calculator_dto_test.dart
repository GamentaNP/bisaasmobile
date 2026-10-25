import 'package:bisaasmobile/features/calculator/data/models/calculator_dto.dart';
import 'package:bisaasmobile/features/calculator/domain/entities/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorDto', () {
    test('fromJson snake_case tolerant', () {
      final dto = CalculatorDto.fromJson({
        'slug': 'beam-deflection',
        'domain': 'civil',
        'label': 'Beam Deflection',
      });
      expect(dto.slug, 'beam-deflection');
      expect(dto.domain, 'civil');
      expect(dto.label, 'Beam Deflection');
      expect(dto.toDomain(), isA<Calculator>());
      expect(dto.toDomain().path, '/civil/beam-deflection');
    });

    test('label fallback to slug spaced', () {
      final dto = CalculatorDto.fromJson({
        'slug': 'soil-compaction',
        'domain': 'civil',
      });
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
          {
            'domain': 'electrical',
            'label': 'Elec',
            'calculators': [
              {'slug': 'c', 'domain': 'electrical', 'label': 'C'},
            ],
          },
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

    test('parses the documented §9.1 object shapes for dimensions and modes',
        () {
      final dto = CalculatorConfigDto.fromJson({
        'domain': 'civil',
        'slug': 'beam-deflection',
        'label': 'Beam Deflection',
        'domain_label': 'Civil Engineering',
        'output_dimensions': {
          'max_deflection_mm': {'dimension': 'length', 'canonical_unit': 'mm'},
          'allowable_deflection_mm': {'dimension': 'length', 'canonical_unit': 'mm'},
        },
        'calculation_modes': {
          'point_load': {'inputs': <String>[]},
        },
      });

      final cfg = dto.toDomain();
      expect(cfg.calculateEndpoint, '/civil/beam-deflection/calculate');
      final maxDeflection =
          cfg.outputDimensions['max_deflection_mm'] as Map<String, dynamic>?;
      expect(maxDeflection?['canonical_unit'], 'mm');
      expect(cfg.outputDimensions.containsKey('moment_mpa'), isFalse);
      expect(cfg.calculationModes.containsKey('point_load'), isTrue);
    });

    test('an empty dimensions object is a normal answer, not an error', () {
      // API guide §9.1: "The key is always present; an empty object is a
      // normal answer" — the calculator has no curated dimension map.
      final dto = CalculatorConfigDto.fromJson({
        'domain': 'civil',
        'slug': 'some-calculator',
        'label': 'Some Calculator',
        'domain_label': 'Civil Engineering',
        'output_dimensions': <String, dynamic>{},
      });

      final cfg = dto.toDomain();
      expect(cfg.outputDimensions, isEmpty);
      expect(cfg.calculationModes, isEmpty);
    });

    test('the live beam-deflection payload (object dimensions) parses', () {
      // Regression: this DTO used to cast output_dimensions as a List, and
      // the server (per §9.1) sends a keyed object — the mismatch threw a
      // TypeError on every calculator schema screen on device.
      final dto = CalculatorConfigDto.fromJson({
        'domain': 'civil',
        'slug': 'beam-deflection',
        'schema_source': 'registry',
        'label': 'Beam Deflection',
        'description': null,
        'standards': <String>[],
        'fields': [
          {
            'name': 'uniform_load_kn_per_m',
            'label': 'Uniform Load Kn per M',
            'type': 'quantity',
            'required': true,
            'unit': 'kn_per_m',
            'min': 0.001,
            'max': 1000,
            'options': null,
            'step': 0.001,
            'dimension': 'force_per_length',
            'canonical_unit': 'kn_per_m',
            'default_unit': 'kn_per_m',
            'allowed_units': ['kn_per_m'],
          },
        ],
        'sections': <String>[],
        'repeatable_schemas': <String>[],
        'result_metrics': <String>[],
        'compliance_checks': <String>[],
        'output_dimensions': {
          'max_deflection_mm': {'dimension': 'length', 'canonical_unit': 'mm'},
          'allowable_deflection_mm': {'dimension': 'length', 'canonical_unit': 'mm'},
          'moment_mpa': {'dimension': 'pressure', 'canonical_unit': 'mpa'},
          'bending_stress_mpa': {'dimension': 'pressure', 'canonical_unit': 'mpa'},
        },
        'default_payload': {'span_meters': 6.0},
        'formula_latex': null,
        'steps_in_response': false,
        'diagram': null,
      });

      final cfg = dto.toDomain();
      expect(cfg.fields, hasLength(1));
      expect(cfg.fields.first.name, 'uniform_load_kn_per_m');
      expect(cfg.outputDimensions, hasLength(4));
      final bendingStress =
          cfg.outputDimensions['bending_stress_mpa'] as Map<String, dynamic>?;
      expect(bendingStress?['dimension'], 'pressure');
      expect(cfg.defaults['span_meters'], 6.0);
    });
  });

  group('CalculationResult', () {
    test('holds inputs and data', () {
      const r = CalculationResult(
        inputs: {'length': 5},
        data: {'result': 25},
        message: 'ok',
      );
      expect(r.inputs['length'], 5);
      expect(r.data['result'], 25);
    });
  });
}
