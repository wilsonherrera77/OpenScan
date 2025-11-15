/// ═══════════════════════════════════════════════════════════════════════════
/// LOGGING SERVICE - Sistema Centralizado de Logs y Monitoreo
/// ═══════════════════════════════════════════════════════════════════════════
///
/// PROPÓSITO: Proporcionar sistema de logging unificado para toda la app,
///            facilitando debugging y análisis de fallas.
///
/// CARACTERÍSTICAS:
/// - 5 niveles de logging (DEBUG, INFO, WARNING, ERROR, CRITICAL)
/// - 7 categorías (UPLOAD, RETRY, NETWORK, AUTH, DATABASE, UI, SYNC)
/// - Formato estructurado con contexto JSON
/// - Output a múltiples destinos (console, file, remote)
/// - Buffer en memoria con límite configurable
/// - Rotación automática de archivos
/// - Timestamps precisos (milisegundos)
/// - Stack traces para errores
/// - Filtrado por nivel y categoría
///
/// INTEGRACIÓN:
/// ```dart
/// final log = LoggingService();
///
/// log.info(
///   category: LogCategory.UPLOAD,
///   message: "Starting document upload",
///   context: {'upload_id': 123, 'person_id': 2071}
/// );
/// ```
///
/// v6.3.2 - Sistema de logging y monitoreo en tiempo real
///
/// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async' show unawaited, Completer, Future, Stream, StreamController;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Niveles de Logging
/// ═══════════════════════════════════════════════════════════════════════════
enum LogLevel {
  DEBUG,    // Información detallada de debugging
  INFO,     // Operaciones normales
  WARNING,  // Situaciones anormales pero recuperables
  ERROR,    // Errores que impiden operación
  CRITICAL  // Errores críticos que pueden crashear app
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Categorías de Logging
/// ═══════════════════════════════════════════════════════════════════════════
enum LogCategory {
  UPLOAD,    // Todo relacionado con subida de documentos
  RETRY,     // Sistema de reintentos
  NETWORK,   // Llamadas HTTP y respuestas
  AUTH,      // Autenticación y autorización
  DATABASE,  // Operaciones SQLite
  UI,        // Interacciones de usuario
  SYNC       // Sincronización background
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Entrada de Log Individual
/// ═══════════════════════════════════════════════════════════════════════════
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final Map<String, dynamic>? context;
  final String? location; // Archivo:línea donde se generó
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.context,
    this.location,
    this.stackTrace,
  });

  /// Convierte LogEntry a formato String estructurado
  String toFormattedString() {
    final timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final levelStr = level.toString().split('.').last.padRight(8);
    final categoryStr = category.toString().split('.').last.padRight(8);
    final locationStr = location ?? 'Unknown';

    var result = '[$timestampStr] [$levelStr] [$categoryStr] $locationStr $message';

    if (context != null && context!.isNotEmpty) {
      result += ' | ${jsonEncode(context)}';
    }

    if (stackTrace != null) {
      result += '\n$stackTrace';
    }

    return result;
  }

  /// Convierte LogEntry a JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString().split('.').last,
      'category': category.toString().split('.').last,
      'message': message,
      'context': context,
      'location': location,
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Servicio de Logging (Singleton)
/// ═══════════════════════════════════════════════════════════════════════════
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // Configuración
  final int _maxBufferSize = 1000;
  final int _maxLogFileSizeMB = 50;
  final int _maxLogFilesCount = 7; // 7 días de logs

  // Estado interno
  final List<LogEntry> _logBuffer = [];
  File? _currentLogFile;
  bool _initialized = false;
  LogLevel _minLevel = LogLevel.DEBUG; // Nivel mínimo a loggear

  // Stream para logs en tiempo real
  final _logStreamController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// ═══════════════════════════════════════════════════════════════════════
  /// Inicializa el servicio de logging
  /// ═══════════════════════════════════════════════════════════════════════
  Future<void> initialize({LogLevel minLevel = LogLevel.DEBUG}) async {
    if (_initialized) return;

    _minLevel = minLevel;

    try {
      // Obtener directorio de logs
      final directory = await _getLogsDirectory();

      // Crear directorio si no existe
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Crear archivo de log del día actual
      _currentLogFile = await _createTodayLogFile(directory);

      // Rotar logs antiguos
      await _rotateOldLogs(directory);

      _initialized = true;

      // Log de inicialización
      info(
        category: LogCategory.UI,
        message: 'LoggingService initialized successfully',
        context: {
          'min_level': minLevel.toString(),
          'log_directory': directory.path,
          'log_file': _currentLogFile?.path,
        },
      );
    } catch (e, stackTrace) {
      // Fallback: solo imprimir a console si falla inicialización
      developer.log(
        'Failed to initialize LoggingService: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Obtiene el directorio de logs
  /// ═══════════════════════════════════════════════════════════════════════
  Future<Directory> _getLogsDirectory() async {
    final externalDir = await getExternalStorageDirectory();
    return Directory('${externalDir!.path}/logs');
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Crea el archivo de log del día actual
  /// ═══════════════════════════════════════════════════════════════════════
  Future<File> _createTodayLogFile(Directory directory) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final filePath = '${directory.path}/app_$today.log';
    final file = File(filePath);

    // Si no existe, crear con header
    if (!await file.exists()) {
      await file.create();
      await file.writeAsString(
        '═══════════════════════════════════════════════════════════════\n'
        'LUMARA LOG FILE - $today\n'
        '═══════════════════════════════════════════════════════════════\n\n',
      );
    }

    return file;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Rota logs antiguos (elimina logs > 7 días)
  /// ═══════════════════════════════════════════════════════════════════════
  Future<void> _rotateOldLogs(Directory directory) async {
    try {
      final files = await directory.list().toList();
      final logFiles = files.whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      // Ordenar por fecha de modificación (más antiguos primero)
      logFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Si hay más de maxLogFilesCount, eliminar los más antiguos
      if (logFiles.length > _maxLogFilesCount) {
        final filesToDelete = logFiles.take(logFiles.length - _maxLogFilesCount);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      developer.log('Failed to rotate old logs: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Método principal de logging
  /// ═══════════════════════════════════════════════════════════════════════
  void log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    // Filtrar por nivel mínimo
    if (level.index < _minLevel.index) return;

    // Obtener ubicación del caller (archivo:línea)
    final location = _getCallerLocation();

    // Crear entrada de log
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      context: context,
      location: location,
      stackTrace: stackTrace,
    );

    // Agregar a buffer
    _addToBuffer(entry);

    // ⚡ v6.3.7: Escribir a archivo con catchError para evitar crashes silenciosos
    _writeToFile(entry).catchError((e) => developer.log('Log write failed: $e'));

    // Imprimir a console (Android logcat)
    _printToConsole(entry);

    // Emitir en stream para listeners
    _logStreamController.add(entry);
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Agrega entrada al buffer en memoria
  /// ═══════════════════════════════════════════════════════════════════════
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);

    // Limitar tamaño del buffer
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Escribe entrada a archivo de log
  /// ═══════════════════════════════════════════════════════════════════════
  /// ⚡ v6.3.7: NON-BLOCKING log write using IOSink
  /// Previous version used await File.writeAsString() which BLOCKED the Dart isolate
  /// under heavy I/O load, freezing ALL execution including debug logs.
  ///
  /// IOSink.writeln() is synchronous and buffered - does NOT block the isolate.
  Future<void> _writeToFile(LogEntry entry) async {
    if (!_initialized || _currentLogFile == null) return;

    try {
      final formattedLog = entry.toFormattedString();

      // ⚡ v6.3.7: Use IOSink for non-blocking writes
      final sink = _currentLogFile!.openWrite(mode: FileMode.append);
      sink.writeln(formattedLog);

      // ⚡ Close without await - fire and forget (non-blocking)
      unawaited(sink.close());

      // ⚡ Check file size asynchronously without blocking
      unawaited(_checkAndRotateLogFile());
    } catch (e) {
      developer.log('Failed to write log to file: $e');
    }
  }

  /// ⚡ v6.3.7: Separate method for non-blocking file rotation
  Future<void> _checkAndRotateLogFile() async {
    if (_currentLogFile == null) return;

    try {
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxLogFileSizeMB * 1024 * 1024) {
        final directory = await _getLogsDirectory();
        final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        final newFilePath = '${directory.path}/app_$timestamp.log';
        _currentLogFile = File(newFilePath);
        await _currentLogFile!.create();
      }
    } catch (e) {
      developer.log('Failed to rotate log file: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Imprime entrada a console (Android logcat)
  /// ═══════════════════════════════════════════════════════════════════════
  void _printToConsole(LogEntry entry) {
    final formattedLog = entry.toFormattedString();

    // Usar dart:developer log para mejor integración con logcat
    developer.log(
      formattedLog,
      name: 'Lumara.${entry.category.toString().split('.').last}',
      level: _logLevelToInt(entry.level),
      error: entry.level == LogLevel.ERROR || entry.level == LogLevel.CRITICAL ? entry.message : null,
      stackTrace: entry.stackTrace,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Convierte LogLevel a int para dart:developer
  /// ═══════════════════════════════════════════════════════════════════════
  int _logLevelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.DEBUG:
        return 500; // FINE
      case LogLevel.INFO:
        return 800; // INFO
      case LogLevel.WARNING:
        return 900; // WARNING
      case LogLevel.ERROR:
        return 1000; // SEVERE
      case LogLevel.CRITICAL:
        return 1200; // SHOUT
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Obtiene ubicación del caller (archivo:línea)
  /// ═══════════════════════════════════════════════════════════════════════
  String _getCallerLocation() {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');

      // Buscar el primer frame que NO sea de logging_service.dart
      for (var frame in frames) {
        if (!frame.contains('logging_service.dart') &&
            frame.contains('.dart')) {
          // Extraer información del frame
          final match = RegExp(r'([^/]+\.dart):(\d+)').firstMatch(frame);
          if (match != null) {
            final file = match.group(1);
            final line = match.group(2);
            return '$file:$line';
          }
        }
      }
    } catch (e) {
      // Silencioso: si falla, retornar Unknown
    }

    return 'Unknown';
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Métodos de conveniencia para cada nivel
  /// ═══════════════════════════════════════════════════════════════════════

  void debug({
    required LogCategory category,
    required String message,
    Map<String, dynamic>? context,
  }) {
    log(
      level: LogLevel.DEBUG,
      category: category,
      message: message,
      context: context,
    );
  }

  void info({
    required LogCategory category,
    required String message,
    Map<String, dynamic>? context,
  }) {
    log(
      level: LogLevel.INFO,
      category: category,
      message: message,
      context: context,
    );
  }

  void warning({
    required LogCategory category,
    required String message,
    Map<String, dynamic>? context,
  }) {
    log(
      level: LogLevel.WARNING,
      category: category,
      message: message,
      context: context,
    );
  }

  void error({
    required LogCategory category,
    required String message,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.ERROR,
      category: category,
      message: message,
      context: context,
      stackTrace: stackTrace,
    );
  }

  void critical({
    required LogCategory category,
    required String message,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.CRITICAL,
      category: category,
      message: message,
      context: context,
      stackTrace: stackTrace,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Obtiene logs del buffer
  /// ═══════════════════════════════════════════════════════════════════════
  List<LogEntry> getRecentLogs({int count = 100}) {
    final startIndex = _logBuffer.length > count ? _logBuffer.length - count : 0;
    return _logBuffer.sublist(startIndex);
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Filtra logs por nivel y/o categoría
  /// ═══════════════════════════════════════════════════════════════════════
  List<LogEntry> filterLogs({
    LogLevel? level,
    LogCategory? category,
    int count = 100,
  }) {
    var filtered = _logBuffer.where((entry) {
      if (level != null && entry.level != level) return false;
      if (category != null && entry.category != category) return false;
      return true;
    }).toList();

    final startIndex = filtered.length > count ? filtered.length - count : 0;
    return filtered.sublist(startIndex);
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Exporta logs a archivo
  /// ═══════════════════════════════════════════════════════════════════════
  Future<File> exportLogs({String? filename}) async {
    final directory = await _getLogsDirectory();
    final exportFilename = filename ?? 'export_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.log';
    final exportFile = File('${directory.path}/$exportFilename');

    final buffer = StringBuffer();
    for (final entry in _logBuffer) {
      buffer.writeln(entry.toFormattedString());
    }

    await exportFile.writeAsString(buffer.toString());
    return exportFile;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// Limpia buffer y cierra streams
  /// ═══════════════════════════════════════════════════════════════════════
  void dispose() {
    _logBuffer.clear();
    _logStreamController.close();
  }
}
