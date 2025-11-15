import '../../services/logger_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Performance Monitor
/// Tracks app performance metrics for optimization
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final LoggerAdapter _logger = LoggerAdapter();
  static const String _metricsKey = 'performance_metrics';
  static const int _maxStoredMetrics = 500;

  final Map<String, DateTime> _operationStartTimes = {};

  /// Start tracking an operation
  void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    _logger.d('⏱️ Started: $operationId');
  }

  /// End tracking and record metrics
  Future<void> endOperation(
    String operationId, {
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = _operationStartTimes[operationId];
    if (startTime == null) {
      _logger.w('Operation $operationId was not started');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _operationStartTimes.remove(operationId);

    _logger.d('⏱️ Completed: $operationId in ${duration.inMilliseconds}ms');

    await _recordMetric(
      PerformanceMetric(
        operation: operationId,
        durationMs: duration.inMilliseconds,
        timestamp: DateTime.now(),
        metadata: metadata,
      ),
    );
  }

  /// Track a completed operation with duration
  Future<void> trackOperation(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) async {
    await _recordMetric(
      PerformanceMetric(
        operation: operation,
        durationMs: duration.inMilliseconds,
        timestamp: DateTime.now(),
        metadata: metadata,
      ),
    );
  }

  /// Execute and track an operation
  Future<T> track<T>(
    String operationId,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();
    try {
      final result = await operation();
      final duration = DateTime.now().difference(startTime);

      await _recordMetric(
        PerformanceMetric(
          operation: operationId,
          durationMs: duration.inMilliseconds,
          timestamp: DateTime.now(),
          metadata: metadata,
          success: true,
        ),
      );

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      await _recordMetric(
        PerformanceMetric(
          operation: operationId,
          durationMs: duration.inMilliseconds,
          timestamp: DateTime.now(),
          metadata: metadata,
          success: false,
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  /// Get performance statistics for an operation
  Future<OperationStats> getOperationStats(String operation) async {
    try {
      final metrics = await getMetrics(operation: operation);

      if (metrics.isEmpty) {
        return OperationStats.empty(operation);
      }

      final durations = metrics.map((m) => m.durationMs).toList();
      durations.sort();

      final sum = durations.reduce((a, b) => a + b);
      final avg = sum / durations.length;
      final min = durations.first;
      final max = durations.last;
      final p50 = durations[durations.length ~/ 2];
      final p95 = durations[(durations.length * 0.95).toInt()];
      final p99 = durations[(durations.length * 0.99).toInt()];

      final successCount = metrics.where((m) => m.success).length;
      final failCount = metrics.length - successCount;

      return OperationStats(
        operation: operation,
        count: metrics.length,
        avgDurationMs: avg.toInt(),
        minDurationMs: min,
        maxDurationMs: max,
        p50DurationMs: p50,
        p95DurationMs: p95,
        p99DurationMs: p99,
        successCount: successCount,
        failCount: failCount,
        lastRun: metrics.first.timestamp,
      );
    } catch (e) {
      _logger.e('Failed to get operation stats: $e');
      return OperationStats.empty(operation);
    }
  }

  /// Get all performance metrics
  Future<List<PerformanceMetric>> getMetrics({
    String? operation,
    DateTime? since,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString(_metricsKey) ?? '[]';
      var metrics = (json.decode(metricsJson) as List)
          .map((e) => PerformanceMetric.fromJson(e as Map<String, dynamic>))
          .toList();

      if (operation != null) {
        metrics = metrics.where((m) => m.operation == operation).toList();
      }

      if (since != null) {
        metrics = metrics.where((m) => m.timestamp.isAfter(since)).toList();
      }

      metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return metrics;
    } catch (e) {
      _logger.e('Failed to get metrics: $e');
      return [];
    }
  }

  /// Get performance summary
  Future<PerformanceSummary> getSummary() async {
    try {
      final metrics = await getMetrics();
      final now = DateTime.now();
      final last24h = now.subtract(const Duration(hours: 24));

      final metricsLast24h = metrics.where((m) => m.timestamp.isAfter(last24h)).toList();

      final operations = <String>{};
      for (final metric in metricsLast24h) {
        operations.add(metric.operation);
      }

      final slowOperations = <String>[];
      for (final op in operations) {
        final stats = await getOperationStats(op);
        if (stats.avgDurationMs > 1000) {
          // Slower than 1 second
          slowOperations.add(op);
        }
      }

      return PerformanceSummary(
        totalOperations: metricsLast24h.length,
        uniqueOperations: operations.length,
        slowOperations: slowOperations,
        avgResponseTime: metricsLast24h.isNotEmpty
            ? metricsLast24h.map((m) => m.durationMs).reduce((a, b) => a + b) /
                metricsLast24h.length
            : 0,
      );
    } catch (e) {
      _logger.e('Failed to get performance summary: $e');
      return PerformanceSummary.empty();
    }
  }

  /// Clear all metrics
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metricsKey);
      _logger.i('🗑️ All performance metrics cleared');
    } catch (e) {
      _logger.e('Failed to clear metrics: $e');
    }
  }

  /// Record a performance metric
  Future<void> _recordMetric(PerformanceMetric metric) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString(_metricsKey) ?? '[]';
      final metrics = (json.decode(metricsJson) as List)
          .map((e) => PerformanceMetric.fromJson(e as Map<String, dynamic>))
          .toList();

      metrics.add(metric);

      // Keep only recent metrics
      if (metrics.length > _maxStoredMetrics) {
        metrics.removeRange(0, metrics.length - _maxStoredMetrics);
      }

      await prefs.setString(
        _metricsKey,
        json.encode(metrics.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      _logger.e('Failed to record metric: $e');
    }
  }
}

/// Performance Metric Model
class PerformanceMetric {
  final String operation;
  final int durationMs;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool success;
  final String? error;

  PerformanceMetric({
    required this.operation,
    required this.durationMs,
    required this.timestamp,
    this.metadata,
    this.success = true,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'operation': operation,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
        'success': success,
        if (error != null) 'error': error,
      };

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) =>
      PerformanceMetric(
        operation: json['operation'] as String,
        durationMs: json['duration_ms'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
        success: json['success'] as bool? ?? true,
        error: json['error'] as String?,
      );
}

/// Operation Statistics Model
class OperationStats {
  final String operation;
  final int count;
  final int avgDurationMs;
  final int minDurationMs;
  final int maxDurationMs;
  final int p50DurationMs;
  final int p95DurationMs;
  final int p99DurationMs;
  final int successCount;
  final int failCount;
  final DateTime? lastRun;

  OperationStats({
    required this.operation,
    required this.count,
    required this.avgDurationMs,
    required this.minDurationMs,
    required this.maxDurationMs,
    required this.p50DurationMs,
    required this.p95DurationMs,
    required this.p99DurationMs,
    required this.successCount,
    required this.failCount,
    this.lastRun,
  });

  factory OperationStats.empty(String operation) => OperationStats(
        operation: operation,
        count: 0,
        avgDurationMs: 0,
        minDurationMs: 0,
        maxDurationMs: 0,
        p50DurationMs: 0,
        p95DurationMs: 0,
        p99DurationMs: 0,
        successCount: 0,
        failCount: 0,
      );

  double get successRate {
    if (count == 0) return 0.0;
    return (successCount / count) * 100;
  }

  bool get isHealthy => successRate >= 95 && avgDurationMs < 2000;
}

/// Performance Summary Model
class PerformanceSummary {
  final int totalOperations;
  final int uniqueOperations;
  final List<String> slowOperations;
  final double avgResponseTime;

  PerformanceSummary({
    required this.totalOperations,
    required this.uniqueOperations,
    required this.slowOperations,
    required this.avgResponseTime,
  });

  factory PerformanceSummary.empty() => PerformanceSummary(
        totalOperations: 0,
        uniqueOperations: 0,
        slowOperations: [],
        avgResponseTime: 0,
      );

  bool get isHealthy => slowOperations.isEmpty && avgResponseTime < 1000;
}
