import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/logger_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Error Reporter
/// Captures and reports errors for monitoring and debugging
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();
  factory ErrorReporter() => _instance;
  ErrorReporter._internal();

  final LoggerAdapter _logger = LoggerAdapter();
  static const String _errorsKey = 'error_reports';
  static const int _maxStoredErrors = 100;

  /// Initialize error reporting
  /// Call this early in main()
  static void initialize() {
    // Catch all Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorReporter().reportFlutterError(details);
    };

    // Catch all Dart errors
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorReporter().reportError(error, stack);
      return true;
    };
  }

  /// Report a Flutter framework error
  Future<void> reportFlutterError(FlutterErrorDetails details) async {
    try {
      _logger.e(
        '❌ Flutter Error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );

      await _storeError(
        ErrorReport(
          type: 'FlutterError',
          message: details.exceptionAsString(),
          stackTrace: details.stack.toString(),
          timestamp: DateTime.now(),
          context: {
            'library': details.library ?? 'unknown',
            'context': details.context?.toString() ?? 'none',
          },
        ),
      );

      // In debug mode, show error in console
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    } catch (e) {
      _logger.e('Failed to report Flutter error: $e');
    }
  }

  /// Report a generic Dart error
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    try {
      _logger.e(
        '❌ Error: $error',
        error: error,
        stackTrace: stackTrace,
      );

      await _storeError(
        ErrorReport(
          type: 'DartError',
          message: error.toString(),
          stackTrace: stackTrace?.toString() ?? 'No stack trace',
          timestamp: DateTime.now(),
          context: context,
        ),
      );
    } catch (e) {
      _logger.e('Failed to report error: $e');
    }
  }

  /// Report a caught exception with context
  Future<void> reportException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? operation,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final context = <String, dynamic>{
        if (operation != null) 'operation': operation,
        if (metadata != null) ...metadata,
      };

      _logger.e(
        '❌ Exception in $operation: $exception',
        error: exception,
        stackTrace: stackTrace,
      );

      await _storeError(
        ErrorReport(
          type: 'Exception',
          message: exception.toString(),
          stackTrace: stackTrace?.toString() ?? 'No stack trace',
          timestamp: DateTime.now(),
          context: context,
        ),
      );
    } catch (e) {
      _logger.e('Failed to report exception: $e');
    }
  }

  /// Report a network error
  Future<void> reportNetworkError(
    dynamic error, {
    String? url,
    String? method,
    int? statusCode,
  }) async {
    await reportError(
      error,
      StackTrace.current,
      context: {
        'type': 'network_error',
        if (url != null) 'url': url,
        if (method != null) 'method': method,
        if (statusCode != null) 'status_code': statusCode,
      },
    );
  }

  /// Report a database error
  Future<void> reportDatabaseError(
    dynamic error,
    StackTrace? stackTrace, {
    String? query,
    String? operation,
  }) async {
    await reportError(
      error,
      stackTrace,
      context: {
        'type': 'database_error',
        if (query != null) 'query': query,
        if (operation != null) 'operation': operation,
      },
    );
  }

  /// Get all stored error reports
  Future<List<ErrorReport>> getErrorReports({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorsJson = prefs.getString(_errorsKey) ?? '[]';
      final errors = (json.decode(errorsJson) as List)
          .map((e) => ErrorReport.fromJson(e as Map<String, dynamic>))
          .toList();

      errors.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (limit != null && errors.length > limit) {
        return errors.take(limit).toList();
      }

      return errors;
    } catch (e) {
      _logger.e('Failed to get error reports: $e');
      return [];
    }
  }

  /// Get error statistics
  Future<ErrorStatistics> getStatistics() async {
    try {
      final errors = await getErrorReports();

      final now = DateTime.now();
      final last24h = now.subtract(const Duration(hours: 24));
      final last7days = now.subtract(const Duration(days: 7));

      return ErrorStatistics(
        totalErrors: errors.length,
        errorsLast24h: errors.where((e) => e.timestamp.isAfter(last24h)).length,
        errorsLast7days: errors.where((e) => e.timestamp.isAfter(last7days)).length,
        errorsByType: _groupByType(errors),
        mostRecentError: errors.isNotEmpty ? errors.first : null,
      );
    } catch (e) {
      _logger.e('Failed to get error statistics: $e');
      return ErrorStatistics.empty();
    }
  }

  /// Clear all error reports
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorsKey);
      _logger.i('🗑️ All error reports cleared');
    } catch (e) {
      _logger.e('Failed to clear error reports: $e');
    }
  }

  /// Store error report
  Future<void> _storeError(ErrorReport error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorsJson = prefs.getString(_errorsKey) ?? '[]';
      final errors = (json.decode(errorsJson) as List)
          .map((e) => ErrorReport.fromJson(e as Map<String, dynamic>))
          .toList();

      errors.add(error);

      // Keep only the most recent errors
      if (errors.length > _maxStoredErrors) {
        errors.removeRange(0, errors.length - _maxStoredErrors);
      }

      await prefs.setString(
        _errorsKey,
        json.encode(errors.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      _logger.e('Failed to store error: $e');
    }
  }

  /// Group errors by type
  Map<String, int> _groupByType(List<ErrorReport> errors) {
    final grouped = <String, int>{};
    for (final error in errors) {
      grouped[error.type] = (grouped[error.type] ?? 0) + 1;
    }
    return grouped;
  }
}

/// Error Report Model
class ErrorReport {
  final String type;
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  ErrorReport({
    required this.type,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'stack_trace': stackTrace,
        'timestamp': timestamp.toIso8601String(),
        if (context != null) 'context': context,
      };

  factory ErrorReport.fromJson(Map<String, dynamic> json) => ErrorReport(
        type: json['type'] as String,
        message: json['message'] as String,
        stackTrace: json['stack_trace'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        context: json['context'] as Map<String, dynamic>?,
      );

  /// Get a short summary of the error
  String get summary {
    final lines = message.split('\n');
    return lines.first.trim();
  }

  /// Get time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}

/// Error Statistics Model
class ErrorStatistics {
  final int totalErrors;
  final int errorsLast24h;
  final int errorsLast7days;
  final Map<String, int> errorsByType;
  final ErrorReport? mostRecentError;

  ErrorStatistics({
    required this.totalErrors,
    required this.errorsLast24h,
    required this.errorsLast7days,
    required this.errorsByType,
    this.mostRecentError,
  });

  factory ErrorStatistics.empty() => ErrorStatistics(
        totalErrors: 0,
        errorsLast24h: 0,
        errorsLast7days: 0,
        errorsByType: {},
      );

  /// Check if app is healthy (low error rate)
  bool get isHealthy => errorsLast24h < 10;

  /// Get error rate per day (over last 7 days)
  double get errorRatePerDay {
    if (errorsLast7days == 0) return 0.0;
    return errorsLast7days / 7.0;
  }
}
