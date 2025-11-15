import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/upload_service.dart';
import 'dart:async';

/// Sync Status Widget
/// Displays current sync status and pending uploads count
class SyncStatusWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusWidget({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  SyncStats? _stats;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadStats();

    // Refresh stats every 5 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadStats(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final uploadService = context.read<UploadService>();
      final statsMap = await uploadService.getEnhancedStatistics();
      if (mounted) {
        setState(() {
          _stats = SyncStats(
            completedCount: statsMap['completed'] as int? ?? 0,
            pendingCount: statsMap['pending'] as int? ?? 0,
            failedCount: statsMap['failed'] as int? ?? 0,
            totalSize: statsMap['total_size'] as int? ?? 0,
            lastSyncTime: statsMap['last_sync_time'] != null
                ? DateTime.fromMillisecondsSinceEpoch(statsMap['last_sync_time'] as int)
                : null,
          );
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Color _getStatusColor() {
    if (_stats == null) return Colors.grey;
    if (_stats!.failedCount > 0) return Colors.red;
    if (_stats!.pendingCount > 0) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (_stats == null) return Icons.cloud_queue;
    if (_stats!.failedCount > 0) return Icons.cloud_off;
    if (_stats!.pendingCount > 0) return Icons.cloud_upload;
    return Icons.cloud_done;
  }

  String _getStatusText() {
    if (_stats == null) return 'Cargando...';
    if (_stats!.failedCount > 0) {
      return '${_stats!.failedCount} fallido${_stats!.failedCount > 1 ? 's' : ''}';
    }
    if (_stats!.pendingCount > 0) {
      return '${_stats!.pendingCount} pendiente${_stats!.pendingCount > 1 ? 's' : ''}';
    }
    if (_stats!.completedCount > 0) {
      return '${_stats!.completedCount} sincronizado${_stats!.completedCount > 1 ? 's' : ''}';
    }
    return 'Todo sincronizado';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showDetails) {
      return _buildDetailedView();
    } else {
      return _buildCompactView();
    }
  }

  Widget _buildCompactView() {
    final color = _getStatusColor();
    final isActive = _stats != null && _stats!.pendingCount > 0;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon for active uploads
            if (isActive)
              FadeTransition(
                opacity: _pulseController,
                child: Icon(
                  _getStatusIcon(),
                  size: 20,
                  color: color,
                ),
              )
            else
              Icon(
                _getStatusIcon(),
                size: 20,
                color: color,
              ),
            const SizedBox(width: 8),
            Text(
              _getStatusText(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedView() {
    final color = _getStatusColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 32,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de Sincronización',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _getStatusText(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_stats != null && _stats!.pendingCount > 0)
                    FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sync,
                          size: 20,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),

              if (_stats != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.cloud_done,
                      label: 'Completados',
                      value: _stats!.completedCount,
                      color: Colors.green,
                    ),
                    _StatItem(
                      icon: Icons.cloud_upload,
                      label: 'Pendientes',
                      value: _stats!.pendingCount,
                      color: Colors.orange,
                    ),
                    _StatItem(
                      icon: Icons.cloud_off,
                      label: 'Fallidos',
                      value: _stats!.failedCount,
                      color: Colors.red,
                    ),
                  ],
                ),

                // Total size
                if (_stats!.totalSize > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${_formatBytes(_stats!.totalSize)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],

                // Last sync time
                if (_stats!.lastSyncTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Última sincronización: ${_formatTime(_stats!.lastSyncTime!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Sync Statistics Model
class SyncStats {
  final int completedCount;
  final int pendingCount;
  final int failedCount;
  final int totalSize;
  final DateTime? lastSyncTime;

  SyncStats({
    required this.completedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.totalSize,
    this.lastSyncTime,
  });
}
