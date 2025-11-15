import '../../services/logger_adapter.dart';

/// Rate Limiter
/// Implements rate limiting to prevent brute-force attacks
///
/// Uses token bucket algorithm for flexible rate limiting
class RateLimiter {
  final LoggerAdapter _logger = LoggerAdapter();

  final int _maxAttempts;
  final Duration _window;
  final Map<String, _RateLimitEntry> _attempts = {};

  /// Create rate limiter
  ///
  /// [maxAttempts]: Maximum number of attempts allowed
  /// [window]: Time window for rate limiting
  RateLimiter({
    required int maxAttempts,
    required Duration window,
  })  : _maxAttempts = maxAttempts,
        _window = window;

  /// Check if action is allowed for given key
  ///
  /// Returns true if action is allowed, false if rate limit exceeded
  bool isAllowed(String key) {
    _cleanupOldEntries();

    final entry = _attempts[key];
    final now = DateTime.now();

    if (entry == null) {
      // First attempt
      _attempts[key] = _RateLimitEntry(
        attempts: 1,
        firstAttemptAt: now,
        lastAttemptAt: now,
      );
      _logger.d('🔓 Rate limit check: $key (1/$_maxAttempts)');
      return true;
    }

    // Check if window has expired
    final elapsed = now.difference(entry.firstAttemptAt);
    if (elapsed > _window) {
      // Window expired, reset counter
      _attempts[key] = _RateLimitEntry(
        attempts: 1,
        firstAttemptAt: now,
        lastAttemptAt: now,
      );
      _logger.d('🔓 Rate limit reset: $key (1/$_maxAttempts)');
      return true;
    }

    // Check if limit exceeded
    if (entry.attempts >= _maxAttempts) {
      final remaining = _window - elapsed;
      _logger.w(
        '🚫 Rate limit exceeded: $key '
        '(${entry.attempts}/$_maxAttempts). '
        'Retry in ${remaining.inSeconds}s',
      );
      return false;
    }

    // Increment counter
    entry.attempts++;
    entry.lastAttemptAt = now;
    _logger.d('🔓 Rate limit check: $key (${entry.attempts}/$_maxAttempts)');
    return true;
  }

  /// Record attempt without checking limit (for tracking only)
  void recordAttempt(String key) {
    _cleanupOldEntries();

    final entry = _attempts[key];
    final now = DateTime.now();

    if (entry == null) {
      _attempts[key] = _RateLimitEntry(
        attempts: 1,
        firstAttemptAt: now,
        lastAttemptAt: now,
      );
    } else {
      entry.attempts++;
      entry.lastAttemptAt = now;
    }
  }

  /// Get remaining attempts for key
  int getRemainingAttempts(String key) {
    final entry = _attempts[key];
    if (entry == null) return _maxAttempts;

    final elapsed = DateTime.now().difference(entry.firstAttemptAt);
    if (elapsed > _window) {
      return _maxAttempts;
    }

    return (_maxAttempts - entry.attempts).clamp(0, _maxAttempts);
  }

  /// Get time until rate limit resets
  Duration? getResetTime(String key) {
    final entry = _attempts[key];
    if (entry == null) return null;

    final elapsed = DateTime.now().difference(entry.firstAttemptAt);
    if (elapsed > _window) {
      return null;
    }

    return _window - elapsed;
  }

  /// Clear rate limit for key (admin use)
  void clear(String key) {
    _attempts.remove(key);
    _logger.i('🔓 Rate limit cleared for: $key');
  }

  /// Clear all rate limits
  void clearAll() {
    _attempts.clear();
    _logger.i('🔓 All rate limits cleared');
  }

  /// Cleanup expired entries
  void _cleanupOldEntries() {
    final now = DateTime.now();
    _attempts.removeWhere((key, entry) {
      final elapsed = now.difference(entry.firstAttemptAt);
      return elapsed > _window;
    });
  }

  /// Get current statistics
  Map<String, dynamic> getStatistics() {
    _cleanupOldEntries();

    return {
      'max_attempts': _maxAttempts,
      'window_seconds': _window.inSeconds,
      'active_limits': _attempts.length,
      'details': _attempts.map(
        (key, entry) => MapEntry(
          key,
          {
            'attempts': entry.attempts,
            'remaining': getRemainingAttempts(key),
            'reset_in_seconds': getResetTime(key)?.inSeconds,
          },
        ),
      ),
    };
  }
}

/// Rate limit entry
class _RateLimitEntry {
  int attempts;
  DateTime firstAttemptAt;
  DateTime lastAttemptAt;

  _RateLimitEntry({
    required this.attempts,
    required this.firstAttemptAt,
    required this.lastAttemptAt,
  });
}

/// Login Rate Limiter
/// Pre-configured rate limiter for login attempts
class LoginRateLimiter extends RateLimiter {
  /// Maximum login attempts per user
  static const int maxLoginAttempts = 5;

  /// Time window for login rate limiting (15 minutes)
  static const Duration loginWindow = Duration(minutes: 15);

  LoginRateLimiter()
      : super(
          maxAttempts: maxLoginAttempts,
          window: loginWindow,
        );

  /// Check if login is allowed for username
  bool isLoginAllowed(String username) {
    return isAllowed('login:$username');
  }

  /// Record login attempt
  void recordLoginAttempt(String username) {
    recordAttempt('login:$username');
  }

  /// Get remaining login attempts
  int getRemainingLoginAttempts(String username) {
    return getRemainingAttempts('login:$username');
  }

  /// Get time until login attempts reset
  Duration? getLoginResetTime(String username) {
    return getResetTime('login:$username');
  }

  /// Clear login rate limit for user
  void clearLoginLimit(String username) {
    clear('login:$username');
  }
}

/// API Rate Limiter
/// Pre-configured rate limiter for API requests
class ApiRateLimiter extends RateLimiter {
  /// Maximum API requests per endpoint
  static const int maxApiRequests = 100;

  /// Time window for API rate limiting (1 minute)
  static const Duration apiWindow = Duration(minutes: 1);

  ApiRateLimiter()
      : super(
          maxAttempts: maxApiRequests,
          window: apiWindow,
        );

  /// Check if API request is allowed for endpoint
  bool isApiRequestAllowed(String endpoint, String? userId) {
    final key = userId != null ? 'api:$endpoint:$userId' : 'api:$endpoint';
    return isAllowed(key);
  }

  /// Record API request
  void recordApiRequest(String endpoint, String? userId) {
    final key = userId != null ? 'api:$endpoint:$userId' : 'api:$endpoint';
    recordAttempt(key);
  }
}
