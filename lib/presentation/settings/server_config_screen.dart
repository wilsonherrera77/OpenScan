import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/logger_adapter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/security/secure_config_manager.dart';
import '../../data/datasources/tejido_api_client.dart';

/// Server Configuration Screen
/// Allows users to configure and test Tejido server connection
///
/// FASE 1: Solución crítica para problema de conectividad
class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({Key? key}) : super(key: key);

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _logger = LoggerAdapter();
  final _configManager = SecureConfigManager();

  bool _isLoading = false;
  bool _isTesting = false;
  String? _connectionStatus;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Load current server configuration
  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);

    try {
      final savedUrl = await _configManager.getBaseUrl();
      _urlController.text = savedUrl ?? ApiConstants.defaultBaseUrl;

      _logger.i('Loaded server config: ${_urlController.text}');
    } catch (e) {
      _logger.e('Failed to load config: $e');
      _urlController.text = ApiConstants.defaultBaseUrl;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Test connection to server
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _connectionStatus = 'Probando conexión...';
      _statusColor = Colors.orange;
    });

    try {
      final url = _urlController.text.trim();

      _logger.i('🔍 Testing connection to: $url');

      // Create temporary API client with test URL
      final apiClient = TejidoApiClient(baseUrl: url);
      final isReachable = await apiClient.testConnection();

      if (isReachable) {
        setState(() {
          _connectionStatus = '✅ Conexión exitosa';
          _statusColor = Colors.green;
        });
        _logger.i('✅ Server is reachable');

        // Show success dialog
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        setState(() {
          _connectionStatus = '❌ Servidor no responde';
          _statusColor = Colors.red;
        });
        _logger.e('❌ Server is not reachable');
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: ${e.toString().replaceAll('Exception: ', '')}';
        _statusColor = Colors.red;
      });
      _logger.e('❌ Connection test failed: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  /// Save server configuration
  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = _urlController.text.trim();

      _logger.i('💾 Saving server config: $url');

      // Save to secure storage
      await _configManager.setBaseUrl(url);

      // Update API client with new URL
      final apiClient = TejidoApiClient(baseUrl: url);
      apiClient.setBaseUrl(url);

      _logger.i('✅ Server config saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Return to previous screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _logger.e('❌ Failed to save config: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show success dialog with option to save
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Conexión Exitosa'),
          ],
        ),
        content: const Text(
          'El servidor está accesible. ¿Deseas guardar esta configuración?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveConfiguration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Validate URL format
  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa la URL del servidor';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return 'URL inválida. Debe comenzar con http:// o https://';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Protocolo inválido. Usa http:// o https://';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Servidor'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Configuración del Servidor',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ingresa la URL del servidor Tejido-NGX. '
                              'Debe estar en la misma red WiFi que este dispositivo.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // URL input field
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL del Servidor',
                        hintText: 'http://192.168.1.100:8001',
                        prefixIcon: const Icon(Icons.dns),
                        border: const OutlineInputBorder(),
                        helperText: 'Ejemplo: http://192.168.1.100:8001',
                      ),
                      validator: _validateUrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                    ),

                    const SizedBox(height: 16),

                    // Quick presets
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'URLs Rápidas:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPresetChip(
                                  'LAN Actual',
                                  ApiConstants.defaultBaseUrl,
                                  Icons.wifi,
                                ),
                                _buildPresetChip(
                                  'Localhost',
                                  ApiConstants.localhostUrl,
                                  Icons.computer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Test connection button
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isTesting ? 'Probando...' : 'Probar Conexión'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Connection status
                    if (_connectionStatus != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _statusColor),
                        ),
                        child: Row(
                          children: [
                            Icon(_statusColor == Colors.green
                                ? Icons.check_circle
                                : _statusColor == Colors.orange
                                  ? Icons.hourglass_empty
                                  : Icons.error,
                              color: _statusColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _connectionStatus!,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveConfiguration,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Configuración'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Troubleshooting section
                    ExpansionTile(
                      title: const Text('Solución de Problemas'),
                      leading: const Icon(Icons.help_outline),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTroubleshootItem(
                                '1. Verifica que el servidor esté corriendo',
                                'docker-compose ps',
                              ),
                              const SizedBox(height: 12),
                              _buildTroubleshootItem(
                                '2. Verifica la IP del servidor',
                                'ip addr show',
                              ),
                              const SizedBox(height: 12),
                              _buildTroubleshootItem(
                                '3. Verifica que estés en la misma red WiFi',
                                'Ambos dispositivos deben estar conectados a la misma red',
                              ),
                              const SizedBox(height: 12),
                              _buildTroubleshootItem(
                                '4. Verifica el puerto',
                                'El servidor debe estar en el puerto 8001',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPresetChip(String label, String url, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        setState(() {
          _urlController.text = url;
        });
      },
    );
  }

  Widget _buildTroubleshootItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
