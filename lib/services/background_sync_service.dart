import 'dart:async';
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/logger_adapter.dart';
import 'package:lumara_scan/data/local/database/app_database.dart';
import 'package:lumara_scan/data/datasources/paperless_api_client.dart';
import 'package:lumara_scan/data/repositories/document_repository.dart';
import 'package:lumara_scan/services/upload_service.dart';
import 'package:lumara_scan/services/connectivity_service.dart';

/// Background Sync Service with Foreground Task
/// Provides robust background synchronization with retry logic
/// Compatible with Android SDK 36
class BackgroundSyncService {
  static final LoggerAdapter _logger = LoggerAdapter();

  /// Initialize background sync service
  static Future<void> initialize() async {
    _logger.i('🚀 Initializing BackgroundSyncService with foreground task support...');

    // Initialize foreground task
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'lumara_sync_channel',
        channelName: 'Lumara Scan Sincronización',
        channelDescription: 'Notificación de sincronización de documentos en segundo plano',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000), // 5 minutes
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _logger.i('✅ BackgroundSyncService initialized');
  }

  /// Start periodic background sync
  static Future<bool> startPeriodicSync({
    Duration interval = const Duration(minutes: 15),
  }) async {
    try {
      _logger.i('🔄 Starting periodic background sync (every ${interval.inMinutes} minutes)...');

      // Start foreground service
      final ServiceRequestResult startResult =
          await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Lumara Scan',
        notificationText: 'Sincronización automática activada',
        callback: startCallback,
      );

      if (startResult is ServiceRequestSuccess) {
        _logger.i('✅ Periodic sync started');
        return true;
      } else {
        _logger.e('❌ Failed to start periodic sync: $startResult');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error starting periodic sync: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Stop periodic background sync
  static Future<void> stopPeriodicSync() async {
    try {
      _logger.i('🛑 Stopping periodic sync...');

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        _logger.i('✅ Periodic sync stopped');
      } else {
        _logger.d('ℹ️ Periodic sync was not running');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error stopping periodic sync: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// Background sync callback (entry point for foreground task)
  @pragma('vm:entry-point')
  static void startCallback() {
    FlutterForegroundTask.setTaskHandler(_BackgroundSyncHandler());
  }

  /// Schedule immediate sync (manual trigger)
  ///
  /// ⚡ v6.0.5: Added global timeout (90s) to prevent infinite loading
  static Future<bool> scheduleImmediateSync() async {
    debugPrint('🔵 [BG-SYNC-DEBUG] scheduleImmediateSync() CALLED');
    try {
      _logger.i('🔄 Starting immediate manual sync with 90s timeout...');

      // ✅ v6.0.5: Global timeout - NEVER wait more than 90 seconds
      debugPrint('🔵 [BG-SYNC-DEBUG] Calling _performSync() with 90s timeout...');
      return await Future.any([
        _performSync(),
        Future.delayed(
          const Duration(seconds: 90),
          () {
            _logger.w('⏰ Sync timeout after 90 seconds');
            debugPrint('🔴 [BG-SYNC-DEBUG] TIMEOUT after 90 seconds');
            return false;
          },
        ),
      ]);
    } catch (e, stackTrace) {
      _logger.e('❌ Immediate sync failed: $e', error: e, stackTrace: stackTrace);
      debugPrint('🔴 [BG-SYNC-DEBUG] ERROR: $e');
      return false;
    }
  }

  /// Extract sync logic to separate method
  /// ⚡ v6.0.5: Extracted for timeout control
  static Future<bool> _performSync() async {
    debugPrint('🔵 [BG-SYNC-DEBUG] _performSync() STARTED');

    // Step 1: Check connectivity
    debugPrint('🔵 [BG-SYNC-DEBUG] Step 1: Checking connectivity...');
    final hasConnection = await ConnectivityService.hasInternetConnection();
    debugPrint('🔵 [BG-SYNC-DEBUG] hasConnection=$hasConnection');
    if (!hasConnection) {
      _logger.w('⚠️ No internet connection, waiting...');

      // Wait for connection (up to 30 seconds)
      final connected = await ConnectivityService.waitForConnection(
        timeout: const Duration(seconds: 30),
      );

      if (!connected) {
        _logger.e('❌ Sync aborted: No internet connection');
        return false;
      }
    }

    // Step 2: Verify Paperless server
    final apiClient = PaperlessApiClient();
    final baseUrl = apiClient.baseUrl;

    final serverCheck = await ConnectivityService.validatePaperlessConnection(baseUrl);
    if (serverCheck['error'] != null) {
      _logger.e('❌ Paperless server validation failed: ${serverCheck['error']}');
      return false;
    }

    _logger.i('✅ Server validated (latency: ${serverCheck['latencyMs']}ms)');
    debugPrint('🔵 [BG-SYNC-DEBUG] Step 2: Server validated, latency=${serverCheck['latencyMs']}ms');

    // Step 3: Execute sync with retry logic
    debugPrint('🔵 [BG-SYNC-DEBUG] Step 3: Executing sync with retry logic...');
    // ✅ v6.0.5: Reduced maxRetries from 3 to 2 (faster to fail)
    final result = await ConnectivityService.retryWithBackoff<bool>(
      operation: () async {
        // ⚡ v6.3.5: Exhaustive logging + timeout for database initialization
        _logger.d('🔧 [SYNC] Step 1: Creating AppDatabase instance...');

        late AppDatabase database;
        try {
          // Timeout de 30s para inicialización de DB
          database = await Future.any([
            Future(() async {
              _logger.d('🔧 [SYNC] Calling AppDatabase() constructor...');
              final db = AppDatabase();
              _logger.d('✅ [SYNC] AppDatabase() constructor completed');
              return db;
            }),
            Future.delayed(
              const Duration(seconds: 30),
              () => throw TimeoutException('AppDatabase initialization timeout after 30s'),
            ),
          ]);
          _logger.i('✅ [SYNC] AppDatabase initialized successfully');
        } catch (e, stackTrace) {
          _logger.e('❌ [SYNC] AppDatabase initialization failed: $e', error: e, stackTrace: stackTrace);
          rethrow;
        }

        _logger.d('🔧 [SYNC] Step 2: Creating DocumentRepository...');
        final documentRepository = DocumentRepository(apiClient, database); // ⚡ FASE 2: Added database
        _logger.d('✅ [SYNC] DocumentRepository created');

        _logger.d('🔧 [SYNC] Step 3: Creating UploadService...');
        final uploadService = UploadService(database, documentRepository);
        _logger.d('✅ [SYNC] UploadService created');

        _logger.d('🔧 [SYNC] Step 4: Getting pending uploads count...');
        debugPrint('🔵 [BG-SYNC-DEBUG] Getting pending uploads count...');
        final pendingBefore = await uploadService.getPendingCount();
        _logger.i('📊 Pending uploads: $pendingBefore');
        debugPrint('🔵 [BG-SYNC-DEBUG] Pending uploads: $pendingBefore');

        if (pendingBefore == 0) {
          _logger.i('✅ No pending uploads');
          debugPrint('🔵 [BG-SYNC-DEBUG] No pending uploads, returning true');
          return true;
        }

        // Process all pending uploads
        debugPrint('🔵 [BG-SYNC-DEBUG] Processing $pendingBefore pending uploads...');
        await uploadService.processAllPending();
        debugPrint('🔵 [BG-SYNC-DEBUG] processAllPending() completed');

        final stats = await uploadService.getStatistics();
        _logger.i('✅ Sync completed: $stats');
        debugPrint('🔵 [BG-SYNC-DEBUG] Sync completed: $stats');

        return true;
      },
      operationName: 'Manual sync',
      maxRetries: 2,  // ✅ v6.0.5: REDUCED from 3 to 2
      initialDelay: const Duration(seconds: 2),
    );

    return result ?? false;
  }

  /// Check if periodic sync is running
  static Future<bool> isPeriodicSyncRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Cancel all background tasks
  static Future<void> cancelAll() async {
    await stopPeriodicSync();
  }

  /// Cancel periodic sync (alias)
  static Future<void> cancelPeriodicSync() async {
    await stopPeriodicSync();
  }

  /// Re-schedule periodic sync
  static Future<void> rescheduleSync({required Duration frequency}) async {
    await stopPeriodicSync();
    await Future.delayed(const Duration(seconds: 1));
    await startPeriodicSync(interval: frequency);
  }
}

/// Background Sync Task Handler
/// Handles background sync execution in isolate
class _BackgroundSyncHandler extends TaskHandler {
  static final LoggerAdapter _logger = LoggerAdapter();
  int _syncCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _logger.i('🚀 Background sync handler started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    _syncCount++;
    _logger.i('🔄 Background sync event #$_syncCount triggered');

    try {
      // Update notification
      FlutterForegroundTask.updateService(
        notificationTitle: 'Lumara Scan',
        notificationText: 'Sincronizando documentos... (#$_syncCount)',
      );

      // Check connectivity
      final hasConnection = await ConnectivityService.hasInternetConnection();
      if (!hasConnection) {
        _logger.w('⚠️ No internet connection, skipping sync');
        FlutterForegroundTask.updateService(
          notificationTitle: 'Lumara Scan',
          notificationText: 'Esperando conexión a Internet...',
        );
        return;
      }

      // Execute sync
      final database = AppDatabase();
      final apiClient = PaperlessApiClient();
      final documentRepository = DocumentRepository(apiClient, database); // ⚡ FASE 2: Added database
      final uploadService = UploadService(database, documentRepository);

      final pendingBefore = await uploadService.getPendingCount();

      if (pendingBefore == 0) {
        _logger.d('ℹ️ No pending uploads');
        FlutterForegroundTask.updateService(
          notificationTitle: 'Lumara Scan',
          notificationText: 'Sin documentos pendientes',
        );
        return;
      }

      _logger.i('📊 Processing $pendingBefore pending uploads...');

      // Process uploads with retry logic
      await ConnectivityService.retryWithBackoff(
        operation: () async {
          await uploadService.processAllPending();
          return true;
        },
        operationName: 'Background sync',
        maxRetries: 3,
      );

      final stats = await uploadService.getStatistics();
      final successful = stats['success'] ?? 0;

      _logger.i('✅ Background sync completed: $successful documents uploaded');

      FlutterForegroundTask.updateService(
        notificationTitle: 'Lumara Scan',
        notificationText: 'Sincronización completada ($successful documentos)',
      );

      // Send data to main isolate
      FlutterForegroundTask.sendDataToMain({
        'syncCount': _syncCount,
        'timestamp': timestamp.toIso8601String(),
        'stats': stats,
      });
    } catch (e, stackTrace) {
      _logger.e('❌ Background sync error: $e', error: e, stackTrace: stackTrace);

      FlutterForegroundTask.updateService(
        notificationTitle: 'Lumara Scan',
        notificationText: 'Error en sincronización',
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _logger.i('🛑 Background sync handler stopped (total syncs: $_syncCount)');
  }

  @override
  void onNotificationButtonPressed(String id) {
    _logger.d('📱 Notification button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    _logger.d('📱 Notification pressed');
    FlutterForegroundTask.launchApp('/');
  }
}
