import 'dart:developer' as developer;

enum AppEnvironment { dev, staging, prod }

class AppEnvironmentConfig {
  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static AppEnvironment get environment {
    switch (_envName.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(_apiBaseUrlOverride);
    }

    switch (environment) {
      case AppEnvironment.dev:
        return 'http://localhost:5485/';
      case AppEnvironment.staging:
        return 'https://staging-api.futsalapp.com/';
      case AppEnvironment.prod:
        return 'https://api.futsalapp.com/';
    }
  }

  static void logSelectedEnvironment() {
    developer.log(
      'Startup API endpoint selected for Flutter client -> env=$_envName, baseUrl=$apiBaseUrl',
      name: 'AppEnvironmentConfig',
    );
  }

  static String _normalizeBaseUrl(String value) =>
      value.endsWith('/') ? value : '$value/';
}

