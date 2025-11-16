import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Enhanced Offline Indicator Widget
///
/// Provides clear connection status and pending queue visibility:
/// - Real-time connection status monitoring
/// - Visual indicator (banner, icon, color-coded)
/// - Pending operations counter
/// - Queue details on tap
/// - Auto-sync notification when online
class EnhancedOfflineIndicator extends StatefulWidget {
  final int pendingUploadsCount;
  final VoidCallback? onViewQueue;
  final VoidCallback? onRetrySync;
  final Stream<bool>? syncStatusStream;

  const EnhancedOfflineIndicator({
    super.key,
    required this.pendingUploadsCount,
    this.onViewQueue,
    this.onRetrySync,
    this.syncStatusStream,
  });

  @override
  State<EnhancedOfflineIndicator> createState() =>
      _EnhancedOfflineIndicatorState();
}

class _EnhancedOfflineIndicatorState extends State<EnhancedOfflineIndicator>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late AnimationController _pulseController;
  bool _isOnline = true;
  bool _isSyncing = false;
  ConnectivityResult _currentConnectivity = ConnectivityResult.wifi;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _initConnectivity();
    _listenToConnectivityChanges();
    _listenToSyncStatus();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (!mounted) return;

      setState(() {
        _currentConnectivity = results.first;
        _isOnline = _currentConnectivity != ConnectivityResult.none;
      });
    } catch (e) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (!mounted) return;

      final newConnectivity = results.first;
      final wasOffline = !_isOnline;
      final isNowOnline = newConnectivity != ConnectivityResult.none;

      setState(() {
        _currentConnectivity = newConnectivity;
        _isOnline = isNowOnline;
      });

      // Notify user when connection is restored
      if (wasOffline && isNowOnline && widget.pendingUploadsCount > 0) {
        _showConnectionRestoredNotification();
      }
    });
  }

  void _listenToSyncStatus() {
    widget.syncStatusStream?.listen((isSyncing) {
      if (!mounted) return;
      setState(() {
        _isSyncing = isSyncing;
      });
    });
  }

  void _showConnectionRestoredNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conexión restaurada. ${widget.pendingUploadsCount} documentos pendientes de sincronizar.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Sincronizar',
          textColor: Colors.white,
          onPressed: () {
            widget.onRetrySync?.call();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && widget.pendingUploadsCount == 0) {
      // Everything is good, show minimal indicator
      return _buildMinimalIndicator();
    }

    if (!_isOnline) {
      // Offline mode
      return _buildOfflineBanner();
    }

    if (widget.pendingUploadsCount > 0) {
      // Has pending uploads
      return _buildPendingQueueIndicator();
    }

    return const SizedBox.shrink();
  }

  Widget _buildMinimalIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getConnectivityIcon(),
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            _getConnectivityLabel(),
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulseController,
            child: const Icon(
              Icons.cloud_off,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modo Sin Conexión',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (widget.pendingUploadsCount > 0)
                  Text(
                    '${widget.pendingUploadsCount} documentos en cola',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
          if (widget.pendingUploadsCount > 0)
            TextButton(
              onPressed: widget.onViewQueue,
              child: const Text('Ver Cola'),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingQueueIndicator() {
    return InkWell(
      onTap: widget.onViewQueue,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isSyncing
              ? Colors.blue.withOpacity(0.1)
              : Colors.amber.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: _isSyncing
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.amber.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            if (_isSyncing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            else
              const Icon(
                Icons.cloud_upload,
                color: Colors.amber,
                size: 24,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSyncing
                        ? 'Sincronizando...'
                        : '${widget.pendingUploadsCount} Pendientes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isSyncing
                        ? 'Subiendo documentos al servidor'
                        : 'Toca para ver detalles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isSyncing ? Colors.blue : Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.pendingUploadsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConnectivityIcon() {
    switch (_currentConnectivity) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      default:
        return Icons.cloud_done;
    }
  }

  String _getConnectivityLabel() {
    switch (_currentConnectivity) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Datos móviles';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      default:
        return 'En línea';
    }
  }
}

/// Compact offline indicator for AppBar
class CompactOfflineIndicator extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;

  const CompactOfflineIndicator({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0) {
      return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
    }

    if (!isOnline) {
      return Stack(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          if (pendingCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  pendingCount > 9 ? '9+' : '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    if (isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    return Stack(
      children: [
        const Icon(Icons.cloud_upload, color: Colors.amber, size: 20),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
            child: Text(
              pendingCount > 9 ? '9+' : '$pendingCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
