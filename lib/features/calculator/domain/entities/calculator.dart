import 'package:meta/meta.dart';

@immutable
class Calculator {
  const Calculator({
    required this.slug,
    required this.domain,
    required this.label,
  });

  final String slug;
  final String domain;
  final String label;

  String get path => '/$domain/$slug';
}

/// One option for a `select`-type field.
@immutable
class CalculatorSelectOption {
  const CalculatorSelectOption({required this.value, required this.label});
  final String value;
  final String label;

  factory CalculatorSelectOption.fromJson(Map<String, dynamic> j) =>
      CalculatorSelectOption(
        value: (j['value'] as String?) ?? '',
        label: (j['label'] as String?) ?? ((j['value'] as String?) ?? ''),
      );
}

/// Field definition returned by `GET /api/v1/calculators/{domain}/{slug}`.
/// The Flutter form is rendered from this schema — never a generic
/// key/value editor.
@immutable
class CalculatorField {
  const CalculatorField({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    this.unit,
    this.min,
    this.max,
    this.precision,
    this.options = const [],
    this.helpText,
  });

  /// API field name (e.g. "span_length").
  final String name;

  /// Display label (e.g. "Span Length").
  final String label;

  /// One of: `number`, `select`, `boolean`, `text`.
  final String type;

  final bool required;
  final String? unit;
  final double? min;
  final double? max;

  /// Decimal places used to round display + when serialising payload.
  final int? precision;

  /// For `type == 'select'`.
  final List<CalculatorSelectOption> options;

  /// Optional hint rendered under the input.
  final String? helpText;

  factory CalculatorField.fromJson(Map<String, dynamic> j) => CalculatorField(
        name: (j['name'] as String?) ?? '',
        label: (j['label'] as String?) ?? ((j['name'] as String?) ?? ''),
        type: (j['type'] as String?) ?? 'number',
        required: (j['required'] as bool?) ?? false,
        unit: j['unit'] as String?,
        min: (j['min'] as num?)?.toDouble(),
        max: (j['max'] as num?)?.toDouble(),
        precision: j['precision'] as int?,
        options: ((j['options'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CalculatorSelectOption.fromJson)
            .toList(),
        helpText: j['help_text'] as String?,
      );
}

@immutable
class CalculatorConfig {
  const CalculatorConfig({
    required this.domain,
    required this.slug,
    required this.label,
    required this.domainLabel,
    required this.calculateEndpoint,
    this.formulaLatex,
    this.fields = const [],
    this.stepsInResponse = false,
    this.defaults = const {},
  });

  final String domain;
  final String slug;
  final String label;
  final String domainLabel;
  final String calculateEndpoint;

  /// LaTeX source rendered with `flutter_math_fork`. Null = no formula shown.
  final String? formulaLatex;

  /// Server-driven input schema. Empty list = fall back to legacy
  /// generic key/value editor.
  final List<CalculatorField> fields;

  /// When true, the response `data.steps[]` array is rendered as a
  /// step-by-step solution card list.
  final bool stepsInResponse;

  /// Server-supplied default values keyed by `field.name`.
  final Map<String, dynamic> defaults;
}

@immutable
class CalculationResult {
  const CalculationResult({
    required this.inputs,
    required this.data,
    this.message,
  });

  final Map<String, dynamic> inputs;
  final Map<String, dynamic> data;
  final String? message;

  /// `data.status` ∈ {`safe`, `check`, `fail`} when server returns it.
  String? get status => data['status'] as String?;
  num? get limitValue => (data['limit_value'] as num?) ?? (data['limit'] as num?);
  num? get actualValue => (data['actual_value'] as num?) ?? (data['value'] as num?);

  /// `data.steps` → list of {label, formula, result}.
  List<Map<String, dynamic>> get steps {
    final raw = data['steps'];
    if (raw is! List) return const [];
    return raw.cast<Map<String, dynamic>>();
  }
}
