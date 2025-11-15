import 'package:flutter/material.dart';
import '../../services/upload_service.dart';
import '../../Utilities/constants.dart';

/// Sync Status Indicator Widget
/// Shows real-time synchronization status with visual feedback
class SyncStatusIndicator extends StatelessWidget {
  final Stream<SyncStatus> statusStream;
  final SyncStatus currentStatus;

  const SyncStatusIndicator({
    Key? key,
    required this.statusStream,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: statusStream,
      initialData: currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        return _buildStatusChip(status);
      },
    );
  }

  Widget _buildStatusChip(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return _StatusChip(
          icon: Icons.cloud_done_outlined,
          label: 'Listo',
          color: Colors.grey,
          backgroundColor: Colors.grey.withOpacity(0.1),
        );

      case SyncStatus.syncing:
        return _StatusChip(
          icon: Icons.cloud_upload,
          label: 'Sincronizando...',
          color: Colors.blue,
          backgroundColor: Colors.blue.withOpacity(0.1),
          animated: true,
        );

      case SyncStatus.success:
        return _StatusChip(
          icon: Icons.check_circle,
          label: 'Sincronizado',
          color: Colors.green,
          backgroundColor: Colors.green.withOpacity(0.1),
        );

      case SyncStatus.failed:
        return _StatusChip(
          icon: Icons.error_outline,
          label: 'Error',
          color: Colors.red,
          backgroundColor: Colors.red.withOpacity(0.1),
        );

      case SyncStatus.retrying:
        return _StatusChip(
          icon: Icons.refresh,
          label: 'Reintentando...',
          color: Colors.orange,
          backgroundColor: Colors.orange.withOpacity(0.1),
          animated: true,
        );
    }
  }
}

/// Internal status chip widget
class _StatusChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final bool animated;

  const _StatusChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.animated = false,
  }) : super(key: key);

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.animated
              ? RotationTransition(
                  turns: _controller,
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: widget.color,
                  ),
                )
              : Icon(
                  widget.icon,
                  size: 16,
                  color: widget.color,
                ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Sync Status Icon (for AppBar or small spaces)
class SyncStatusIcon extends StatelessWidget {
  final Stream<SyncStatus> statusStream;
  final SyncStatus currentStatus;

  const SyncStatusIcon({
    Key? key,
    required this.statusStream,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: statusStream,
      initialData: currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        return _buildStatusIcon(status);
      },
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icon(Icons.cloud_done, color: Colors.grey, size: 20);

      case SyncStatus.syncing:
        return _AnimatedIcon(
          icon: Icons.cloud_upload,
          color: Colors.blue,
        );

      case SyncStatus.success:
        return Icon(Icons.check_circle, color: Colors.green, size: 20);

      case SyncStatus.failed:
        return Icon(Icons.error, color: Colors.red, size: 20);

      case SyncStatus.retrying:
        return _AnimatedIcon(
          icon: Icons.refresh,
          color: Colors.orange,
        );
    }
  }
}

/// Animated icon for syncing/retrying states
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({
    Key? key,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        widget.icon,
        color: widget.color,
        size: 20,
      ),
    );
  }
}
