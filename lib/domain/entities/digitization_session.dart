/// Digitization Session Entity
/// Tracks actual digitization sessions for accurate time metrics
class DigitizationSession {
  final int id;
  final int userId;
  final String username;
  final int? assignmentId;
  final String? assignmentPersonName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int documentsCount;
  final String? deviceInfo;
  final String? appVersion;
  final bool isActive;

  DigitizationSession({
    required this.id,
    required this.userId,
    required this.username,
    this.assignmentId,
    this.assignmentPersonName,
    required this.startedAt,
    this.endedAt,
    required this.documentsCount,
    this.deviceInfo,
    this.appVersion,
    required this.isActive,
  });

  factory DigitizationSession.fromJson(Map<String, dynamic> json) {
    return DigitizationSession(
      id: json['id'],
      userId: json['user'],
      username: json['username'] ?? '',
      assignmentId: json['assignment'],
      assignmentPersonName: json['assignment_person_name'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      documentsCount: json['documents_count'] ?? 0,
      deviceInfo: json['device_info'],
      appVersion: json['app_version'],
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'username': username,
      'assignment': assignmentId,
      'assignment_person_name': assignmentPersonName,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'documents_count': documentsCount,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'is_active': isActive,
    };
  }

  /// Calculate session duration in minutes
  double get durationMinutes {
    if (endedAt != null) {
      return endedAt!.difference(startedAt).inMinutes.toDouble();
    }
    return DateTime.now().difference(startedAt).inMinutes.toDouble();
  }

  /// Calculate average time per document
  double get avgTimePerDocument {
    if (documentsCount > 0 && endedAt != null) {
      return durationMinutes / documentsCount;
    }
    return 0.0;
  }

  /// Check if session is currently active
  bool get isRunning => isActive && endedAt == null;

  /// Format duration as human-readable string
  String get formattedDuration {
    final minutes = durationMinutes.toInt();
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours h $mins min';
    }
    return '$mins min';
  }
}

/// Session Summary Entity
/// Aggregated statistics for multiple sessions
class SessionSummary {
  final int totalSessions;
  final double totalTimeMinutes;
  final int totalDocuments;
  final double avgTimePerDocument;
  final double avgSessionDuration;

  SessionSummary({
    required this.totalSessions,
    required this.totalTimeMinutes,
    required this.totalDocuments,
    required this.avgTimePerDocument,
    required this.avgSessionDuration,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      totalSessions: json['total_sessions'] ?? 0,
      totalTimeMinutes: (json['total_time_minutes'] ?? 0).toDouble(),
      totalDocuments: json['total_documents'] ?? 0,
      avgTimePerDocument: (json['avg_time_per_document'] ?? 0).toDouble(),
      avgSessionDuration: (json['avg_session_duration'] ?? 0).toDouble(),
    );
  }

  /// Format total time as human-readable string
  String get formattedTotalTime {
    final hours = totalTimeMinutes ~/ 60;
    final minutes = (totalTimeMinutes % 60).toInt();

    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  /// Calculate documents per hour
  double get documentsPerHour {
    if (totalTimeMinutes > 0) {
      return (totalDocuments / (totalTimeMinutes / 60));
    }
    return 0.0;
  }
}
