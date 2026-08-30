import '../../domain/entities/calculator.dart';

class CalculatorDto {
  const CalculatorDto({
    required this.slug,
    required this.domain,
    required this.label,
  });

  factory CalculatorDto.fromJson(Map<String, dynamic> j) => CalculatorDto(
        slug: (j['slug'] as String?) ?? '',
        domain: (j['domain'] as String?) ?? '',
        label: (j['label'] as String?) ??
            ((j['slug'] as String?)?.replaceAll('-', ' ') ?? ''),
      );

  final String slug;
  final String domain;
  final String label;

  Calculator toDomain() => Calculator(slug: slug, domain: domain, label: label);
}

class CalculatorDomainDto {
  const CalculatorDomainDto({
    required this.domain,
    required this.label,
    required this.calculators,
  });

  factory CalculatorDomainDto.fromJson(Map<String, dynamic> j) {
    final list = (j['calculators'] as List?) ?? [];
    return CalculatorDomainDto(
      domain: (j['domain'] as String?) ?? '',
      label: (j['label'] as String?) ?? (j['domain'] as String? ?? ''),
      calculators: list
          .cast<Map<String, dynamic>>()
          .map(CalculatorDto.fromJson)
          .toList(),
    );
  }

  final String domain;
  final String label;
  final List<CalculatorDto> calculators;
}

class CalculatorCatalogDto {
  const CalculatorCatalogDto({
    required this.totalCalculators,
    required this.domains,
  });

  factory CalculatorCatalogDto.fromJson(Map<String, dynamic> j) => CalculatorCatalogDto(
        totalCalculators: (j['total_calculators'] as int?) ?? 0,
        domains: ((j['domains'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(CalculatorDomainDto.fromJson)
            .toList(),
      );

  final int totalCalculators;
  final List<CalculatorDomainDto> domains;

  List<Calculator> toDomainsFlat() => domains
      .expand((d) => d.calculators.map((c) => c.toDomain()))
      .toList();
}

class CalculatorConfigDto {
  const CalculatorConfigDto({
    required this.domain,
    required this.slug,
    required this.label,
    required this.domainLabel,
    required this.endpoints,
  });

  factory CalculatorConfigDto.fromJson(Map<String, dynamic> j) => CalculatorConfigDto(
        domain: (j['domain'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        label: (j['label'] as String?) ?? '',
        domainLabel: (j['domain_label'] as String?) ?? '',
        endpoints: (j['endpoints'] as Map<String, dynamic>?) ?? {},
      );

  final String domain;
  final String slug;
  final String label;
  final String domainLabel;
  final Map<String, dynamic> endpoints;

  CalculatorConfig toDomain() => CalculatorConfig(
        domain: domain,
        slug: slug,
        label: label,
        domainLabel: domainLabel,
        calculateEndpoint: endpoints['calculate'] as String? ?? '/api/v1/$domain/$slug/calculate',
      );
}
