/// ═══════════════════════════════════════════════════════════════════════════
/// LOGGER ADAPTER - Adaptador de Compatibilidad para Logger Package
/// ═══════════════════════════════════════════════════════════════════════════
///
/// PROPÓSITO: Proporcionar API compatible con Logger package pero escribiendo
///            a archivo vía LoggingService para visibilidad en producción.
///
/// PROBLEMA RESUELTO:
/// - Logger package solo escribe a logcat (invisible en release mode)
/// - 42 archivos usaban Logger con llamadas simples: _logger.i("mensaje")
/// - Necesitamos logs visibles en producción sin reescribir 42 archivos
///
/// SOLUCIÓN:
/// - API idéntica a Logger: .d(), .i(), .w(), .e()
/// - Internamente usa LoggingService (escribe a archivo)
/// - Inferencia automática de categorías basada en contenido del mensaje
/// - Drop-in replacement: solo cambiar import
///
/// MIGRACIÓN:
/// ```dart
/// // ANTES:
/// import '../services/logger_adapter.dart';
/// final LoggerAdapter _logger = LoggerAdapter();
/// _logger.i('📤 Uploading document');
///
/// // DESPUÉS:
/// import '../services/logger_adapter.dart';
/// final LoggerAdapter _logger = LoggerAdapter();
/// _logger.i('📤 Uploading document'); // Mismo código!
/// ```
///
/// CATEGORÍAS INFERIDAS:
/// - UPLOAD: mensaje contiene "upload", "sync", "📤", "🔄"
/// - AUTH: mensaje contiene "auth", "login", "token", "🔑", "🔐"
/// - NETWORK: mensaje contiene "network", "http", "api", "🌐", "📡"
/// - RETRY: mensaje contiene "retry", "attempt", "🔁"
/// - DATABASE: mensaje contiene "database", "db", "sqlite", "📊"
/// - SYNC: mensaje contiene "sync", "background"
/// - UI: default para todo lo demás
///
/// v6.3.4 - Adapter para compatibilidad con Logger package
///
/// ═══════════════════════════════════════════════════════════════════════════

import 'logging_service.dart';

/// Adaptador compatible con Logger package
/// Escribe a archivo vía LoggingService en lugar de solo logcat
class LoggerAdapter {
  // Instancia singleton de LoggingService
  final LoggingService _log = LoggingService();

  /// Constructor
  LoggerAdapter();

  // ═══════════════════════════════════════════════════════════════════════
  // API COMPATIBLE CON LOGGER PACKAGE
  // ═══════════════════════════════════════════════════════════════════════

  /// Debug level - Información detallada de debugging
  void d(String message, {dynamic error, StackTrace? stackTrace}) {
    _log.debug(
      category: _inferCategory(message),
      message: _cleanMessage(message),
      context: error != null ? {'error': error.toString()} : null,
    );
  }

  /// Info level - Operaciones normales
  void i(String message, {dynamic error, StackTrace? stackTrace}) {
    _log.info(
      category: _inferCategory(message),
      message: _cleanMessage(message),
      context: error != null ? {'error': error.toString()} : null,
    );
  }

  /// Warning level - Situaciones anormales pero recuperables
  void w(String message, {dynamic error, StackTrace? stackTrace}) {
    _log.warning(
      category: _inferCategory(message),
      message: _cleanMessage(message),
      context: error != null ? {'error': error.toString()} : null,
    );
  }

  /// Error level - Errores que impiden operación
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    _log.error(
      category: _inferCategory(message),
      message: _cleanMessage(message),
      context: error != null ? {'error': error.toString()} : null,
      stackTrace: stackTrace,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INFERENCIA AUTOMÁTICA DE CATEGORÍAS
  // ═══════════════════════════════════════════════════════════════════════

  /// Infiere la categoría del log basándose en el contenido del mensaje
  ///
  /// Reglas de inferencia (en orden de prioridad):
  /// 1. UPLOAD: palabras clave relacionadas con subida de archivos
  /// 2. AUTH: palabras clave de autenticación
  /// 3. NETWORK: palabras clave de red/HTTP
  /// 4. RETRY: palabras clave de reintentos
  /// 5. DATABASE: palabras clave de base de datos
  /// 6. SYNC: palabras clave de sincronización
  /// 7. UI: default si no coincide con ninguna
  LogCategory _inferCategory(String message) {
    final lowerMsg = message.toLowerCase();

    // UPLOAD: subida de documentos
    if (_containsAny(lowerMsg, [
      'upload', 'uploading', 'subida', 'subiendo',
      '📤', '📥', 'enqueue', 'document', 'file',
    ])) {
      return LogCategory.UPLOAD;
    }

    // AUTH: autenticación y autorización
    if (_containsAny(lowerMsg, [
      'auth', 'login', 'logout', 'token', 'password',
      '🔑', '🔐', '🔓', 'credential', 'permission',
    ])) {
      return LogCategory.AUTH;
    }

    // NETWORK: llamadas HTTP y respuestas
    if (_containsAny(lowerMsg, [
      'network', 'http', 'api', 'request', 'response',
      '🌐', '📡', 'endpoint', 'post', 'get', 'put', 'delete',
    ])) {
      return LogCategory.NETWORK;
    }

    // RETRY: sistema de reintentos
    if (_containsAny(lowerMsg, [
      'retry', 'retrying', 'attempt', 'reintento',
      '🔁', '🔄', 'fallback', 'backoff',
    ])) {
      return LogCategory.RETRY;
    }

    // DATABASE: operaciones SQLite
    if (_containsAny(lowerMsg, [
      'database', 'db', 'sqlite', 'query', 'insert',
      '📊', 'table', 'migration', 'drift',
    ])) {
      return LogCategory.DATABASE;
    }

    // SYNC: sincronización background
    if (_containsAny(lowerMsg, [
      'sync', 'background', 'foreground', 'task',
      'synchroniz', 'sincroniz',
    ])) {
      return LogCategory.SYNC;
    }

    // Default: UI interactions
    return LogCategory.UI;
  }

  /// Helper: verifica si el mensaje contiene alguna de las palabras clave
  bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  /// Limpia el mensaje de emojis redundantes para formato de archivo
  /// (LoggingService ya agrega prefijos por categoría)
  String _cleanMessage(String message) {
    // Remover emojis comunes al inicio que son redundantes
    var cleaned = message.trim();

    // Lista de emojis a remover si están al inicio
    final redundantEmojis = [
      '📤', '📥', '🔄', '🔁', '✅', '❌', '⚠️', '🔑', '🔐',
      '🔓', '🌐', '📡', '📊', '🎯', '💾', '📁', '🗂️',
    ];

    for (final emoji in redundantEmojis) {
      if (cleaned.startsWith(emoji)) {
        cleaned = cleaned.substring(emoji.length).trim();
      }
    }

    return cleaned;
  }
}
