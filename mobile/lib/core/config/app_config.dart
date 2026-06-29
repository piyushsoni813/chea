/// All runtime configuration in one place. Switch environments by changing
/// [activeEnv] at build time or via --dart-define=ENV=production.
class AppConfig {
  AppConfig._();

  static const _env = String.fromEnvironment('ENV', defaultValue: 'development');

  static const development = _Config(
    baseUrl: 'http://10.0.2.2:8000/api/v1', // Android emulator localhost
    apiVersion: 'v1',
  );

  static const production = _Config(
    baseUrl: 'https://api.chea.edu/api/v1',
    apiVersion: 'v1',
  );

  static _Config get active =>
      _env == 'production' ? production : development;

  static String get baseUrl    => active.baseUrl;
  static String get apiVersion => active.apiVersion;
}

class _Config {
  final String baseUrl;
  final String apiVersion;
  const _Config({required this.baseUrl, required this.apiVersion});
}
