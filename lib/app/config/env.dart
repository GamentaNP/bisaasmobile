/// Environment flavor config.
/// Mirror backend contract versioning — never switch API prefix here.
/// All hosts point at the Laravel server at `C:\laragon\www\bisaas`.
library;

enum AppEnv { dev, staging, prod }

/// Compile-time flavor: `flutter run --dart-define=ENV=dev|staging|prod`
/// Defaults to dev when not supplied (local Laragon).
AppEnv currentEnv() {
  const raw = String.fromEnvironment('ENV', defaultValue: 'dev');
  return switch (raw) {
    'prod' => AppEnv.prod,
    'staging' => AppEnv.staging,
    _ => AppEnv.dev,
  };
}

extension AppEnvX on AppEnv {
  /// Host without trailing slash, without /api prefix.
  /// Android emulator cannot hit `bisaas.test` directly — it must use 10.0.2.2.
  String get host {
    const override = String.fromEnvironment('API_HOST');
    if (override.isNotEmpty) return override;

    return switch (this) {
      AppEnv.prod => 'https://bisaas.com',
      // staging host — replace when DNS is live
      AppEnv.staging => 'https://staging.bisaas.com',
      // Local Laragon (Laragon auto-generates self-signed cert). Chrome/Windows can resolve bisaas.test;
      // Android emulator needs 10.0.2.2 (or 10.0.2.2:443) — set via --dart-define=API_HOST=https://10.0.2.2
      // For raw http fallback (no cert), use --dart-define=API_HOST=http://bisaas.test
      AppEnv.dev => 'https://bisaas.test',
    };
  }

  bool get isDev => this == AppEnv.dev;
  bool get isProd => this == AppEnv.prod;
}
