enum AppEnvironment {
  local,
  test,
  staging,
  production;

  static AppEnvironment fromName(String name) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == name,
      orElse: () => AppEnvironment.local,
    );
  }
}

abstract final class AppConfig {
  static const environmentName = String.fromEnvironment(
    'LIFEOS_ENV',
    defaultValue: 'local',
  );

  static final environment = AppEnvironment.fromName(environmentName);
}
