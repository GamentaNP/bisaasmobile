import '../../domain/entities/calculator_assistant.dart';

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// One value the assistant proposed for a calculator field.
///
/// The server publishes the *source text* it read the value from, so the UI
/// can show the user why it believes what it believes.
class AssistantFieldMappingDto {
  const AssistantFieldMappingDto({
    required this.field,
    this.value,
    this.unit,
    this.confidence = 0,
    this.sourceText,
  });

  factory AssistantFieldMappingDto.fromJson(Map<String, dynamic> j) {
    return AssistantFieldMappingDto(
      field: (j['field'] ?? '').toString(),
      value: j['value'],
      unit: j['unit'] as String?,
      confidence: _asDouble(j['confidence']) ?? 0,
      sourceText: j['source_text'] as String?,
    );
  }

  final String field;
  final Object? value;
  final String? unit;
  final double confidence;
  final String? sourceText;

  AssistantFieldMapping toDomain() => AssistantFieldMapping(
        field: field,
        value: value,
        unit: unit,
        confidence: confidence,
        sourceText: sourceText,
      );
}

/// The assistant's answer.
class CalculatorAssistantDto {
  const CalculatorAssistantDto({
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

  factory CalculatorAssistantDto.fromJson(
    Map<String, dynamic> j, {
    Map<String, dynamic> metadata = const {},
  }) {
    final mappings = <AssistantFieldMappingDto>[];
    final rawMappings = j['field_mappings'];
    if (rawMappings is List) {
      for (final m in rawMappings) {
        if (m is Map<String, dynamic>) {
          mappings.add(AssistantFieldMappingDto.fromJson(m));
        }
      }
    }

    final preferences = <String, String>{};
    final rawPreferences = j['unit_preferences'];
    if (rawPreferences is Map) {
      rawPreferences.forEach((key, value) {
        preferences[key.toString()] = value.toString();
      });
    }

    final related = <String>[];
    final rawRelated = j['related_calculators'];
    if (rawRelated is List) {
      for (final r in rawRelated) {
        if (r is Map) {
          final slug = r['slug'] ?? r['calculator_slug'];
          if (slug != null) related.add(slug.toString());
        }
      }
    }

    final followUps = <String>[];
    final rawFollowUps = j['follow_up_questions'];
    if (rawFollowUps is List) {
      for (final q in rawFollowUps) {
        if (q != null) followUps.add(q.toString());
      }
    }

    return CalculatorAssistantDto(
      intent: (j['intent'] ?? '').toString(),
      explanation: (j['explanation'] ?? '').toString(),
      calculatorType: j['calculator_type'] as String?,
      calculatorSlug: j['calculator_slug'] as String?,
      fieldMappings: mappings,
      unitPreferences: preferences,
      relatedCalculators: related,
      followUpQuestions: followUps,
      confidence: _asDouble(j['confidence']) ?? 0,
      provider: metadata['provider'] as String?,
      model: metadata['model'] as String?,
    );
  }

  final String intent;
  final String explanation;
  final String? calculatorType;
  final String? calculatorSlug;
  final List<AssistantFieldMappingDto> fieldMappings;
  final Map<String, String> unitPreferences;
  final List<String> relatedCalculators;
  final List<String> followUpQuestions;
  final double confidence;
  final String? provider;
  final String? model;

  CalculatorAssistant toDomain() => CalculatorAssistant(
        intent: intent,
        explanation: explanation,
        calculatorType: calculatorType,
        calculatorSlug: calculatorSlug,
        fieldMappings: fieldMappings.map((m) => m.toDomain()).toList(),
        unitPreferences: unitPreferences,
        relatedCalculators: relatedCalculators,
        followUpQuestions: followUpQuestions,
        confidence: confidence,
        provider: provider,
        model: model,
      );
}

