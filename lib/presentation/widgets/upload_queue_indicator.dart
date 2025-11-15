import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/upload_service.dart';
import '../../data/local/database/app_database.dart';

/// Upload Queue Indicator Widget
/// Shows pending uploads count and status in real-time
class UploadQueueIndicator extends StatefulWidget {
  final VoidCallback? onTap;

  const UploadQueueIndicator({Key? key, this.onTap}) : super(key: key);

  @override
  State<UploadQueueIndicator> createState() => _UploadQueueIndicatorState();
}

class _UploadQueueIndicatorState extends State<UploadQueueIndicator> {
  int _pendingCount = 0;
  int _failedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uploadService = context.read<UploadService>();

    try {
      final stats = await uploadService.getStatistics();

      if (mounted) {
        setState(() {
          _pendingCount = stats['pending'] ?? 0;
          _failedCount = stats['failed'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_pendingCount == 0 && _failedCount == 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: widget.onTap ?? _showQueueDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _failedCount > 0 ? Colors.red.shade700 : Colors.blue.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _failedCount > 0 ? Icons.error : Icons.cloud_upload,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              _failedCount > 0
                  ? '$_failedCount fallidos'
                  : '$_pendingCount pendientes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueueDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _QueueDetailsSheet(),
    );
  }
}

/// Queue Details Sheet
/// Shows detailed information about pending and failed uploads
class _QueueDetailsSheet extends StatelessWidget {
  const _QueueDetailsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cola de Sincronización',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<Map<String, int>>(
              future: context.read<UploadService>().getStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final stats = snapshot.data ?? {};

                return ListView(
                  shrinkWrap: true,
                  children: [
                    _StatCard(
                      icon: Icons.cloud_upload,
                      title: 'Pendientes',
                      count: stats['pending'] ?? 0,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _StatCard(
                      icon: Icons.error,
                      title: 'Fallidos',
                      count: stats['failed'] ?? 0,
                      color: Colors.red,
                      trailing: stats['failed']! > 0
                          ? TextButton(
                              onPressed: () => _retryAll(context),
                              child: const Text('Reintentar'),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _StatCard(
                      icon: Icons.check_circle,
                      title: 'Completados',
                      count: stats['success'] ?? 0,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    if ((stats['pending'] ?? 0) > 0 || (stats['failed'] ?? 0) > 0) ...[
                      ElevatedButton.icon(
                        onPressed: () => _showPendingList(context),
                        icon: const Icon(Icons.list),
                        label: const Text('Ver Detalles'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryAll(BuildContext context) async {
    final uploadService = context.read<UploadService>();

    try {
      await uploadService.retryAllFailed();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reintentando uploads fallidos...'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al reintentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPendingList(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _PendingUploadsScreen(),
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final Widget? trailing;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          count == 1 ? '$count documento' : '$count documentos',
        ),
        trailing: trailing,
      ),
    );
  }
}

/// Pending Uploads Screen
/// Shows detailed list of pending and failed uploads
class _PendingUploadsScreen extends StatelessWidget {
  const _PendingUploadsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploads Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reload the screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const _PendingUploadsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<PendingUpload>>(
        future: context.read<UploadService>().getPendingUploads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final uploads = snapshot.data ?? [];

          if (uploads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No hay uploads pendientes',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: uploads.length,
            itemBuilder: (context, index) {
              final upload = uploads[index];
              return _PendingUploadCard(upload: upload);
            },
          );
        },
      ),
    );
  }
}

/// Pending Upload Card Widget
class _PendingUploadCard extends StatelessWidget {
  final PendingUpload upload;

  const _PendingUploadCard({required this.upload});

  @override
  Widget build(BuildContext context) {
    final isFailed = upload.status == 'failed';
    final isUploading = upload.status == 'uploading';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFailed
              ? Colors.red
              : isUploading
                  ? Colors.orange
                  : Colors.blue,
          child: Icon(
            isFailed
                ? Icons.error
                : isUploading
                    ? Icons.cloud_upload
                    : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(upload.personName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${upload.documentType} - ${upload.fileName}'),
            if (isFailed && upload.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${upload.lastError}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Intentos: ${upload.retryCount}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: isFailed
            ? IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _retryUpload(context, upload.id),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Future<void> _retryUpload(BuildContext context, int uploadId) async {
    final uploadService = context.read<UploadService>();

    try {
      await uploadService.retryUpload(uploadId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reintentando upload...'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const _PendingUploadsScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
