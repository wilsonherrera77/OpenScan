import 'package:flutter/material.dart';
import 'dart:async';

/// Upload Progress Dialog
/// Shows real-time upload progress with detailed feedback
class UploadProgressDialog extends StatefulWidget {
  final Stream<UploadProgress> progressStream;
  final VoidCallback? onCancel;

  const UploadProgressDialog({
    super.key,
    required this.progressStream,
    this.onCancel,
  });

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    required Stream<UploadProgress> progressStream,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        progressStream: progressStream,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<UploadProgress> _subscription;
  UploadProgress? _currentProgress;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _subscription = widget.progressStream.listen(
      (progress) {
        setState(() {
          _currentProgress = progress;
        });

        // Auto-close on completion or error
        if (progress.status == UploadStatus.completed) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _currentProgress = UploadProgress(
              status: UploadStatus.failed,
              message: 'Error: $error',
              progress: 0,
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_currentProgress?.status) {
      case UploadStatus.preparing:
        return Colors.blue;
      case UploadStatus.uploading:
        return Colors.orange;
      case UploadStatus.processing:
        return Colors.purple;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentProgress?.status) {
      case UploadStatus.preparing:
        return Icons.settings;
      case UploadStatus.uploading:
        return Icons.cloud_upload;
      case UploadStatus.processing:
        return Icons.memory;
      case UploadStatus.completed:
        return Icons.check_circle;
      case UploadStatus.failed:
        return Icons.error;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentProgress;
    final color = _getStatusColor();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Icon
          if (progress?.status == UploadStatus.completed)
            Icon(
              _getStatusIcon(),
              size: 64,
              color: color,
            )
          else if (progress?.status == UploadStatus.failed)
            Icon(
              _getStatusIcon(),
              size: 64,
              color: color,
            )
          else
            RotationTransition(
              turns: _animationController,
              child: Icon(
                _getStatusIcon(),
                size: 64,
                color: color,
              ),
            ),

          const SizedBox(height: 24),

          // Status message
          Text(
            progress?.message ?? 'Preparando...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Progress bar
          if (progress != null &&
              progress.status != UploadStatus.completed &&
              progress.status != UploadStatus.failed)
            Column(
              children: [
                LinearProgressIndicator(
                  value: progress.progress > 0 ? progress.progress / 100 : null,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.progress.toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),

          // File info
          if (progress?.fileName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      progress!.fileName!,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (progress.fileSize != null)
                    Text(
                      _formatBytes(progress.fileSize!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ),
            ),
          ],

          // Upload speed and time remaining
          if (progress?.uploadSpeed != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatBytes(progress!.uploadSpeed!.toInt())}/s',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (progress.timeRemaining != null)
                  Text(
                    _formatDuration(progress.timeRemaining!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ],

          // Cancel button (only for in-progress uploads)
          if (widget.onCancel != null &&
              progress?.status != UploadStatus.completed &&
              progress?.status != UploadStatus.failed) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Cancelar'),
            ),
          ],

          // Retry button (only for failed uploads)
          if (progress?.status == UploadStatus.failed &&
              progress?.onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: progress!.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],

          // Close button (for completed uploads)
          if (progress?.status == UploadStatus.completed) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }
}

/// Upload Status Enum
enum UploadStatus {
  preparing,
  uploading,
  processing,
  completed,
  failed,
}

/// Upload Progress Model
class UploadProgress {
  final UploadStatus status;
  final String message;
  final double progress; // 0-100
  final String? fileName;
  final int? fileSize;
  final double? uploadSpeed; // bytes per second
  final Duration? timeRemaining;
  final VoidCallback? onRetry;

  UploadProgress({
    required this.status,
    required this.message,
    required this.progress,
    this.fileName,
    this.fileSize,
    this.uploadSpeed,
    this.timeRemaining,
    this.onRetry,
  });

  UploadProgress copyWith({
    UploadStatus? status,
    String? message,
    double? progress,
    String? fileName,
    int? fileSize,
    double? uploadSpeed,
    Duration? timeRemaining,
    VoidCallback? onRetry,
  }) {
    return UploadProgress(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      onRetry: onRetry ?? this.onRetry,
    );
  }
}
