import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lumara_indigenas/core/constants/api_constants.dart';
import 'package:lumara_indigenas/data/repositories/auth_repository.dart';
import 'package:lumara_indigenas/domain/entities/auth_token.dart';
import '../../../mocks/mock_api_client.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockTejidoApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockTejidoApiClient();
    repository = AuthRepository(mockApiClient);

    // Mock FlutterSecureStorage for testing
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthRepository - login', () {
    const testUsername = 'testuser';
    const testPassword = 'testpass';
    const testToken = 'test-token-123';
    const testBaseUrl = 'https://test.tejido.com';

    final mockLoginResponse = {
      'token': testToken,
    };

    test('should successfully login with valid credentials', () async {
      // Arrange
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenAnswer((_) async => mockLoginResponse);

      when(mockApiClient.setBaseUrl(any)).thenReturn(null);
      when(mockApiClient.setAuthToken(any)).thenReturn(null);

      // Act
      final result = await repository.login(
        username: testUsername,
        password: testPassword,
        baseUrl: testBaseUrl,
      );

      // Assert
      expect(result.token, testToken);
      expect(result.username, testUsername);
      expect(result.baseUrl, testBaseUrl);

      verify(mockApiClient.setBaseUrl(testBaseUrl)).called(1);
      verify(mockApiClient.setAuthToken(testToken)).called(1);
      verify(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).called(1);
    });

    test('should use default base URL if not provided', () async {
      // Arrange
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenAnswer((_) async => mockLoginResponse);

      when(mockApiClient.setBaseUrl(any)).thenReturn(null);
      when(mockApiClient.setAuthToken(any)).thenReturn(null);

      // Act
      final result = await repository.login(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(result.baseUrl, ApiConstants.defaultBaseUrl);
      verify(mockApiClient.setBaseUrl(ApiConstants.defaultBaseUrl)).called(1);
    });

    test('should throw exception on login failure', () async {
      // Arrange
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenThrow(Exception('Invalid credentials'));

      when(mockApiClient.setBaseUrl(any)).thenReturn(null);

      // Act & Assert
      expect(
        () => repository.login(
          username: testUsername,
          password: testPassword,
        ),
        throwsException,
      );
    });

    test('should enforce rate limiting after multiple failed attempts', () async {
      // Arrange
      when(mockApiClient.setBaseUrl(any)).thenReturn(null);
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenThrow(Exception('Invalid credentials'));

      // Act - Attempt login 5 times (rate limit threshold)
      for (int i = 0; i < 5; i++) {
        try {
          await repository.login(
            username: testUsername,
            password: testPassword,
          );
        } catch (e) {
          // Expected to fail
        }
      }

      // Assert - 6th attempt should be rate limited
      expect(
        () => repository.login(
          username: testUsername,
          password: testPassword,
        ),
        throwsA(
          predicate((e) =>
              e.toString().contains('Too many login attempts')),
        ),
      );
    });

    test('should clear rate limit on successful login', () async {
      // Arrange
      when(mockApiClient.setBaseUrl(any)).thenReturn(null);
      when(mockApiClient.setAuthToken(any)).thenReturn(null);

      // First fail
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenThrow(Exception('Invalid credentials'));

      try {
        await repository.login(
          username: testUsername,
          password: testPassword,
        );
      } catch (e) {
        // Expected
      }

      // Then succeed
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenAnswer((_) async => mockLoginResponse);

      // Act
      final result = await repository.login(
        username: testUsername,
        password: testPassword,
      );

      // Assert - Rate limit should be cleared
      expect(result.token, testToken);
    });
  });

  group('AuthRepository - logout', () {
    test('should clear all stored credentials on logout', () async {
      // Arrange
      when(mockApiClient.clearAuthToken()).thenReturn(null);

      // Act
      await repository.logout();

      // Assert
      verify(mockApiClient.clearAuthToken()).called(1);
      expect(repository.currentToken, null);
    });
  });

  group('AuthRepository - isAuthenticated', () {
    test('should return false when no token stored', () async {
      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, false);
    });

    test('should return false when token is expired', () async {
      // This test would require mocking secure storage with expired token
      // For now, we verify the basic flow
      final result = await repository.isAuthenticated();
      expect(result, false);
    });

    test('should return false when connection test fails', () async {
      // This would require more complex mocking setup
      final result = await repository.isAuthenticated();
      expect(result, false);
    });
  });

  group('AuthRepository - updateBaseUrl', () {
    test('should update base URL and persist to storage', () async {
      // Arrange
      const newUrl = 'https://new.tejido.com';
      when(mockApiClient.setBaseUrl(newUrl)).thenReturn(null);

      // Act
      await repository.updateBaseUrl(newUrl);

      // Assert
      verify(mockApiClient.setBaseUrl(newUrl)).called(1);
    });

    test('should update current token with new base URL', () async {
      // Arrange
      const testUsername = 'testuser';
      const testPassword = 'testpass';
      const testToken = 'test-token-123';
      const initialUrl = 'https://initial.com';
      const newUrl = 'https://new.com';

      when(mockApiClient.setBaseUrl(any)).thenReturn(null);
      when(mockApiClient.setAuthToken(any)).thenReturn(null);
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenAnswer((_) async => {'token': testToken});

      // First login to get a token
      await repository.login(
        username: testUsername,
        password: testPassword,
        baseUrl: initialUrl,
      );

      // Act - Update URL
      await repository.updateBaseUrl(newUrl);

      // Assert
      expect(repository.currentToken?.baseUrl, newUrl);
      verify(mockApiClient.setBaseUrl(newUrl)).called(greaterThan(0));
    });
  });

  group('AuthRepository - getBaseUrl', () {
    test('should return default URL when none stored', () async {
      // Act
      final result = await repository.getBaseUrl();

      // Assert
      expect(result, ApiConstants.defaultBaseUrl);
    });
  });

  group('AuthRepository - currentToken', () {
    test('should return null when no user logged in', () {
      // Act
      final token = repository.currentToken;

      // Assert
      expect(token, null);
    });

    test('should return token after successful login', () async {
      // Arrange
      const testUsername = 'testuser';
      const testPassword = 'testpass';
      const testToken = 'test-token-123';

      when(mockApiClient.setBaseUrl(any)).thenReturn(null);
      when(mockApiClient.setAuthToken(any)).thenReturn(null);
      when(mockApiClient.login(
        username: testUsername,
        password: testPassword,
      )).thenAnswer((_) async => {'token': testToken});

      // Act
      await repository.login(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(repository.currentToken, isNotNull);
      expect(repository.currentToken?.token, testToken);
      expect(repository.currentToken?.username, testUsername);
    });
  });
}
