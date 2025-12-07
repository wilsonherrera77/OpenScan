import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/logger_adapter.dart';

/// Secure Configuration Manager
/// Manages sensitive configuration securely using encrypted storage
class SecureConfigManager {
  static final SecureConfigManager _instance = SecureConfigManager._internal();
  factory SecureConfigManager() => _instance;
  SecureConfigManager._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final LoggerAdapter _logger = LoggerAdapter();

  // Storage keys
  static const String _keyApiToken = 'tejido_api_token';
  static const String _keyBaseUrl = 'tejido_base_url';
  static const String _keyUsername = 'username';
  static const String _keyLastTokenRotation = 'last_token_rotation';

  // Security: Token rotation interval (7 days)
  static const Duration tokenRotationInterval = Duration(days: 7);

  /// Initialize with default configuration (first run)
  Future<void> initialize({
    String? defaultBaseUrl,
    String? defaultToken,
  }) async {
    try {
      // Check if already initialized
      final existingUrl = await getBaseUrl();
      if (existingUrl != null) {
        _logger.d('🔐 Config already initialized');
        return;
      }

      // Set defaults if provided
      if (defaultBaseUrl != null) {
        await setBaseUrl(defaultBaseUrl);
        _logger.i('🔐 Initialized base URL');
      }

      if (defaultToken != null) {
        await setApiToken(defaultToken);
        _logger.i('🔐 Initialized API token');
      }
    } catch (e) {
      _logger.e('❌ Failed to initialize secure config: $e');
      rethrow;
    }
  }

  /// Get Tejido base URL
  Future<String?> getBaseUrl() async {
    try {
      return await _storage.read(key: _keyBaseUrl);
    } catch (e) {
      _logger.e('❌ Failed to read base URL: $e');
      return null;
    }
  }

  /// Set Tejido base URL
  Future<void> setBaseUrl(String url) async {
    try {
      // Validate URL format
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw ArgumentError('Invalid URL format: $url');
      }

      await _storage.write(key: _keyBaseUrl, value: url);
      _logger.i('🔐 Base URL updated');
    } catch (e) {
      _logger.e('❌ Failed to write base URL: $e');
      rethrow;
    }
  }

  /// Get API token
  Future<String?> getApiToken() async {
    try {
      return await _storage.read(key: _keyApiToken);
    } catch (e) {
      _logger.e('❌ Failed to read API token: $e');
      return null;
    }
  }

  /// Set API token and record rotation timestamp
  Future<void> setApiToken(String token) async {
    try {
      await _storage.write(key: _keyApiToken, value: token);
      await _storage.write(
        key: _keyLastTokenRotation,
        value: DateTime.now().toIso8601String(),
      );
      _logger.i('🔐 API token updated and rotation recorded');
    } catch (e) {
      _logger.e('❌ Failed to write API token: $e');
      rethrow;
    }
  }

  /// Get username
  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _keyUsername);
    } catch (e) {
      _logger.e('❌ Failed to read username: $e');
      return null;
    }
  }

  /// Set username
  Future<void> setUsername(String username) async {
    try {
      await _storage.write(key: _keyUsername, value: username);
      _logger.d('🔐 Username stored');
    } catch (e) {
      _logger.e('❌ Failed to write username: $e');
      rethrow;
    }
  }

  /// Check if token needs rotation
  Future<bool> needsTokenRotation() async {
    try {
      final lastRotationStr = await _storage.read(key: _keyLastTokenRotation);

      if (lastRotationStr == null) {
        return true; // Never rotated
      }

      final lastRotation = DateTime.parse(lastRotationStr);
      final now = DateTime.now();
      final elapsed = now.difference(lastRotation);

      return elapsed > tokenRotationInterval;
    } catch (e) {
      _logger.w('⚠️ Failed to check token rotation: $e');
      return false;
    }
  }

  /// Get days since last token rotation
  Future<int> getDaysSinceRotation() async {
    try {
      final lastRotationStr = await _storage.read(key: _keyLastTokenRotation);

      if (lastRotationStr == null) {
        return -1; // Never rotated
      }

      final lastRotation = DateTime.parse(lastRotationStr);
      final now = DateTime.now();
      return now.difference(lastRotation).inDays;
    } catch (e) {
      _logger.w('⚠️ Failed to calculate days since rotation: $e');
      return -1;
    }
  }

  /// Clear all stored credentials (logout)
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _keyApiToken);
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyLastTokenRotation);
      _logger.i('🔐 Credentials cleared');
    } catch (e) {
      _logger.e('❌ Failed to clear credentials: $e');
      rethrow;
    }
  }

  /// Clear all configuration (reset)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _logger.w('🔐 All secure storage cleared');
    } catch (e) {
      _logger.e('❌ Failed to clear storage: $e');
      rethrow;
    }
  }

  /// Validate current configuration
  Future<bool> isConfigured() async {
    final url = await getBaseUrl();
    final token = await getApiToken();
    return url != null && token != null;
  }

  /// Get configuration status for debugging (sanitized)
  Future<Map<String, dynamic>> getConfigStatus() async {
    final url = await getBaseUrl();
    final hasToken = await getApiToken() != null;
    final username = await getUsername();
    final daysSinceRotation = await getDaysSinceRotation();

    return {
      'configured': url != null && hasToken,
      'base_url': url ?? 'not_set',
      'has_token': hasToken,
      'username': username ?? 'not_set',
      'days_since_rotation': daysSinceRotation,
      'needs_rotation': await needsTokenRotation(),
    };
  }
}
