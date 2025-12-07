import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/database/app_database.dart';
import '../../services/reporting_service.dart';
import '../../services/gap_analysis_service.dart';
import '../../services/workflow_engine.dart';
import '../../core/config/production_config.dart';

/// Admin Panel Screen
///
/// Administrative interface for monitoring and configuration
class AdminPanelScreen extends StatefulWidget {
  static const String route = '/admin';

  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSystemStatus(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildWorkflowManagement(),
          const SizedBox(height: 16),
          _buildSystemConfig(),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Estado del Sistema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusItem('Versión', ProductionConfig.appVersion),
            _buildStatusItem('Entorno', ProductionConfig.environmentName),
            _buildStatusItem('API', ProductionConfig.tejidoBaseUrl),
            _buildStatusItem('Modo Offline', ProductionConfig.enableOfflineMode ? 'Activo' : 'Inactivo'),
            _buildStatusItem('Encriptación', 'AES-256-GCM'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Ver Reportes',
              'Estadísticas y análisis',
              Icons.analytics,
              Colors.blue,
              () => Navigator.pushNamed(context, '/dashboard'),
            ),
            _buildActionTile(
              'Análisis de Brechas',
              'Documentos faltantes',
              Icons.warning,
              Colors.orange,
              () => Navigator.pushNamed(context, '/gap-analysis'),
            ),
            _buildActionTile(
              'Sincronización Manual',
              'Forzar sincronización',
              Icons.sync,
              Colors.green,
              () => _showSyncDialog(),
            ),
            _buildActionTile(
              'Limpiar Caché',
              'Liberar espacio',
              Icons.cleaning_services,
              Colors.red,
              () => _showClearCacheDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildWorkflowManagement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Workflows Automatizados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('5 reglas activas', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showWorkflowSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Configurar Workflows'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Configuración',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Modo Offline'),
              subtitle: const Text('Cola de subida sin conexión'),
              value: ProductionConfig.enableOfflineMode,
              onChanged: null, // Read-only in UI
            ),
            SwitchListTile(
              title: const Text('Background Sync'),
              subtitle: const Text('Sincronización automática'),
              value: ProductionConfig.enableBackgroundSync,
              onChanged: null,
            ),
            SwitchListTile(
              title: const Text('Analytics'),
              subtitle: const Text('Recopilación local de datos'),
              value: ProductionConfig.enableAnalytics,
              onChanged: null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronización Manual'),
        content: const Text('¿Deseas sincronizar todos los documentos pendientes ahora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sincronización iniciada')),
              );
            },
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Caché'),
        content: const Text('Esto eliminará archivos temporales. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caché limpiado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showWorkflowSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reglas de Workflow',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      _buildWorkflowRuleTile(
                        'Auto-etiquetar Cédulas',
                        'Aplica etiqueta automáticamente',
                        true,
                      ),
                      _buildWorkflowRuleTile(
                        'Notificar Documentos Prioritarios',
                        'Alerta en docs de personas con brechas',
                        true,
                      ),
                      _buildWorkflowRuleTile(
                        'Clasificar por Nombre de Archivo',
                        'Auto-clasificación inteligente',
                        true,
                      ),
                      _buildWorkflowRuleTile(
                        'Recordatorio de Calidad',
                        'Avisa si la imagen es de baja calidad',
                        true,
                      ),
                      _buildWorkflowRuleTile(
                        'Familia Completa',
                        'Celebra cuando una familia termina',
                        true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkflowRuleTile(String title, String description, bool enabled) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(description),
      value: enabled,
      onChanged: (value) {
        // In production, update workflow rule
      },
    );
  }
}
