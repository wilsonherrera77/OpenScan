import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/navigation/role_based_navigator.dart';
import '../providers/auth_provider.dart';
import '../providers/assignment_provider.dart';
import 'qr_config_screen.dart';

/// Login Screen
/// Allows users to authenticate with Paperless-ngx
class LoginScreen extends StatefulWidget {
  static const String route = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _baseUrlController = TextEditingController();

  bool _obscurePassword = true;
  bool _showAdvanced = false;
  bool _isLoadingUrl = true;

  @override
  void initState() {
    super.initState();
    _loadSavedBaseUrl();
    // ✅ DEBUG: Auto-fill for testing (REMOVE BEFORE PRODUCTION)
    _usernameController.text = 'admin';
    _passwordController.text = 'admin';
    // ✅ DEBUG: Auto-login after 2 seconds (REMOVE BEFORE PRODUCTION)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _handleLogin();
    });
  }

  /// Load previously saved base URL
  Future<void> _loadSavedBaseUrl() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final savedUrl = await authProvider.getBaseUrl();

      setState(() {
        _baseUrlController.text = savedUrl;
        _isLoadingUrl = false;
      });
    } catch (e) {
      setState(() {
        _baseUrlController.text = ApiConstants.defaultBaseUrl;
        _isLoadingUrl = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    final success = await authProvider.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      baseUrl: _baseUrlController.text.trim(),
    );

    if (success && mounted) {
      // Navigate based on user role
      await RoleBasedNavigator.navigateAfterLogin(context, assignmentProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo and Title
                Icon(
                  Icons.document_scanner,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                Text(
                  ApiConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Digitaliza, organiza y gestiona\ndocumentos de forma inteligente',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Server URL (always visible)
                TextFormField(
                  controller: _baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL del Servidor Paperless',
                    prefixIcon: Icon(Icons.cloud),
                    border: OutlineInputBorder(),
                    hintText: 'http://127.0.0.1:8001',
                    helperText: 'Asegúrate de estar en la misma WiFi que el servidor',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la URL del servidor';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'URL debe comenzar con http:// o https://';
                    }
                    // Validate format (IP:PORT)
                    final urlPattern = RegExp(r'https?://[\d\.]+:\d+');
                    if (!urlPattern.hasMatch(value)) {
                      return 'Formato: http://IP:PUERTO (ej: http://192.168.1.10:8001)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),

                        // Error Message
                        if (authProvider.error != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.red.shade900,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      authProvider.error!,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                // QR Scanner Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRConfigScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Configurar con QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ⚡ Configuración INSTANTÁNEA de IP (sin QR)
                TextButton.icon(
                  onPressed: () => _showManualIPConfig(),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Configurar IP Manualmente'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // QR Help Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Escanea el QR desde la web de Tejido para configurar automáticamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Help Text
                Card(
                  color: Colors.blue.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.help_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '¿Cómo obtener credenciales?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Accede al panel admin de Paperless\n'
                          '2. Usa las mismas credenciales del admin\n'
                          '3. Usuario por defecto: admin',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ⚡ Configuración INSTANTÁNEA de IP sin QR
  Future<void> _showManualIPConfig() async {
    final ipController = TextEditingController(text: '127.0.0.1');
    final portController = TextEditingController(text: '8001');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.settings_ethernet, color: Colors.teal),
            SizedBox(width: 12),
            Text('Configurar IP del Servidor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa la IP y puerto del servidor Tejido:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP del Servidor',
                hintText: '127.0.0.1',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                hintText: '8001',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 20, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La IP por defecto es la del servidor actual',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final ip = ipController.text.trim();
      final port = portController.text.trim();

      if (ip.isEmpty || port.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor ingresa IP y puerto válidos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Construir URL
      final serverUrl = 'http://$ip:$port';

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', serverUrl);
      await prefs.setString('server_name', 'Tejido Cabildo');
      await prefs.setBool('is_configured', true);

      // Actualizar el campo de URL en el formulario
      setState(() {
        _baseUrlController.text = serverUrl;
      });

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Servidor configurado: $serverUrl'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
