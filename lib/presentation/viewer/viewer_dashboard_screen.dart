import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/logger_adapter.dart';

import '../../presentation/providers/assignment_provider.dart';
import '../../domain/entities/assignment.dart';
import '../../services/csv_export_service.dart'; // ⏱️ FASE 2: CSV export
import '../../data/repositories/assignment_repository.dart'; // ⏱️ FASE 2: For CSV service

/// Viewer Dashboard Screen - Read-only dashboard for coordinators/viewers
///
/// Features:
/// - Overview of system status (high-level metrics)
/// - Progress reports (by digitizer, by family, by timeframe)
/// - Analytics and charts (visual representations)
/// - Export functionality (CSV, PDF reports)
/// - Read-only access (no modification capabilities)
///
/// Role Required: VIEWER
class ViewerDashboardScreen extends StatefulWidget {
  static const String route = '/viewer-dashboard';

  const ViewerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ViewerDashboardScreen> createState() => _ViewerDashboardScreenState();
}

class _ViewerDashboardScreenState extends State<ViewerDashboardScreen> {
  final LoggerAdapter _logger = LoggerAdapter();
  bool _isInitialized = false;
  String _selectedTimeframe = 'today'; // today, week, month, all

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
      _logger.i('📊 Loading viewer dashboard data...');

      // Load read-only data
      await Future.wait([
        provider.loadAllAssignments(),
        provider.loadTeamStatistics(),
      ]);

      _logger.i('✅ Viewer dashboard data loaded successfully');
    } catch (e) {
      _logger.e('❌ Failed to load viewer dashboard data', error: e);
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
        title: const Text('Dashboard - Reportes'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refrescar datos',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              _showExportDialog();
            },
            tooltip: 'Exportar reportes',
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
        final stats = provider.teamStatistics;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              _buildWelcomeHeader(provider),
              const SizedBox(height: 24),

              // Timeframe selector
              _buildTimeframeSelector(),
              const SizedBox(height: 16),

              // System overview metrics
              _buildSystemOverview(provider, stats),
              const SizedBox(height: 16),

              // Progress charts
              _buildProgressCharts(provider),
              const SizedBox(height: 16),

              // Digitizers performance
              _buildDigitizersPerformance(provider, stats),
              const SizedBox(height: 16),

              // Documents breakdown
              _buildDocumentsBreakdown(provider),
              const SizedBox(height: 16),

              // Export options
              _buildExportOptions(),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(AssignmentProvider provider) {
    final userName = provider.currentUserProfile?.username ?? 'Coordinador';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.blueGrey, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 32),
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
                        'Reportes y Analytics del Sistema',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vista de solo lectura - Acceso a reportes y estadísticas',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text(
              'Período:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  _buildTimeframeChip('Hoy', 'today'),
                  _buildTimeframeChip('Semana', 'week'),
                  _buildTimeframeChip('Mes', 'month'),
                  _buildTimeframeChip('Todo', 'all'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeChip(String label, String value) {
    final isSelected = _selectedTimeframe == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTimeframe = value;
        });
        _showMessage('Filtrando por: $label');
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blueGrey,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSystemOverview(
    AssignmentProvider provider,
    TeamStatistics? stats,
  ) {
    final totalAssignments = provider.allAssignments.length;
    final completed = provider.allAssignments
        .where((a) => a.status == AssignmentStatus.completed || a.status == AssignmentStatus.reviewed)
        .length;
    final inProgress =
        provider.allAssignments.where((a) => a.status == AssignmentStatus.inProgress).length;
    final pending = provider.allAssignments.where((a) => a.status == AssignmentStatus.pending).length;

    final completionPercentage =
        totalAssignments > 0 ? (completed / totalAssignments * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General del Sistema',
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
                    _buildOverviewMetric(
                      'Asignaciones',
                      '$totalAssignments',
                      Icons.assignment,
                      Colors.blue,
                    ),
                    _buildOverviewMetric(
                      'Completadas',
                      '$completed',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildOverviewMetric(
                      'En Progreso',
                      '$inProgress',
                      Icons.hourglass_top,
                      Colors.orange,
                    ),
                    _buildOverviewMetric(
                      'Pendientes',
                      '$pending',
                      Icons.pending,
                      Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progreso Global',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMetric(
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressCharts(AssignmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gráficos de Progreso',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.bar_chart, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'Gráficos Visuales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Próximamente: Gráficos de barras, líneas y pie charts\nmostrando progreso por digitalizador, familia, y período',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Características incluirán:\n'
                  '• Progreso diario/semanal/mensual\n'
                  '• Comparativa entre digitalizadores\n'
                  '• Distribución por tipo de documento\n'
                  '• Tendencias de productividad',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitizersPerformance(
    AssignmentProvider provider,
    TeamStatistics? stats,
  ) {
    final digitizers = <String, Map<String, int>>{};

    // Group assignments by digitizer
    for (var assignment in provider.allAssignments) {
      final digitizerName = assignment.digitizerName ?? 'Unknown';
      if (!digitizers.containsKey(digitizerName)) {
        digitizers[digitizerName] = {
          'total': 0,
          'completed': 0,
          'inProgress': 0,
          'pending': 0,
        };
      }

      digitizers[digitizerName]!['total'] = digitizers[digitizerName]!['total']! + 1;

      if (assignment.status == AssignmentStatus.completed ||
          assignment.status == AssignmentStatus.reviewed) {
        digitizers[digitizerName]!['completed'] =
            digitizers[digitizerName]!['completed']! + 1;
      } else if (assignment.status == AssignmentStatus.inProgress) {
        digitizers[digitizerName]!['inProgress'] =
            digitizers[digitizerName]!['inProgress']! + 1;
      } else if (assignment.status == AssignmentStatus.pending) {
        digitizers[digitizerName]!['pending'] =
            digitizers[digitizerName]!['pending']! + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desempeño por Digitalizador',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: digitizers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No hay digitalizadores activos',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: digitizers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = digitizers.entries.elementAt(index);
                    final name = entry.key;
                    final metrics = entry.value;
                    final total = metrics['total']!;
                    final completed = metrics['completed']!;
                    final percentage =
                        total > 0 ? (completed / total * 100).toInt() : 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.withOpacity(0.1),
                        child:
                            const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: $total | Completadas: $completed | En Progreso: ${metrics['inProgress']} | Pendientes: ${metrics['pending']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                            minHeight: 4,
                          ),
                        ],
                      ),
                      trailing: Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentsBreakdown(AssignmentProvider provider) {
    final totalDocs = provider.allAssignments.fold<int>(
        0, (sum, a) => sum + a.digitizedDocuments);
    final requiredDocs = provider.allAssignments.fold<int>(
        0, (sum, a) => sum + a.requiredDocuments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desglose de Documentos',
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
                    _buildDocMetric(
                      'Digitalizados',
                      '$totalDocs',
                      Colors.green,
                    ),
                    _buildDocMetric(
                      'Requeridos',
                      '$requiredDocs',
                      Colors.blue,
                    ),
                    _buildDocMetric(
                      'Faltantes',
                      '${requiredDocs - totalDocs}',
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Próximamente: Desglose por tipo de documento',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cédulas, Registro Civil, Tarjetas de Identidad, etc.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
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

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exportar Reportes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildExportButton(
                  'Exportar a CSV',
                  'Descarga datos en formato CSV para Excel',
                  Icons.table_chart,
                  Colors.green,
                  () => _exportToCSV(),
                ),
                const SizedBox(height: 12),
                _buildExportButton(
                  'Exportar a PDF',
                  'Genera reporte completo en PDF',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () => _exportToPDF(),
                ),
                const SizedBox(height: 12),
                _buildExportButton(
                  'Compartir Reporte',
                  'Envía reporte por email o WhatsApp',
                  Icons.share,
                  Colors.blue,
                  () => _shareReport(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }

  void _showExportDialog() {
    // ⏱️ FASE 2: Show CSV export menu with three options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blueGrey),
            SizedBox(width: 8),
            Text('Exportar Reportes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.blue),
              title: const Text('Exportar Asignaciones'),
              subtitle: const Text('CSV con todas las asignaciones'),
              onTap: () {
                Navigator.pop(context);
                _exportAssignmentsCSV();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),
              title: const Text('Exportar Productividad'),
              subtitle: const Text('Métricas por digitalizador'),
              onTap: () {
                Navigator.pop(context);
                _exportProductivityCSV();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.orange),
              title: const Text('Exportar Resumen Equipo'),
              subtitle: const Text('Estadísticas globales'),
              onTap: () {
                Navigator.pop(context);
                _exportTeamSummaryCSV();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // ⏱️ FASE 2: CSV Export Methods
  Future<void> _exportAssignmentsCSV() async {
    final repository = context.read<AssignmentRepository>();
    final csvService = CSVExportService(repository);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando CSV de Asignaciones...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await csvService.exportAndShareAssignments();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showMessage(
          success
              ? '✅ CSV exportado exitosamente'
              : '❌ Error al exportar CSV',
        );
      }
    } catch (e) {
      _logger.e('Error exporting assignments CSV', error: e);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showMessage('❌ Error: ${e.toString()}');
      }
    }
  }

  Future<void> _exportProductivityCSV() async {
    final repository = context.read<AssignmentRepository>();
    final csvService = CSVExportService(repository);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando CSV de Productividad...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Map timeframe to period parameter
      String? period;
      switch (_selectedTimeframe) {
        case 'today':
          period = 'day';
          break;
        case 'week':
          period = 'week';
          break;
        case 'month':
          period = 'month';
          break;
        default:
          period = null;
      }

      final success = await csvService.exportAndShareProductivity(period: period);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showMessage(
          success
              ? '✅ CSV de productividad exportado exitosamente'
              : '❌ Error al exportar CSV',
        );
      }
    } catch (e) {
      _logger.e('Error exporting productivity CSV', error: e);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showMessage('❌ Error: ${e.toString()}');
      }
    }
  }

  Future<void> _exportTeamSummaryCSV() async {
    final repository = context.read<AssignmentRepository>();
    final csvService = CSVExportService(repository);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando Resumen del Equipo...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await csvService.exportAndShareTeamSummary();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showMessage(
          success
              ? '✅ Resumen del equipo exportado exitosamente'
              : '❌ Error al exportar resumen',
        );
      }
    } catch (e) {
      _logger.e('Error exporting team summary CSV', error: e);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showMessage('❌ Error: ${e.toString()}');
      }
    }
  }

  void _exportToCSV() {
    // Redirect to new method
    _exportAssignmentsCSV();
  }

  void _exportToPDF() {
    _showMessage('Generando PDF... (funcionalidad en desarrollo)');
    // TODO: Implement PDF export using printing package
  }

  void _shareReport() {
    // Show export dialog instead
    _showExportDialog();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
