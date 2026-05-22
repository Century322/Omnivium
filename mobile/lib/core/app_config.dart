enum AppEnvironment { dev, staging, production }

class AppConfig {
  static AppEnvironment get environment {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.dev;
    }
  }

  static bool get isDev => environment == AppEnvironment.dev;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProd => environment == AppEnvironment.production;

  static String get supabaseUrl {
    return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  static String get supabaseAnonKey {
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  static String get sentryDsn {
    return const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  }

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.production:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.omnivium.app',
        );
      case AppEnvironment.staging:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://staging-api.omnivium.app',
        );
      case AppEnvironment.dev:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8787',
        );
    }
  }

  static bool get enableSentry => !isDev;
  static bool get enableVerboseLogging => isDev;
  static bool get enablePerformanceOverlay => isDev;
  static bool get enableHotReload => isDev;

  static String get appName {
    switch (environment) {
      case AppEnvironment.production:
        return 'Omnivium';
      case AppEnvironment.staging:
        return 'Omnivium Staging';
      case AppEnvironment.dev:
        return 'Omnivium Dev';
    }
  }

  static Map<String, dynamic> toDiagnosticMap() => {
        'environment': environment.name,
        'appName': appName,
        'apiBaseUrl': apiBaseUrl,
        'enableSentry': enableSentry,
        'enableVerboseLogging': enableVerboseLogging,
      };
}
