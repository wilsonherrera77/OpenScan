import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/database/app_database.dart';
import '../../services/reporting_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';
import 'family_report_screen.dart';
import 'export_report_screen.dart';

/// Dashboard Screen
///
/// Main analytics and reporting dashboard showing:
/// - Overall statistics
/// - Progress charts
/// - Quick actions
/// - Recent activity
class DashboardScreen extends StatefulWidget {
  static const String route = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ReportingService _reportingService;
  bool _isLoading = true;
  String? _error;

  OverallStatistics? _overallStats;
  List<DailyStatistics>? _dailyTrends;
  Map<String, int>? _documentTypes;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      _reportingService = ReportingService(database);

      // Load all data in parallel
      final results = await Future.wait([
        _reportingService.getOverallStatistics(),
        _reportingService.getDailyTrends(days: 7),
        _reportingService.getDocumentTypeDistribution(),
      ]);

      setState(() {
        _overallStats = results[0] as OverallStatistics;
        _dailyTrends = results[1] as List<DailyStatistics>;
        _documentTypes = results[2] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => Navigator.pushNamed(context, ExportReportScreen.route),
            tooltip: 'Exportar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando estadísticas...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStats(),
            const SizedBox(height: 24),
            _buildProgressSection(),
            const SizedBox(height: 24),
            _buildTrendsChart(),
            const SizedBox(height: 24),
            _buildDocumentTypesChart(),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    if (_overallStats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: 'Documentos Totales',
              value: _overallStats!.totalDocuments.toString(),
              icon: Icons.description,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Personas',
              value: _overallStats!.uniquePersons.toString(),
              icon: Icons.people,
              color: Colors.green,
            ),
            StatCard(
              title: 'Familias',
              value: _overallStats!.uniqueFamilies.toString(),
              icon: Icons.family_restroom,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Tamaño Total',
              value: ReportingService.formatBytes(_overallStats!.totalSize),
              icon: Icons.storage,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    if (_overallStats == null) return const SizedBox();

    final total = _overallStats!.totalDocuments +
        _overallStats!.pendingDocuments +
        _overallStats!.failedDocuments;

    final completedPercentage = total > 0 ? (_overallStats!.totalDocuments / total) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progreso de Digitalización',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completedPercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                completedPercentage >= 75 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${completedPercentage.toStringAsFixed(1)}% completado',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressItem(
                  'Completados',
                  _overallStats!.totalDocuments,
                  Colors.green,
                ),
                _buildProgressItem(
                  'Pendientes',
                  _overallStats!.pendingDocuments,
                  Colors.orange,
                ),
                _buildProgressItem(
                  'Fallidos',
                  _overallStats!.failedDocuments,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasa de éxito: ${_overallStats!.successRate.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Últimos 7 días: ${_overallStats!.recentUploadsLast7Days}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTrendsChart() {
    if (_dailyTrends == null || _dailyTrends!.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendencia de Últimos 7 Días',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChartWidget(
                data: _dailyTrends!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypesChart() {
    if (_documentTypes == null || _documentTypes!.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipos de Documentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChartWidget(
                data: _documentTypes!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.family_restroom, color: Colors.blue),
              title: const Text('Reportes por Familia'),
              subtitle: const Text('Ver estadísticas de cada familia'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, FamilyReportScreen.route),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.green),
              title: const Text('Análisis de Brechas'),
              subtitle: const Text('Documentos faltantes por persona'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to gap analysis
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Análisis de brechas (próximamente)')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.orange),
              title: const Text('Exportar Reportes'),
              subtitle: const Text('Generar PDF o Excel'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, ExportReportScreen.route),
            ),
          ],
        ),
      ),
    );
  }
}
