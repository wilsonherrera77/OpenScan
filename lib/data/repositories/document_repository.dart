import 'dart:io';
import '../../services/logger_adapter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/person.dart' as entities;
import '../../domain/entities/document_existence_check.dart';
import '../datasources/tejido_api_client.dart';
import '../local/database/app_database.dart' as db;

/// Document Repository
/// Manages document uploads to Tejido
///
/// ⚡ FASE 2: Enhanced with metadata caching for better performance
class DocumentRepository {
  final TejidoApiClient _apiClient;
  final db.AppDatabase _database;
  final LoggerAdapter _logger = LoggerAdapter();

  /// ⚡ FASE 2: Cache TTL (Time To Live)
  static const Duration cacheTtl = Duration(hours: 1);

  DocumentRepository(this._apiClient, this._database);

  /// Upload generic document WITHOUT person association
  /// Used for documents captured through Normal Scan flow
  Future<Map<String, dynamic>> uploadGenericDocument({
    required String filePath,
    required String fileName,
    String? title,
    int? documentTypeId,
    List<int>? tagIds,
  }) async {
    try {
      _logger.i('📤 Uploading generic document: $fileName');

      final generatedTitle = title ?? 'Documento ${fileName.split('.').first}';

      // Use default document type if not provided
      final docTypeId = documentTypeId ?? ApiConstants.documentTypeIds['OTRO_DOCUMENTO']!;

      // Use default tags if not provided
      final tags = tagIds ?? [
        ApiConstants.tagIds['PENDIENTE']!,
        ApiConstants.tagIds['DIGITALIZADO_MOVIL']!,
      ];

      // Upload to Tejido
      final response = await _apiClient.uploadDocument(
        filePath: filePath,
        fileName: fileName,
        title: generatedTitle,
        documentType: docTypeId,
        tags: tags,
      );

      _logger.i('✅ Generic document uploaded successfully');

      return response;
    } catch (e) {
      _logger.e('❌ Upload failed: $e');
      rethrow;
    }
  }

  /// Upload document with auto-assigned metadata from person
  ///
  /// **NEW in v4.5.0:** Supports document replacement for anti-duplicate system
  ///
  /// Parameters:
  /// - isReplacement: If true, this upload will replace an existing low-quality
  ///   document. The backend will automatically delete the old document.
  ///   This parameter should be set based on the result from checkDocumentExists().
  Future<Map<String, dynamic>> uploadDocumentForPerson({
    required String filePath,
    required String fileName,
    required entities.Person person,
    required String documentType,
    String? documentNumber,
    String? digitizedBy,
    bool isReplacement = false, // NEW: Support for document replacement
  }) async {
    try {
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('📦 DOCUMENT REPOSITORY - uploadDocumentForPerson');
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('👤 Person:');
      _logger.i('   ID: ${person.personId}');
      _logger.i('   Full Name: ${person.fullName}');
      _logger.i('   First Name: ${person.firstName}');
      _logger.i('   Last Name: ${person.lastName}');
      _logger.i('   Family ID: ${person.familyId}');
      _logger.i('   Document Number (from Person): ${person.documentNumber}');
      _logger.i('');
      _logger.i('📄 Document:');
      _logger.i('   Type: $documentType');
      _logger.i('   File: $fileName');
      _logger.i('   Path: $filePath');
      _logger.i('   Is Replacement: $isReplacement');
      _logger.i('   Document Number (parameter): ${documentNumber ?? "N/A"}');
      _logger.i('   Digitized By: ${digitizedBy ?? "N/A"}');
      _logger.i('');

      // Verify file exists
      final file = File(filePath);
      if (!file.existsSync()) {
        _logger.e('❌ File does not exist: $filePath');
        throw Exception('File not found: $filePath');
      }
      _logger.i('✅ File verified: exists, size ${file.lengthSync()} bytes');
      _logger.i('');

      // Get document type label for new API endpoint
      final docTypeLabel = _getDocumentTypeLabel(documentType);
      _logger.i('📋 Document Type Label: "$docTypeLabel"');
      _logger.i('   (Converted from: "$documentType")');
      _logger.i('');

      final finalDocNumber = documentNumber ?? person.documentNumber;
      _logger.i('📋 Final values to send to API:');
      _logger.i('   person_id: ${person.personId}');
      _logger.i('   document_type: $docTypeLabel');
      _logger.i('   nuip: $finalDocNumber');
      _logger.i('   is_replacement: $isReplacement');
      _logger.i('');
      _logger.i('🌐 Calling API Client...');

      // Use new specialized endpoint for person-document association
      final response = await _apiClient.uploadDocumentWithPerson(
        personId: person.personId,
        documentType: docTypeLabel,
        filePath: filePath,
        fileName: fileName,
        isReplacement: isReplacement,
        documentNumber: finalDocNumber, // Use person's NUIP if not provided
        digitizedBy: digitizedBy,
      );

      _logger.i('');
      _logger.i('✅ API Client responded successfully');
      _logger.i('Response keys: ${response.keys.join(", ")}');
      _logger.i('Response data: $response');
      _logger.i('═══════════════════════════════════════════════════════');

      return response;
    } catch (e, stackTrace) {
      _logger.e('═══════════════════════════════════════════════════════');
      _logger.e('❌ REPOSITORY ERROR');
      _logger.e('═══════════════════════════════════════════════════════');
      _logger.e('Error: $e');
      _logger.e('Stack trace: $stackTrace');
      _logger.e('');
      _logger.e('Upload details:');
      _logger.e('   Person ID: ${person.personId}');
      _logger.e('   Person Name: ${person.fullName}');
      _logger.e('   Document Type: $documentType');
      _logger.e('   File: $fileName');
      _logger.e('   Path: $filePath');
      _logger.e('═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Check if document already exists for a person
  ///
  /// This method calls the `/api/documents/check_exists/` endpoint to verify
  /// if a document of the specified type already exists for the given person.
  ///
  /// This should be called BEFORE capturing/uploading the document to avoid
  /// unnecessary file transfers.
  ///
  /// Returns DocumentExistenceCheck entity with:
  /// - exists: bool - whether document exists
  /// - can_replace: bool - whether document can be replaced (low quality)
  /// - ocr_confidence: double - OCR quality score (0.0-1.0)
  /// - has_minimum_data: bool - whether minimum data was extracted
  /// - existing_document: metadata of existing document (if exists)
  /// - person: person information
  /// - message: user-friendly message in Spanish
  Future<DocumentExistenceCheck> checkDocumentExists({
    required String personId,
    required String documentType,
  }) async {
    try {
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('🔍 CHECKING DOCUMENT EXISTENCE');
      _logger.i('═══════════════════════════════════════════════════════');
      _logger.i('Person ID: $personId');
      _logger.i('Document Type: $documentType');

      final docTypeLabel = _getDocumentTypeLabel(documentType);
      _logger.i('Document Type Label: "$docTypeLabel"');

      final response = await _apiClient.checkDocumentExists(
        personId: personId,
        documentType: docTypeLabel,
      );

      _logger.i('✅ Check completed');
      _logger.i('Response: $response');

      // Parse response into DocumentExistenceCheck entity
      final check = DocumentExistenceCheck.fromJson(response);

      if (check.exists) {
        _logger.w('⚠️ DOCUMENT ALREADY EXISTS:');
        _logger.w('   Person: ${check.person.name}');
        _logger.w('   Type: $docTypeLabel');
        if (check.existingDocument != null) {
          final doc = check.existingDocument!;
          _logger.w('   Existing Doc ID: ${doc.id}');
          _logger.w('   OCR Quality: ${check.ocrQualityPercentage}%');
          _logger.w('   Created: ${doc.formattedDate}');
          _logger.w('   Can Replace: ${check.canReplace}');
        }
      } else {
        _logger.i('✅ Document does not exist. Safe to upload.');
      }

      return check;
    } catch (e, stackTrace) {
      _logger.e('❌ REPOSITORY ERROR checking document existence');
      _logger.e('Error: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Smart upload with automatic quality comparison (RECOMMENDED)
  ///
  /// This is the PREFERRED method for uploading documents. It:
  /// 1. Always accepts the upload (no pre-checks needed)
  /// 2. Backend automatically compares with existing documents
  /// 3. Backend keeps the best quality document automatically
  /// 4. Backend deletes the worse quality document automatically
  ///
  /// No need to call checkDocumentExists() first!
  ///
  /// Use this method unless you specifically need the old behavior
  /// with manual user confirmation dialogs.
  Future<Map<String, dynamic>> smartUploadDocumentForPerson({
    required String filePath,
    required String fileName,
    required entities.Person person,
    required String documentType,
    String? documentNumber,
    String? digitizedBy,
  }) async {
    try {
      _logger.i('🤖 Smart upload for: ${person.fullName}');
      _logger.d('File: $fileName, Type: $documentType');
      _logger.d('Backend will handle quality comparison automatically');

      // Get document type label
      final docTypeLabel = _getDocumentTypeLabel(documentType);

      // Use smart upload endpoint
      final response = await _apiClient.smartUploadDocument(
        personId: person.personId,
        documentType: docTypeLabel,
        filePath: filePath,
        fileName: fileName,
        documentNumber: documentNumber ?? person.documentNumber,
        digitizedBy: digitizedBy,
      );

      final action = response['action'] as String?;

      if (action == 'pending_comparison') {
        _logger.i(
          '🔄 Document will be compared with existing one. '
          'Best quality will be kept automatically.'
        );
      } else {
        _logger.i('✅ Document uploaded successfully (no duplicates)');
      }

      return response;
    } catch (e) {
      _logger.e('❌ Smart upload failed: $e');
      rethrow;
    }
  }

  /// Generate document title
  String _generateDocumentTitle({
    required entities.Person person,
    required String documentType,
    String? documentNumber,
  }) {
    final typeLabel = _getDocumentTypeLabel(documentType);
    final parts = [
      typeLabel,
      person.fullName,
    ];

    if (documentNumber != null && documentNumber.isNotEmpty) {
      parts.add(documentNumber);
    }

    return parts.join(' - ');
  }

  /// Get human-readable document type label
  String _getDocumentTypeLabel(String documentType) {
    const labels = {
      'CEDULA_CIUDADANIA': 'Cédula de Ciudadanía',
      'TARJETA_IDENTIDAD': 'Tarjeta de Identidad',
      'REGISTRO_CIVIL': 'Registro Civil',
      'CERTIFICADO_AFILIACION_EPS': 'Certificado EPS',
      'CERTIFICADO_ESTUDIO': 'Certificado de Estudio',
      'CERTIFICADO_DEFUNCION': 'Certificado de Defunción',
      'CERTIFICADO_MATRIMONIO': 'Certificado de Matrimonio',
      'OTRO_DOCUMENTO': 'Otro Documento',
    };

    return labels[documentType] ?? documentType;
  }

  /// Get available document types
  /// ⚡ FASE 2: Enhanced with caching - reduces API calls by ~80%
  Future<List<dynamic>> getDocumentTypes() async {
    try {
      // 1. Check cache expiration
      final isExpired = await _database.isMetadataCacheExpired();

      // 2. Return cached data if still valid
      if (!isExpired) {
        final cached = await _database.getCachedDocumentTypes();
        if (cached.isNotEmpty) {
          _logger.d('📋 Using cached document types (${cached.length} items)');
          return cached
              .map((dt) => {'id': dt.id, 'name': dt.name})
              .toList();
        }
      }

      // 3. Fetch from API if cache expired or empty
      _logger.d('📋 Fetching document types from API');
      final apiData = await _apiClient.getDocumentTypes();

      // 4. Update cache
      await _database.cacheDocumentTypes(
        apiData.map((dt) => dt as Map<String, dynamic>).toList(),
      );

      _logger.i('✅ Document types cached (${apiData.length} items)');
      return apiData;
    } catch (e) {
      _logger.e('❌ Failed to get document types: $e');

      // Fallback: try returning stale cache data
      final cached = await _database.getCachedDocumentTypes();
      if (cached.isNotEmpty) {
        _logger.w('⚠️ Using stale cache due to API error');
        return cached
            .map((dt) => {'id': dt.id, 'name': dt.name})
            .toList();
      }

      rethrow;
    }
  }

  /// Get available tags
  /// ⚡ FASE 2: Enhanced with caching - reduces API calls by ~80%
  Future<List<dynamic>> getTags() async {
    try {
      // 1. Check cache expiration
      final isExpired = await _database.isMetadataCacheExpired();

      // 2. Return cached data if still valid
      if (!isExpired) {
        final cached = await _database.getCachedTags();
        if (cached.isNotEmpty) {
          _logger.d('🏷️  Using cached tags (${cached.length} items)');
          return cached
              .map((tag) => {
                    'id': tag.id,
                    'name': tag.name,
                    'colour': tag.color,
                  })
              .toList();
        }
      }

      // 3. Fetch from API if cache expired or empty
      _logger.d('🏷️  Fetching tags from API');
      final apiData = await _apiClient.getTags();

      // 4. Update cache
      await _database.cacheTags(
        apiData.map((tag) => tag as Map<String, dynamic>).toList(),
      );

      _logger.i('✅ Tags cached (${apiData.length} items)');
      return apiData;
    } catch (e) {
      _logger.e('❌ Failed to get tags: $e');

      // Fallback: try returning stale cache data
      final cached = await _database.getCachedTags();
      if (cached.isNotEmpty) {
        _logger.w('⚠️ Using stale cache due to API error');
        return cached
            .map((tag) => {
                  'id': tag.id,
                  'name': tag.name,
                  'colour': tag.color,
                })
            .toList();
      }

      rethrow;
    }
  }

  /// Get custom fields
  /// ⚡ FASE 2: Enhanced with caching - reduces API calls by ~80%
  Future<List<dynamic>> getCustomFields() async {
    try {
      // 1. Check cache expiration
      final isExpired = await _database.isMetadataCacheExpired();

      // 2. Return cached data if still valid
      if (!isExpired) {
        final cached = await _database.getCachedCustomFields();
        if (cached.isNotEmpty) {
          _logger.d('📝 Using cached custom fields (${cached.length} items)');
          return cached
              .map((cf) => {
                    'id': cf.id,
                    'name': cf.name,
                    'data_type': cf.dataType,
                  })
              .toList();
        }
      }

      // 3. Fetch from API if cache expired or empty
      _logger.d('📝 Fetching custom fields from API');
      final apiData = await _apiClient.getCustomFields();

      // 4. Update cache
      await _database.cacheCustomFields(
        apiData.map((cf) => cf as Map<String, dynamic>).toList(),
      );

      _logger.i('✅ Custom fields cached (${apiData.length} items)');
      return apiData;
    } catch (e) {
      _logger.e('❌ Failed to get custom fields: $e');

      // Fallback: try returning stale cache data
      final cached = await _database.getCachedCustomFields();
      if (cached.isNotEmpty) {
        _logger.w('⚠️ Using stale cache due to API error');
        return cached
            .map((cf) => {
                  'id': cf.id,
                  'name': cf.name,
                  'data_type': cf.dataType,
                })
            .toList();
      }

      rethrow;
    }
  }

  /// Get uploaded documents
  Future<Map<String, dynamic>> getDocuments({
    int? page,
    int? pageSize,
    String? search,
  }) async {
    try {
      _logger.d('📄 Getting documents');
      return await _apiClient.getDocuments(
        page: page,
        pageSize: pageSize,
        search: search,
      );
    } catch (e) {
      _logger.e('❌ Failed to get documents: $e');
      rethrow;
    }
  }
}
