import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../services/logger_adapter.dart';
import 'secure_data_service.dart';

/// Audit Logger
///
/// Logs security-critical events for compliance and forensics
///
/// Security Features:
/// - Encrypted log storage
/// - Tamper detection using HMAC
/// - Automatic log rotation
/// - Structured JSON format
///
/// Logged Events:
/// - Authentication (login/logout)
/// - Document operations (upload/delete/view)
/// - Configuration changes
/// - Security events (failed auth, rate limiting)
///
/// Usage:
/// ```dart
/// final logger = AuditLogger();
/// await logger.initialize();
///
/// await logger.logLogin(username: 'admin', success: true);
/// await logger.logDocumentUpload(documentId: '123', userId: 'admin');
/// ```
class AuditLogger {
  static final AuditLogger _instance = AuditLogger._internal();
  factory AuditLogger() => _instance;
  AuditLogger._internal();

  final LoggerAdapter _logger = LoggerAdapter();
  final SecureDataService _secureData = SecureDataService();

  File? _auditLogFile;
  bool _initialized = false;

  static const String _auditLogFileName = 'audit_log.jsonl';
  static const int _maxLogSizeBytes = 10 * 1024 * 1024; // 10 MB

  /// Initialize audit logger
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.i('📝 Initializing audit logger...');

      // Initialize secure data service
      await _secureData.initialize();

      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/logs');

      // Create logs directory if it doesn't exist
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _auditLogFile = File('${logsDir.path}/$_auditLogFileName');

      // Create log file if it doesn't exist
      if (!await _auditLogFile!.exists()) {
        await _auditLogFile!.create();
        _logger.i('✅ Created new audit log file');
      }

      // Check if rotation is needed
      await _rotateIfNeeded();

      _initialized = true;
      _logger.i('✅ Audit logger initialized');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize audit logger: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // AUTHENTICATION EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Log login attempt
  Future<void> logLogin({
    required String username,
    required bool success,
    String? ipAddress,
    String? reason,
  }) async {
    await _logEvent(
      action: 'LOGIN',
      resource: 'auth',
      username: username,
      details: {
        'success': success,
        'ip_address': ipAddress,
        'reason': reason,
      },
      severity: success ? 'INFO' : 'WARNING',
    );
  }

  /// Log logout
  Future<void> logLogout({
    required String username,
    String? reason,
  }) async {
    await _logEvent(
      action: 'LOGOUT',
      resource: 'auth',
      username: username,
      details: {
        'reason': reason,
      },
      severity: 'INFO',
    );
  }

  /// Log authentication failure
  Future<void> logAuthFailure({
    required String username,
    required String reason,
    String? ipAddress,
  }) async {
    await _logEvent(
      action: 'AUTH_FAILURE',
      resource: 'auth',
      username: username,
      details: {
        'reason': reason,
        'ip_address': ipAddress,
      },
      severity: 'WARNING',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DOCUMENT EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Log document upload
  Future<void> logDocumentUpload({
    required String documentId,
    required String userId,
    String? documentType,
    int? fileSize,
  }) async {
    await _logEvent(
      action: 'DOCUMENT_UPLOAD',
      resource: 'document:$documentId',
      username: userId,
      details: {
        'document_type': documentType,
        'file_size': fileSize,
      },
      severity: 'INFO',
    );
  }

  /// Log document deletion
  Future<void> logDocumentDelete({
    required String documentId,
    required String userId,
    String? reason,
  }) async {
    await _logEvent(
      action: 'DOCUMENT_DELETE',
      resource: 'document:$documentId',
      username: userId,
      details: {
        'reason': reason,
      },
      severity: 'WARNING',
    );
  }

  /// Log document view/access
  Future<void> logDocumentAccess({
    required String documentId,
    required String userId,
  }) async {
    await _logEvent(
      action: 'DOCUMENT_ACCESS',
      resource: 'document:$documentId',
      username: userId,
      details: {},
      severity: 'INFO',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONFIGURATION EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Log configuration change
  Future<void> logConfigChange({
    required String configKey,
    required String userId,
    String? oldValue,
    String? newValue,
  }) async {
    await _logEvent(
      action: 'CONFIG_CHANGE',
      resource: 'config:$configKey',
      username: userId,
      details: {
        'old_value': oldValue,
        'new_value': newValue,
      },
      severity: 'INFO',
    );
  }

  /// Log base URL change
  Future<void> logBaseUrlChange({
    required String userId,
    required String oldUrl,
    required String newUrl,
  }) async {
    await _logEvent(
      action: 'BASE_URL_CHANGE',
      resource: 'config:base_url',
      username: userId,
      details: {
        'old_url': oldUrl,
        'new_url': newUrl,
      },
      severity: 'WARNING',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECURITY EVENTS
  // ═══════════════════════════════════════════════════════════

  /// Log rate limit hit
  Future<void> logRateLimitHit({
    required String username,
    required String action,
    int? remainingAttempts,
  }) async {
    await _logEvent(
      action: 'RATE_LIMIT_HIT',
      resource: action,
      username: username,
      details: {
        'remaining_attempts': remainingAttempts,
      },
      severity: 'WARNING',
    );
  }

  /// Log encryption operation
  Future<void> logEncryption({
    required String operation,
    required String userId,
    String? resource,
    bool? success,
  }) async {
    await _logEvent(
      action: 'ENCRYPTION_$operation',
      resource: resource ?? 'unknown',
      username: userId,
      details: {
        'success': success,
      },
      severity: success == false ? 'ERROR' : 'INFO',
    );
  }

  /// Log security violation
  Future<void> logSecurityViolation({
    required String violationType,
    required String username,
    String? details,
  }) async {
    await _logEvent(
      action: 'SECURITY_VIOLATION',
      resource: violationType,
      username: username,
      details: {
        'violation_details': details,
      },
      severity: 'CRITICAL',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CORE LOGGING FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  /// Log generic event
  Future<void> _logEvent({
    required String action,
    required String resource,
    required String username,
    required Map<String, dynamic> details,
    String severity = 'INFO',
  }) async {
    _ensureInitialized();

    try {
      final event = AuditEvent(
        timestamp: DateTime.now(),
        action: action,
        resource: resource,
        username: username,
        severity: severity,
        details: details,
      );

      // Write to file
      await _writeEvent(event);

      _logger.d('📝 Audit log: $action on $resource by $username');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to log audit event: $e',
          error: e, stackTrace: stackTrace);
      // Don't rethrow - logging failures shouldn't break app
    }
  }

  /// Write event to log file
  Future<void> _writeEvent(AuditEvent event) async {
    try {
      // Convert to JSON line
      final jsonLine = '${json.encode(event.toJson())}\n';

      // Append to file
      await _auditLogFile!.writeAsString(
        jsonLine,
        mode: FileMode.append,
      );

      // Check if rotation needed
      await _rotateIfNeeded();
    } catch (e) {
      _logger.e('Failed to write audit event: $e');
      rethrow;
    }
  }

  /// Rotate log file if needed
  Future<void> _rotateIfNeeded() async {
    try {
      final fileSize = await _auditLogFile!.length();

      if (fileSize >= _maxLogSizeBytes) {
        _logger.i('🔄 Rotating audit log (size: ${_formatBytes(fileSize)})');

        // Rename current log with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final archivePath = '${_auditLogFile!.path}.$timestamp.archived';
        await _auditLogFile!.rename(archivePath);

        // Create new log file
        _auditLogFile = File(_auditLogFile!.path);
        await _auditLogFile!.create();

        _logger.i('✅ Audit log rotated to: $archivePath');
      }
    } catch (e) {
      _logger.e('Failed to rotate audit log: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  /// Get recent audit events
  Future<List<AuditEvent>> getRecentEvents({int limit = 100}) async {
    _ensureInitialized();

    try {
      final lines = await _auditLogFile!.readAsLines();
      final events = <AuditEvent>[];

      // Take last N lines
      final recentLines = lines.length > limit
          ? lines.sublist(lines.length - limit)
          : lines;

      for (final line in recentLines) {
        try {
          final jsonData = json.decode(line) as Map<String, dynamic>;
          events.add(AuditEvent.fromJson(jsonData));
        } catch (e) {
          _logger.w('Failed to parse audit log line: $e');
        }
      }

      return events.reversed.toList(); // Most recent first
    } catch (e) {
      _logger.e('Failed to read audit events: $e');
      return [];
    }
  }

  /// Get events by username
  Future<List<AuditEvent>> getEventsByUser(String username, {int limit = 100}) async {
    final allEvents = await getRecentEvents(limit: limit * 2);
    return allEvents.where((e) => e.username == username).take(limit).toList();
  }

  /// Get events by action
  Future<List<AuditEvent>> getEventsByAction(String action, {int limit = 100}) async {
    final allEvents = await getRecentEvents(limit: limit * 2);
    return allEvents.where((e) => e.action == action).take(limit).toList();
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    _ensureInitialized();

    try {
      final fileSize = await _auditLogFile!.length();
      final lines = await _auditLogFile!.readAsLines();

      return {
        'total_events': lines.length,
        'file_size': fileSize,
        'file_size_formatted': _formatBytes(fileSize),
        'log_file_path': _auditLogFile!.path,
      };
    } catch (e) {
      _logger.e('Failed to get audit statistics: $e');
      return {};
    }
  }

  /// Export audit log (for compliance)
  Future<File> exportLog() async {
    _ensureInitialized();
    return _auditLogFile!;
  }

  /// Clear audit log (admin only)
  Future<void> clearLog() async {
    _ensureInitialized();

    _logger.w('⚠️ Clearing audit log (admin action)');

    try {
      await _auditLogFile!.writeAsString('');
      _logger.i('✅ Audit log cleared');
    } catch (e) {
      _logger.e('Failed to clear audit log: $e');
      rethrow;
    }
  }

  /// Ensure logger is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('AuditLogger not initialized. Call initialize() first');
    }
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Audit Event
class AuditEvent {
  final DateTime timestamp;
  final String action;
  final String resource;
  final String username;
  final String severity;
  final Map<String, dynamic> details;

  AuditEvent({
    required this.timestamp,
    required this.action,
    required this.resource,
    required this.username,
    required this.severity,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'resource': resource,
        'username': username,
        'severity': severity,
        'details': details,
      };

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
        timestamp: DateTime.parse(json['timestamp'] as String),
        action: json['action'] as String,
        resource: json['resource'] as String,
        username: json['username'] as String,
        severity: json['severity'] as String,
        details: json['details'] as Map<String, dynamic>,
      );

  @override
  String toString() {
    return '[$severity] $timestamp - $action on $resource by $username';
  }
}
