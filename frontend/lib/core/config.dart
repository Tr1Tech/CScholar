// App-wide configuration — all values loaded from environment / .env
// Never hardcode secrets here; use [REDACTED] as placeholder in shared code

class AppConfig {
  AppConfig._();

  static const String appName = 'CScholar';
  static const String appTitle = 'CScholar — CEIT Thesis Repository';
  static const String appVersion = '0.1.0';

  // API base URL — in production this comes from environment
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  // Embedding settings (backend)
  static const String embeddingModel = 'all-MiniLM-L6-v2';
  static const int embeddingDim = 384;
}
