/// Document Existence Check Result
///
/// Represents the result of checking if a document already exists for a person
/// before capturing a photo. Used for anti-duplicate detection during mass
/// digitization events.
///
/// This entity encapsulates the response from the backend's check_exists endpoint.
class DocumentExistenceCheck {
  /// Whether the document already exists
  final bool exists;

  /// Whether the document can be replaced (low quality or missing data)
  /// Only present when document exists
  final bool? canReplace;

  /// OCR confidence score (0.0 to 1.0)
  /// Only present when document exists
  final double? ocrConfidence;

  /// Whether minimum required data was extracted (NUIP)
  /// Only present when document exists
  final bool? hasMinimumData;

  /// Metadata of the existing document
  /// Only present when document exists
  final ExistingDocumentInfo? existingDocument;

  /// Person information
  final PersonInfo person;

  /// User-friendly message in Spanish
  final String message;

  DocumentExistenceCheck({
    required this.exists,
    this.canReplace,
    this.ocrConfidence,
    this.hasMinimumData,
    this.existingDocument,
    required this.person,
    required this.message,
  });

  /// Create from JSON response
  factory DocumentExistenceCheck.fromJson(Map<String, dynamic> json) {
    return DocumentExistenceCheck(
      exists: json['exists'] as bool,
      canReplace: json['can_replace'] as bool?,
      ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble(),
      hasMinimumData: json['has_minimum_data'] as bool?,
      existingDocument: json['existing_document'] != null
          ? ExistingDocumentInfo.fromJson(json['existing_document'] as Map<String, dynamic>)
          : null,
      person: PersonInfo.fromJson(json['person'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      if (canReplace != null) 'can_replace': canReplace,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
      if (hasMinimumData != null) 'has_minimum_data': hasMinimumData,
      if (existingDocument != null) 'existing_document': existingDocument!.toJson(),
      'person': person.toJson(),
      'message': message,
    };
  }

  /// Get OCR quality as percentage (0-100)
  int? get ocrQualityPercentage {
    if (ocrConfidence == null) return null;
    return (ocrConfidence! * 100).round();
  }

  /// Whether document exists with GOOD quality (cannot replace)
  bool get existsWithGoodQuality {
    return exists && (canReplace == false);
  }

  /// Whether document exists with LOW quality (can replace)
  bool get existsWithLowQuality {
    return exists && (canReplace == true);
  }

  @override
  String toString() {
    return 'DocumentExistenceCheck(exists: $exists, canReplace: $canReplace, '
        'ocrConfidence: ${ocrQualityPercentage}%, person: ${person.name})';
  }
}

/// Existing Document Information
class ExistingDocumentInfo {
  final int id;
  final String title;
  final DateTime createdAt;
  final String digitizedBy;
  final String? digitizedByUsername;
  final String? nuipExtracted;
  final bool needsReview;

  ExistingDocumentInfo({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.digitizedBy,
    this.digitizedByUsername,
    this.nuipExtracted,
    required this.needsReview,
  });

  factory ExistingDocumentInfo.fromJson(Map<String, dynamic> json) {
    return ExistingDocumentInfo(
      id: json['id'] as int,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      digitizedBy: json['digitized_by'] as String? ?? 'Desconocido',
      digitizedByUsername: json['digitized_by_username'] as String?,
      nuipExtracted: json['nuip_extracted'] as String?,
      needsReview: json['needs_review'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'digitized_by': digitizedBy,
      if (digitizedByUsername != null) 'digitized_by_username': digitizedByUsername,
      if (nuipExtracted != null) 'nuip_extracted': nuipExtracted,
      'needs_review': needsReview,
    };
  }

  /// Get formatted creation date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} '
           '${createdAt.hour.toString().padLeft(2, '0')}:'
           '${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

/// Person Information
class PersonInfo {
  final String id;
  final String name;
  final String nuip;

  PersonInfo({
    required this.id,
    required this.name,
    required this.nuip,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      id: json['id'].toString(),
      name: json['name'] as String,
      nuip: json['nuip'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nuip': nuip,
    };
  }
}
