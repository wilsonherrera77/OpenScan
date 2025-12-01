/// API Constants for Paperless-ngx Integration
/// Indigenous Communities Document Digitization System
class ApiConstants {
  // Paperless API Configuration
  // ⚠️ IMPORTANT: Configure server URL in app settings
  // This is the default fallback - will be overridden by user config
  static const String defaultBaseUrl = 'http://127.0.0.1:8001'; // ✅ DEV: localhost via ADB reverse (adb reverse tcp:8001 tcp:8001)
  static const String apiVersion = 'api';

  // Alternative URLs for development/testing
  static const String localhostUrl = 'http://127.0.0.1:8001'; // For emulator
  static const String dockerInternalUrl = 'http://172.21.0.3:8000'; // Docker container

  // API Endpoints
  static const String loginEndpoint = '/api/token/';
  static const String documentsEndpoint = '/api/documents/';
  static const String documentTypesEndpoint = '/api/document_types/';
  static const String tagsEndpoint = '/api/tags/';
  static const String customFieldsEndpoint = '/api/custom_fields/';

  // Upload endpoints
  static const String uploadEndpoint = '/api/documents/post_document/';

  // ⚡ OPTIMIZED: Timeouts configured for OCR processing
  static const Duration connectTimeout = Duration(seconds: 10);  // ✅ Faster failure detection
  static const Duration receiveTimeout = Duration(seconds: 60); // ✅ Allow time for OCR processing (was 15s - too short)
  static const Duration sendTimeout = Duration(minutes: 5);     // ✅ OK for large uploads

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';

  // Storage keys
  static const String tokenKey = 'paperless_token';
  static const String baseUrlKey = 'paperless_base_url';
  static const String usernameKey = 'paperless_username';
  static const String selectedPersonIdKey = 'selected_person_id';

  // App Configuration
  static const String appName = 'Lumara Scan';
  static const String appVersion = '5.6.0';

  // Census Configuration
  static const String censusFilePath = 'assets/census/persons.csv';

  // Document Types (must match Paperless configuration)
  // ✅ VERIFIED IDs from Paperless database
  static const Map<String, int> documentTypeIds = {
    'CEDULA_CIUDADANIA': 1,
    'TARJETA_IDENTIDAD': 2,
    'REGISTRO_CIVIL': 3,
    'CERTIFICADO_DEFUNCION': 6,
    'CERTIFICADO_MATRIMONIO': 7,
    'PPT_PEP': 9,
    'ARBOL_GENEALOGICO': 10,
    'OTRO_DOCUMENTO': 1, // Default to Cédula de Ciudadanía
  };

  // Tags (must match Paperless configuration)
  // ✅ VERIFIED IDs from Paperless database
  static const Map<String, int> tagIds = {
    'PENDIENTE': 17,
    'VERIFICADO': 18,
    'RECHAZADO': 19,
    'URGENTE': 20,
    'DIGITALIZADO_MOVIL': 21,
    'OCR_IA': 22,
    'INCOMPLETO': 23,
  };

  // Document Type Tags (must match Paperless configuration)
  static const Map<String, int> documentTypeTagIds = {
    'Registro Civil de Nacimiento': 10,
    'Tarjeta de Identidad': 11,
    'Cédula de Ciudadanía': 12,
    'Registro Civil de Matrimonio': 13,
    'Registro Civil de Defunción': 14,
    'PPT/PEP': 15,
    'Árbol Genealógico': 16,
  };

  // Custom Fields (must match Paperless configuration)
  static const Map<String, int> customFieldIds = {
    'person_id': 1,
    'family_id': 2,
    'full_name': 3,
    'document_number': 4,
    'birthdate': 5,
    'community': 6,
    'digitization_date': 7,
    'digitized_by': 8,
    'ai_ocr_confidence': 9,
  };
}
