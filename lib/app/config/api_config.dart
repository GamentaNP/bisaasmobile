/// Canonical API configuration — versioned URL + headers.
/// Single source of truth for every network call.
/// See `C:\laragon\www\bisaas\docs\MOBILE_API_INTEGRATION_GUIDE.md:11`.
library;

import 'env.dart';

abstract final class ApiConfig {
  /// Never construct — static only.

  /// Base URL always ends with `/api/v1`. Do NOT append prefix in call sites.
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return '${currentEnv().host}/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Headers every request must carry.
  static Map<String, String> get defaultHeaders => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// Full OpenAPI docs (for dev tooling, not fetched at runtime).
  static String get openApiUrl => '$baseUrl/openapi.json';
  static String get quizOpenApiUrl => '$baseUrl/quiz/openapi.json';
  static String get changelogUrl => '$baseUrl/openapi/changelog';
}
