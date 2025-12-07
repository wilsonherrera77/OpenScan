import 'package:lumara_indigenas/domain/entities/person.dart';
import 'package:lumara_indigenas/domain/entities/auth_token.dart';

/// Test Fixtures
/// Predefined test data

class Fixtures {
  /// Mock Person
  static Person createMockPerson({
    String? personId,
    String? fullName,
    String? familyId,
  }) {
    return Person(
      personId: personId ?? 'P001',
      fullName: fullName ?? 'Juan Pérez',
      firstName: 'Juan',
      lastName: 'Pérez',
      familyId: familyId ?? 'F001',
      requiredDocumentsCount: 3,
      requiredDocuments: ['CEDULA', 'EPS', 'ESTUDIO'],
    );
  }

  /// Mock list of persons
  static List<Person> createMockPersons(int count) {
    return List.generate(
      count,
      (i) => Person(
        personId: 'P${(i + 1).toString().padLeft(3, '0')}',
        fullName: 'Person $i',
        firstName: 'First$i',
        lastName: 'Last$i',
        familyId: 'F${((i ~/ 5) + 1).toString().padLeft(3, '0')}',
        requiredDocumentsCount: (i % 5) + 1,
        requiredDocuments: [],
      ),
    );
  }

  /// Mock Auth Token
  static AuthToken createMockAuthToken({
    String? token,
    String? username,
    String? baseUrl,
  }) {
    return AuthToken(
      token: token ?? 'mock-token-123456789',
      username: username ?? 'testuser',
      baseUrl: baseUrl ?? 'https://tejido.example.com',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Mock API Response
  static Map<String, dynamic> createMockApiResponse({
    int? id,
    String? title,
    String? status,
  }) {
    return {
      'id': id ?? 1,
      'title': title ?? 'Test Document',
      'created': DateTime.now().toIso8601String(),
      'modified': DateTime.now().toIso8601String(),
      'correspondent': null,
      'document_type': 1,
      'tags': [1, 2],
      'archived_file_name': 'test.pdf',
      'original_file_name': 'test.pdf',
      'content': 'Test content',
      'custom_fields': [],
    };
  }

  /// Mock Login Response
  static Map<String, dynamic> createMockLoginResponse({
    String? token,
  }) {
    return {
      'token': token ?? 'mock-token-123456789',
    };
  }

  /// Mock Census CSV Data
  static String createMockCensusCSV() {
    return '''id,census_id,name,birth_date,life_stage,family_role,community
P001,C001,Juan Pérez,1990-01-01,Adulto,Padre,Comunidad A
P002,C002,María García,1985-05-15,Adulto,Madre,Comunidad A
P003,C003,Pedro López,2010-03-20,Niño,Hijo,Comunidad B''';
  }

  /// Mock File Path
  static String createMockFilePath({String? name}) {
    return '/tmp/test_${name ?? 'image'}.jpg';
  }

  /// Mock Upload Queue Item
  static Map<String, dynamic> createMockUploadQueueItem({
    int? id,
    String? personId,
    String? status,
  }) {
    return {
      'id': id ?? 1,
      'person_id': personId ?? 'P001',
      'person_name': 'Juan Pérez',
      'family_id': 'F001',
      'file_path': '/tmp/test_image.jpg',
      'file_name': 'test_image.jpg',
      'document_type': 'CEDULA_CIUDADANIA',
      'status': status ?? 'pending',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Mock Error Response
  static Map<String, dynamic> createMockErrorResponse({
    int? statusCode,
    String? message,
  }) {
    return {
      'detail': message ?? 'Error occurred',
      'status_code': statusCode ?? 400,
    };
  }
}
