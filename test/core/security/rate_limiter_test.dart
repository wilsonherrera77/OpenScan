import 'package:flutter_test/flutter_test.dart';
import 'package:openscan_indigenas/core/security/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('should allow requests within limit', () {
      final limiter = RateLimiter(
        maxAttempts: 3,
        window: const Duration(minutes: 1),
      );

      expect(limiter.isAllowed('test'), true);
      expect(limiter.isAllowed('test'), true);
      expect(limiter.isAllowed('test'), true);
    });

    test('should block requests exceeding limit', () {
      final limiter = RateLimiter(
        maxAttempts: 3,
        window: const Duration(minutes: 1),
      );

      limiter.isAllowed('test');
      limiter.isAllowed('test');
      limiter.isAllowed('test');

      expect(limiter.isAllowed('test'), false);
    });

    test('should track remaining attempts', () {
      final limiter = RateLimiter(
        maxAttempts: 5,
        window: const Duration(minutes: 1),
      );

      expect(limiter.getRemainingAttempts('test'), 5);

      limiter.isAllowed('test');
      expect(limiter.getRemainingAttempts('test'), 4);

      limiter.isAllowed('test');
      expect(limiter.getRemainingAttempts('test'), 3);
    });

    test('should reset after window expiry', () async {
      final limiter = RateLimiter(
        maxAttempts: 2,
        window: const Duration(milliseconds: 100),
      );

      limiter.isAllowed('test');
      limiter.isAllowed('test');

      expect(limiter.isAllowed('test'), false);

      // Wait for window to expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Should allow again
      expect(limiter.isAllowed('test'), true);
    });

    test('should track different keys independently', () {
      final limiter = RateLimiter(
        maxAttempts: 2,
        window: const Duration(minutes: 1),
      );

      limiter.isAllowed('user1');
      limiter.isAllowed('user1');

      expect(limiter.isAllowed('user1'), false);
      expect(limiter.isAllowed('user2'), true); // Different key
    });

    test('should clear specific key', () {
      final limiter = RateLimiter(
        maxAttempts: 2,
        window: const Duration(minutes: 1),
      );

      limiter.isAllowed('test');
      limiter.isAllowed('test');

      expect(limiter.isAllowed('test'), false);

      limiter.clear('test');

      expect(limiter.isAllowed('test'), true);
    });

    test('should provide statistics', () {
      final limiter = RateLimiter(
        maxAttempts: 5,
        window: const Duration(minutes: 1),
      );

      limiter.isAllowed('user1');
      limiter.isAllowed('user1');
      limiter.isAllowed('user2');

      final stats = limiter.getStatistics();

      expect(stats['max_attempts'], 5);
      expect(stats['window_seconds'], 60);
      expect(stats['active_limits'], 2);
    });
  });

  group('LoginRateLimiter', () {
    test('should limit login attempts', () {
      final limiter = LoginRateLimiter();

      // Should allow first 5 attempts
      for (var i = 0; i < 5; i++) {
        expect(limiter.isLoginAllowed('testuser'), true);
      }

      // Should block 6th attempt
      expect(limiter.isLoginAllowed('testuser'), false);
    });

    test('should track login-specific keys', () {
      final limiter = LoginRateLimiter();

      limiter.recordLoginAttempt('user1');
      limiter.recordLoginAttempt('user1');

      expect(limiter.getRemainingLoginAttempts('user1'), 3);
    });

    test('should clear login limit', () {
      final limiter = LoginRateLimiter();

      for (var i = 0; i < 5; i++) {
        limiter.recordLoginAttempt('testuser');
      }

      expect(limiter.isLoginAllowed('testuser'), false);

      limiter.clearLoginLimit('testuser');

      expect(limiter.isLoginAllowed('testuser'), true);
    });
  });

  group('ApiRateLimiter', () {
    test('should limit API requests', () {
      final limiter = ApiRateLimiter();

      // Should allow many requests within limit
      for (var i = 0; i < 100; i++) {
        expect(limiter.isApiRequestAllowed('/api/test', 'user1'), true);
      }

      // Should block when limit exceeded
      expect(limiter.isApiRequestAllowed('/api/test', 'user1'), false);
    });

    test('should track per-endpoint per-user', () {
      final limiter = ApiRateLimiter();

      limiter.recordApiRequest('/api/login', 'user1');
      limiter.recordApiRequest('/api/documents', 'user1');

      // Different endpoints should be independent
      expect(
        limiter.isApiRequestAllowed('/api/login', 'user1'),
        true,
      );
    });
  });
}
