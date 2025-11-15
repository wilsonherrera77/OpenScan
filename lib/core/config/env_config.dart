/// Environment Configuration
/// Manages environment-specific settings (non-sensitive only)
///
/// SECURITY NOTE: Sensitive data (tokens, passwords) must NEVER be stored here.
/// Use SecureConfigManager for all sensitive configuration.
class EnvConfig {
  // Paperless Configuration (NON-SENSITIVE)
  // Default URLs for development/testing only
  static const String defaultPaperlessBaseUrl = String.fromEnvironment(
    'PAPERLESS_BASE_URL',
    defaultValue: 'http://10.0.2.2:8001', // Android emulator localhost
  );

  // SECURITY: API tokens MUST NOT be hardcoded
  // Tokens are managed by SecureConfigManager using encrypted storage
  @Deprecated('Use SecureConfigManager.getApiToken() instead')
  static const String paperlessApiToken = '';

  // App Configuration
  static const String appName = 'OpenScan Indígenas';
  static const String appVersion = '3.0.0';

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableBackgroundSync = true;
  static const bool enableAnalytics = false;

  // Performance Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Security
  static const bool enableCertificatePinning = false; // TODO: Enable in production
  static const bool enableLogging = true;

  // Storage
  static const int maxImageSize = 1920;
  static const int imageQuality = 85;
  static const String databaseName = 'openscan_indigenas.db';

  /// Check if running in production
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  /// Check if running in debug mode
  static bool get isDebug => !isProduction;

  /// Get complete API URL
  static String getApiUrl(String endpoint) {
    return '$defaultPaperlessBaseUrl$endpoint';
  }
}
