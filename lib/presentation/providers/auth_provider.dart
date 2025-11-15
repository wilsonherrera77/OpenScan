import 'package:flutter/foundation.dart';
import '../../services/logger_adapter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/auth_token.dart';

/// Authentication Provider
/// Manages authentication state using Provider pattern
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final LoggerAdapter _logger = LoggerAdapter();

  AuthToken? _currentToken;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider(this._authRepository) {
    _checkAuthStatus();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthToken? get currentToken => _currentToken;
  String? get username => _currentToken?.username;
  String? get baseUrl => _currentToken?.baseUrl;

  /// Check authentication status on initialization
  Future<void> _checkAuthStatus() async {
    _setLoading(true);

    try {
      _isAuthenticated = await _authRepository.isAuthenticated();
      _currentToken = _authRepository.currentToken;

      _logger.i('Auth status checked: $_isAuthenticated');
    } catch (e) {
      _logger.e('Auth status check failed: $e');
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login
  Future<bool> login({
    required String username,
    required String password,
    String? baseUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _logger.i('🔐 Logging in as: $username');

      final token = await _authRepository.login(
        username: username,
        password: password,
        baseUrl: baseUrl,
      );

      _currentToken = token;
      _isAuthenticated = true;

      _logger.i('✅ Login successful');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Login failed: $e');
      _setError(_getErrorMessage(e));
      _isAuthenticated = false;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      _logger.i('🔓 Logging out');

      await _authRepository.logout();

      _currentToken = null;
      _isAuthenticated = false;

      _logger.i('✅ Logout successful');

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Logout failed: $e');
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Update base URL
  Future<void> updateBaseUrl(String newUrl) async {
    try {
      await _authRepository.updateBaseUrl(newUrl);
      _currentToken = _authRepository.currentToken;
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to update base URL: $e');
      _setError(_getErrorMessage(e));
    }
  }

  /// Get base URL
  Future<String> getBaseUrl() async {
    return await _authRepository.getBaseUrl();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Extract error message from exception
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No se puede conectar con el servidor. Verifica la URL y tu conexión a internet.';
    } else if (error.toString().contains('401')) {
      return 'Usuario o contraseña incorrectos.';
    } else if (error.toString().contains('403')) {
      return 'Acceso denegado. Verifica tus credenciales.';
    } else if (error.toString().contains('404')) {
      return 'Servidor no encontrado. Verifica la URL.';
    } else if (error.toString().contains('500')) {
      return 'Error en el servidor. Intenta más tarde.';
    } else {
      return 'Error: ${error.toString()}';
    }
  }
}
