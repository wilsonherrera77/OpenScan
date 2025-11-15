import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openscan_indigenas/core/security/secure_config_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureConfigManager', () {
    late SecureConfigManager manager;

    setUp(() {
      manager = SecureConfigManager();
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('should store and retrieve base URL', () async {
      await manager.setBaseUrl('https://example.com');
      final url = await manager.getBaseUrl();

      expect(url, 'https://example.com');
    });

    test('should store and retrieve API token', () async {
      await manager.setApiToken('test-token-123');
      final token = await manager.getApiToken();

      expect(token, 'test-token-123');
    });

    test('should validate URL format', () async {
      expect(
        () => manager.setBaseUrl('invalid-url'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should store username', () async {
      await manager.setUsername('testuser');
      final username = await manager.getUsername();

      expect(username, 'testuser');
    });

    test('should check if configured', () async {
      var isConfigured = await manager.isConfigured();
      expect(isConfigured, false);

      await manager.setBaseUrl('https://example.com');
      await manager.setApiToken('test-token');

      isConfigured = await manager.isConfigured();
      expect(isConfigured, true);
    });

    test('should clear credentials', () async {
      await manager.setApiToken('test-token');
      await manager.setUsername('testuser');

      await manager.clearCredentials();

      final token = await manager.getApiToken();
      final username = await manager.getUsername();

      expect(token, null);
      expect(username, null);
    });

    test('should track token rotation', () async {
      await manager.setApiToken('test-token');

      final needsRotation = await manager.needsTokenRotation();
      expect(needsRotation, false); // Just set

      final daysSince = await manager.getDaysSinceRotation();
      expect(daysSince, 0);
    });

    test('should provide configuration status', () async {
      await manager.setBaseUrl('https://example.com');
      await manager.setApiToken('test-token');
      await manager.setUsername('testuser');

      final status = await manager.getConfigStatus();

      expect(status['configured'], true);
      expect(status['base_url'], 'https://example.com');
      expect(status['has_token'], true);
      expect(status['username'], 'testuser');
      expect(status['days_since_rotation'], greaterThanOrEqualTo(0));
    });
  });
}
