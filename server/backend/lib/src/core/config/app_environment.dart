enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' || 'dev' => AppEnvironment.development,
      'staging' => AppEnvironment.staging,
      'production' || 'prod' => AppEnvironment.production,
      _ => throw FormatException(
        'APP_ENV tidak valid: $value. '
        'Gunakan development, staging, atau production.',
      ),
    };
  }
}
