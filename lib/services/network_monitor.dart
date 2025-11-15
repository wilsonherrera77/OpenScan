import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/logger_adapter.dart';
import 'background_sync_service.dart';

/// Network Monitor Service
/// Listens to network connectivity changes and triggers upload sync when online
class NetworkMonitor {
  static final NetworkMonitor _instance = NetworkMonitor._internal();
  factory NetworkMonitor() => _instance;
  NetworkMonitor._internal();

  final Connectivity _connectivity = Connectivity();
  final LoggerAdapter _logger = LoggerAdapter();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;
  bool _isInitialized = false;

  /// Start monitoring network connectivity
  Future<void> startMonitoring() async {
    if (_isInitialized) {
      _logger.w('⚠️ Network monitor already initialized');
      return;
    }

    _logger.i('📡 Starting network connectivity monitoring');

    // Check initial connectivity state
    final initialStatus = await _connectivity.checkConnectivity();
    _wasOffline = _isOffline(initialStatus);

    _logger.i('📊 Initial connectivity: $initialStatus (offline: $_wasOffline)');

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        _logger.e('❌ Connectivity stream error: $error');
      },
    );

    _isInitialized = true;
    _logger.i('✅ Network monitor started');
  }

  /// Stop monitoring network connectivity
  Future<void> stopMonitoring() async {
    if (!_isInitialized) {
      return;
    }

    _logger.i('🛑 Stopping network connectivity monitoring');

    await _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;

    _logger.i('✅ Network monitor stopped');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isCurrentlyOffline = _isOffline(results);

    _logger.d('📊 Connectivity changed: $results (offline: $isCurrentlyOffline)');

    // Detect transition from offline → online
    if (_wasOffline && !isCurrentlyOffline) {
      _logger.i('🌐 Connection restored! Triggering upload sync...');
      _onConnectionRestored();
    } else if (!_wasOffline && isCurrentlyOffline) {
      _logger.w('📵 Connection lost');
    }

    _wasOffline = isCurrentlyOffline;
  }

  /// Triggered when connection is restored
  void _onConnectionRestored() {
    // Schedule immediate sync with 5 second delay
    BackgroundSyncService.scheduleImmediateSync();
    _logger.i('⏱️ Scheduled immediate sync after connection restore');
  }

  /// Check if device is offline based on connectivity results
  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
           results.every((result) => result == ConnectivityResult.none);
  }

  /// Get current connectivity status
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return !_isOffline(results);
  }

  /// Get detailed connectivity info
  Future<String> getConnectivityStatus() async {
    final results = await _connectivity.checkConnectivity();

    if (_isOffline(results)) {
      return 'offline';
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return 'wifi';
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return 'mobile';
    }

    if (results.contains(ConnectivityResult.ethernet)) {
      return 'ethernet';
    }

    return 'unknown';
  }

  /// Check if network is suitable for uploads (wifi or ethernet preferred)
  Future<bool> isGoodForUploads() async {
    final results = await _connectivity.checkConnectivity();

    // WiFi and Ethernet are ideal for uploads
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return true;
    }

    // Mobile data is acceptable but not ideal
    // In production, this could be user-configurable
    if (results.contains(ConnectivityResult.mobile)) {
      return true;
    }

    return false;
  }
}
