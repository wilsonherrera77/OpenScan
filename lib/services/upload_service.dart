import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart'; // debugPrint
import '../services/logger_adapter.dart';
import '../core/config/env_config.dart';
import '../core/constants/api_constants.dart';
import '../data/local/database/app_database.dart';
import '../data/repositories/document_repository.dart';
import '../domain/entities/person.dart' as entities;
import '../Utilities/database_helper.dart'; // v4.4.2: For deleting scanned image directories
import 'file_deletion_service.dart';
import 'image_optimizer.dart'; // ⚡ FASE 2: Image optimization

/// Sync Status States
enum SyncStatus {
  idle,       // No activity
  syncing,    // Currently uploading
  success,    // Upload completed
  failed,     // Upload failed
  retrying,   // Retrying after failure
}

/// Upload Service
/// Manages document upload queue and synchronization with retry logic and backoff
///
/// ⚡ FASE 2 ENHANCEMENTS:
/// - Image optimization before upload (60-80% size reduction)
/// - Metadata caching for faster operations
/// - WAL mode for better concurrency
class UploadService {
  final AppDatabase _database;
  final DocumentRepository _documentRepository;
  final LoggerAdapter _logger = LoggerAdapter();
  final FileDeletionService _fileDeletionService = FileDeletionService();
  final ImageOptimizer _imageOptimizer = ImageOptimizer(); // ⚡ FASE 2

  // Sync status stream
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  // Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelayBase = Duration(seconds: 5);

  UploadService(this._database, this._documentRepository);

  /// Update sync status and emit to stream
  void _updateSyncStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
    _logger.d('🔄 Sync status updated: $status');
  }

  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
  }

  /// Enqueue upload to local database (legacy method - backward compat)
  Future<int> enqueueUpload({
    required entities.Person person,
    required File imageFile,
    required String documentType,
    String? documentNumber,
    String? digitizedBy,
    bool isReplacement = false, // NEW: Support for document replacement
  }) async {
    return enqueueUploadEnhanced(
      person: person,
      imageFile: imageFile,
      documentType: documentType,
      documentNumber: documentNumber,
      digitizedBy: digitizedBy,
      isReplacement: isReplacement,
    );
  }

  /// Enqueue document upload with optional person data (for documents linked to census)
  /// Used when user captures documents through Normal Scan flow
  ///
  /// v4.4.2: Added sourceDirectory parameter to enable cleanup of scanned images after PDF sync
  /// v4.5.1: ONLY assigns tag of selected document type (e.g. Cédula = tag 12)
  /// v6.4.5: Added personId, personName, familyId to link documents with census
  Future<int?> enqueueGenericDocument({
    required File documentFile,
    String? title,
    String? documentType,
    String? documentNumber,
    String? sourceDirectory, // v4.4.2: Path to directory with source images to delete after sync
    String? personId, // v6.4.5: Census person ID for document-person linking
    String? personName, // v6.4.5: Person name for display
    String? familyId, // v6.4.5: Family ID for grouping
  }) async {
    debugPrint('🟣 [ENQUEUE-SERVICE] === enqueueGenericDocument() STARTED ===');
    debugPrint('🟣 [ENQUEUE-SERVICE] File: ${documentFile.path}');
    debugPrint('🟣 [ENQUEUE-SERVICE] Type: $documentType, Number: $documentNumber');
    _logger.i('📥 Enqueuing generic document: ${documentFile.path}');
    _logger.i('   Type: $documentType, Number: $documentNumber');
    if (sourceDirectory != null) {
      _logger.i('   📂 Source directory: $sourceDirectory (will be deleted after sync)');
    }

    try {
      final fileName = documentFile.path.split('/').last;

      // Use document number as title if available, otherwise use provided title or generate one
      final generatedTitle = documentNumber ?? title ?? 'Documento ${DateTime.now().toString().substring(0, 16)}';

      // ✅ v4.4.0: Map document type name to native Paperless document_type ID
      int? nativeDocumentTypeId;
      int? documentTagId; // v4.5.1: Tag ID for the document type

      if (documentType != null) {
        // Map from user-friendly name to API constant
        final typeMapping = {
          'Registro Civil de Nacimiento': 'REGISTRO_CIVIL',
          'Tarjeta de Identidad': 'TARJETA_IDENTIDAD',
          'Cédula de Ciudadanía': 'CEDULA_CIUDADANIA',
          'Registro Civil de Matrimonio': 'CERTIFICADO_MATRIMONIO',
          'Registro Civil de Defunción': 'CERTIFICADO_DEFUNCION',
          'PPT/PEP': 'PPT_PEP',
          'Árbol Genealógico': 'ARBOL_GENEALOGICO',
        };

        // v4.5.1: Map document type name to Tag ID (10-16)
        final documentTypeToTagId = {
          'Registro Civil de Nacimiento': 10,
          'Tarjeta de Identidad': 11,
          'Cédula de Ciudadanía': 12,
          'Registro Civil de Matrimonio': 13,
          'Registro Civil de Defunción': 14,
          'PPT/PEP': 15,
          'Árbol Genealógico': 16,
        };

        final apiKey = typeMapping[documentType];
        if (apiKey != null) {
          nativeDocumentTypeId = ApiConstants.documentTypeIds[apiKey];
          documentTagId = documentTypeToTagId[documentType]; // v4.5.1
          _logger.i('   ✅ Mapped to document_type: $apiKey (ID: $nativeDocumentTypeId)');
          _logger.i('   ✅ Mapped to tag: $documentType (Tag ID: $documentTagId)');
        }
      }

      // Default to CEDULA_CIUDADANIA if no valid type
      nativeDocumentTypeId ??= ApiConstants.documentTypeIds['CEDULA_CIUDADANIA'];
      documentTagId ??= 12; // Default tag: Cédula de Ciudadanía

      // ✅ v4.5.1: Assign ONLY the tag of the selected document type
      // Tag IDs are 10-16, NOT the same as document_type IDs (1-8)
      final List<int> tagList = documentTagId != null ? [documentTagId] : [];
      _logger.i('🏷️  Assigning ONLY document type tag: $tagList');

      debugPrint('🟣 [ENQUEUE-SERVICE] About to call _database.enqueueUpload()...');
      debugPrint('🟣 [ENQUEUE-SERVICE] filePath: ${documentFile.path}');
      debugPrint('🟣 [ENQUEUE-SERVICE] documentTypeId: $nativeDocumentTypeId');

      // ✅ DEBUG: Add timeout to detect database hanging
      final int id;
      try {
        // v6.4.5: Use person data from CensusProvider if available
        final effectivePersonId = personId ?? 'GENERIC';
        final effectivePersonName = personName ?? 'Usuario Lumara Scan';
        final effectiveFamilyId = familyId ?? '';

        _logger.i('👤 Linking document to person: $effectivePersonName (ID: $effectivePersonId, Family: $effectiveFamilyId)');

        id = await _database.enqueueUpload(
          filePath: documentFile.path,
          personId: effectivePersonId,
          personName: effectivePersonName,
          familyId: effectiveFamilyId,
          docNumber: documentNumber,
          documentTypeId: nativeDocumentTypeId, // ✅ Use mapped native document_type
          tagIds: tagList,
          metadata: {
            'title': generatedTitle,
            'source': 'normal_scan',
            'captured_at': DateTime.now().toIso8601String(),
            if (documentType != null) 'document_type': documentType,
            if (documentNumber != null) 'document_number': documentNumber,
            if (sourceDirectory != null) 'source_directory': sourceDirectory, // v4.4.2: Store source directory for cleanup
          },
        ).timeout(const Duration(seconds: 10), onTimeout: () {
          debugPrint('🔴 [ENQUEUE-SERVICE] TIMEOUT! Database operation took >10s');
          throw TimeoutException('Database enqueueUpload timed out after 10 seconds');
        });
        debugPrint('🟢 [ENQUEUE-SERVICE] Database insert succeeded: id=$id');
      } on TimeoutException catch (e) {
        debugPrint('🔴 [ENQUEUE-SERVICE] TimeoutException: $e');
        return null;
      }

      debugPrint('🟣 [ENQUEUE-SERVICE] _database.enqueueUpload() returned: $id');
      _logger.i('✅ Generic document enqueued with ID: $id');

      // ✅ FIX v6.4.0: LOG DETALLADO para debugging
      print('📤 Document enqueued: ID=$id, file=${documentFile.path}');

      final count = await getPendingCount();
      print('📊 Total pending uploads now: $count');

      // Listar todos los pendientes
      final allPending = await _database.getAllPendingUploads();
      print('📋 Pending uploads list (${allPending.length} total):');
      for (final upload in allPending.take(5)) {
        print('  - ${upload.id}: ${upload.fileName} (${upload.status})');
      }
      if (allPending.length > 5) {
        print('  ... y ${allPending.length - 5} más');
      }

      // Try immediate upload if possible (await to catch errors)
      await _attemptImmediateUpload(id);

      return id;
    } catch (e, stackTrace) {
      debugPrint('🔴 [ENQUEUE-SERVICE] ERROR: $e');
      debugPrint('🔴 [ENQUEUE-SERVICE] Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      _logger.e('❌ Failed to enqueue generic document: $e', error: e, stackTrace: stackTrace);
      return null; // Return null instead of rethrowing so sync can continue
    }
  }

  /// Enqueue upload with enhanced metadata support
  ///
  /// **NEW in v4.5.0:** Supports is_replacement flag for anti-duplicate system
  Future<int> enqueueUploadEnhanced({
    required entities.Person person,
    required File imageFile,
    required String documentType,
    String? documentNumber,
    String? digitizedBy,
    int? documentTypeId,
    List<int>? tagIds,
    Map<String, dynamic>? metadata,
    bool isReplacement = false, // NEW: Support for document replacement
  }) async {
    _logger.i('📥 Enqueuing upload for ${person.fullName}');
    if (isReplacement) {
      _logger.i('🔄 This upload will REPLACE an existing low-quality document');
    }

    try {
      // Add isReplacement flag to metadata for later use during upload
      final enhancedMetadata = {
        ...?metadata,
        'is_replacement': isReplacement,
        if (isReplacement) 'replacement_reason': 'Low quality document replaced',
      };

      final id = await _database.enqueueUpload(
        filePath: imageFile.path,
        personId: person.personId,
        personName: person.fullName,
        familyId: person.familyId,
        docNumber: documentNumber,
        documentTypeId: documentTypeId,
        tagIds: tagIds,
        metadata: enhancedMetadata,
      );

      _logger.i('✅ Upload enqueued with ID: $id');

      // Try immediate upload if possible (await to catch errors)
      await _attemptImmediateUpload(id);

      return id;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to enqueue upload: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Attempt immediate upload (non-blocking)
  /// Auth errors are rethrown so user knows to login
  /// Network errors are silently queued for retry
  Future<void> _attemptImmediateUpload(int uploadId) async {
    debugPrint('🔷 [UPLOAD-DEBUG] _attemptImmediateUpload($uploadId) STARTED');
    try {
      debugPrint('🔷 [UPLOAD-DEBUG] Calling processUpload($uploadId)...');
      await processUpload(uploadId);
      debugPrint('🟢 [UPLOAD-DEBUG] processUpload($uploadId) completed successfully');
    } catch (e, stack) {
      debugPrint('🔴 [UPLOAD-DEBUG] processUpload($uploadId) threw exception: $e');
      debugPrint('🔴 [UPLOAD-DEBUG] Stack: ${stack.toString().split('\n').take(3).join('\n')}');
      final errorStr = e.toString().toLowerCase();

      // Auth errors - user needs to know immediately
      if (errorStr.contains('401') || errorStr.contains('403') || errorStr.contains('unauthorized')) {
        debugPrint('🔴 [UPLOAD-DEBUG] Auth error detected, rethrowing');
        _logger.e('❌ Auth error during immediate upload: $e');
        throw Exception('No autorizado. Por favor inicia sesión de nuevo.');
      }

      // Network/connection errors - will retry in background
      if (errorStr.contains('socket') || errorStr.contains('network') ||
          errorStr.contains('connection') || errorStr.contains('timeout')) {
        debugPrint('🟠 [UPLOAD-DEBUG] Network error, will retry in background');
        _logger.w('⚠️ Network error, will retry in background: $e');
        // Don't throw - will be retried by background service
        return;
      }

      // Other errors - log and rethrow so user sees them
      debugPrint('🔴 [UPLOAD-DEBUG] Other error, rethrowing');
      _logger.e('❌ Upload error: $e');
      throw Exception('Error al subir: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Process a single upload with retry logic and performance tracking
  Future<void> processUpload(int uploadId) async {
    debugPrint('🔶 [PROCESS-DEBUG] processUpload($uploadId) STARTED');
    final upload = await _database.getPendingUploadById(uploadId);
    debugPrint('🔶 [PROCESS-DEBUG] Got upload from DB: ${upload != null ? 'found' : 'NULL'}');

    if (upload == null) {
      debugPrint('🔴 [PROCESS-DEBUG] Upload $uploadId not found in DB, returning');
      _logger.w('Upload $uploadId not found');
      return;
    }

    debugPrint('🔶 [PROCESS-DEBUG] Upload status: ${upload.status}');
    if (upload.status == 'uploading') {
      debugPrint('🟠 [PROCESS-DEBUG] Upload $uploadId already in progress, returning');
      _logger.d('Upload $uploadId already in progress');
      return;
    }

    debugPrint('🔶 [PROCESS-DEBUG] Processing upload: ${upload.fileName}');
    _logger.i('📤 Processing upload $uploadId (attempt ${upload.retryCount + 1}): ${upload.fileName}');

    // Check if need to wait due to exponential backoff
    if (upload.lastAttemptAt != null && upload.retryCount > 0) {
      _updateSyncStatus(SyncStatus.retrying);
      final backoffDelay = _calculateBackoffDelay(upload.retryCount);
      final timeSinceLastAttempt = DateTime.now().difference(upload.lastAttemptAt!);

      if (timeSinceLastAttempt < backoffDelay) {
        final waitTime = backoffDelay - timeSinceLastAttempt;
        _logger.d('⏳ Backoff: waiting ${waitTime.inSeconds}s before retry');
        await Future.delayed(waitTime);
      }
    }

    // Update status to uploading
    debugPrint('🔶 [PROCESS-DEBUG] Updating status to uploading...');
    _updateSyncStatus(SyncStatus.syncing);
    await _database.updateUploadStatus(
      id: uploadId,
      status: 'uploading',
    );
    debugPrint('🔶 [PROCESS-DEBUG] Status updated to uploading');

    final startTime = DateTime.now();
    final wasOffline = upload.retryCount > 0;

    try {
      // Verify file exists
      debugPrint('🔶 [PROCESS-DEBUG] Checking if file exists: ${upload.filePath}');
      File file = File(upload.filePath);
      final fileExists = await file.exists();
      debugPrint('🔶 [PROCESS-DEBUG] File exists: $fileExists');
      if (!fileExists) {
        throw Exception('File not found: ${upload.filePath}');
      }

      int originalFileSize = await file.length();
      int optimizedFileSize = originalFileSize;

      // ⚡ FASE 2: Optimize image before upload
      // Check if file is an image and needs optimization
      final isImage = _isImageFile(upload.filePath);
      if (isImage) {
        try {
          final needsOpt = await _imageOptimizer.needsOptimization(file);
          if (needsOpt) {
            _logger.i('🖼️  Image optimization enabled for ${upload.fileName}');

            final result = await _imageOptimizer.optimizeForUpload(file);

            if (result.isSuccess) {
              // Use optimized file for upload
              file = result.optimizedFile;
              optimizedFileSize = result.optimizedSize;

              _logger.i('✅ Image optimized: ${result.summary}');
              _logger.i('   Upload size: ${_formatBytes(optimizedFileSize)} (was ${_formatBytes(originalFileSize)})');
            } else {
              _logger.w('⚠️ Image optimization failed, using original');
            }
          } else {
            _logger.d('ℹ️  Image already optimized, skipping');
          }
        } catch (optimizationError) {
          // If optimization fails, continue with original file
          _logger.w('⚠️ Image optimization error: $optimizationError');
          _logger.w('   Continuing with original file');
        }
      }

      final fileSize = optimizedFileSize;
      debugPrint('🔶 [PROCESS-DEBUG] File size: $fileSize bytes');

      // Upload to Paperless (generic or person-specific)
      // Note: Using potentially optimized file here
      debugPrint('🔶 [PROCESS-DEBUG] === CALLING _uploadDocument() ===');
      debugPrint('🔶 [PROCESS-DEBUG] upload.personId: ${upload.personId}');
      debugPrint('🔶 [PROCESS-DEBUG] upload.fileName: ${upload.fileName}');
      final response = await _uploadDocument(upload, fileToUpload: file);
      debugPrint('🟢 [PROCESS-DEBUG] _uploadDocument() returned: $response');

      final duration = DateTime.now().difference(startTime);

      debugPrint('🟢 [PROCESS-DEBUG] Upload successful in ${duration.inSeconds}s');
      _logger.i('✅ Upload $uploadId successful in ${duration.inSeconds}s. Paperless ID: ${response['id']}');

      // Add to history with performance metrics
      await _database.recordUploadHistory(
        personId: upload.personId,
        personName: upload.personName,
        documentType: upload.documentType,
        paperlessDocumentId: response['id'] as int?,
        fileSize: fileSize,
        uploadDurationMs: duration.inMilliseconds,
        wasOffline: wasOffline,
      );

      // Delete from pending
      await _database.deletePendingUpload(uploadId);

      // 🔒 SECURITY: Delete local file after successful sync (GDPR/Privacy compliance)
      // Files containing sensitive personal data MUST be removed from device
      // after confirmed upload to Paperless server
      await _deleteLocalFileAfterSync(file, upload.filePath, uploadId);

      // Update sync status to success
      _updateSyncStatus(SyncStatus.success);

      // Auto-reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_currentStatus == SyncStatus.success) {
          _updateSyncStatus(SyncStatus.idle);
        }
      });
    } catch (e, stackTrace) {
      _logger.e('❌ Upload $uploadId failed: $e', error: e, stackTrace: stackTrace);

      // Determine if should retry
      final shouldRetry = upload.retryCount < maxRetryAttempts && _isRetryableError(e);

      await _database.updateUploadStatus(
        id: uploadId,
        status: shouldRetry ? 'pending' : 'failed',
        retryCount: upload.retryCount + 1,
        lastError: e.toString(),
      );

      if (!shouldRetry) {
        _logger.e('❌ Upload $uploadId permanently failed after ${upload.retryCount + 1} attempts');
        _updateSyncStatus(SyncStatus.failed);

        // Auto-reset to idle after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (_currentStatus == SyncStatus.failed) {
            _updateSyncStatus(SyncStatus.idle);
          }
        });
      }

      rethrow;
    }
  }

  /// Upload document based on type (generic or person-specific)
  ///
  /// ⚡ FASE 2: Enhanced to support optimized file uploads
  Future<Map<String, dynamic>> _uploadDocument(
    PendingUpload upload, {
    File? fileToUpload, // Optional: use optimized file instead of original
  }) async {
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('📤 INICIANDO UPLOAD - Diagnóstico Completo');
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('Upload ID: ${upload.id}');
    _logger.i('File Name: ${upload.fileName}');
    _logger.i('File Path: ${upload.filePath}');

    final file = File(upload.filePath);
    _logger.i('File exists: ${file.existsSync()}');
    if (file.existsSync()) {
      _logger.i('File size: ${_formatBytes(file.lengthSync())}');
    }
    _logger.i('');
    _logger.i('👤 PERSONA (desde PendingUpload):');
    _logger.i('   Person ID: ${upload.personId ?? "NULL ⚠️⚠️⚠️"}');
    _logger.i('   Person Name: ${upload.personName ?? "NULL ⚠️"}');
    _logger.i('   Family ID: ${upload.familyId ?? "NULL ⚠️"}');
    _logger.i('');
    _logger.i('📄 DOCUMENTO (desde PendingUpload):');
    _logger.i('   Document Type: ${upload.documentType}');
    _logger.i('   Document Number: ${upload.documentNumber ?? "N/A"}');
    _logger.i('   Digitized By: ${upload.digitizedBy ?? "N/A"}');
    _logger.i('');

    // Parse metadata once
    final metadata = upload.metadata != null
        ? (upload.metadata is String
            ? jsonDecode(upload.metadata as String) as Map<String, dynamic>
            : upload.metadata as Map<String, dynamic>)
        : <String, dynamic>{};

    _logger.i('📋 Metadata: ${metadata.keys.join(", ")}');
    _logger.i('');

    // Use provided file or fallback to original path
    final filePath = fileToUpload?.path ?? upload.filePath;

    // Check if this is a generic document (uploaded through Normal Scan)
    if (upload.personId == 'GENERIC') {
      _logger.i('🔵 TIPO: Upload GENÉRICO (sin persona asociada)');
      _logger.i('   Este documento NO se asociará con ninguna persona del censo');
      _logger.i('');

      // Upload as generic document
      final title = metadata['title'] as String?;
      final tagIds = upload.tags.isNotEmpty
          ? upload.tags.split(',').map((e) => int.parse(e)).toList()
          : null;

      _logger.i('🌐 Llamando a uploadGenericDocument...');
      return await _documentRepository.uploadGenericDocument(
        filePath: filePath, // ⚡ Use potentially optimized file
        fileName: upload.fileName,
        title: title,
        documentTypeId: upload.documentTypeId,
        tagIds: tagIds,
      );
    } else {
      _logger.i('🟢 TIPO: Upload CON PERSONA ASOCIADA');
      _logger.i('   Este documento SÍ se asociará con persona del censo');
      _logger.i('');

      // ⚠️ VALIDACIÓN CRÍTICA
      if (upload.personId == null || upload.personId!.isEmpty) {
        _logger.e('');
        _logger.e('❌❌❌ PROBLEMA CRÍTICO DETECTADO ❌❌❌');
        _logger.e('═══════════════════════════════════════════════════════');
        _logger.e('personId es NULL o vacío en PendingUpload');
        _logger.e('Este upload NO se podrá asociar con ninguna persona');
        _logger.e('');
        _logger.e('Posibles causas:');
        _logger.e('  1. selectedPerson era null al crear el pending upload');
        _logger.e('  2. personId no se guardó correctamente en la base de datos');
        _logger.e('  3. Error en DocumentCaptureScreen al pasar parámetros');
        _logger.e('');
        _logger.e('Upload ID afectado: ${upload.id}');
        _logger.e('File: ${upload.fileName}');
        _logger.e('═══════════════════════════════════════════════════════');
        _logger.e('');
        _logger.e('⚠️ ABORTANDO upload - No tiene sentido continuar sin person_id');
        _logger.e('   El backend rechazaría este upload de todos modos');
        _logger.e('');

        throw Exception(
          'Upload sin person_id. No se puede crear asociación documento-persona. '
          'Verifica que se seleccionó una persona antes de capturar el documento.'
        );
      }

      _logger.i('✅ Validación pasada: person_id presente y válido');
      _logger.i('');
      _logger.i('📦 Construyendo objeto Person desde PendingUpload...');

      // Upload as person-specific document
      final person = entities.Person(
        personId: upload.personId,
        fullName: upload.personName,
        firstName: upload.personName.split(' ').first,
        lastName: upload.personName.split(' ').skip(1).join(' '),
        familyId: upload.familyId,
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      _logger.i('✅ Person object construido:');
      _logger.i('   ID: ${person.personId}');
      _logger.i('   Full Name: ${person.fullName}');
      _logger.i('   First Name: ${person.firstName}');
      _logger.i('   Last Name: ${person.lastName}');
      _logger.i('   Family ID: ${person.familyId}');
      _logger.i('');

      // Extract isReplacement flag from metadata (set by anti-duplicate check)
      final isReplacement = metadata['is_replacement'] as bool? ?? false;

      _logger.i('🎯 Parámetros de upload:');
      _logger.i('   Is Replacement: $isReplacement');
      _logger.i('   Document Type: ${upload.documentType}');
      _logger.i('   Document Number: ${upload.documentNumber ?? "N/A"}');
      _logger.i('');
      _logger.i('🌐 Llamando a DocumentRepository.smartUploadDocumentForPerson...');
      _logger.i('   ✨ SMART UPLOAD: Backend will compare quality automatically');

      try {
        final result = await _documentRepository.smartUploadDocumentForPerson(
          filePath: filePath, // ⚡ Use potentially optimized file
          fileName: upload.fileName,
          person: person,
          documentType: upload.documentType,
          documentNumber: upload.documentNumber,
          digitizedBy: upload.digitizedBy,
        );

        _logger.i('');
        _logger.i('═══════════════════════════════════════════════════════');
        _logger.i('✅✅✅ SMART UPLOAD EXITOSO ✅✅✅');
        _logger.i('═══════════════════════════════════════════════════════');
        _logger.i('Response: $result');
        _logger.i('');

        // Smart upload endpoint returns 'action' field
        final action = result['action'] as String?;
        if (action != null) {
          if (action == 'created') {
            _logger.i('🎉 Documento NUEVO creado:');
            _logger.i('   Document ID: ${result['document_id']}');
            _logger.i('   Person ID: ${result['person_id']}');
            _logger.i('   Relation ID: ${result['relation_id']} ⭐ ASOCIACIÓN CREADA');
            _logger.i('   No existía documento previo');
          } else if (action == 'pending_comparison') {
            _logger.i('🔄 Documento DUPLICADO detectado:');
            _logger.i('   New Document ID: ${result['new_document_id']}');
            _logger.i('   Existing Document ID: ${result['existing_document_id']}');
            _logger.i('   ⏳ Comparación de calidad PENDIENTE (post-OCR)');
            _logger.i('   El sistema comparará automáticamente y mantendrá el mejor');
          } else if (action == 'replaced') {
            _logger.i('✨ Documento REEMPLAZADO:');
            _logger.i('   Kept Document ID: ${result['kept_document_id']}');
            _logger.i('   Deleted Document ID: ${result['deleted_document_id']}');
            _logger.i('   ✅ Se mantuvo el de mejor calidad');
          }
        } else if (result['success'] == true) {
          // Fallback for old endpoint format
          _logger.i('🎉 Backend confirmó éxito (formato antiguo):');
          _logger.i('   Document ID: ${result['document_id']}');
          _logger.i('   Person ID: ${result['person_id']}');
          _logger.i('   Relation ID: ${result['relation_id']}');
        } else {
          _logger.w('⚠️ Respuesta inesperada del backend');
          _logger.w('   Result: $result');
        }

        _logger.i('═══════════════════════════════════════════════════════');

        // Normalize response to include 'id' field for compatibility
        // processUpload() expects response['id']
        if (result['id'] == null) {
          if (result['document_id'] != null) {
            result['id'] = result['document_id'];
          } else if (result['new_document_id'] != null) {
            result['id'] = result['new_document_id'];
          } else if (result['kept_document_id'] != null) {
            result['id'] = result['kept_document_id'];
          }
          _logger.d('   ℹ️  Normalized response: added id=${result['id']} for compatibility');
        }

        return result;

      } catch (e, stackTrace) {
        _logger.e('');
        _logger.e('═══════════════════════════════════════════════════════');
        _logger.e('❌❌❌ ERROR EN UPLOAD CON PERSONA ❌❌❌');
        _logger.e('═══════════════════════════════════════════════════════');
        _logger.e('Error: $e');
        _logger.e('Stack trace: $stackTrace');
        _logger.e('');
        _logger.e('Detalles del upload fallido:');
        _logger.e('   Upload ID: ${upload.id}');
        _logger.e('   Person ID: ${upload.personId}');
        _logger.e('   Person Name: ${upload.personName}');
        _logger.e('   Document Type: ${upload.documentType}');
        _logger.e('   File: ${upload.fileName}');
        _logger.e('═══════════════════════════════════════════════════════');
        rethrow;
      }
    }
  }

  /// Check if file is an image based on extension
  /// ⚡ FASE 2: Helper for image optimization
  bool _isImageFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'].contains(extension);
  }

  /// Format bytes to human-readable string
  /// ⚡ FASE 2: Helper for logging file sizes
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int attempt) {
    // Exponential backoff: 5s, 10s, 20s, 40s...
    final seconds = retryDelayBase.inSeconds * (1 << (attempt - 1));
    return Duration(seconds: seconds.clamp(5, 300)); // Max 5 minutes
  }

  /// Check if error is retryable
  bool _isRetryableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors - retryable
    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout')) {
      return true;
    }

    // Auth errors - not retryable (need user intervention)
    if (errorStr.contains('401') || errorStr.contains('403')) {
      return false;
    }

    // Server errors - retryable
    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
      return true;
    }

    // Client errors - not retryable
    if (errorStr.contains('400') || errorStr.contains('404')) {
      return false;
    }

    // File errors - not retryable
    if (errorStr.contains('file not found')) {
      return false;
    }

    // Default: retry
    return true;
  }

  /// Delete local file after successful sync to Paperless
  /// 🔒 SECURITY & COMPLIANCE: GDPR/Privacy requirement
  /// Files with sensitive personal data MUST be deleted from device after upload
  ///
  /// v4.4.1: Enhanced deletion with MediaStore API support for Android 10+
  /// v4.4.2: Also deletes source directory with scanned images
  Future<void> _deleteLocalFileAfterSync(File file, String filePath, int uploadId) async {
    try {
      // Get upload metadata to check for source directory
      final upload = await _database.getPendingUploadById(uploadId);
      final metadata = upload?.metadata != null
          ? (upload!.metadata is String
              ? jsonDecode(upload.metadata as String) as Map<String, dynamic>
              : upload.metadata as Map<String, dynamic>)
          : <String, dynamic>{};
      final sourceDirectory = metadata['source_directory'] as String?;

      // 🔒 v4.4.2: Enhanced deletion - PDF + source images
      _logger.i('🔒 v4.4.2: Starting secure file deletion after successful sync');
      _logger.i('   └─ Upload ID: $uploadId');
      _logger.i('   └─ PDF File: ${filePath.split('/').last}');
      _logger.i('   └─ PDF Path: $filePath');
      if (sourceDirectory != null) {
        _logger.i('   └─ Source Directory: $sourceDirectory (will also be deleted)');
      }

      // Check if file exists first
      if (!await file.exists()) {
        _logger.w('⚠️ PDF already deleted or not found: $filePath');
      } else {
        // Use enhanced deletion service (supports MediaStore API for Android 10+)
        final deleted = await _fileDeletionService.deleteFile(filePath);

        if (deleted) {
          // 🔒 SECURITY LOG: Document successful PDF deletion
          _logger.i('🔒 SECURITY: PDF deleted successfully after sync');
          _logger.i('   └─ Upload ID: $uploadId');
          _logger.i('   └─ PDF File: ${filePath.split('/').last}');
          _logger.i('   └─ Method: MediaStore API (Android 10+) or direct deletion');
          _logger.i('   └─ Reason: GDPR/Privacy compliance - sensitive data removed from device');
          _logger.i('   └─ Status: ✅ CONFIRMED - PDF deleted from device storage');

          // Verify PDF deletion
          if (await file.exists()) {
            _logger.e('❌ CRITICAL: PDF still exists after deletion reported as successful!');
            _logger.e('   └─ File: $filePath');
            _logger.e('   └─ This may indicate a filesystem caching issue');
          } else {
            _logger.i('   └─ Verification: ✅ PDF confirmed deleted (does not exist)');
          }
        } else {
          // ❌ CRITICAL: PDF Deletion failed
          _logger.e('❌ SECURITY WARNING: Failed to delete PDF after sync!');
          _logger.e('   └─ Upload ID: $uploadId');
          _logger.e('   └─ File: $filePath');
        }
      }

      // v4.4.2: Delete source directory with scanned images after PDF sync
      if (sourceDirectory != null) {
        _logger.i('🧹 v4.4.2: Deleting source directory with scanned images...');
        _logger.i('   └─ Directory: $sourceDirectory');

        final sourceDir = Directory(sourceDirectory);
        if (await sourceDir.exists()) {
          try {
            await sourceDir.delete(recursive: true);
            _logger.i('✅ Source directory deleted successfully');
            _logger.i('   └─ All scanned images removed from device');

            // Also delete from SQLite database
            try {
              final dirName = sourceDirectory.split('/').last;
              final dbHelper = DatabaseHelper();
              await dbHelper.deleteDirectory(dirPath: sourceDirectory);
              _logger.i('✅ Directory removed from database');
              _logger.i('   └─ Directory: $dirName');
            } catch (dbError) {
              _logger.w('⚠️ Failed to remove directory from database: $dbError');
              // Non-critical - directory files are already deleted
            }
          } catch (e) {
            _logger.e('❌ Failed to delete source directory: $e');
            _logger.e('   └─ Directory: $sourceDirectory');
            _logger.e('   └─ Images may still be visible in app');
          }
        } else {
          _logger.w('⚠️ Source directory not found (already deleted or moved)');
          _logger.w('   └─ Directory: $sourceDirectory');
        }
      }
    } catch (e, stackTrace) {
      // ❌ CRITICAL: Log deletion failure but don't block - upload already succeeded
      _logger.e('❌ SECURITY CRITICAL: Exception during file deletion!',
        error: e,
        stackTrace: stackTrace
      );
      _logger.e('   └─ Upload ID: $uploadId');
      _logger.e('   └─ File: $filePath');
      _logger.e('   └─ Error: $e');
      _logger.e('   └─ ACTION REQUIRED: Manual deletion REQUIRED for compliance');

      // Don't throw - upload was successful, deletion is cleanup
      // But log prominently for compliance audit
    }
  }

  /// Process all pending uploads (with parallelization to avoid timeout)
  Future<void> processAllPending() async {
    _logger.i('🔄 Processing all pending uploads');

    // ⚡ FIX: Limit uploads to prevent timeout (90s global timeout)
    const int batchSize = 3;    // Process 3 in parallel
    const int maxUploads = 10;  // Max 10 per sync session

    final pending = await _database.getAllPendingUploads();
    final toProcess = pending.take(maxUploads).toList();

    _logger.i('Found ${pending.length} pending uploads, processing ${toProcess.length}');

    if (toProcess.isEmpty) {
      _logger.i('✅ No pending uploads to process');
      return;
    }

    int successCount = 0;
    int failCount = 0;

    // ⚡ FIX: Process in parallel batches instead of sequential
    for (int i = 0; i < toProcess.length; i += batchSize) {
      final end = (i + batchSize > toProcess.length) ? toProcess.length : i + batchSize;
      final batch = toProcess.sublist(i, end);

      _logger.i('📦 Processing batch ${(i ~/ batchSize) + 1}: ${batch.length} uploads');

      // Process batch in parallel
      final results = await Future.wait(
        batch.map((upload) async {
          try {
            await processUpload(upload.id);
            return true; // Success
          } catch (e) {
            _logger.e('Failed to process upload ${upload.id}: $e');
            return false; // Failed
          }
        }),
        eagerError: false, // Continue even if one fails
      );

      // Count results
      for (final success in results) {
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }
    }

    _logger.i('✅ Finished processing: $successCount succeeded, $failCount failed');

    if (pending.length > maxUploads) {
      _logger.w('⚠️ ${pending.length - maxUploads} uploads remaining for next sync');
    }
  }

  /// Get upload statistics
  Future<Map<String, int>> getStatistics() {
    return _database.getUploadStats();
  }

  /// Get enhanced upload statistics with performance metrics
  Future<Map<String, dynamic>> getEnhancedStatistics() {
    return _database.getEnhancedUploadStats();
  }

  /// Get pending uploads count (with timeout to prevent sync blocking)
  Future<int> getPendingCount() async {
    // ⚡ FIX: Add timeout to prevent DB query from blocking sync
    const timeout = Duration(seconds: 5);

    try {
      return await Future.any([
        _database.countPendingUploads(),
        Future.delayed(timeout, () {
          _logger.w('⚠️ getPendingCount() timed out after 5s');
          return 0; // Return 0 on timeout to allow sync to continue
        }),
      ]);
    } catch (e) {
      _logger.e('❌ getPendingCount() error: $e');
      return 0; // Return 0 on error to allow sync to continue
    }
  }

  /// Get all pending uploads
  Future<List<PendingUpload>> getPendingUploads() {
    return _database.getAllPendingUploads();
  }

  /// Get failed uploads
  Future<List<PendingUpload>> getFailedUploads() {
    return _database.getFailedUploads();
  }

  /// Retry failed upload
  Future<void> retryUpload(int uploadId) async {
    _logger.i('🔄 Retrying upload $uploadId');

    await _database.updateUploadStatus(
      id: uploadId,
      status: 'pending',
      retryCount: 0, // Reset retry count
      lastError: null,
    );

    await processUpload(uploadId);
  }

  /// Retry all failed uploads
  Future<void> retryAllFailed() async {
    final failed = await _database.getFailedUploads();

    _logger.i('🔄 Retrying ${failed.length} failed uploads');

    for (final upload in failed) {
      await retryUpload(upload.id);
    }
  }

  /// Clear all failed uploads
  Future<void> clearFailedUploads() async {
    _logger.i('🗑️ Clearing all failed uploads');
    await _database.clearAllFailed();
  }

  /// Get upload history
  Future<List<UploadHistoryData>> getHistory({int limit = 50}) {
    return _database.getUploadHistory(limit: limit);
  }

  /// Get history by person
  Future<List<UploadHistoryData>> getHistoryByPerson(String personId) {
    return _database.getHistoryByPerson(personId);
  }

  /// Clean old history
  Future<void> cleanOldHistory() async {
    _logger.i('🧹 Cleaning old upload history');
    await _database.cleanOldHistory();
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() {
    return _database.getDatabaseStats();
  }
}
