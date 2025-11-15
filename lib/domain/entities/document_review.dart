/// Document Review Entity
/// Represents a review/approval of a completed assignment
class DocumentReview {
  final int id;
  final int assignmentId;
  final String assignmentPersonName;
  final String assignmentDigitizer;
  final int reviewerId;
  final String reviewerUsername;
  final ReviewStatus status;
  final int? qualityScore;
  final String? feedback;
  final String? issuesFound;
  final DateTime reviewedAt;
  final DateTime updatedAt;

  DocumentReview({
    required this.id,
    required this.assignmentId,
    required this.assignmentPersonName,
    required this.assignmentDigitizer,
    required this.reviewerId,
    required this.reviewerUsername,
    required this.status,
    this.qualityScore,
    this.feedback,
    this.issuesFound,
    required this.reviewedAt,
    required this.updatedAt,
  });

  factory DocumentReview.fromJson(Map<String, dynamic> json) {
    return DocumentReview(
      id: json['id'],
      assignmentId: json['assignment'],
      assignmentPersonName: json['assignment_person_name'] ?? '',
      assignmentDigitizer: json['assignment_digitizer'] ?? '',
      reviewerId: json['reviewer'],
      reviewerUsername: json['reviewer_username'] ?? '',
      status: ReviewStatus.fromString(json['status']),
      qualityScore: json['quality_score'],
      feedback: json['feedback'],
      issuesFound: json['issues_found'],
      reviewedAt: DateTime.parse(json['reviewed_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment': assignmentId,
      'assignment_person_name': assignmentPersonName,
      'assignment_digitizer': assignmentDigitizer,
      'reviewer': reviewerId,
      'reviewer_username': reviewerUsername,
      'status': status.value,
      'quality_score': qualityScore,
      'feedback': feedback,
      'issues_found': issuesFound,
      'reviewed_at': reviewedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if review is pending
  bool get isPending => status == ReviewStatus.pending;

  /// Check if review is approved
  bool get isApproved => status == ReviewStatus.approved;

  /// Check if review is rejected
  bool get isRejected => status == ReviewStatus.rejected;

  /// Check if needs revision
  bool get needsRevision => status == ReviewStatus.needsRevision;

  /// Get quality rating (1-5 stars)
  int get qualityRating {
    if (qualityScore == null) return 0;
    return ((qualityScore! / 100) * 5).round();
  }

  /// Get quality level description
  String get qualityLevel {
    if (qualityScore == null) return 'Sin calificar';
    if (qualityScore! >= 90) return 'Excelente';
    if (qualityScore! >= 75) return 'Bueno';
    if (qualityScore! >= 60) return 'Aceptable';
    if (qualityScore! >= 40) return 'Necesita mejora';
    return 'Deficiente';
  }
}

/// Review Status Enum
enum ReviewStatus {
  pending,
  approved,
  rejected,
  needsRevision;

  String get value {
    switch (this) {
      case ReviewStatus.pending:
        return 'PENDING';
      case ReviewStatus.approved:
        return 'APPROVED';
      case ReviewStatus.rejected:
        return 'REJECTED';
      case ReviewStatus.needsRevision:
        return 'NEEDS_REVISION';
    }
  }

  String get label {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pendiente';
      case ReviewStatus.approved:
        return 'Aprobado';
      case ReviewStatus.rejected:
        return 'Rechazado';
      case ReviewStatus.needsRevision:
        return 'Necesita Revisión';
    }
  }

  static ReviewStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return ReviewStatus.pending;
      case 'APPROVED':
        return ReviewStatus.approved;
      case 'REJECTED':
        return ReviewStatus.rejected;
      case 'NEEDS_REVISION':
        return ReviewStatus.needsRevision;
      default:
        return ReviewStatus.pending;
    }
  }
}

/// Review Request Entity
/// Data structure for creating/updating reviews
class ReviewRequest {
  final int assignmentId;
  final int? qualityScore;
  final String? feedback;
  final String? issuesFound;

  ReviewRequest({
    required this.assignmentId,
    this.qualityScore,
    this.feedback,
    this.issuesFound,
  });

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (feedback != null && feedback!.isNotEmpty) 'feedback': feedback,
      if (issuesFound != null && issuesFound!.isNotEmpty) 'issues_found': issuesFound,
    };
  }

  /// Validate review data
  bool get isValid {
    // Quality score must be between 1-100 if provided
    if (qualityScore != null && (qualityScore! < 1 || qualityScore! > 100)) {
      return false;
    }
    return true;
  }
}
