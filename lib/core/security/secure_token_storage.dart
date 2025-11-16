import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'encryption_service.dart';

/// Secure storage for authentication tokens and sensitive data
/// Uses encryption and secure storage mechanisms
class SecureTokenStorage {
  static final SecureTokenStorage _instance = SecureTokenStorage._internal();
  factory SecureTokenStorage() => _instance;
  SecureTokenStorage._internal();

  final _logger = Logger('SecureTokenStorage');
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  final _encryptionService = EncryptionService();

  // Storage keys
  static const String _accessTokenKey = 'secure_access_token';
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _userIdKey = 'secure_user_id';
  static const String _usernameKey = 'secure_username';
  static const String _apiUrlKey = 'secure_api_url';
  static const String _sessionIdKey = 'secure_session_id';
  static const String _deviceIdKey = 'secure_device_id';

  /// Initialize secure storage
  Future<void> initialize() async {
    try {
      _logger.info('Initializing secure token storage...');
      await _encryptionService.initialize();
      _logger.info('Secure token storage initialized');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize secure storage', e, stackTrace);
      rethrow;
    }
  }

  /// Store access token securely
  Future<void> storeAccessToken(String token) async {
    try {
      final encrypted = await _encryptionService.encryptToken(token);
      await _storage.write(key: _accessTokenKey, value: encrypted);
      _logger.info('Access token stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store access token', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    try {
      final encrypted = await _storage.read(key: _accessTokenKey);
      if (encrypted == null) return null;

      return await _encryptionService.decryptToken(encrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve access token', e, stackTrace);
      return null;
    }
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    try {
      final encrypted = await _encryptionService.encryptToken(token);
      await _storage.write(key: _refreshTokenKey, value: encrypted);
      _logger.info('Refresh token stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store refresh token', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      final encrypted = await _storage.read(key: _refreshTokenKey);
      if (encrypted == null) return null;

      return await _encryptionService.decryptToken(encrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve refresh token', e, stackTrace);
      return null;
    }
  }

  /// Store user ID
  Future<void> storeUserId(int userId) async {
    try {
      final encrypted = await _encryptionService.encrypt(userId.toString());
      await _storage.write(key: _userIdKey, value: encrypted);
      _logger.info('User ID stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store user ID', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve user ID
  Future<int?> getUserId() async {
    try {
      final encrypted = await _storage.read(key: _userIdKey);
      if (encrypted == null) return null;

      final decrypted = await _encryptionService.decrypt(encrypted);
      return int.tryParse(decrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve user ID', e, stackTrace);
      return null;
    }
  }

  /// Store username
  Future<void> storeUsername(String username) async {
    try {
      final encrypted = await _encryptionService.encrypt(username);
      await _storage.write(key: _usernameKey, value: encrypted);
      _logger.info('Username stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store username', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve username
  Future<String?> getUsername() async {
    try {
      final encrypted = await _storage.read(key: _usernameKey);
      if (encrypted == null) return null;

      return await _encryptionService.decrypt(encrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve username', e, stackTrace);
      return null;
    }
  }

  /// Store API URL
  Future<void> storeApiUrl(String url) async {
    try {
      final encrypted = await _encryptionService.encrypt(url);
      await _storage.write(key: _apiUrlKey, value: encrypted);
      _logger.info('API URL stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store API URL', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve API URL
  Future<String?> getApiUrl() async {
    try {
      final encrypted = await _storage.read(key: _apiUrlKey);
      if (encrypted == null) return null;

      return await _encryptionService.decrypt(encrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve API URL', e, stackTrace);
      return null;
    }
  }

  /// Store session ID
  Future<void> storeSessionId(String sessionId) async {
    try {
      final encrypted = await _encryptionService.encrypt(sessionId);
      await _storage.write(key: _sessionIdKey, value: encrypted);
      _logger.info('Session ID stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store session ID', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve session ID
  Future<String?> getSessionId() async {
    try {
      final encrypted = await _storage.read(key: _sessionIdKey);
      if (encrypted == null) return null;

      return await _encryptionService.decrypt(encrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve session ID', e, stackTrace);
      return null;
    }
  }

  /// Store device ID
  Future<void> storeDeviceId(String deviceId) async {
    try {
      final encrypted = await _encryptionService.encrypt(deviceId);
      await _storage.write(key: _deviceIdKey, value: encrypted);
      _logger.info('Device ID stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store device ID', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve device ID
  Future<String?> getDeviceId() async {
    try {
      final encrypted = await _storage.read(key: _deviceIdKey);
      if (encrypted == null) return null;

      return await _encryptionService.decrypt(encrypted);
    } catch (e, stackTrace) {
      _logger.severe('Failed to retrieve device ID', e, stackTrace);
      return null;
    }
  }

  /// Store credentials (username + password hash)
  Future<void> storeCredentials(String username, String passwordHash) async {
    try {
      await storeUsername(username);

      final encrypted = await _encryptionService.encrypt(passwordHash);
      await _storage.write(key: 'secure_password_hash', value: encrypted);

      _logger.info('Credentials stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store credentials', e, stackTrace);
      rethrow;
    }
  }

  /// Clear all stored tokens and credentials
  Future<void> clearAll() async {
    try {
      _logger.info('Clearing all secure storage...');

      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _usernameKey),
        _storage.delete(key: _apiUrlKey),
        _storage.delete(key: _sessionIdKey),
        _storage.delete(key: _deviceIdKey),
        _storage.delete(key: 'secure_password_hash'),
      ]);

      _logger.info('All secure storage cleared');
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear secure storage', e, stackTrace);
      rethrow;
    }
  }

  /// Check if user is logged in (has valid tokens)
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      _logger.warning('Failed to check login status', e);
      return false;
    }
  }

  /// Get all stored credentials as a map
  Future<Map<String, String?>> getAllCredentials() async {
    try {
      final results = await Future.wait([
        getAccessToken(),
        getRefreshToken(),
        getUserId().then((id) => id?.toString()),
        getUsername(),
        getApiUrl(),
        getSessionId(),
        getDeviceId(),
      ]);

      return {
        'accessToken': results[0],
        'refreshToken': results[1],
        'userId': results[2],
        'username': results[3],
        'apiUrl': results[4],
        'sessionId': results[5],
        'deviceId': results[6],
      };
    } catch (e, stackTrace) {
      _logger.severe('Failed to get all credentials', e, stackTrace);
      rethrow;
    }
  }

  /// Verify storage integrity
  Future<bool> verifyIntegrity() async {
    try {
      // Verify encryption is working
      final encryptionWorks = await _encryptionService.verifyEncryption();
      if (!encryptionWorks) {
        _logger.severe('Encryption verification failed');
        return false;
      }

      // Verify secure storage is accessible
      await _storage.write(key: 'test_key', value: 'test_value');
      final testValue = await _storage.read(key: 'test_key');
      await _storage.delete(key: 'test_key');

      if (testValue != 'test_value') {
        _logger.severe('Secure storage verification failed');
        return false;
      }

      _logger.info('Storage integrity verified successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Storage integrity verification failed', e, stackTrace);
      return false;
    }
  }
}
