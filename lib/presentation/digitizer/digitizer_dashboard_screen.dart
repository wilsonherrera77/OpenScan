import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/logger_adapter.dart';

import '../../presentation/providers/assignment_provider.dart';
import '../../domain/entities/assignment.dart';
import '../assignment/widgets/dashboard_widgets.dart';
import '../assignment/assignment_list_screen.dart';
import '../widgets/session_indicator_widget.dart';
import '../census/person_selection_screen.dart'; // ⚡ RESTAURADO: Navegación a digitalización

/// Digitizer Dashboard Screen - Personalized dashboard for digitizers
///
/// Features:
/// - Personal productivity metrics (documents/day, quality scores)
/// - My assignments summary with quick access
/// - Daily/weekly/monthly progress tracking
/// - Quick actions (start capture, view pending assignments)
/// - Motivational elements (achievements, progress bars)
/// - Real-time sync with backend
///
/// Role Required: DIGITALIZADOR
class DigitizerDashboardScreen extends StatefulWidget {
  static const String route = '/digitizer-dashboard';

  const DigitizerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DigitizerDashboardScreen> createState() =>
      _DigitizerDashboardScreenState();
}

class _DigitizerDashboardScreenState extends State<DigitizerDashboardScreen> {
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
      _logger.i('📊 Loading digitizer dashboard data...');

      // Load personal data concurrently
      await Future.wait([
        provider.loadMyAssignments(),
        provider.loadMyProductivity(),
      ]);

      _logger.i('✅ Digitizer dashboard data loaded successfully');
    } catch (e) {
      _logger.e('❌ Failed to load digitizer dashboard data', error: e);
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
        title: const Text('Mi Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // ⏱️ FASE 2: Session indicator
          SessionIndicatorWidget(
            onTap: () {
              // Show session details dialog
              _showSessionDetailsDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refrescar datos',
          ),
        ],
      ),
      body: _isInitialized
          ? RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: _buildDashboardContent(),
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // ⚡ RESTAURADO: Navegar a selección de persona para digitalizar
          Navigator.of(context).pushNamed(PersonSelectionScreen.route);
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capturar'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header with today's goal
              _buildWelcomeHeader(provider),
              const SizedBox(height: 24),

              // Personal productivity card
              if (provider.myProductivity != null)
                ProductivityCard(metrics: provider.myProductivity!),
              const SizedBox(height: 16),

              // My assignments summary
              _buildAssignmentsSummary(provider),
              const SizedBox(height: 16),

              // Quick actions
              _buildQuickActionsGrid(provider),
              const SizedBox(height: 16),

              // Recent assignments (top 5)
              _buildRecentAssignments(provider),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(AssignmentProvider provider) {
    final userName = provider.currentUserProfile?.username ?? 'Digitalizador';
    final assignments = provider.myAssignments;
    final pending =
        assignments.where((a) => a.status == AssignmentStatus.pending).length;
    final inProgress = assignments
        .where((a) => a.status == AssignmentStatus.inProgress)
        .length;

    // Motivational message based on progress
    String motivationalMessage;
    if (inProgress > 0) {
      motivationalMessage = '¡Sigue así! Tienes $inProgress en progreso';
    } else if (pending > 0) {
      motivationalMessage = '¡Comienza tu jornada! $pending personas esperan';
    } else {
      motivationalMessage = '¡Excelente trabajo! Todo al día';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 32),
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
                        motivationalMessage,
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
                  label: 'Pendientes',
                  value: '$pending',
                ),
                _buildQuickStat(
                  icon: Icons.hourglass_top,
                  label: 'En Progreso',
                  value: '$inProgress',
                ),
                _buildQuickStat(
                  icon: Icons.check_circle,
                  label: 'Completadas',
                  value:
                      '${assignments.where((a) => a.status == AssignmentStatus.completed).length}',
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
        ),
      ],
    );
  }

  Widget _buildAssignmentsSummary(AssignmentProvider provider) {
    final assignments = provider.myAssignments;

    if (assignments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.assignment_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No tienes asignaciones',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contacta al administrador para recibir asignaciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate total progress
    final totalRequired = assignments.fold<int>(
        0, (sum, a) => sum + a.requiredDocuments);
    final totalDigitized = assignments.fold<int>(
        0, (sum, a) => sum + a.digitizedDocuments);
    final overallProgress = totalRequired > 0
        ? (totalDigitized / totalRequired * 100).toInt()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Asignaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AssignmentListScreen.route);
              },
              child: const Text('Ver Todas'),
            ),
          ],
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
                      'Progreso General',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$overallProgress%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: overallProgress / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 12),
                Text(
                  '$totalDigitized de $totalRequired documentos completados',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total',
                      '${assignments.length}',
                      Colors.blue,
                    ),
                    _buildSummaryItem(
                      'Personas',
                      '${assignments.length}',
                      Colors.orange,
                    ),
                    _buildSummaryItem(
                      'Documentos',
                      '$totalDigitized',
                      Colors.green,
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(AssignmentProvider provider) {
    final pendingCount = provider.myAssignments
        .where((a) => a.status == AssignmentStatus.pending)
        .length;
    final inProgressCount = provider.myAssignments
        .where((a) => a.status == AssignmentStatus.inProgress)
        .length;

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
              icon: Icons.camera_alt,
              title: 'Capturar Documento',
              subtitle: 'Iniciar captura',
              color: Colors.teal,
              onTap: () {
                // ⚡ RESTAURADO: Navegar a selección de persona
                Navigator.of(context).pushNamed(PersonSelectionScreen.route);
              },
            ),
            _buildQuickActionCard(
              icon: Icons.pending_actions,
              title: 'Pendientes',
              subtitle: '$pendingCount asignaciones',
              color: Colors.orange,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AssignmentListScreen.route,
                  arguments: {'initialFilter': AssignmentStatus.pending},
                );
              },
            ),
            _buildQuickActionCard(
              icon: Icons.hourglass_top,
              title: 'En Progreso',
              subtitle: '$inProgressCount asignaciones',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AssignmentListScreen.route,
                  arguments: {'initialFilter': AssignmentStatus.inProgress},
                );
              },
            ),
            _buildQuickActionCard(
              icon: Icons.bar_chart,
              title: 'Mi Productividad',
              subtitle: 'Ver estadísticas',
              color: Colors.purple,
              onTap: () {
                _showProductivityDialog(provider);
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

  Widget _buildRecentAssignments(AssignmentProvider provider) {
    final recentAssignments = provider.myAssignments.take(5).toList();

    if (recentAssignments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asignaciones Recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentAssignments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final assignment = recentAssignments[index];
              return _buildAssignmentListTile(assignment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentListTile(PersonAssignment assignment) {
    Color statusColor;
    IconData statusIcon;

    switch (assignment.status) {
      case AssignmentStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case AssignmentStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      case AssignmentStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AssignmentStatus.reviewed:
        statusColor = Colors.purple;
        statusIcon = Icons.verified;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(
        assignment.personName ?? 'Persona ${assignment.personId}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${assignment.digitizedDocuments}/${assignment.requiredDocuments} documentos',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${assignment.progressPercentage}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: assignment.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 4,
            ),
          ],
        ),
      ),
      onTap: () {
        // TODO: Navigate to assignment details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Ver detalles de ${assignment.personName ?? "persona"}'),
          ),
        );
      },
    );
  }

  void _showProductivityDialog(AssignmentProvider provider) {
    final metrics = provider.myProductivity;

    if (metrics == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay métricas disponibles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Productividad'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricRow(
                'Documentos Digitalizados',
                '${metrics.totalDocuments}',
                Icons.description,
              ),
              const Divider(),
              _buildMetricRow(
                'Personas Completadas',
                '${metrics.totalPersons}',
                Icons.people,
              ),
              const Divider(),
              _buildMetricRow(
                'Calidad Promedio',
                '${metrics.avgQualityScore.toStringAsFixed(1)}%',
                Icons.star,
              ),
              const Divider(),
              _buildMetricRow(
                'Tiempo Total',
                '${metrics.totalTimeHours.toStringAsFixed(1)} hrs',
                Icons.access_time,
              ),
              const Divider(),
              _buildMetricRow(
                'Documentos/Hora',
                metrics.documentsPerHour.toStringAsFixed(1),
                Icons.speed,
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

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  // ⏱️ FASE 2: Session management dialog
  void _showSessionDetailsDialog(BuildContext context) {
    final provider = context.read<AssignmentProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.teal),
            SizedBox(width: 8),
            Text('Sesión de Digitalización'),
          ],
        ),
        content: Consumer<AssignmentProvider>(
          builder: (context, provider, child) {
            if (provider.hasActiveSession) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tienes una sesión activa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Los documentos que digitalices serán contados automáticamente para métricas precisas.'),
                  const SizedBox(height: 24),
                  SessionControlButton(),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No hay sesión activa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Inicia una sesión para trackear tu tiempo y productividad.'),
                  const SizedBox(height: 24),
                  SessionControlButton(),
                ],
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
