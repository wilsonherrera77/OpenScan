import '../../services/logger_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Analytics Service
/// Tracks app usage metrics locally (privacy-first, no external tracking)
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final LoggerAdapter _logger = LoggerAdapter();
  static const String _analyticsKey = 'app_analytics';

  // Event types
  static const String eventAppOpened = 'app_opened';
  static const String eventLogin = 'login';
  static const String eventLogout = 'logout';
  static const String eventDocumentScanned = 'document_scanned';
  static const String eventDocumentUploaded = 'document_uploaded';
  static const String eventUploadFailed = 'upload_failed';
  static const String eventPersonSelected = 'person_selected';
  static const String eventOfflineQueuedUpload = 'offline_queued_upload';
  static const String eventBackgroundSync = 'background_sync';

  /// Track an event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      _logger.d('📊 Analytics: $eventName ${properties != null ? json.encode(properties) : ''}');

      final event = AnalyticsEvent(
        name: eventName,
        timestamp: DateTime.now(),
        properties: properties ?? {},
      );

      await _saveEvent(event);
    } catch (e) {
      _logger.e('Failed to track event: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreen(String screenName) async {
    await trackEvent('screen_view', properties: {'screen_name': screenName});
  }

  /// Track error
  Future<void> trackError(
    String error, {
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      'error',
      properties: {
        'error': error,
        if (stackTrace != null) 'stack_trace': stackTrace,
        if (context != null) ...context,
      },
    );
  }

  /// Track timing (for performance metrics)
  Future<void> trackTiming(
    String category,
    String variable,
    Duration duration, {
    String? label,
  }) async {
    await trackEvent(
      'timing',
      properties: {
        'category': category,
        'variable': variable,
        'duration_ms': duration.inMilliseconds,
        if (label != null) 'label': label,
      },
    );
  }

  /// Get analytics summary
  Future<AnalyticsSummary> getSummary() async {
    try {
      final events = await _getAllEvents();

      final totalEvents = events.length;
      final appOpens = events.where((e) => e.name == eventAppOpened).length;
      final documentsScanned = events.where((e) => e.name == eventDocumentScanned).length;
      final documentsUploaded = events.where((e) => e.name == eventDocumentUploaded).length;
      final uploadsFailed = events.where((e) => e.name == eventUploadFailed).length;
      final offlineQueued = events.where((e) => e.name == eventOfflineQueuedUpload).length;

      final firstEventTime = events.isNotEmpty ? events.first.timestamp : null;
      final lastEventTime = events.isNotEmpty ? events.last.timestamp : null;

      return AnalyticsSummary(
        totalEvents: totalEvents,
        appOpens: appOpens,
        documentsScanned: documentsScanned,
        documentsUploaded: documentsUploaded,
        uploadsFailed: uploadsFailed,
        offlineQueued: offlineQueued,
        firstEventTime: firstEventTime,
        lastEventTime: lastEventTime,
      );
    } catch (e) {
      _logger.e('Failed to get analytics summary: $e');
      return AnalyticsSummary.empty();
    }
  }

  /// Get events for a specific time range
  Future<List<AnalyticsEvent>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventName,
  }) async {
    try {
      var events = await _getAllEvents();

      if (startDate != null) {
        events = events.where((e) => e.timestamp.isAfter(startDate)).toList();
      }

      if (endDate != null) {
        events = events.where((e) => e.timestamp.isBefore(endDate)).toList();
      }

      if (eventName != null) {
        events = events.where((e) => e.name == eventName).toList();
      }

      return events;
    } catch (e) {
      _logger.e('Failed to get events: $e');
      return [];
    }
  }

  /// Clear all analytics data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_analyticsKey);
      _logger.i('🗑️ Analytics data cleared');
    } catch (e) {
      _logger.e('Failed to clear analytics: $e');
    }
  }

  /// Save event to local storage
  Future<void> _saveEvent(AnalyticsEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_analyticsKey) ?? '[]';
      final events = (json.decode(eventsJson) as List)
          .map((e) => AnalyticsEvent.fromJson(e as Map<String, dynamic>))
          .toList();

      events.add(event);

      // Keep only last 1000 events to avoid storage issues
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }

      await prefs.setString(
        _analyticsKey,
        json.encode(events.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      _logger.e('Failed to save event: $e');
    }
  }

  /// Get all events from local storage
  Future<List<AnalyticsEvent>> _getAllEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_analyticsKey) ?? '[]';
      return (json.decode(eventsJson) as List)
          .map((e) => AnalyticsEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Failed to get events: $e');
      return [];
    }
  }
}

/// Analytics Event Model
class AnalyticsEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  AnalyticsEvent({
    required this.name,
    required this.timestamp,
    required this.properties,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        'properties': properties,
      };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
        name: json['name'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        properties: json['properties'] as Map<String, dynamic>? ?? {},
      );
}

/// Analytics Summary Model
class AnalyticsSummary {
  final int totalEvents;
  final int appOpens;
  final int documentsScanned;
  final int documentsUploaded;
  final int uploadsFailed;
  final int offlineQueued;
  final DateTime? firstEventTime;
  final DateTime? lastEventTime;

  AnalyticsSummary({
    required this.totalEvents,
    required this.appOpens,
    required this.documentsScanned,
    required this.documentsUploaded,
    required this.uploadsFailed,
    required this.offlineQueued,
    this.firstEventTime,
    this.lastEventTime,
  });

  factory AnalyticsSummary.empty() => AnalyticsSummary(
        totalEvents: 0,
        appOpens: 0,
        documentsScanned: 0,
        documentsUploaded: 0,
        uploadsFailed: 0,
        offlineQueued: 0,
      );

  double get uploadSuccessRate {
    final total = documentsUploaded + uploadsFailed;
    if (total == 0) return 0.0;
    return (documentsUploaded / total) * 100;
  }
}
