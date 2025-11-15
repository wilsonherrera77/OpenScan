/// Person Assignment Entity
/// Represents an assignment of persons to a digitizer
class PersonAssignment {
  final int id;
  final int digitizerId;
  final String digitizerName;
  final String personId;
  final String personName;
  final String? familyId;
  final AssignmentStatus status;
  final int requiredDocuments;
  final int digitizedDocuments;
  final int? assignedById;
  final String? assignedByName;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;

  PersonAssignment({
    required this.id,
    required this.digitizerId,
    required this.digitizerName,
    required this.personId,
    required this.personName,
    this.familyId,
    required this.status,
    required this.requiredDocuments,
    required this.digitizedDocuments,
    this.assignedById,
    this.assignedByName,
    required this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  factory PersonAssignment.fromJson(Map<String, dynamic> json) {
    return PersonAssignment(
      id: json['id'],
      digitizerId: json['digitizer'],
      digitizerName: json['digitizer_name'] ?? '',
      personId: json['person_id'],
      personName: json['person_name'],
      familyId: json['family_id'],
      status: AssignmentStatus.fromString(json['status']),
      requiredDocuments: json['required_documents'] ?? 0,
      digitizedDocuments: json['digitized_documents'] ?? 0,
      assignedById: json['assigned_by'],
      assignedByName: json['assigned_by_name'],
      assignedAt: DateTime.parse(json['assigned_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'digitizer': digitizerId,
      'digitizer_name': digitizerName,
      'person_id': personId,
      'person_name': personName,
      'family_id': familyId,
      'status': status.value,
      'required_documents': requiredDocuments,
      'digitized_documents': digitizedDocuments,
      'assigned_by': assignedById,
      'assigned_by_name': assignedByName,
      'assigned_at': assignedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Calculate progress percentage
  int get progressPercentage {
    if (requiredDocuments == 0) return 0;
    return ((digitizedDocuments / requiredDocuments) * 100).round();
  }

  /// Check if assignment is pending
  bool get isPending => status == AssignmentStatus.pending;

  /// Check if assignment is in progress
  bool get isInProgress => status == AssignmentStatus.inProgress;

  /// Check if assignment is completed
  bool get isCompleted => status == AssignmentStatus.completed;

  /// Check if assignment is reviewed
  bool get isReviewed => status == AssignmentStatus.reviewed;

  /// Get color for status
  String get statusColor {
    switch (status) {
      case AssignmentStatus.pending:
        return 'grey';
      case AssignmentStatus.inProgress:
        return 'blue';
      case AssignmentStatus.completed:
        return 'green';
      case AssignmentStatus.reviewed:
        return 'purple';
    }
  }
}

/// Assignment Status Enum
enum AssignmentStatus {
  pending,
  inProgress,
  completed,
  reviewed;

  String get value {
    switch (this) {
      case AssignmentStatus.pending:
        return 'PENDING';
      case AssignmentStatus.inProgress:
        return 'IN_PROGRESS';
      case AssignmentStatus.completed:
        return 'COMPLETED';
      case AssignmentStatus.reviewed:
        return 'REVIEWED';
    }
  }

  String get label {
    switch (this) {
      case AssignmentStatus.pending:
        return 'Pendiente';
      case AssignmentStatus.inProgress:
        return 'En Progreso';
      case AssignmentStatus.completed:
        return 'Completado';
      case AssignmentStatus.reviewed:
        return 'Revisado';
    }
  }

  static AssignmentStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return AssignmentStatus.pending;
      case 'IN_PROGRESS':
        return AssignmentStatus.inProgress;
      case 'COMPLETED':
        return AssignmentStatus.completed;
      case 'REVIEWED':
        return AssignmentStatus.reviewed;
      default:
        return AssignmentStatus.pending;
    }
  }
}

/// Productivity Metrics Entity
class ProductivityMetrics {
  final int totalDocuments;
  final int totalPersons;
  final double avgQualityScore;
  final double ocrLocalPercentage;
  final double totalTimeHours;
  final double documentsPerHour;

  ProductivityMetrics({
    required this.totalDocuments,
    required this.totalPersons,
    required this.avgQualityScore,
    required this.ocrLocalPercentage,
    required this.totalTimeHours,
    required this.documentsPerHour,
  });

  factory ProductivityMetrics.fromJson(Map<String, dynamic> json) {
    return ProductivityMetrics(
      totalDocuments: json['total_documents'] ?? 0,
      totalPersons: json['total_persons'] ?? 0,
      avgQualityScore: (json['avg_quality_score'] ?? 0).toDouble(),
      ocrLocalPercentage: (json['ocr_local_percentage'] ?? 0).toDouble(),
      totalTimeHours: (json['total_time_hours'] ?? 0).toDouble(),
      documentsPerHour: (json['documents_per_hour'] ?? 0).toDouble(),
    );
  }
}

/// Team Statistics Entity
class TeamStatistics {
  final int totalDigitizers;
  final int totalAssignments;
  final int completedAssignments;
  final int inProgressAssignments;
  final int pendingAssignments;
  final double completionPercentage;
  final int totalDocumentsToday;
  final int totalDocumentsWeek;
  final int totalDocumentsMonth;
  final List<TopDigitizer> topDigitizers;

  TeamStatistics({
    required this.totalDigitizers,
    required this.totalAssignments,
    required this.completedAssignments,
    required this.inProgressAssignments,
    required this.pendingAssignments,
    required this.completionPercentage,
    required this.totalDocumentsToday,
    required this.totalDocumentsWeek,
    required this.totalDocumentsMonth,
    required this.topDigitizers,
  });

  factory TeamStatistics.fromJson(Map<String, dynamic> json) {
    return TeamStatistics(
      totalDigitizers: json['total_digitizers'] ?? 0,
      totalAssignments: json['total_assignments'] ?? 0,
      completedAssignments: json['completed_assignments'] ?? 0,
      inProgressAssignments: json['in_progress_assignments'] ?? 0,
      pendingAssignments: json['pending_assignments'] ?? 0,
      completionPercentage: (json['completion_percentage'] ?? 0).toDouble(),
      totalDocumentsToday: json['total_documents_today'] ?? 0,
      totalDocumentsWeek: json['total_documents_week'] ?? 0,
      totalDocumentsMonth: json['total_documents_month'] ?? 0,
      topDigitizers: (json['top_digitizers'] as List? ?? [])
          .map((e) => TopDigitizer.fromJson(e))
          .toList(),
    );
  }
}

/// Top Digitizer Entity
class TopDigitizer {
  final String username;
  final int count;

  TopDigitizer({
    required this.username,
    required this.count,
  });

  factory TopDigitizer.fromJson(Map<String, dynamic> json) {
    return TopDigitizer(
      username: json['digitizer__username'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

/// Paginated Response Entity
/// Generic wrapper for paginated API responses
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Check if there are more pages
  bool get hasNextPage => next != null && next!.isNotEmpty;

  /// Check if there are previous pages
  bool get hasPreviousPage => previous != null && previous!.isNotEmpty;

  /// Get current page number from URL
  int get currentPage {
    if (next != null) {
      final uri = Uri.tryParse(next!);
      final pageParam = uri?.queryParameters['page'];
      if (pageParam != null) {
        final nextPage = int.tryParse(pageParam);
        if (nextPage != null && nextPage > 1) {
          return nextPage - 1;
        }
      }
    }
    return 1;
  }

  /// Get total pages
  int get totalPages {
    if (count == 0 || results.isEmpty) return 0;
    final pageSize = results.length;
    return (count / pageSize).ceil();
  }
}
