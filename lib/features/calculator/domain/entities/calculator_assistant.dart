import 'package:meta/meta.dart';

/// A value the calculator assistant proposed for one field.
///
/// The assistant is **advisory**: it proposes values and the user accepts
/// them. The client never writes a value into a calculation on the
/// assistant's word — the user sees the proposal and taps "apply".
@immutable
class AssistantFieldMapping {
  const AssistantFieldMapping({
    required this.field,
    this.value,
    this.unit,
    this.confidence = 0,
    this.sourceText,
  });

  /// The calculator field the value belongs to.
  final String field;

  /// The proposed value. It is a JSON scalar (string, number or bool).
  final Object? value;
  final String? unit;

  /// The model's confidence in this mapping, 0..1.
  final double confidence;

  /// The phrase the value was read from, when the server published one.
  final String? sourceText;

  /// The value as a string, for display and for writing into an input field.
  String get displayValue => value?.toString() ?? '';

  bool get hasValue => value != null && value.toString().trim().isNotEmpty;
}

/// The assistant's answer.
@immutable
class CalculatorAssistant {
  const CalculatorAssistant({
    required this.intent,
    required this.explanation,
    this.calculatorType,
    this.calculatorSlug,
    this.fieldMappings = const [],
    this.unitPreferences = const {},
    this.relatedCalculators = const [],
    this.followUpQuestions = const [],
    this.confidence = 0,
    this.provider,
    this.model,
  });

  /// What the assistant understood the request to be.
  final String intent;

  /// The explanation, in prose. The server authored it.
  final String explanation;
  final String? calculatorType;
  final String? calculatorSlug;
  final List<AssistantFieldMapping> fieldMappings;

  /// Preferred unit per field, when the model proposed one.
  final Map<String, String> unitPreferences;
  final List<String> relatedCalculators;
  final List<String> followUpQuestions;
  final double confidence;

  /// Which provider served the request. Useful for support; never a cost.
  final String? provider;
  final String? model;

  bool get hasFieldMappings =>
      fieldMappings.any((m) => m.hasValue);
}
