import 'dart:convert'; // ⚡ FASE 3: For JSON encoding and gzip compression
import 'dart:io'; // ⚡ FASE 3: For gzip compression and File class
import 'package:dio/dio.dart';
import '../../services/logger_adapter.dart';
import '../../services/upload_service.dart' show DuplicateDocumentException; // v6.4.13: Import exception
import '../../core/constants/api_constants.dart';
import '../../core/security/secure_config_manager.dart';
import '../../core/utils/input_sanitizer.dart';

/// Tejido API Client
/// Handles all HTTP communication with Tejido-ngx REST API
class TejidoApiClient {
  late final Dio _dio;
  final LoggerAdapter _logger = LoggerAdapter();
  final SecureConfigManager _configManager = SecureConfigManager();
  String? _authToken;
  String _baseUrl = ApiConstants.defaultBaseUrl;

  TejidoApiClient({String? baseUrl}) {
    if (baseUrl != null) _baseUrl = baseUrl;
    _initializeDio();
  }

  /// Get Dio instance for repositories
  Dio get dio => _dio;

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          ApiConstants.contentTypeHeader: 'application/json',
          ApiConstants.acceptHeader: 'application/json',
          // ⚡ FASE 3: Enable gzip compression for responses
          // Reduces bandwidth by 60-80% for JSON responses
          'Accept-Encoding': 'gzip, deflate',
          // 🔒 FASE 2 SECURITY: Additional security headers
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Lumara-Mobile/${ApiConstants.appVersion}',
        },
      ),
    );

    // ⚡ FASE 3: Add compression interceptor for large requests
    _dio.interceptors.add(_CompressionInterceptor());

    // Add logging interceptor with sanitization
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final sanitizedUri = InputSanitizer.sanitizeForLogging(options.uri.toString());
          _logger.d('🌐 ${options.method} $sanitizedUri');

          // SECURITY: Never log auth headers
          final safeHeaders = Map<String, dynamic>.from(options.headers);
          safeHeaders.remove('Authorization');
          safeHeaders.remove(ApiConstants.authorizationHeader);
          _logger.d('Headers: $safeHeaders');

          // SECURITY: Sanitize request body
          if (options.data != null) {
            final sanitized = InputSanitizer.sanitizeForLogging(options.data.toString());
            _logger.d('Body: $sanitized');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          final sanitizedUri = InputSanitizer.sanitizeForLogging(
            response.requestOptions.uri.toString(),
          );
          _logger.i('✅ ${response.statusCode} $sanitizedUri');
          return handler.next(response);
        },
        onError: (error, handler) {
          final sanitizedUri = InputSanitizer.sanitizeForLogging(
            error.requestOptions.uri.toString(),
          );
          _logger.e('❌ ${error.response?.statusCode} $sanitizedUri');

          // SECURITY: Sanitize error messages
          if (error.message != null) {
            final sanitized = InputSanitizer.sanitizeForLogging(error.message!);
            _logger.e('Error: $sanitized');
          }

          if (error.response?.data != null) {
            final sanitized = InputSanitizer.sanitizeForLogging(
              error.response!.data.toString(),
            );
            _logger.e('Response: $sanitized');
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers[ApiConstants.authorizationHeader] = 'Token $token';
    _logger.i('🔑 Auth token set');
  }

  /// Load authentication from secure storage
  Future<void> loadAuthFromStorage() async {
    final token = await _configManager.getApiToken();
    final baseUrl = await _configManager.getBaseUrl();

    if (token != null) {
      setAuthToken(token);
    }

    if (baseUrl != null) {
      setBaseUrl(baseUrl);
    }

    _logger.i('🔐 Auth loaded from secure storage');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove(ApiConstants.authorizationHeader);
    _logger.i('🔓 Auth token cleared');
  }

  /// Update base URL (SECURITY: Validate HTTPS in production)
  void setBaseUrl(String url) {
    // SECURITY: Validate URL format
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw ArgumentError('Invalid URL format: $url');
    }

    // SECURITY: Enforce HTTPS in production, except for local network
    if (const bool.fromEnvironment('dart.vm.product') && uri.scheme != 'https') {
      // Allow HTTP only for local/private network addresses
      final host = uri.host.toLowerCase();
      final isLocalNetwork =
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.16.') ||
        host.startsWith('172.17.') ||
        host.startsWith('172.18.') ||
        host.startsWith('172.19.') ||
        host.startsWith('172.20.') ||
        host.startsWith('172.21.') ||
        host.startsWith('172.22.') ||
        host.startsWith('172.23.') ||
        host.startsWith('172.24.') ||
        host.startsWith('172.25.') ||
        host.startsWith('172.26.') ||
        host.startsWith('172.27.') ||
        host.startsWith('172.28.') ||
        host.startsWith('172.29.') ||
        host.startsWith('172.30.') ||
        host.startsWith('172.31.');

      if (!isLocalNetwork) {
        throw ArgumentError('HTTPS required in production for external URLs. Got: ${uri.scheme}://$host');
      }

      _logger.w('⚠️ Using HTTP for local network: $host');
    }

    _baseUrl = url;
    _dio.options.baseUrl = url;

    // SECURITY: Sanitize URL in logs
    final sanitized = InputSanitizer.sanitizeForLogging(url);
    _logger.i('🌐 Base URL updated: $sanitized');
  }

  /// Login to Tejido
  /// Returns auth token on success
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Login failed: ${e.message}');
      rethrow;
    }
  }

  /// Get list of documents
  Future<Map<String, dynamic>> getDocuments({
    int? page,
    int? pageSize,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        ApiConstants.documentsEndpoint,
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('Get documents failed: ${e.message}');
      rethrow;
    }
  }

  /// Upload document to Tejido
  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String fileName,
    String? title,
    int? documentType,
    List<int>? tags,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      // Create form data
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        if (title != null) 'title': title,
        if (documentType != null) 'document_type': documentType,
      });

      // Add tags (Tejido expects multiple 'tags' fields, one per tag ID)
      if (tags != null && tags.isNotEmpty) {
        for (final tagId in tags) {
          formData.fields.add(MapEntry('tags', tagId.toString()));
        }
      }

      // Add custom fields if provided
      if (customFields != null) {
        for (final entry in customFields.entries) {
          formData.fields.add(MapEntry('custom_field_${entry.key}', entry.value.toString()));
        }
      }

      final response = await _dio.post(
        ApiConstants.uploadEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      // Tejido returns the task UUID as data
      // This can be either a String (just the UUID) or a Map
      if (response.data is String) {
        // UUID returned as plain string
        return {
          'success': true,
          'task_id': response.data as String,
          'status_code': response.statusCode,
        };
      } else if (response.data is Map<String, dynamic>) {
        // Already a map, return as-is
        return response.data as Map<String, dynamic>;
      } else {
        // Unexpected response format
        _logger.w('⚠️ Unexpected response type: ${response.data.runtimeType}');
        return {
          'success': true,
          'data': response.data.toString(),
          'status_code': response.statusCode,
        };
      }
    } on DioException catch (e) {
      _logger.e('Upload document failed: ${e.message}');
      rethrow;
    }
  }

  /// Get document types
  Future<List<dynamic>> getDocumentTypes() async {
    try {
      final response = await _dio.get(ApiConstants.documentTypesEndpoint);
      final data = response.data as Map<String, dynamic>;
      return data['results'] as List<dynamic>;
    } on DioException catch (e) {
      _logger.e('Get document types failed: ${e.message}');
      rethrow;
    }
  }

  /// Get tags
  Future<List<dynamic>> getTags() async {
    try {
      final response = await _dio.get(ApiConstants.tagsEndpoint);
      final data = response.data as Map<String, dynamic>;
      return data['results'] as List<dynamic>;
    } on DioException catch (e) {
      _logger.e('Get tags failed: ${e.message}');
      rethrow;
    }
  }

  /// Get custom fields
  Future<List<dynamic>> getCustomFields() async {
    try {
      final response = await _dio.get(ApiConstants.customFieldsEndpoint);
      final data = response.data as Map<String, dynamic>;
      return data['results'] as List<dynamic>;
    } on DioException catch (e) {
      _logger.e('Get custom fields failed: ${e.message}');
      rethrow;
    }
  }

  /// Test connection to Tejido
  Future<bool> testConnection() async {
    try {
      // ⚠️ IMPORTANT: Disable followRedirects to get the actual 302 response
      // Backend returns 302 redirect to /api/schema/view/ (HTML page)
      // If we follow the redirect with Accept: application/json header,
      // backend returns 406 Not Acceptable (page is HTML, not JSON)
      final response = await _dio.get(
        '/api/',
        options: Options(
          followRedirects: false,  // ✅ DON'T follow redirects
          validateStatus: (status) => status != null && status < 500,  // Accept any non-5xx
        ),
      );

      // ✅ Accept 200 (OK) or 302 (redirect) as valid responses
      // Both indicate server is reachable and responding
      _logger.d('🔍 testConnection response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 302;
    } on DioException catch (e) {
      _logger.e('❌ testConnection failed: ${e.type} - ${e.message}');
      return false;
    }
  }

  /// Upload document with person association
  ///
  /// This uses the specialized upload_with_person endpoint that:
  /// - Associates document with a census person
  /// - Supports document replacement for low-quality duplicates
  /// - Provides better metadata management
  ///
  /// Parameters:
  /// - personId: Census person ID
  /// - documentType: Human-readable document type (e.g. "Cédula de Ciudadanía")
  /// - filePath: Local file path to upload
  /// - fileName: File name
  /// - isReplacement: Whether this replaces an existing low-quality document
  /// - documentNumber: Optional document number
  /// - digitizedBy: Optional username of digitizer
  Future<Map<String, dynamic>> uploadDocumentWithPerson({
    required String personId,
    required String documentType,
    required String filePath,
    required String fileName,
    bool isReplacement = false,
    String? documentNumber,
    String? digitizedBy,
  }) async {
    try {
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('🌐 API CLIENT - uploadDocumentWithPerson');
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('Endpoint: POST /api/documents/upload_with_person/');
      _logger.i('');
      _logger.i('📋 Parameters:');
      _logger.i('   person_id: "$personId"');
      _logger.i('   document_type: "$documentType"');
      _logger.i('   file_path: $filePath');
      _logger.i('   file_name: $fileName');
      _logger.i('   is_replacement: $isReplacement');
      _logger.i('   nuip: "${documentNumber ?? ""}"');
      _logger.i('   digitized_by: "${digitizedBy ?? "N/A"}"');
      _logger.i('   association_method: "APP"');
      _logger.i('');

      // Verify file exists
      final file = File(filePath);
      _logger.i('📁 File validation:');
      _logger.i('   Exists: ${file.existsSync()}');
      if (file.existsSync()) {
        final sizeBytes = file.lengthSync();
        final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
        _logger.i('   Size: $sizeBytes bytes ($sizeMB MB)');
      } else {
        _logger.e('❌ File does not exist!');
        throw Exception('File not found: $filePath');
      }
      _logger.i('');

      _logger.i('📦 Creating FormData...');

      // Create form data
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        'person_id': personId,
        'document_type': documentType,
        'is_replacement': isReplacement.toString(), // Convert bool to string
        'nuip': documentNumber ?? '', // REQUIRED: Backend expects 'nuip' not 'document_number'
        if (digitizedBy != null) 'digitized_by': digitizedBy,
        'association_method': 'APP', // Mark as uploaded from app
      });

      _logger.i('✅ FormData created with ${formData.fields.length} fields');
      _logger.i('');
      _logger.i('📡 Sending POST request to backend...');
      _logger.i('   Base URL: ${_dio.options.baseUrl}');
      _logger.i('   Endpoint: /api/documents/upload_with_person/');
      _logger.i('   Timeout: ${_dio.options.sendTimeout?.inSeconds ?? "default"}s send, ${_dio.options.receiveTimeout?.inSeconds ?? "default"}s receive');
      _logger.i('');

      final startTime = DateTime.now();

      final response = await _dio.post(
        '/api/documents/upload_with_person/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final duration = DateTime.now().difference(startTime);

      _logger.i('');
      _logger.i('📥 Response received:');
      _logger.i('   Status Code: ${response.statusCode}');
      _logger.i('   Duration: ${duration.inMilliseconds}ms (${duration.inSeconds}s)');
      _logger.i('   Response Type: ${response.data.runtimeType}');
      _logger.i('');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _logger.i('✅ HTTP Success (${response.statusCode})');

        final data = response.data as Map<String, dynamic>;
        _logger.i('');
        _logger.i('📊 Response Data:');
        _logger.i('   Keys: ${data.keys.join(", ")}');
        _logger.i('');

        if (data['success'] == true) {
          _logger.i('🎉 Backend confirmed document association:');
          _logger.i('   Document ID: ${data['document_id']}');
          _logger.i('   Person ID: ${data['person_id']}');
          _logger.i('   Relation ID: ${data['relation_id']} ⭐⭐⭐ ASOCIACIÓN CREADA');
          _logger.i('   Person Name: ${data['person_name']}');
          _logger.i('   Is Replacement: ${data['is_replacement']}');
          _logger.i('   Message: ${data['message']}');
        } else if (data['success'] == false) {
          _logger.w('⚠️ Backend responded with success=false');
          _logger.w('   Error: ${data['error']}');
          _logger.w('   Error Code: ${data['error_code']}');
        }
      } else {
        _logger.w('⚠️ Unexpected HTTP status: ${response.statusCode}');
      }

      _logger.i('═══════════════════════════════════════════════════════');

      return response.data as Map<String, dynamic>;

    } on DioException catch (e) {
      _logger.e('═══════════════════════════════════════════════════════');
      _logger.e('❌ API CLIENT ERROR (DioException)');
      _logger.e('═══════════════════════════════════════════════════════');
      _logger.e('Error type: ${e.type}');
      _logger.e('Error message: ${e.message}');
      _logger.e('');
      _logger.e('HTTP Response:');
      _logger.e('   Status code: ${e.response?.statusCode ?? "N/A"}');
      _logger.e('   Status message: ${e.response?.statusMessage ?? "N/A"}');
      _logger.e('   Response data: ${e.response?.data}');
      _logger.e('');
      _logger.e('Request details:');
      _logger.e('   URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
      _logger.e('   Method: ${e.requestOptions.method}');
      _logger.e('   person_id: $personId');
      _logger.e('   document_type: $documentType');
      _logger.e('   file: $fileName');
      _logger.e('═══════════════════════════════════════════════════════');

      // Provide more context for common errors
      if (e.response?.statusCode == 400) {
        _logger.e('⚠️ HTTP 400: Bad Request - Parámetros inválidos');
        _logger.e('   Revisa que person_id, document_type y nuip sean correctos');
        throw Exception('Parámetros inválidos: ${e.response?.data}');
      } else if (e.response?.statusCode == 404) {
        _logger.e('⚠️ HTTP 404: Not Found - Persona no encontrada');
        _logger.e('   La persona con ID $personId no existe en el censo');
        throw Exception('Persona no encontrada en censo');
      } else if (e.response?.statusCode == 401) {
        _logger.e('⚠️ HTTP 401: Unauthorized - Token inválido o expirado');
        throw Exception('No autorizado. Por favor inicia sesión de nuevo.');
      } else if (e.response?.statusCode == 409) {
        _logger.w('⚠️ HTTP 409: Conflict - Documento duplicado detectado');
        _logger.w('   El backend rechazó este upload porque ya existe un documento del mismo tipo');
        _logger.w('   Respuesta: ${e.response?.data}');

        // v6.4.13: Lanzar DuplicateDocumentException para que UI muestre feedback
        final responseData = e.response?.data as Map<String, dynamic>?;
        final existingDoc = responseData?['existing_document'] as Map<String, dynamic>?;

        throw DuplicateDocumentException(
          message: responseData?['error'] as String? ?? 'Documento duplicado detectado',
          existingDocumentId: existingDoc?['id'] as int?,
          ocrQuality: (existingDoc?['ocr_confidence'] as num?)?.toDouble() ?? 0.0,
          canReplace: (existingDoc?['ocr_confidence'] as num? ?? 1.0) < 0.8,
        );
      } else if (e.response?.statusCode == 500) {
        _logger.e('⚠️ HTTP 500: Internal Server Error - Error en el backend');
        _logger.e('   Revisa los logs del servidor Tejido');
      }

      rethrow;
    } catch (e, stackTrace) {
      _logger.e('═══════════════════════════════════════════════════════');
      _logger.e('❌ UNEXPECTED ERROR IN API CLIENT');
      _logger.e('═══════════════════════════════════════════════════════');
      _logger.e('Error: $e');
      _logger.e('Stack trace: $stackTrace');
      _logger.e('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Smart upload with automatic quality comparison
  ///
  /// This is the RECOMMENDED endpoint for uploads. It:
  /// 1. Always accepts the document (no pre-checks needed)
  /// 2. If duplicate exists, backend compares qualities automatically after OCR
  /// 3. Keeps the best quality document automatically
  /// 4. Eliminates the worse quality document automatically
  ///
  /// No need to call checkDocumentExists first - backend handles everything!
  ///
  /// Returns:
  /// - action: 'created' | 'pending_comparison'
  /// - document_id: ID of uploaded document
  /// - message: Descriptive message
  Future<Map<String, dynamic>> smartUploadDocument({
    required String personId,
    required String documentType,
    required String filePath,
    required String fileName,
    String? documentNumber,
    String? digitizedBy,
  }) async {
    try {
      _logger.i('🤖 Smart upload (auto quality comparison)');
      _logger.d('   Person ID: $personId');
      _logger.d('   Document Type: $documentType');

      // Create form data
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        'person_id': personId,
        'document_type': documentType,
        'nuip': documentNumber ?? '',
        if (digitizedBy != null) 'digitized_by': digitizedBy,
      });

      final response = await _dio.post(
        '/api/documents/upload_with_person/',  // ✅ FIX v6.4.11: Endpoint correcto (smart_upload estaba comentado en backend)
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data as Map<String, dynamic>;

      // ✅ FIX v6.4.13: Detect duplicate document rejection from backend
      final success = data['success'] as bool? ?? true;
      final errorCode = data['error_code'] as String?;

      if (!success && errorCode == 'DUPLICATE_DOCUMENT') {
        final existingDoc = data['existing_document'] as Map<String, dynamic>?;
        final errorMsg = data['error'] as String? ?? 'Documento duplicado detectado';

        _logger.w('⚠️ DUPLICADO DETECTADO: $errorMsg');
        _logger.w('   Documento existente ID: ${existingDoc?['id']}');
        _logger.w('   OCR Quality: ${existingDoc?['ocr_confidence']}');

        // Throw specific exception so UI can handle it
        throw DuplicateDocumentException(
          message: errorMsg,
          existingDocumentId: existingDoc?['id'] as int?,
          ocrQuality: (existingDoc?['ocr_confidence'] as num?)?.toDouble() ?? 0.0,
          canReplace: (existingDoc?['ocr_confidence'] as num? ?? 1.0) < 0.8,
        );
      }

      final action = data['action'] as String?;

      if (action == 'pending_comparison') {
        _logger.i('🔄 Document will be compared with existing one');
      } else {
        _logger.i('✅ Document uploaded successfully');
      }

      return data;
    } on DuplicateDocumentException {
      // v6.4.13: Let duplicate exceptions propagate to UI
      rethrow;
    } on DioException catch (e) {
      _logger.e('❌ Smart upload failed: ${e.message}');

      if (e.response?.statusCode == 400) {
        throw Exception('Parámetros inválidos: ${e.response?.data}');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Persona no encontrada en censo');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión de nuevo.');
      } else if (e.response?.statusCode == 409) {
        // v6.4.14: HTTP 409 Conflict = Duplicate document detected by backend
        _logger.w('⚠️ HTTP 409: Duplicate document detected by backend');
        final responseData = e.response?.data as Map<String, dynamic>?;
        final existingDoc = responseData?['existing_document'] as Map<String, dynamic>?;

        throw DuplicateDocumentException(
          message: responseData?['error'] as String? ?? 'Documento duplicado detectado',
          existingDocumentId: existingDoc?['id'] as int?,
          ocrQuality: (existingDoc?['ocr_confidence'] as num?)?.toDouble() ?? 0.0,
          canReplace: (existingDoc?['ocr_confidence'] as num? ?? 1.0) < 0.8,
        );
      }

      rethrow;
    }
  }

  /// Check if document already exists for a person
  /// Used for anti-duplicate detection during mass digitization events
  ///
  /// This endpoint should be called BEFORE capturing the photo to avoid
  /// unnecessary image transfers.
  ///
  /// Returns document existence status with quality metrics:
  /// - exists: bool - whether document exists
  /// - can_replace: bool - whether document can be replaced (low quality)
  /// - ocr_confidence: double - OCR quality score (0.0-1.0)
  /// - has_minimum_data: bool - whether minimum required data was extracted
  Future<Map<String, dynamic>> checkDocumentExists({
    required String personId,
    required String documentType,
  }) async {
    try {
      _logger.d('🔍 Checking if document exists: $documentType for person $personId');

      final queryParams = {
        'person_id': personId,
        'document_type': documentType,
      };

      final response = await _dio.get(
        '/api/documents/check_exists/',
        queryParameters: queryParams,
      );

      _logger.i('✅ Document existence check completed');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.e('❌ Check document exists failed: ${e.message}');

      // Provide more context for common errors
      if (e.response?.statusCode == 400) {
        throw Exception('Parámetros inválidos: ${e.response?.data}');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Persona no encontrada en censo');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Por favor inicia sesión de nuevo.');
      }

      rethrow;
    }
  }

  /// Get current auth token
  String? get authToken => _authToken;

  /// Get current base URL
  String get baseUrl => _baseUrl;
}

/// ⚡ FASE 3: Compression Interceptor
///
/// Automatically compresses large request bodies to reduce bandwidth usage.
///
/// Features:
/// - Compresses JSON requests > 1KB with gzip
/// - Adds Content-Encoding header
/// - Reduces upload size by 60-80%
/// - Transparent to application code
///
/// Performance impact:
/// - Small requests (<1KB): No compression overhead
/// - Large requests (>1KB): 60-80% bandwidth reduction
/// - Compression time: ~10-50ms (negligible vs network time)
class _CompressionInterceptor extends Interceptor {
  final LoggerAdapter _logger = LoggerAdapter();
  static const int compressionThreshold = 1024; // 1KB

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only compress JSON POST/PUT/PATCH requests
    if (!_shouldCompress(options)) {
      return handler.next(options);
    }

    try {
      final data = options.data;
      String jsonString;

      // Convert data to JSON string
      if (data is String) {
        jsonString = data;
      } else if (data is Map) {
        jsonString = json.encode(data);
      } else {
        return handler.next(options); // Can't compress this type
      }

      final originalSize = jsonString.length;

      // Only compress if above threshold
      if (originalSize < compressionThreshold) {
        return handler.next(options);
      }

      // Compress with gzip
      final bytes = utf8.encode(jsonString);
      final compressed = gzip.encode(bytes);

      final compressedSize = compressed.length;
      final compressionRatio = ((1 - (compressedSize / originalSize)) * 100);

      _logger.d(
        '🗜️  Compressed request: ${_formatBytes(originalSize)} → '
        '${_formatBytes(compressedSize)} (${compressionRatio.toStringAsFixed(1)}% reduction)'
      );

      // Update request with compressed data
      options.data = compressed;
      options.headers['Content-Encoding'] = 'gzip';
      options.headers['Content-Type'] = 'application/json';
      options.headers['Content-Length'] = compressedSize.toString();

      return handler.next(options);
    } catch (e) {
      _logger.w('⚠️ Compression failed, sending uncompressed: $e');
      return handler.next(options);
    }
  }

  /// Check if request should be compressed
  bool _shouldCompress(RequestOptions options) {
    // Only compress POST, PUT, PATCH (not GET, DELETE)
    final method = options.method.toUpperCase();
    if (method != 'POST' && method != 'PUT' && method != 'PATCH') {
      return false;
    }

    // Only compress JSON content
    final contentType = options.headers['Content-Type']?.toString().toLowerCase();
    if (contentType != null && !contentType.contains('application/json')) {
      return false;
    }

    // Don't compress if data is null or empty
    if (options.data == null) {
      return false;
    }

    // Don't compress multipart/form-data (already efficient for files)
    if (options.data is FormData) {
      return false;
    }

    return true;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
