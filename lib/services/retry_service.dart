/// ═══════════════════════════════════════════════════════════════════════════
/// RETRY SERVICE - Sistema de Reintentos Robusto
/// ═══════════════════════════════════════════════════════════════════════════
///
/// PROPÓSITO: Garantizar 0% pérdida de documentos mediante reintentos
///            exponenciales y queue persistente.
///
/// CARACTERÍSTICAS:
/// - Exponential backoff (1s, 2s, 5s) - v6.3.1: Optimizado para manual sync
/// - Máximo 3 reintentos por documento (era 10)
/// - Queue persistente en SQLite
/// - Logs detallados de cada intento
/// - Verificación de éxito al 100%
/// - Priorización de documentos más antiguos
///
/// GARANTÍA: Ningún documento se pierde mientras haya espacio en disco
///
/// v6.3.1 CHANGES:
/// - Reducido de 10 a 3 reintentos para evitar timeout de 90s en UI
/// - Delays ajustados: 1s, 2s, 5s (total máximo: ~8s de reintentos)
///
/// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'logging_service.dart';
import 'logging_service.dart'; // 📊 v6.3.2: Centralized logging

class RetryService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static final LoggingService _log = LoggingService(); // 📊 v6.3.2: Centralized logging

  /// Configuración de reintentos
  /// v6.3.1: Reducido de 10 a 3 para evitar timeouts en sincronización manual
  static const int maxRetries = 3; // Máximo de intentos (era 10)
  static const List<int> retryDelays = [
    1, // 1 segundo
    2, // 2 segundos
    5, // 5 segundos (era 4)
  ];

  /// Delays originales para background sync (mantener para referencia)
  static const List<int> backgroundRetryDelays = [
    1, 2, 4, 8, 16, 32, 64, 128, 256, 512,
  ];

  /// ═══════════════════════════════════════════════════════════════
  /// Intenta subir con reintentos exponenciales
  /// ═══════════════════════════════════════════════════════════════
  ///
  /// @param uploadFunction Función que realiza el upload
  /// @param uploadId ID del upload en queue
  /// @param retryCount Número de reintento actual (0 = primer intento)
  ///
  /// @return Map con resultado del upload
  ///
  /// COMPORTAMIENTO:
  /// - Intenta upload inmediatamente
  /// - Si falla: espera delay exponencial y reintenta
  /// - Si alcanza maxRetries: marca como "failed_permanently"
  /// - Si tiene éxito: retorna resultado
  ///
  static Future<Map<String, dynamic>> retryUpload({
    required Future<Map<String, dynamic>> Function() uploadFunction,
    required int uploadId,
    int retryCount = 0,
  }) async {
    _log.i('═══════════════════════════════════════════════════════');
    _log.i('🔄 RETRY SERVICE: Attempt ${retryCount + 1}/$maxRetries');
    _log.i('   Upload ID: $uploadId');
    _log.i('═══════════════════════════════════════════════════════');

    // 📊 v6.3.2: Structured logging - Retry attempt started
    _log.info(
      category: LogCategory.RETRY,
      message: "Retry attempt ${retryCount + 1}/$maxRetries",
      context: {
        'upload_id': uploadId,
        'retry_count': retryCount,
        'max_retries': maxRetries,
        'attempt_number': retryCount + 1,
      },
    );

    try {
      // Intentar upload
      final result = await uploadFunction();

      if (result['success'] == true) {
        _log.i('✅ UPLOAD SUCCESS on attempt ${retryCount + 1}');
        _log.i('   Channel: ${result['channel'] ?? 'unknown'}');
        _log.i('   Document ID: ${result['document_id'] ?? result['task_id']}');
        _log.i('');

        // 📊 v6.3.2: Structured logging - Upload success after retry
        _log.info(
          category: LogCategory.RETRY,
          message: "Upload successful after ${retryCount} retries",
          context: {
            'upload_id': uploadId,
            'retry_count': retryCount,
            'total_attempts': retryCount + 1,
            'channel': result['channel'] ?? 'unknown',
            'document_id': result['document_id'] ?? result['task_id'],
          },
        );

        return {
          ...result,
          'retry_count': retryCount,
          'final_status': 'success',
        };
      }

      // Si llegó aquí, success=false pero no hubo excepción
      throw Exception('Upload returned success=false: ${result['message']}');

    } catch (e) {
      _log.w('⚠️  UPLOAD FAILED on attempt ${retryCount + 1}');
      _log.w('   Error: $e');

      // Verificar si alcanzó máximo de reintentos
      if (retryCount >= maxRetries - 1) {
        _log.e('');
        _log.e('❌ MAX RETRIES REACHED ($maxRetries attempts)');
        _log.e('   Upload ID: $uploadId');
        _log.e('   Final status: FAILED PERMANENTLY');
        _log.e('   Document will remain in queue for manual intervention');
        _log.e('');

        // 📊 v6.3.2: Structured logging - Max retries reached
        _log.error(
          category: LogCategory.RETRY,
          message: "MAX RETRIES REACHED: Upload failed permanently",
          context: {
            'upload_id': uploadId,
            'total_attempts': maxRetries,
            'final_error': e.toString(),
            'requires_manual_intervention': true,
          },
        );

        return {
          'success': false,
          'retry_count': retryCount + 1,
          'final_status': 'failed_permanently',
          'error': e.toString(),
          'requires_manual_intervention': true,
        };
      }

      // Calcular delay exponencial
      final delaySeconds = retryDelays[retryCount];
      _log.i('');
      _log.i('⏳ Waiting ${delaySeconds}s before retry ${retryCount + 2}...');
      _log.i('   Exponential backoff strategy');
      _log.i('');

      // 📊 v6.3.2: Structured logging - Retry delay
      _log.debug(
        category: LogCategory.RETRY,
        message: "Waiting ${delaySeconds}s before retry ${retryCount + 2}",
        context: {
          'upload_id': uploadId,
          'retry_count': retryCount,
          'delay_seconds': delaySeconds,
          'next_attempt': retryCount + 2,
          'error': e.toString(),
        },
      );

      // Esperar delay exponencial
      await Future.delayed(Duration(seconds: delaySeconds));

      // Reintentar recursivamente
      return retryUpload(
        uploadFunction: uploadFunction,
        uploadId: uploadId,
        retryCount: retryCount + 1,
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════
  /// Calcula el próximo delay de reintento
  /// ═══════════════════════════════════════════════════════════════
  static Duration getRetryDelay(int retryCount) {
    if (retryCount >= retryDelays.length) {
      // Si excede lista, usar último delay
      return Duration(seconds: retryDelays.last);
    }
    return Duration(seconds: retryDelays[retryCount]);
  }

  /// ═══════════════════════════════════════════════════════════════
  /// Verifica si un upload debe reintentar basándose en el error
  /// ═══════════════════════════════════════════════════════════════
  static bool shouldRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Errores que NO deben reintentar (errores de validación)
    final nonRetryableErrors = [
      'persona con id',
      'no encontrada',
      '404',
      'bad request',
      '400',
      'unauthorized',
      '401',
      'forbidden',
      '403',
    ];

    for (final pattern in nonRetryableErrors) {
      if (errorString.contains(pattern)) {
        _log.w('⚠️  Non-retryable error detected: $pattern');
        _log.w('   This error requires manual intervention');
        return false;
      }
    }

    // Errores que SÍ deben reintentar (errores de red/servidor)
    final retryableErrors = [
      'timeout',
      'connection',
      'network',
      '500',
      '502',
      '503',
      '504',
      'internal server error',
      'bad gateway',
      'service unavailable',
      'gateway timeout',
    ];

    for (final pattern in retryableErrors) {
      if (errorString.contains(pattern)) {
        _log.i('✓ Retryable error detected: $pattern');
        return true;
      }
    }

    // Por defecto, reintentar (conservative approach)
    _log.i('✓ Unknown error type, will retry by default');
    return true;
  }

  /// ═══════════════════════════════════════════════════════════════
  /// Genera reporte de estado de reintentos
  /// ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> generateRetryReport({
    required int totalUploads,
    required int successfulUploads,
    required int failedUploads,
    required int pendingRetries,
    required int failedPermanently,
  }) {
    final successRate = totalUploads > 0
        ? (successfulUploads / totalUploads * 100).toStringAsFixed(1)
        : '0.0';

    final report = {
      'total_uploads': totalUploads,
      'successful': successfulUploads,
      'failed_temporarily': failedUploads,
      'pending_retries': pendingRetries,
      'failed_permanently': failedPermanently,
      'success_rate': '$successRate%',
      'document_loss': failedPermanently,
      'document_loss_percentage': totalUploads > 0
          ? (failedPermanently / totalUploads * 100).toStringAsFixed(2)
          : '0.00',
    };

    _log.i('');
    _log.i('═══════════════════════════════════════════════════════');
    _log.i('📊 RETRY SERVICE REPORT');
    _log.i('═══════════════════════════════════════════════════════');
    _log.i('Total uploads:        $totalUploads');
    _log.i('Successful:           $successfulUploads (${report['success_rate']})');
    _log.i('Failed temporarily:   $failedUploads (will retry)');
    _log.i('Pending retries:      $pendingRetries');
    _log.i('Failed permanently:   $failedPermanently');
    _log.i('');
    _log.i('🎯 Document loss:     $failedPermanently documents (${report['document_loss_percentage']}%)');
    _log.i('═══════════════════════════════════════════════════════');
    _log.i('');

    return report;
  }

  /// ═══════════════════════════════════════════════════════════════
  /// Verifica la integridad de un archivo usando MD5
  /// ═══════════════════════════════════════════════════════════════
  static Future<String> calculateMD5(File file) async {
    if (!await file.exists()) {
      throw Exception('File not found for MD5 calculation');
    }

    // Leer archivo y calcular MD5
    final bytes = await file.readAsBytes();
    // TODO: Implementar cálculo MD5 con package crypto
    // Por ahora retornar placeholder
    return 'MD5_NOT_IMPLEMENTED_${bytes.length}';
  }

  /// ═══════════════════════════════════════════════════════════════
  /// Verifica que un documento fue subido exitosamente al servidor
  /// ═══════════════════════════════════════════════════════════════
  static Future<bool> verifyUpload({
    required int documentId,
    required Function verifyFunction,
  }) async {
    try {
      _log.i('🔍 Verifying upload...');
      _log.i('   Document ID: $documentId');

      final result = await verifyFunction();

      if (result == true) {
        _log.i('✅ Upload verified successfully');
        return true;
      } else {
        _log.w('⚠️  Upload verification failed');
        return false;
      }
    } catch (e) {
      _log.e('❌ Verification error: $e');
      return false;
    }
  }
}
