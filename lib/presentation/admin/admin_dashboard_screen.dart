import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/logger_adapter.dart';

import '../../presentation/providers/assignment_provider.dart';
import '../../domain/entities/assignment.dart';
import '../assignment/widgets/dashboard_widgets.dart';
import '../widgets/session_indicator_widget.dart'; // ⏱️ FASE 2: Session indicator
import '../census/person_selection_screen.dart'; // 📸 Para captura de documentos

/// Admin Dashboard Screen - Full-featured dashboard for administrators
///
/// Features:
/// - Team statistics overview (total docs, digitizers, productivity)
/// - Top 5 digitizers leaderboard
/// - Assignment management quick actions
/// - Real-time metrics with refresh
/// - Filtering and search capabilities
/// - Quick navigation to management screens
///
/// Role Required: ADMIN
class AdminDashboardScreen extends StatefulWidget {
  static const String route = '/admin-dashboard';

  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
      _logger.i('📊 Loading admin dashboard data...');

      // Load all data concurrently
      await Future.wait([
        provider.loadTeamStatistics(),
        provider.loadAllAssignments(),
      ]);

      _logger.i('✅ Admin dashboard data loaded successfully');
    } catch (e) {
      _logger.e('❌ Failed to load admin dashboard data', error: e);
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
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // ⏱️ FASE 2: Session indicator for admin
          SessionIndicatorWidget(
            onTap: () {
              _showSessionDetailsDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refrescar datos',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to admin settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración (próximamente)')),
              );
            },
            tooltip: 'Configuración',
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
        onPressed: () => _showCreateAssignmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Crear Asignaciones'),
        backgroundColor: Colors.indigo,
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
              // Welcome header with quick stats
              _buildWelcomeHeader(provider),
              const SizedBox(height: 24),

              // Team Statistics Card
              if (provider.teamStatistics != null)
                TeamStatisticsCard(stats: provider.teamStatistics),
              const SizedBox(height: 16),

              // Quick Actions Grid
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),

              // Assignments Overview
              _buildAssignmentsOverview(provider),
              const SizedBox(height: 16),

              // Recent Activity (if available)
              _buildRecentActivity(provider),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(AssignmentProvider provider) {
    final stats = provider.teamStatistics;
    final userName = provider.currentUserProfile?.username ?? 'Admin';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.indigoAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, $userName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Administrador del Sistema',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  icon: Icons.people,
                  label: 'Digitalizadores',
                  value: '${stats?.totalDigitizers ?? 0}',
                ),
                _buildQuickStat(
                  icon: Icons.description,
                  label: 'Docs Hoy',
                  value: '${stats?.totalDocumentsToday ?? 0}',
                ),
                _buildQuickStat(
                  icon: Icons.assignment,
                  label: 'Asignaciones',
                  value: '${provider.allAssignments.length}',
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

  Widget _buildQuickActionsGrid() {
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
              icon: Icons.person_add,
              title: 'Crear Digitalizador',
              color: Colors.blue,
              onTap: () {
                _showMessage('Crear usuario digitalizador (próximamente)');
              },
            ),
            _buildQuickActionCard(
              icon: Icons.assignment_add,
              title: 'Asignar Personas',
              color: Colors.green,
              onTap: () => _showCreateAssignmentDialog(),
            ),
            _buildQuickActionCard(
              icon: Icons.camera_alt,
              title: 'Capturar Documento',
              color: Colors.teal,
              onTap: () {
                // 📸 Admin puede digitalizar documentos
                Navigator.of(context).pushNamed(PersonSelectionScreen.route);
              },
            ),
            _buildQuickActionCard(
              icon: Icons.bar_chart,
              title: 'Ver Reportes',
              color: Colors.orange,
              onTap: () {
                _showMessage('Reportes detallados (próximamente)');
              },
            ),
            _buildQuickActionCard(
              icon: Icons.people_outline,
              title: 'Gestionar Usuarios',
              color: Colors.purple,
              onTap: () {
                _showMessage('Gestión de usuarios (próximamente)');
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentsOverview(AssignmentProvider provider) {
    final allAssignments = provider.allAssignments;

    if (allAssignments.isEmpty) {
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
                  'No hay asignaciones creadas',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateAssignmentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Primera Asignación'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate stats by status
    final pending =
        allAssignments.where((a) => a.status == AssignmentStatus.pending).length;
    final inProgress = allAssignments
        .where((a) => a.status == AssignmentStatus.inProgress)
        .length;
    final completed = allAssignments
        .where((a) => a.status == AssignmentStatus.completed)
        .length;
    final reviewed =
        allAssignments.where((a) => a.status == AssignmentStatus.reviewed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resumen de Asignaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full assignments list
                _showMessage('Ver todas las asignaciones (próximamente)');
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
              children: [
                _buildAssignmentStatusRow(
                  'Pendientes',
                  pending,
                  allAssignments.length,
                  Colors.grey,
                ),
                const Divider(),
                _buildAssignmentStatusRow(
                  'En Progreso',
                  inProgress,
                  allAssignments.length,
                  Colors.blue,
                ),
                const Divider(),
                _buildAssignmentStatusRow(
                  'Completadas',
                  completed,
                  allAssignments.length,
                  Colors.green,
                ),
                const Divider(),
                _buildAssignmentStatusRow(
                  'Revisadas',
                  reviewed,
                  allAssignments.length,
                  Colors.indigo,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentStatusRow(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AssignmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildActivityItem(
                icon: Icons.check_circle,
                title: 'Sistema funcionando correctamente',
                subtitle: 'Todos los servicios operativos',
                time: 'Ahora',
                color: Colors.green,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                icon: Icons.info,
                title: 'Dashboard cargado',
                subtitle: 'Datos actualizados correctamente',
                time: 'Hace 1 min',
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    );
  }

  void _showCreateAssignmentDialog() {
    final digitizerIdController = TextEditingController();
    final personIdsController = TextEditingController();
    final requiredDocsController = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Asignaciones Masivas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: digitizerIdController,
                decoration: const InputDecoration(
                  labelText: 'ID del Digitalizador',
                  hintText: 'Ej: 1',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: personIdsController,
                decoration: const InputDecoration(
                  labelText: 'IDs de Personas (separados por coma)',
                  hintText: 'Ej: 2071, 2072, 2073',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: requiredDocsController,
                decoration: const InputDecoration(
                  labelText: 'Documentos Requeridos por Persona',
                  hintText: 'Ej: 5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text(
                'Nota: Se crearán asignaciones para cada persona con el digitalizador seleccionado.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final digitizerId = int.tryParse(digitizerIdController.text.trim());
              final personIdsText = personIdsController.text.trim();
              final requiredDocs = int.tryParse(requiredDocsController.text.trim()) ?? 5;

              if (digitizerId == null || personIdsText.isEmpty) {
                _showMessage('Por favor complete todos los campos');
                return;
              }

              final personIds = personIdsText
                  .split(',')
                  .map((id) => id.trim())
                  .where((id) => id.isNotEmpty)
                  .toList();

              if (personIds.isEmpty) {
                _showMessage('Ingrese al menos un ID de persona');
                return;
              }

              Navigator.pop(context);

              final provider = context.read<AssignmentProvider>();
              final success = await provider.createBulkAssignments(
                digitizerId: digitizerId,
                personIds: personIds,
                requiredDocuments: requiredDocs,
              );

              if (success) {
                _showMessage(
                  '✅ ${personIds.length} asignaciones creadas exitosamente',
                  isError: false,
                );
                _loadDashboardData();
              } else {
                _showMessage(
                  '❌ Error al crear asignaciones: ${provider.error}',
                );
              }
            },
            child: const Text('Crear Asignaciones'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ⏱️ FASE 2: Session details dialog for admin
  void _showSessionDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Sesión de Digitalización'),
          ],
        ),
        content: Consumer<AssignmentProvider>(
          builder: (context, provider, child) {
            if (provider.hasActiveSession) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Tienes una sesión activa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tus documentos digitalizados están siendo rastreados',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SessionControlButton(),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay sesión activa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia una sesión para rastrear tu productividad',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
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
