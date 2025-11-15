/// Person entity from census data
/// Represents an individual from the indigenous community census
class Person {
  final String personId;
  final String fullName;
  final String firstName;
  final String lastName;
  final String? birthdate;
  final String? documentNumber; // Número de documento/identificación
  final String? familyId; // OPCIONAL - muchos registros no tienen familia asignada
  final int requiredDocumentsCount;
  final List<String> requiredDocuments;

  const Person({
    required this.personId,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    this.birthdate,
    this.documentNumber,
    this.familyId, // OPCIONAL - no es required
    required this.requiredDocumentsCount,
    required this.requiredDocuments,
  });

  /// Create Person from CSV row
  factory Person.fromCsvRow(Map<String, dynamic> row) {
    final requiredDocsString = row['required_documents'] as String? ?? '';
    final requiredDocs = requiredDocsString.isNotEmpty
        ? requiredDocsString.split(',')
        : <String>[];

    // Use 'last_name' column directly from CSV
    // (CSV has single 'last_name' column, not 'first_lastname'/'second_lastname')
    final lastName = row['last_name']?.toString() ?? '';

    return Person(
      personId: row['person_id']?.toString() ?? '',
      fullName: row['full_name']?.toString() ?? '',
      firstName: row['first_name']?.toString() ?? '',
      lastName: lastName,
      birthdate: row['birthdate']?.toString(),
      documentNumber: row['document_number']?.toString() ?? row['num_doc']?.toString(),
      familyId: row['family_id']?.toString() ?? '',
      requiredDocumentsCount: int.tryParse(
            row['required_documents_count']?.toString() ?? '0',
          ) ??
          0,
      requiredDocuments: requiredDocs,
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'person_id': personId,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'birthdate': birthdate,
      'document_number': documentNumber,
      'family_id': familyId,
      'required_documents_count': requiredDocumentsCount,
      'required_documents': requiredDocuments,
    };
  }

  /// Create copy with updated fields
  Person copyWith({
    String? personId,
    String? fullName,
    String? firstName,
    String? lastName,
    String? birthdate,
    String? documentNumber,
    String? familyId,
    int? requiredDocumentsCount,
    List<String>? requiredDocuments,
  }) {
    return Person(
      personId: personId ?? this.personId,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthdate: birthdate ?? this.birthdate,
      documentNumber: documentNumber ?? this.documentNumber,
      familyId: familyId ?? this.familyId,
      requiredDocumentsCount:
          requiredDocumentsCount ?? this.requiredDocumentsCount,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
    );
  }

  @override
  String toString() {
    return 'Person(id: $personId, name: $fullName, family: $familyId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Person && other.personId == personId;
  }

  @override
  int get hashCode => personId.hashCode;
}
