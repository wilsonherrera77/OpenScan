import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumara_indigenas/presentation/providers/auth_provider.dart';
import 'package:lumara_indigenas/domain/entities/auth_token.dart';
import '../../../mocks/mock_repositories.mocks.dart';
import '../../../helpers/fixtures.dart';

void main() {
  late AuthProvider provider;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();

    // Mock initial auth check
    when(mockRepository.isAuthenticated()).thenAnswer((_) async => false);
    when(mockRepository.currentToken).thenReturn(null);

    provider = AuthProvider(mockRepository);
  });

  group('AuthProvider - Initial State', () {
    test('should have correct initial values', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
      expect(provider.error, null);
      expect(provider.currentToken, null);
      expect(provider.username, null);
      expect(provider.baseUrl, null);
    });

    test('should check auth status on initialization', () async {
      // Wait for async initialization
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockRepository.isAuthenticated()).called(1);
    });

    test('should restore authenticated state if token exists', () async {
      // Arrange
      final mockToken = Fixtures.createMockAuthToken();

      when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);
      when(mockRepository.currentToken).thenReturn(mockToken);

      // Act
      final newProvider = AuthProvider(mockRepository);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(newProvider.isAuthenticated, true);
      expect(newProvider.currentToken, mockToken);
    });
  });

  group('AuthProvider - login', () {
    test('should successfully login with valid credentials', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';
      final mockToken = Fixtures.createMockAuthToken(username: username);

      when(mockRepository.login(
        username: username,
        password: password,
      )).thenAnswer((_) async => mockToken);

      // Act
      final result = await provider.login(
        username: username,
        password: password,
      );

      // Assert
      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(provider.currentToken, mockToken);
      expect(provider.username, username);
      expect(provider.error, null);

      verify(mockRepository.login(
        username: username,
        password: password,
      )).called(1);
    });

    test('should set loading state during login', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';
      final mockToken = Fixtures.createMockAuthToken();

      when(mockRepository.login(
        username: username,
        password: password,
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockToken;
      });

      // Act
      final loginFuture = provider.login(
        username: username,
        password: password,
      );

      // Assert - should be loading
      expect(provider.isLoading, true);

      await loginFuture;

      // Assert - should not be loading after completion
      expect(provider.isLoading, false);
    });

    test('should handle login failure and set error', () async {
      // Arrange
      const username = 'testuser';
      const password = 'wrongpass';

      when(mockRepository.login(
        username: username,
        password: password,
      )).thenThrow(Exception('401 Unauthorized'));

      // Act
      final result = await provider.login(
        username: username,
        password: password,
      );

      // Assert
      expect(result, false);
      expect(provider.isAuthenticated, false);
      expect(provider.currentToken, null);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Usuario o contraseña incorrectos'));
    });

    test('should pass base URL to repository', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';
      const baseUrl = 'https://custom.tejido.com';
      final mockToken = Fixtures.createMockAuthToken();

      when(mockRepository.login(
        username: username,
        password: password,
        baseUrl: baseUrl,
      )).thenAnswer((_) async => mockToken);

      // Act
      await provider.login(
        username: username,
        password: password,
        baseUrl: baseUrl,
      );

      // Assert
      verify(mockRepository.login(
        username: username,
        password: password,
        baseUrl: baseUrl,
      )).called(1);
    });

    test('should clear previous error on new login attempt', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';

      // First login fails
      when(mockRepository.login(
        username: username,
        password: password,
      )).thenThrow(Exception('Error'));

      await provider.login(username: username, password: password);
      expect(provider.error, isNotNull);

      // Second login succeeds
      final mockToken = Fixtures.createMockAuthToken();
      when(mockRepository.login(
        username: username,
        password: password,
      )).thenAnswer((_) async => mockToken);

      // Act
      await provider.login(username: username, password: password);

      // Assert
      expect(provider.error, null);
    });

    test('should handle connection errors with appropriate message', () async {
      // Arrange
      when(mockRepository.login(
        username: any,
        password: any,
      )).thenThrow(Exception('SocketException: Network unreachable'));

      // Act
      await provider.login(username: 'user', password: 'pass');

      // Assert
      expect(provider.error, contains('No se puede conectar con el servidor'));
    });

    test('should handle 404 errors with appropriate message', () async {
      // Arrange
      when(mockRepository.login(
        username: any,
        password: any,
      )).thenThrow(Exception('404 Not Found'));

      // Act
      await provider.login(username: 'user', password: 'pass');

      // Assert
      expect(provider.error, contains('Servidor no encontrado'));
    });
  });

  group('AuthProvider - logout', () {
    test('should successfully logout', () async {
      // Arrange
      when(mockRepository.logout()).thenAnswer((_) async => {});

      // Login first
      final mockToken = Fixtures.createMockAuthToken();
      when(mockRepository.login(
        username: any,
        password: any,
      )).thenAnswer((_) async => mockToken);

      await provider.login(username: 'user', password: 'pass');
      expect(provider.isAuthenticated, true);

      // Act
      await provider.logout();

      // Assert
      expect(provider.isAuthenticated, false);
      expect(provider.currentToken, null);
      verify(mockRepository.logout()).called(1);
    });

    test('should handle logout errors', () async {
      // Arrange
      when(mockRepository.logout()).thenThrow(Exception('Logout failed'));

      // Act
      await provider.logout();

      // Assert
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Logout failed'));
    });
  });

  group('AuthProvider - updateBaseUrl', () {
    test('should update base URL successfully', () async {
      // Arrange
      const newUrl = 'https://new.tejido.com';
      final updatedToken = Fixtures.createMockAuthToken();

      when(mockRepository.updateBaseUrl(newUrl))
          .thenAnswer((_) async => {});
      when(mockRepository.currentToken).thenReturn(updatedToken);

      // Act
      await provider.updateBaseUrl(newUrl);

      // Assert
      verify(mockRepository.updateBaseUrl(newUrl)).called(1);
      expect(provider.currentToken, updatedToken);
    });

    test('should handle update base URL errors', () async {
      // Arrange
      const newUrl = 'https://invalid';

      when(mockRepository.updateBaseUrl(newUrl))
          .thenThrow(Exception('Invalid URL'));

      // Act
      await provider.updateBaseUrl(newUrl);

      // Assert
      expect(provider.error, isNotNull);
    });
  });

  group('AuthProvider - getBaseUrl', () {
    test('should return base URL from repository', () async {
      // Arrange
      const expectedUrl = 'https://tejido.example.com';
      when(mockRepository.getBaseUrl())
          .thenAnswer((_) async => expectedUrl);

      // Act
      final result = await provider.getBaseUrl();

      // Assert
      expect(result, expectedUrl);
      verify(mockRepository.getBaseUrl()).called(1);
    });
  });

  group('AuthProvider - Error Messages', () {
    test('should return appropriate message for 403 error', () async {
      // Arrange
      when(mockRepository.login(username: any, password: any))
          .thenThrow(Exception('403 Forbidden'));

      // Act
      await provider.login(username: 'user', password: 'pass');

      // Assert
      expect(provider.error, contains('Acceso denegado'));
    });

    test('should return appropriate message for 500 error', () async {
      // Arrange
      when(mockRepository.login(username: any, password: any))
          .thenThrow(Exception('500 Internal Server Error'));

      // Act
      await provider.login(username: 'user', password: 'pass');

      // Assert
      expect(provider.error, contains('Error en el servidor'));
    });

    test('should return generic message for unknown error', () async {
      // Arrange
      when(mockRepository.login(username: any, password: any))
          .thenThrow(Exception('Unknown error'));

      // Act
      await provider.login(username: 'user', password: 'pass');

      // Assert
      expect(provider.error, contains('Error:'));
      expect(provider.error, contains('Unknown error'));
    });
  });
}
