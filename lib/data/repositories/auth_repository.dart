import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/logger_adapter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/security/rate_limiter.dart';
import '../../core/security/audit_logger.dart';
import '../../domain/entities/auth_token.dart';
import '../datasources/paperless_api_client.dart';

/// Authentication Repository
/// Manages authentication state and token storage with rate limiting
class AuthRepository {
  final PaperlessApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LoggerAdapter _logger = LoggerAdapter();
  final LoginRateLimiter _rateLimiter = LoginRateLimiter();
  final AuditLogger _auditLogger = AuditLogger();

  AuthToken? _currentToken;
  bool _auditLoggerInitialized = false;

  AuthRepository(this._apiClient) {
    _initializeAuditLogger();
  }

  /// Initialize audit logger (async, doesn't block constructor)
  Future<void> _initializeAuditLogger() async {
    try {
      await _auditLogger.initialize();
      _auditLoggerInitialized = true;
      _logger.i('✅ Audit logger initialized in AuthRepository');
    } catch (e) {
      _logger.e('❌ Failed to initialize audit logger: $e');
    }
  }

  /// Login with username and password (with rate limiting)
  Future<AuthToken> login({
    required String username,
    required String password,
    String? baseUrl,
  }) async {
    // SECURITY: Check rate limit
    if (!_rateLimiter.isLoginAllowed(username)) {
      final resetTime = _rateLimiter.getLoginResetTime(username);
      final remaining = _rateLimiter.getRemainingLoginAttempts(username);

      _logger.w('🚫 Login rate limit exceeded for: $username');

      throw Exception(
        'Too many login attempts. '
        'Please try again in ${resetTime?.inMinutes ?? 0} minutes. '
        'Remaining attempts: $remaining',
      );
    }

    try {
      _logger.i('🔐 Attempting login for user: $username');

      // Update base URL if provided
      final url = baseUrl ?? ApiConstants.defaultBaseUrl;
      _apiClient.setBaseUrl(url);

      // Call login API
      final response = await _apiClient.login(
        username: username,
        password: password,
      );

      // Create auth token
      final token = AuthToken.fromJson(response, username, url);

      // Set token in API client
      _apiClient.setAuthToken(token.token);

      // Save to secure storage
      await _saveToken(token);

      _currentToken = token;

      // SECURITY: Clear rate limit on successful login
      _rateLimiter.clearLoginLimit(username);

      // 🔒 FASE 2 SECURITY: Audit log successful login
      if (_auditLoggerInitialized) {
        await _auditLogger.logLogin(
          username: username,
          success: true,
        );
      }

      _logger.i('✅ Login successful for: $username');

      return token;
    } catch (e) {
      // SECURITY: Record failed login attempt
      _rateLimiter.recordLoginAttempt(username);

      final remaining = _rateLimiter.getRemainingLoginAttempts(username);
      _logger.w('❌ Login failed for: $username (Remaining attempts: $remaining)');

      // 🔒 FASE 2 SECURITY: Audit log failed login
      if (_auditLoggerInitialized) {
        await _auditLogger.logAuthFailure(
          username: username,
          reason: e.toString(),
        );
      }

      _logger.e('❌ Login failed: $e');
      rethrow;
    }
  }

  /// Logout and clear stored credentials
  Future<void> logout() async {
    try {
      _logger.i('🔓 Logging out');

      final username = _currentToken?.username ?? 'unknown';

      // 🔒 FASE 2 SECURITY: Audit log logout
      if (_auditLoggerInitialized) {
        await _auditLogger.logLogout(
          username: username,
          reason: 'user_initiated',
        );
      }

      // Clear API client token
      _apiClient.clearAuthToken();

      // Clear secure storage
      await _secureStorage.delete(key: ApiConstants.tokenKey);
      await _secureStorage.delete(key: ApiConstants.usernameKey);
      await _secureStorage.delete(key: ApiConstants.baseUrlKey);

      _currentToken = null;

      _logger.i('✅ Logout successful');
    } catch (e) {
      _logger.e('❌ Logout failed: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      // Check if we have a stored token
      final storedToken = await _secureStorage.read(key: ApiConstants.tokenKey);

      if (storedToken == null) {
        _logger.d('No stored token found');
        return false;
      }

      // Try to restore the token
      final token = await _restoreToken();

      if (token == null) {
        _logger.d('Failed to restore token');
        return false;
      }

      // Check if token is expired
      if (token.isExpired) {
        _logger.w('⚠️ Token is expired');
        await logout();
        return false;
      }

      // Test the connection
      final isConnected = await _apiClient.testConnection();

      if (!isConnected) {
        _logger.w('⚠️ Connection test failed');
        return false;
      }

      _currentToken = token;
      _apiClient.setAuthToken(token.token);

      _logger.i('✅ User is authenticated');
      return true;
    } catch (e) {
      _logger.e('❌ Authentication check failed: $e');
      return false;
    }
  }

  /// Get current auth token
  AuthToken? get currentToken => _currentToken;

  /// Save token to secure storage
  Future<void> _saveToken(AuthToken token) async {
    await _secureStorage.write(
      key: ApiConstants.tokenKey,
      value: token.token,
    );
    await _secureStorage.write(
      key: ApiConstants.usernameKey,
      value: token.username,
    );
    await _secureStorage.write(
      key: ApiConstants.baseUrlKey,
      value: token.baseUrl,
    );

    _logger.d('💾 Token saved to secure storage');
  }

  /// Restore token from secure storage
  Future<AuthToken?> _restoreToken() async {
    try {
      final token = await _secureStorage.read(key: ApiConstants.tokenKey);
      final username = await _secureStorage.read(key: ApiConstants.usernameKey);
      final baseUrl = await _secureStorage.read(key: ApiConstants.baseUrlKey);

      if (token == null || username == null || baseUrl == null) {
        return null;
      }

      return AuthToken(
        token: token,
        username: username,
        baseUrl: baseUrl,
      );
    } catch (e) {
      _logger.e('Failed to restore token: $e');
      return null;
    }
  }

  /// Update base URL
  Future<void> updateBaseUrl(String newUrl) async {
    final oldUrl = await getBaseUrl();
    final username = _currentToken?.username ?? 'unknown';

    _apiClient.setBaseUrl(newUrl);
    await _secureStorage.write(
      key: ApiConstants.baseUrlKey,
      value: newUrl,
    );

    if (_currentToken != null) {
      _currentToken = AuthToken(
        token: _currentToken!.token,
        username: _currentToken!.username,
        baseUrl: newUrl,
        expiresAt: _currentToken!.expiresAt,
      );
    }

    // 🔒 FASE 2 SECURITY: Audit log base URL change
    if (_auditLoggerInitialized) {
      await _auditLogger.logBaseUrlChange(
        userId: username,
        oldUrl: oldUrl,
        newUrl: newUrl,
      );
    }

    _logger.i('🌐 Base URL updated to: $newUrl');
  }

  /// Get stored base URL
  Future<String> getBaseUrl() async {
    final storedUrl = await _secureStorage.read(key: ApiConstants.baseUrlKey);
    return storedUrl ?? ApiConstants.defaultBaseUrl;
  }
}
