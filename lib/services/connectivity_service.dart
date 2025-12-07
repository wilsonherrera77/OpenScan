import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/logger_adapter.dart';

/// Connectivity Service
/// ⚡ FASE 3: Enhanced with jitter, circuit breaker, and advanced retry logic
/// Manages network connectivity checks and provides intelligent retry mechanisms
class ConnectivityService {
  static final LoggerAdapter _logger = LoggerAdapter();
  static final Connectivity _connectivity = Connectivity();
  static final Random _random = Random();

  // ⚡ FASE 3: Circuit Breaker state
  static final Map<String, CircuitBreakerState> _circuitBreakers = {};

  /// Circuit Breaker Configuration
  static const int circuitBreakerThreshold = 5; // Failed attempts before opening
  static const Duration circuitBreakerTimeout = Duration(minutes: 2); // Time before retry

  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      // Check connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        _logger.w('⚠️ No network connectivity');
        return false;
      }

      // Verify actual internet access by pinging a reliable server
      // Use Google DNS as fallback
      try {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 5),
        );

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _logger.d('✅ Internet connection verified');
          return true;
        }
      } catch (e) {
        _logger.w('⚠️ DNS lookup failed: $e');
      }

      return false;
    } catch (e, stackTrace) {
      _logger.e('❌ Connectivity check error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if specific server is reachable
  static Future<bool> canReachServer(String baseUrl) async {
    try {
      _logger.d('🔍 Checking server reachability: $baseUrl');

      // Parse URL to get host
      final uri = Uri.parse(baseUrl);
      final host = uri.host;
      final port = uri.port;

      // Try to connect to server
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );

      await socket.close();
      _logger.i('✅ Server reachable: $baseUrl');
      return true;
    } catch (e) {
      _logger.w('⚠️ Server unreachable: $baseUrl - $e');
      return false;
    }
  }

  /// ⚡ FASE 3: Enhanced retry logic with exponential backoff, jitter, and circuit breaker
  ///
  /// Features:
  /// - Exponential backoff with configurable multiplier
  /// - Jitter to prevent thundering herd problem
  /// - Circuit breaker to avoid hammering failing services
  /// - Smart error classification (retryable vs non-retryable)
  /// - Detailed retry metrics and logging
  static Future<T?> retryWithBackoff<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 5,
    Duration initialDelay = const Duration(seconds: 2),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(minutes: 5),
    bool useJitter = true,
    bool useCircuitBreaker = true,
  }) async {
    // ⚡ v6.3.5: Log entry to retryWithBackoff
    _logger.d('🔧 [RETRY] Entering retryWithBackoff for: $operationName');

    // ⚡ FASE 3: Check circuit breaker
    if (useCircuitBreaker) {
      _logger.d('🔧 [RETRY] Checking circuit breaker...');
      final breaker = _getOrCreateCircuitBreaker(operationName);
      _logger.d('🔧 [RETRY] Circuit breaker retrieved');
      if (breaker.isOpen) {
        if (breaker.shouldAttemptReset()) {
          _logger.i('🔄 Circuit breaker: attempting reset for $operationName');
          breaker.halfOpen();
        } else {
          final remainingTime = breaker.timeUntilReset();
          _logger.w('⚠️ Circuit breaker OPEN for $operationName (retry in ${remainingTime.inSeconds}s)');
          throw CircuitBreakerOpenException(operationName, remainingTime);
        }
      }
    }

    int attempt = 0;
    Duration currentDelay = initialDelay;
    final startTime = DateTime.now();

    while (attempt < maxRetries) {
      try {
        _logger.d('🔄 Attempt ${attempt + 1}/$maxRetries for: $operationName');

        // Execute operation
        final result = await operation();

        // ⚡ FASE 3: Success - reset circuit breaker
        if (useCircuitBreaker) {
          _getOrCreateCircuitBreaker(operationName).recordSuccess();
        }

        final duration = DateTime.now().difference(startTime);
        _logger.i('✅ $operationName succeeded on attempt ${attempt + 1} (${duration.inMilliseconds}ms)');

        return result;
      } catch (e, stackTrace) {
        attempt++;

        // ⚡ FASE 3: Classify error type
        final errorType = _classifyError(e);

        if (attempt >= maxRetries) {
          // ⚡ FASE 3: Record failure in circuit breaker
          if (useCircuitBreaker) {
            _getOrCreateCircuitBreaker(operationName).recordFailure();
          }

          _logger.e(
            '❌ $operationName failed after $maxRetries attempts: $e',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }

        // ⚡ FASE 3: Don't retry non-retryable errors
        if (!errorType.isRetryable) {
          _logger.w('⚠️ Non-retryable error (${errorType.description}), aborting: $e');
          rethrow;
        }

        // ⚡ FASE 3: Calculate delay with jitter
        Duration delayWithJitter = currentDelay;
        if (useJitter) {
          // Add ±25% jitter to prevent thundering herd
          final jitterRange = currentDelay.inMilliseconds * 0.25;
          final jitterMs = _random.nextDouble() * jitterRange * 2 - jitterRange;
          delayWithJitter = Duration(
            milliseconds: (currentDelay.inMilliseconds + jitterMs).round(),
          );
        }

        _logger.w(
          '⚠️ Attempt $attempt failed (${errorType.description}), '
          'retrying in ${delayWithJitter.inSeconds}s: $e'
        );

        // Wait before retry
        await Future.delayed(delayWithJitter);

        // Calculate next delay with exponential backoff
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );

        // Cap at max delay
        if (currentDelay > maxDelay) {
          currentDelay = maxDelay;
        }
      }
    }

    return null;
  }

  /// ⚡ FASE 3: Classify error for retry decision
  static ErrorType _classifyError(dynamic error) {
    // Network errors - always retry
    if (error is SocketException) {
      return ErrorType.network;
    }
    if (error is TimeoutException) {
      return ErrorType.timeout;
    }

    final errorStr = error.toString().toLowerCase();

    // Connection errors - retry
    if (errorStr.contains('connection') ||
        errorStr.contains('network') ||
        errorStr.contains('unreachable')) {
      return ErrorType.network;
    }

    // Server errors (5xx) - retry
    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504')) {
      return ErrorType.serverError;
    }

    // Client errors (4xx) - don't retry
    if (errorStr.contains('400') ||
        errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('404')) {
      return ErrorType.clientError;
    }

    // Rate limiting - retry with backoff
    if (errorStr.contains('429') || errorStr.contains('rate limit')) {
      return ErrorType.rateLimited;
    }

    // Unknown error - don't retry to be safe
    return ErrorType.unknown;
  }

  /// ⚡ FASE 3: Get or create circuit breaker for operation
  static CircuitBreakerState _getOrCreateCircuitBreaker(String operationName) {
    if (!_circuitBreakers.containsKey(operationName)) {
      _circuitBreakers[operationName] = CircuitBreakerState(operationName);
    }
    return _circuitBreakers[operationName]!;
  }

  /// ⚡ FASE 3: Get circuit breaker metrics
  static Map<String, dynamic> getCircuitBreakerMetrics() {
    return _circuitBreakers.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
  }

  /// ⚡ FASE 3: Reset all circuit breakers (for testing)
  static void resetAllCircuitBreakers() {
    _circuitBreakers.clear();
    _logger.i('🔄 All circuit breakers reset');
  }

  /// Wait for internet connection to be available
  /// Returns true if connection becomes available, false if timeout
  static Future<bool> waitForConnection({
    Duration timeout = const Duration(minutes: 2),
    Duration checkInterval = const Duration(seconds: 5),
  }) async {
    _logger.i('⏳ Waiting for internet connection...');

    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      if (await hasInternetConnection()) {
        _logger.i('✅ Connection established');
        return true;
      }

      _logger.d('⏳ Still waiting for connection...');
      await Future.delayed(checkInterval);
    }

    _logger.w('⚠️ Connection timeout after ${timeout.inSeconds}s');
    return false;
  }

  /// Listen to connectivity changes
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Get current connectivity status
  static Future<List<ConnectivityResult>> getCurrentConnectivity() {
    return _connectivity.checkConnectivity();
  }

  /// Validate Tejido server connection
  static Future<Map<String, dynamic>> validateTejidoConnection(String baseUrl) async {
    final result = {
      'hasInternet': false,
      'serverReachable': false,
      'serverResponding': false,
      'latencyMs': 0,
      'error': null,
    };

    try {
      // Step 1: Check internet
      result['hasInternet'] = await hasInternetConnection();
      if (!(result['hasInternet'] as bool)) {
        result['error'] = 'No hay conexión a Internet';
        return result;
      }

      // Step 2: Check server reachability
      result['serverReachable'] = await canReachServer(baseUrl);
      if (!(result['serverReachable'] as bool)) {
        result['error'] = 'Servidor Tejido no alcanzable en $baseUrl';
        return result;
      }

      // Step 3: Check server response
      final startTime = DateTime.now();

      final socket = await Socket.connect(
        Uri.parse(baseUrl).host,
        Uri.parse(baseUrl).port,
        timeout: const Duration(seconds: 10),
      );
      await socket.close();

      final latency = DateTime.now().difference(startTime);
      result['latencyMs'] = latency.inMilliseconds;
      result['serverResponding'] = true;

      _logger.i('✅ Tejido connection validated (latency: ${latency.inMilliseconds}ms)');

    } catch (e, stackTrace) {
      result['error'] = 'Error de conexión: $e';
      _logger.e('❌ Tejido connection validation failed: $e', error: e, stackTrace: stackTrace);
    }

    return result;
  }
}

/// ⚡ FASE 3: Error Type Classification
enum ErrorType {
  network('Network error', true),
  timeout('Timeout', true),
  serverError('Server error (5xx)', true),
  rateLimited('Rate limited', true),
  clientError('Client error (4xx)', false),
  unknown('Unknown error', false);

  final String description;
  final bool isRetryable;

  const ErrorType(this.description, this.isRetryable);
}

/// ⚡ FASE 3: Circuit Breaker State
/// Implements the Circuit Breaker pattern to prevent cascading failures
///
/// States:
/// - CLOSED: Normal operation, requests pass through
/// - OPEN: Too many failures, requests are blocked
/// - HALF_OPEN: Testing if service recovered
class CircuitBreakerState {
  final String operationName;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerStatus _status = CircuitBreakerStatus.closed;

  CircuitBreakerState(this.operationName);

  bool get isOpen => _status == CircuitBreakerStatus.open;
  bool get isClosed => _status == CircuitBreakerStatus.closed;
  bool get isHalfOpen => _status == CircuitBreakerStatus.halfOpen;

  /// Record successful operation
  void recordSuccess() {
    _successCount++;
    if (_status == CircuitBreakerStatus.halfOpen) {
      // Success in half-open state = reset to closed
      _status = CircuitBreakerStatus.closed;
      _failureCount = 0;
      _lastFailureTime = null;
      LoggerAdapter().i('✅ Circuit breaker CLOSED for $operationName (service recovered)');
    }
  }

  /// Record failed operation
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= ConnectivityService.circuitBreakerThreshold) {
      if (_status != CircuitBreakerStatus.open) {
        _status = CircuitBreakerStatus.open;
        LoggerAdapter().w('⚠️ Circuit breaker OPEN for $operationName ($_failureCount consecutive failures)');
      }
    }
  }

  /// Check if should attempt reset
  bool shouldAttemptReset() {
    if (_status != CircuitBreakerStatus.open) return false;
    if (_lastFailureTime == null) return false;

    final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
    return timeSinceFailure >= ConnectivityService.circuitBreakerTimeout;
  }

  /// Move to half-open state (testing)
  void halfOpen() {
    _status = CircuitBreakerStatus.halfOpen;
    LoggerAdapter().i('🔄 Circuit breaker HALF-OPEN for $operationName (testing service)');
  }

  /// Get time until reset attempt
  Duration timeUntilReset() {
    if (_lastFailureTime == null) return Duration.zero;

    final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
    final remaining = ConnectivityService.circuitBreakerTimeout - timeSinceFailure;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get metrics as map
  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'status': _status.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'timeUntilReset': timeUntilReset().inSeconds,
    };
  }
}

/// Circuit Breaker Status
enum CircuitBreakerStatus {
  closed,   // Normal operation
  open,     // Blocking requests
  halfOpen, // Testing recovery
}

/// ⚡ FASE 3: Circuit Breaker Open Exception
class CircuitBreakerOpenException implements Exception {
  final String operationName;
  final Duration retryAfter;

  CircuitBreakerOpenException(this.operationName, this.retryAfter);

  @override
  String toString() =>
      'CircuitBreakerOpenException: $operationName is unavailable, retry after ${retryAfter.inSeconds}s';
}
