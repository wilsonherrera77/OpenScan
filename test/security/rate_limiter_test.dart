import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/core/security/rate_limiter.dart';

void main() {
  group('RateLimiter - Security Tests', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(
        maxAttempts: 3,
        window: const Duration(seconds: 10),
      );
    });

    test('should allow first attempt', () {
      expect(rateLimiter.isAllowed('test_key'), isTrue);
    });

    test('should allow attempts within limit', () {
      expect(rateLimiter.isAllowed('test_key'), isTrue);
      expect(rateLimiter.isAllowed('test_key'), isTrue);
      expect(rateLimiter.isAllowed('test_key'), isTrue);
    });

    test('should block attempts after limit exceeded', () {
      rateLimiter.isAllowed('test_key'); // 1
      rateLimiter.isAllowed('test_key'); // 2
      rateLimiter.isAllowed('test_key'); // 3
      expect(rateLimiter.isAllowed('test_key'), isFalse); // 4 - blocked
    });

    test('should track remaining attempts correctly', () {
      expect(rateLimiter.getRemainingAttempts('test_key'), equals(3));

      rateLimiter.isAllowed('test_key');
      expect(rateLimiter.getRemainingAttempts('test_key'), equals(2));

      rateLimiter.isAllowed('test_key');
      expect(rateLimiter.getRemainingAttempts('test_key'), equals(1));

      rateLimiter.isAllowed('test_key');
      expect(rateLimiter.getRemainingAttempts('test_key'), equals(0));
    });

    test('should reset after time window expires', () async {
      rateLimiter.isAllowed('test_key'); // 1
      rateLimiter.isAllowed('test_key'); // 2
      rateLimiter.isAllowed('test_key'); // 3
      expect(rateLimiter.isAllowed('test_key'), isFalse); // 4 - blocked

      // Wait for window to expire
      await Future.delayed(const Duration(seconds: 11));

      expect(rateLimiter.isAllowed('test_key'), isTrue); // Reset
    });

    test('should clear specific key', () {
      rateLimiter.isAllowed('test_key'); // 1
      rateLimiter.isAllowed('test_key'); // 2
      rateLimiter.isAllowed('test_key'); // 3
      expect(rateLimiter.isAllowed('test_key'), isFalse); // Blocked

      rateLimiter.clear('test_key');

      expect(rateLimiter.isAllowed('test_key'), isTrue); // Allowed after clear
    });

    test('should track different keys independently', () {
      rateLimiter.isAllowed('key1'); // 1
      rateLimiter.isAllowed('key1'); // 2
      rateLimiter.isAllowed('key1'); // 3
      expect(rateLimiter.isAllowed('key1'), isFalse); // Blocked

      // key2 should still be allowed
      expect(rateLimiter.isAllowed('key2'), isTrue);
      expect(rateLimiter.isAllowed('key2'), isTrue);
    });

    test('should return reset time when blocked', () {
      rateLimiter.isAllowed('test_key'); // 1
      rateLimiter.isAllowed('test_key'); // 2
      rateLimiter.isAllowed('test_key'); // 3

      final resetTime = rateLimiter.getResetTime('test_key');
      expect(resetTime, isNotNull);
      expect(resetTime!.inSeconds, greaterThan(0));
      expect(resetTime.inSeconds, lessThanOrEqualTo(10));
    });

    test('should record attempt without checking limit', () {
      rateLimiter.recordAttempt('test_key');
      rateLimiter.recordAttempt('test_key');
      rateLimiter.recordAttempt('test_key');
      rateLimiter.recordAttempt('test_key'); // Over limit but not blocked

      expect(rateLimiter.getRemainingAttempts('test_key'), lessThan(0));
    });

    test('should return statistics', () {
      rateLimiter.isAllowed('key1');
      rateLimiter.isAllowed('key2');

      final stats = rateLimiter.getStatistics();
      expect(stats['max_attempts'], equals(3));
      expect(stats['window_seconds'], equals(10));
      expect(stats['active_limits'], greaterThanOrEqualTo(0));
    });

    test('should clear all limits', () {
      rateLimiter.isAllowed('key1');
      rateLimiter.isAllowed('key2');
      rateLimiter.isAllowed('key3');

      rateLimiter.clearAll();

      expect(rateLimiter.getRemainingAttempts('key1'), equals(3));
      expect(rateLimiter.getRemainingAttempts('key2'), equals(3));
      expect(rateLimiter.getRemainingAttempts('key3'), equals(3));
    });
  });

  group('LoginRateLimiter - Security Tests', () {
    late LoginRateLimiter loginRateLimiter;

    setUp(() {
      loginRateLimiter = LoginRateLimiter();
    });

    test('should allow login attempts within limit', () {
      expect(loginRateLimiter.isLoginAllowed('admin'), isTrue);
      expect(loginRateLimiter.isLoginAllowed('admin'), isTrue);
      expect(loginRateLimiter.isLoginAllowed('admin'), isTrue);
      expect(loginRateLimiter.isLoginAllowed('admin'), isTrue);
      expect(loginRateLimiter.isLoginAllowed('admin'), isTrue);
    });

    test('should block login attempts after 5 failures', () {
      loginRateLimiter.recordLoginAttempt('admin'); // 1
      loginRateLimiter.recordLoginAttempt('admin'); // 2
      loginRateLimiter.recordLoginAttempt('admin'); // 3
      loginRateLimiter.recordLoginAttempt('admin'); // 4
      loginRateLimiter.recordLoginAttempt('admin'); // 5

      expect(loginRateLimiter.isLoginAllowed('admin'), isFalse);
    });

    test('should track remaining login attempts', () {
      expect(loginRateLimiter.getRemainingLoginAttempts('admin'), equals(5));

      loginRateLimiter.recordLoginAttempt('admin');
      expect(loginRateLimiter.getRemainingLoginAttempts('admin'), equals(4));

      loginRateLimiter.recordLoginAttempt('admin');
      expect(loginRateLimiter.getRemainingLoginAttempts('admin'), equals(3));
    });

    test('should clear login limit on successful login', () {
      loginRateLimiter.recordLoginAttempt('admin'); // 1
      loginRateLimiter.recordLoginAttempt('admin'); // 2
      loginRateLimiter.recordLoginAttempt('admin'); // 3

      expect(loginRateLimiter.getRemainingLoginAttempts('admin'), equals(2));

      loginRateLimiter.clearLoginLimit('admin');

      expect(loginRateLimiter.getRemainingLoginAttempts('admin'), equals(5));
    });

    test('should return login reset time when blocked', () {
      loginRateLimiter.recordLoginAttempt('admin'); // 1
      loginRateLimiter.recordLoginAttempt('admin'); // 2
      loginRateLimiter.recordLoginAttempt('admin'); // 3
      loginRateLimiter.recordLoginAttempt('admin'); // 4
      loginRateLimiter.recordLoginAttempt('admin'); // 5

      final resetTime = loginRateLimiter.getLoginResetTime('admin');
      expect(resetTime, isNotNull);
      expect(resetTime!.inMinutes, greaterThan(0));
      expect(resetTime.inMinutes, lessThanOrEqualTo(15));
    });

    test('should track different users independently', () {
      loginRateLimiter.recordLoginAttempt('admin'); // 1
      loginRateLimiter.recordLoginAttempt('admin'); // 2
      loginRateLimiter.recordLoginAttempt('admin'); // 3
      loginRateLimiter.recordLoginAttempt('admin'); // 4
      loginRateLimiter.recordLoginAttempt('admin'); // 5

      expect(loginRateLimiter.isLoginAllowed('admin'), isFalse);
      expect(loginRateLimiter.isLoginAllowed('user'), isTrue); // Different user
    });
  });

  group('ApiRateLimiter - Security Tests', () {
    late ApiRateLimiter apiRateLimiter;

    setUp(() {
      apiRateLimiter = ApiRateLimiter();
    });

    test('should allow API requests within limit', () {
      for (int i = 0; i < 100; i++) {
        expect(apiRateLimiter.isApiRequestAllowed('/api/documents', 'user1'), isTrue);
      }
    });

    test('should block API requests after limit exceeded', () {
      for (int i = 0; i < 100; i++) {
        apiRateLimiter.recordApiRequest('/api/documents', 'user1');
      }

      expect(apiRateLimiter.isApiRequestAllowed('/api/documents', 'user1'), isFalse);
    });

    test('should track different endpoints independently', () {
      for (int i = 0; i < 100; i++) {
        apiRateLimiter.recordApiRequest('/api/documents', 'user1');
      }

      expect(apiRateLimiter.isApiRequestAllowed('/api/documents', 'user1'), isFalse);
      expect(apiRateLimiter.isApiRequestAllowed('/api/login', 'user1'), isTrue); // Different endpoint
    });

    test('should track different users independently', () {
      for (int i = 0; i < 100; i++) {
        apiRateLimiter.recordApiRequest('/api/documents', 'user1');
      }

      expect(apiRateLimiter.isApiRequestAllowed('/api/documents', 'user1'), isFalse);
      expect(apiRateLimiter.isApiRequestAllowed('/api/documents', 'user2'), isTrue); // Different user
    });
  });
}
