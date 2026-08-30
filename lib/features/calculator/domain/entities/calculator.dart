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

@immutable
class CalculatorConfig {
  const CalculatorConfig({
    required this.domain,
    required this.slug,
    required this.label,
    required this.domainLabel,
    required this.calculateEndpoint,
  });

  final String domain;
  final String slug;
  final String label;
  final String domainLabel;
  final String calculateEndpoint;
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
}
