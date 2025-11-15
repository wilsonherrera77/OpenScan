import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/logger_adapter.dart';

import '../../presentation/providers/assignment_provider.dart';
import '../../domain/entities/assignment.dart';
import '../assignment/widgets/dashboard_widgets.dart';
import '../widgets/assignment_review_dialog.dart'; // ⏱️ FASE 2: Review dialog

/// Reviewer Dashboard Screen - Dashboard for quality reviewers
///
/// Features:
/// - Review queue (completed assignments pending review)
/// - Quality metrics overview (avg scores, rejection rate)
/// - Documents to review list with filters
/// - Quick review actions (approve, reject, request re-capture)
/// - Quality statistics (by digitizer, by document type)
/// - Review history
///
/// Role Required: REVISOR
class ReviewerDashboardScreen extends StatefulWidget {
  static const String route = '/reviewer-dashboard';

  const ReviewerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ReviewerDashboardScreen> createState() =>
      _ReviewerDashboardScreenState();
}

class _ReviewerDashboardScreenState extends State<ReviewerDashboardScreen> {
  final LoggerAdapter _logger = LoggerAdapter();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    final provider = context.read<AssignmentProvider>();

    setState(() => _isInitialized = false);

    try {
      _logger.i('📊 Loading reviewer dashboard data...');

      // Load review data
      await Future.wait([
        provider.loadAllAssignments(status: 'COMPLETED'), // Pending review
        provider.loadTeamStatistics(),
      ]);

      _logger.i('✅ Reviewer dashboard data loaded successfully');
    } catch (e) {
      _logger.e('❌ Failed to load reviewer dashboard data', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Revisor'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refrescar datos',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _isInitialized
          ? RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: _buildDashboardContent(),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, child) {
        final completedAssignments = provider.allAssignments
            .where((a) => a.status == AssignmentStatus.completed)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              _buildWelcomeHeader(provider, completedAssignments.length),
              const SizedBox(height: 24),

              // Quality metrics overview
              _buildQualityMetricsOverview(provider),
              const SizedBox(height: 16),

              // Review queue summary
              _buildReviewQueueSummary(completedAssignments),
              const SizedBox(height: 16),

              // Quick actions
              _buildQuickActionsGrid(completedAssignments.length),
              const SizedBox(height: 24),

              // Assignments pending review
              _buildAssignmentsPendingReview(completedAssignments),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(
      AssignmentProvider provider, int pendingReviewCount) {
    final userName = provider.currentUserProfile?.username ?? 'Revisor';

    String message;
    if (pendingReviewCount > 10) {
      message = '¡Alta carga! $pendingReviewCount documentos esperan revisión';
    } else if (pendingReviewCount > 0) {
      message = '$pendingReviewCount documentos listos para revisar';
    } else {
      message = '¡Todo revisado! Sin documentos pendientes';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $userName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(
                  icon: Icons.pending_actions,
                  label: 'Por Revisar',
                  value: '$pendingReviewCount',
                ),
                _buildQuickStat(
                  icon: Icons.check_circle,
                  label: 'Revisados Hoy',
                  value: '0', // TODO: Calculate from logs
                ),
                _buildQuickStat(
                  icon: Icons.star,
                  label: 'Calidad Prom.',
                  value: '0%', // TODO: Calculate from team stats
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQualityMetricsOverview(AssignmentProvider provider) {
    // TODO: Get real quality metrics from backend
    final totalReviewed = 0;
    final avgQuality = 0.0;
    final approvalRate = 0.0;
    final rejectionRate = 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas de Calidad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                      'Revisados',
                      '$totalReviewed',
                      Icons.check_circle_outline,
                      Colors.blue,
                    ),
                    _buildMetricColumn(
                      'Calidad',
                      '${avgQuality.toStringAsFixed(1)}%',
                      Icons.star_outline,
                      Colors.orange,
                    ),
                    _buildMetricColumn(
                      'Aprobados',
                      '${approvalRate.toStringAsFixed(0)}%',
                      Icons.thumb_up_outlined,
                      Colors.green,
                    ),
                    _buildMetricColumn(
                      'Rechazados',
                      '${rejectionRate.toStringAsFixed(0)}%',
                      Icons.thumb_down_outlined,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildReviewQueueSummary(List<PersonAssignment> pendingReview) {
    if (pendingReview.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay documentos pendientes de revisión',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Excelente trabajo! Todo está al día',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group by digitizer
    final Map<int, List<PersonAssignment>> byDigitizer = {};
    for (var assignment in pendingReview) {
      byDigitizer.putIfAbsent(assignment.digitizerId, () => []).add(assignment);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cola de Revisión',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${pendingReview.length} asignaciones',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...byDigitizer.entries.map((entry) {
                  final digitizerName = entry.value.first.digitizerName ?? 'Unknown';
                  final count = entry.value.length;
                  final totalDocs = entry.value.fold<int>(
                      0, (sum, a) => sum + a.digitizedDocuments);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.purple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                digitizerName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '$count asignaciones • $totalDocs documentos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(int pendingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              icon: Icons.rate_review,
              title: 'Revisar Documentos',
              subtitle: '$pendingCount pendientes',
              color: Colors.purple,
              onTap: () {
                _showMessage('Abriendo cola de revisión...');
                // TODO: Navigate to review queue screen
              },
            ),
            _buildQuickActionCard(
              icon: Icons.bar_chart,
              title: 'Estadísticas',
              subtitle: 'Ver métricas detalladas',
              color: Colors.blue,
              onTap: () {
                _showQualityStatsDialog();
              },
            ),
            _buildQuickActionCard(
              icon: Icons.history,
              title: 'Historial',
              subtitle: 'Revisiones anteriores',
              color: Colors.orange,
              onTap: () {
                _showMessage('Historial de revisiones (próximamente)');
              },
            ),
            _buildQuickActionCard(
              icon: Icons.warning,
              title: 'Rechazados',
              subtitle: 'Documentos con issues',
              color: Colors.red,
              onTap: () {
                _showMessage('Ver documentos rechazados (próximamente)');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsPendingReview(List<PersonAssignment> assignments) {
    if (assignments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show top 5
    final topAssignments = assignments.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximas Revisiones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (assignments.length > 5)
              TextButton(
                onPressed: () {
                  _showMessage('Ver todas las asignaciones (próximamente)');
                },
                child: Text('Ver Todas (${assignments.length})'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topAssignments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final assignment = topAssignments[index];
              return _buildAssignmentListTile(assignment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentListTile(PersonAssignment assignment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.purple.withOpacity(0.1),
        child: const Icon(Icons.assignment, color: Colors.purple, size: 20),
      ),
      title: Text(
        assignment.personName ?? 'Persona ${assignment.personId}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digitalizador: ${assignment.digitizerName ?? "Unknown"}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${assignment.digitizedDocuments} documentos completados',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => _reviewAssignment(assignment),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(80, 32),
            ),
            child: const Text('Revisar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      onTap: () => _showAssignmentDetails(assignment),
    );
  }

  void _reviewAssignment(PersonAssignment assignment) {
    // ⏱️ FASE 2: Show review dialog with approve/reject functionality
    showAssignmentReviewDialog(
      context: context,
      assignment: assignment,
      onApprove: (score, feedback) async {
        final provider = context.read<AssignmentProvider>();

        final success = await provider.approveAssignment(
          assignmentId: assignment.id,
          qualityScore: score,
          feedback: feedback,
        );

        if (success && mounted) {
          _showMessage('✅ Asignación aprobada exitosamente');
          // Reload data to update the list
          await _loadDashboardData();
        } else if (mounted) {
          _showMessage('❌ Error al aprobar la asignación');
        }
      },
      onReject: (feedback, issues) async {
        final provider = context.read<AssignmentProvider>();

        final success = await provider.rejectAssignment(
          assignmentId: assignment.id,
          feedback: feedback,
          issuesFound: issues,
        );

        if (success && mounted) {
          _showMessage('✅ Asignación rechazada - Notificado al digitalizador');
          // Reload data to update the list
          await _loadDashboardData();
        } else if (mounted) {
          _showMessage('❌ Error al rechazar la asignación');
        }
      },
    );
  }

  void _showAssignmentDetails(PersonAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Asignación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Persona', assignment.personName ?? 'N/A'),
              _buildDetailRow('Person ID', assignment.personId),
              _buildDetailRow('Family ID', assignment.familyId ?? 'N/A'),
              _buildDetailRow('Digitalizador', assignment.digitizerName ?? 'N/A'),
              _buildDetailRow('Status', assignment.status.label),
              _buildDetailRow(
                'Documentos',
                '${assignment.digitizedDocuments}/${assignment.requiredDocuments}',
              ),
              _buildDetailRow(
                'Progreso',
                '${assignment.progressPercentage}%',
              ),
              _buildDetailRow(
                'Asignado',
                assignment.assignedAt?.toString().substring(0, 16) ?? 'N/A',
              ),
              if (assignment.completedAt != null)
                _buildDetailRow(
                  'Completado',
                  assignment.completedAt!.toString().substring(0, 16),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros de Revisión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtros disponibles próximamente:'),
            const SizedBox(height: 12),
            const Text('• Por digitalizador'),
            const Text('• Por rango de fechas'),
            const Text('• Por calidad estimada'),
            const Text('• Por tipo de documento'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showQualityStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Calidad'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Métricas Globales:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Total Revisados', '0', Icons.check_circle),
              _buildStatRow('Calidad Promedio', '0%', Icons.star),
              _buildStatRow('Tasa de Aprobación', '0%', Icons.thumb_up),
              _buildStatRow('Tasa de Rechazo', '0%', Icons.thumb_down),
              const SizedBox(height: 16),
              const Text(
                'Por Digitalizador:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Datos disponibles próximamente'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
