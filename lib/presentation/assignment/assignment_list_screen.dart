import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/assignment.dart';
import '../../core/navigation/role_based_navigator.dart';
import '../providers/assignment_provider.dart';

/// Assignment List Screen
/// Shows digitizer's assignments with progress tracking
class AssignmentListScreen extends StatefulWidget {
  static const String route = '/assignments';

  const AssignmentListScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  AssignmentStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    await provider.loadMyAssignments();
  }

  Future<void> _refreshAssignments() async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    await provider.loadMyAssignments(
      status: _selectedFilter?.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Asignaciones'),
        actions: [
          // Filter button
          PopupMenuButton<AssignmentStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _selectedFilter = status;
              });
              _refreshAssignments();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todas'),
              ),
              PopupMenuItem(
                value: AssignmentStatus.pending,
                child: Text(AssignmentStatus.pending.label),
              ),
              PopupMenuItem(
                value: AssignmentStatus.inProgress,
                child: Text(AssignmentStatus.inProgress.label),
              ),
              PopupMenuItem(
                value: AssignmentStatus.completed,
                child: Text(AssignmentStatus.completed.label),
              ),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAssignments,
          ),
        ],
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingAssignments) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshAssignments,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final assignments = provider.myAssignments;

          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == null
                        ? 'No tienes asignaciones'
                        : 'No hay asignaciones ${_selectedFilter!.label.toLowerCase()}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAssignments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return _AssignmentCard(
                  assignment: assignment,
                  onTap: () => _showAssignmentDetails(assignment),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAssignmentDetails(PersonAssignment assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AssignmentDetailsSheet(assignment: assignment),
    );
  }
}

/// Assignment Card Widget
class _AssignmentCard extends StatelessWidget {
  final PersonAssignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = assignment.progressPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Person name + Status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.personName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: assignment.status),
                ],
              ),
              const SizedBox(height: 8),

              // Person ID
              Text(
                'ID: ${assignment.personId}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),

              if (assignment.familyId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Familia: ${assignment.familyId}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progressPercent),
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Document count
              Text(
                '${assignment.digitizedDocuments} / ${assignment.requiredDocuments} documentos',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),

              // Dates
              if (assignment.startedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Iniciado: ${_formatDate(assignment.startedAt!)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(int percent) {
    if (percent == 0) return Colors.grey;
    if (percent < 50) return Colors.orange;
    if (percent < 100) return Colors.blue;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final AssignmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case AssignmentStatus.pending:
        return Colors.grey[700]!;
      case AssignmentStatus.inProgress:
        return Colors.blue[700]!;
      case AssignmentStatus.completed:
        return Colors.green[700]!;
      case AssignmentStatus.reviewed:
        return Colors.purple[700]!;
    }
  }
}

/// Assignment Details Bottom Sheet
class _AssignmentDetailsSheet extends StatelessWidget {
  final PersonAssignment assignment;

  const _AssignmentDetailsSheet({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                assignment.personName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _StatusBadge(status: assignment.status),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _DetailRow(
                      icon: Icons.badge,
                      label: 'ID Persona',
                      value: assignment.personId,
                    ),
                    if (assignment.familyId != null)
                      _DetailRow(
                        icon: Icons.family_restroom,
                        label: 'ID Familia',
                        value: assignment.familyId!,
                      ),
                    const Divider(height: 32),
                    _DetailRow(
                      icon: Icons.description,
                      label: 'Documentos requeridos',
                      value: '${assignment.requiredDocuments}',
                    ),
                    _DetailRow(
                      icon: Icons.check_circle,
                      label: 'Documentos digitalizados',
                      value: '${assignment.digitizedDocuments}',
                    ),
                    _DetailRow(
                      icon: Icons.percent,
                      label: 'Progreso',
                      value: '${assignment.progressPercentage}%',
                    ),
                    const Divider(height: 32),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Asignado',
                      value: _formatDateTime(assignment.assignedAt),
                    ),
                    if (assignment.startedAt != null)
                      _DetailRow(
                        icon: Icons.play_arrow,
                        label: 'Iniciado',
                        value: _formatDateTime(assignment.startedAt!),
                      ),
                    if (assignment.completedAt != null)
                      _DetailRow(
                        icon: Icons.done_all,
                        label: 'Completado',
                        value: _formatDateTime(assignment.completedAt!),
                      ),
                    if (assignment.notes != null) ...[
                      const Divider(height: 32),
                      _DetailRow(
                        icon: Icons.notes,
                        label: 'Notas',
                        value: assignment.notes!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Consumer<AssignmentProvider>(
                builder: (context, provider, child) {
                  if (assignment.isPending) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _markAsStarted(context, provider),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Asignación'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    );
                  } else if (assignment.isInProgress) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _markAsCompleted(context, provider),
                      icon: const Icon(Icons.done),
                      label: const Text('Marcar como Completado'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Asignación Completada',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAsStarted(
    BuildContext context,
    AssignmentProvider provider,
  ) async {
    final success = await provider.markAssignmentStarted(assignment.id);

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Asignación iniciada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAsCompleted(
    BuildContext context,
    AssignmentProvider provider,
  ) async {
    final success = await provider.markAssignmentCompleted(assignment.id);

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Asignación completada!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
