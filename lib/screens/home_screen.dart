import 'dart:io';

import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:provider/provider.dart';
import '../Utilities/Classes.dart';
import '../Utilities/constants.dart';
import '../Utilities/database_helper.dart';
import '../Widgets/FAB.dart';
import '../presentation/widgets/sync_status_indicator.dart';
import '../services/upload_service.dart';
import 'about_screen.dart';
import 'getting_started_screen.dart';
import 'view_document.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:lumara_scan/services/background_sync_service.dart';
import 'package:lumara_scan/services/connectivity_service.dart';
import 'package:lumara_scan/data/datasources/paperless_api_client.dart';
import 'package:lumara_scan/presentation/settings/server_config_screen.dart';
import 'package:lumara_scan/presentation/census/person_selection_screen.dart';
import 'package:lumara_scan/presentation/providers/census_provider.dart';
import '../services/logger_adapter.dart';

class HomeScreen extends StatefulWidget {
  static String route = "HomeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  DatabaseHelper database = DatabaseHelper();
  List<Map<String, dynamic>>? masterData;
  List<DirectoryOS> masterDirectories = [];
  QuickActions quickActions = QuickActions();
  final LoggerAdapter _logger = LoggerAdapter();
  bool _isSyncing = false;
  bool _autoSyncEnabled = false;

  Future homeRefresh() async {
    await getMasterData();
    setState(() {});
  }

  void getData() {
    homeRefresh();
  }

  Future<bool> _requestPermission() async {
    if (await Permission.storage.request().isGranted &&
        await Permission.camera.request().isGranted) {
      return true;
    }
    await Permission.storage.request();
    await Permission.camera.request();
    return false;
  }

  void askPermission() async {
    await _requestPermission();
  }

  Future<List<DirectoryOS>> getMasterData() async {
    masterDirectories = [];
    masterData = await database.getMasterData();
    // print('Master Table => $masterData');
    for (var directory in masterData!) {
      var flag = false;
      for (var dir in masterDirectories) {
        if (dir.dirPath == directory['dir_path']) {
          flag = true;
        }
      }
      if (!flag) {
        masterDirectories.add(
          DirectoryOS(
            dirName: directory['dir_name'],
            dirPath: directory['dir_path'],
            created: DateTime.parse(directory['created']),
            imageCount: directory['image_count'],
            firstImgPath: directory['first_img_path'],
            lastModified: DateTime.parse(directory['last_modified']),
            newName: directory['new_name'],
          ),
        );
      }
    }
    masterDirectories = masterDirectories.reversed.toList();
    return masterDirectories;
  }

  /// Clean all scanned documents (v4.4.3)
  Future<void> _cleanAllDocuments() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Limpiar documentos'),
        content: Text('¿Eliminar TODOS los documentos escaneados del dispositivo?\n\nEsta acción NO afecta los documentos ya sincronizados en Paperless.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Delete all directories
              for (var dir in masterDirectories) {
                try {
                  if (dir.dirPath != null) {
                    await Directory(dir.dirPath!).delete(recursive: true);
                    await database.deleteDirectory(dirPath: dir.dirPath!);
                  }
                } catch (e) {
                  _logger.e('Error deleting directory: $e');
                }
              }

              // Refresh UI
              await homeRefresh();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Documentos eliminados'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// ✅ v6.4.0+92: Encolar TODOS los documentos locales antes de sincronizar
  /// Esta función escanea todas las carpetas de documentos y encola las imágenes
  /// que aún no están en la base de datos de uploads pendientes
  /// v6.4.5: Ahora vincula documentos con persona seleccionada del censo
  Future<int> _enqueueAllLocalDocuments() async {
    _logger.i('[ENQUEUE-ALL] === Escaneando carpetas locales ===');
    debugPrint('🔵 [ENQUEUE-DEBUG] === Escaneando ${masterDirectories.length} carpetas ===');

    int totalEnqueued = 0;
    final uploadService = Provider.of<UploadService>(context, listen: false);

    // ✅ v6.4.5: Obtener datos de persona seleccionada del CensusProvider
    final censusProvider = Provider.of<CensusProvider>(context, listen: false);
    final selectedPerson = censusProvider.selectedPerson;
    final documentType = censusProvider.documentType;
    final documentNumber = censusProvider.documentNumber;

    if (selectedPerson != null) {
      _logger.i('[ENQUEUE-ALL] 👤 Persona seleccionada: ${selectedPerson.fullName} (ID: ${selectedPerson.personId})');
      _logger.i('[ENQUEUE-ALL] 📄 Tipo documento: $documentType, Número: $documentNumber');
    } else {
      _logger.w('[ENQUEUE-ALL] ⚠️ No hay persona seleccionada - documentos se marcarán como GENERIC');
    }

    for (final dirOS in masterDirectories) {
      debugPrint('🔵 [ENQUEUE-DEBUG] Processing dir: ${dirOS.dirName}');
      if (dirOS.dirPath == null) continue;

      _logger.i('[ENQUEUE-ALL] Escaneando carpeta: ${dirOS.dirName}');
      _logger.i('[ENQUEUE-ALL]   Path: ${dirOS.dirPath}');

      final dir = Directory(dirOS.dirPath!);
      if (!await dir.exists()) {
        _logger.w('[ENQUEUE-ALL]   ❌ Carpeta no existe, saltando');
        continue;
      }

      // Get all image files in this directory
      final List<FileSystemEntity> files;
      try {
        files = await dir.list().toList();
      } catch (e) {
        _logger.e('[ENQUEUE-ALL]   ❌ Error listando archivos: $e');
        continue;
      }

      final imageFiles = files
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.jpg') ||
                        f.path.toLowerCase().endsWith('.jpeg') ||
                        f.path.toLowerCase().endsWith('.png'))
          .toList();

      _logger.i('[ENQUEUE-ALL]   Imágenes encontradas: ${imageFiles.length}');

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        _logger.i('[ENQUEUE-ALL]   Procesando ${i+1}/${imageFiles.length}: ${imageFile.path.split('/').last}');

        try {
          // ✅ v6.4.5: Pasar datos de persona seleccionada al encolar
          final enqueueId = await uploadService.enqueueGenericDocument(
            documentFile: imageFile,
            title: 'Doc_${dirOS.newName}_${i+1}_${DateTime.now().millisecondsSinceEpoch}',
            documentType: documentType, // Tipo de documento seleccionado
            documentNumber: documentNumber, // Número de documento
            sourceDirectory: dirOS.dirPath,
            personId: selectedPerson?.personId, // ID de persona del censo
            personName: selectedPerson?.fullName, // Nombre completo
            familyId: selectedPerson?.familyId, // ID de familia
          );
          _logger.i('[ENQUEUE-ALL]   ✅ Encolado con ID: $enqueueId (Persona: ${selectedPerson?.personId ?? "GENERIC"})');
          totalEnqueued++;
        } catch (e) {
          _logger.e('[ENQUEUE-ALL]   ❌ Error al encolar: $e');
        }
      }
    }

    _logger.i('[ENQUEUE-ALL] === COMPLETADO: $totalEnqueued documentos encolados ===');
    return totalEnqueued;
  }

  /// Manual sync with Paperless-ngx
  Future<void> _handleManualSync() async {
    // ✅ v6.4.0+94: Debugging - immediate feedback
    debugPrint('🔵 [SYNC-DEBUG] _handleManualSync() CALLED');

    if (_isSyncing) {
      _logger.w('⚠️ Sync already in progress');
      debugPrint('🔴 [SYNC-DEBUG] Sync already in progress, returning');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync ya en progreso...'), backgroundColor: Colors.orange),
      );
      return;
    }

    // ✅ v6.4.0+94: Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando sincronización...'), backgroundColor: Colors.blue, duration: Duration(seconds: 2)),
    );
    debugPrint('🔵 [SYNC-DEBUG] SnackBar shown, setting _isSyncing = true');

    setState(() {
      _isSyncing = true;
    });

    bool dialogShown = false;

    try {
      _logger.i('🔄 Starting manual sync from HomeScreen...');
      debugPrint('🔵 [SYNC-DEBUG] Starting manual sync...');

      final uploadService = Provider.of<UploadService>(context, listen: false);

      // ✅ v6.4.0+92: PRIMERO encolar todos los documentos locales
      _logger.i('📂 Paso 1: Escaneando carpetas locales para encolar...');
      debugPrint('🔵 [SYNC-DEBUG] Step 1: Calling _enqueueAllLocalDocuments()...');
      final enqueued = await _enqueueAllLocalDocuments();
      _logger.i('📊 Documentos encolados en este paso: $enqueued');
      debugPrint('🔵 [SYNC-DEBUG] Enqueued $enqueued documents');

      // ✅ FIX v6.4.0: Get pending count AFTER enqueuing
      final pendingCountBefore = await uploadService.getPendingCount();
      _logger.i('📊 Documents pending before sync: $pendingCountBefore');
      debugPrint('🔵 [SYNC-DEBUG] Pending count: $pendingCountBefore');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: secondaryColor),
              SizedBox(height: 20),
              Text(
                'Sincronizando documentos...',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Por favor espera (timeout: 90s)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
      dialogShown = true;
      debugPrint('🔵 [SYNC-DEBUG] Dialog shown, calling BackgroundSyncService.scheduleImmediateSync()...');

      // Perform sync
      final success = await BackgroundSyncService.scheduleImmediateSync();
      debugPrint('🔵 [SYNC-DEBUG] scheduleImmediateSync() returned: $success');

      // Close loading dialog safely
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // Show result dialog
      if (mounted) {
        // ✅ FIX v6.4.0: Mensaje claro basado en pending count
        final String titleText = success
          ? (pendingCountBefore > 0
              ? 'Sincronización exitosa'
              : 'Sin documentos pendientes')
          : 'Error de sincronización';

        final String messageText = success
          ? (pendingCountBefore > 0
              ? '$pendingCountBefore documentos sincronizados con Paperless-ngx'
              : 'No hay documentos pendientes para sincronizar.\n\nCaptura documentos desde la pantalla principal.')
          : 'No se pudo sincronizar. Verifica tu conexión.';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? successColor : errorColor,
                ),
                SizedBox(width: 10),
                Text(titleText),
              ],
            ),
            content: Text(
              messageText,
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: secondaryColor)),
              ),
            ],
          ),
        );
      }

      if (success) {
        _logger.i('✅ Manual sync completed successfully');
      } else {
        _logger.e('❌ Manual sync failed');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Manual sync error: $e', error: e, stackTrace: stackTrace);
      debugPrint('🔴 [SYNC-DEBUG] ERROR: $e');
      debugPrint('🔴 [SYNC-DEBUG] StackTrace: $stackTrace');

      // Close loading dialog if still open (safely)
      if (dialogShown && mounted && Navigator.canPop(context)) {
        try {
          Navigator.pop(context);
        } catch (popError) {
          _logger.w('⚠️ Could not pop dialog: $popError');
        }
        dialogShown = false;
      }

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: errorColor),
                SizedBox(width: 10),
                Text('Error'),
              ],
            ),
            content: Text(
              'Error al sincronizar: $e',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: secondaryColor)),
              ),
            ],
          ),
        );
      }
    } finally {
      // Ensure loading dialog is closed
      if (dialogShown && mounted && Navigator.canPop(context)) {
        try {
          Navigator.pop(context);
        } catch (e) {
          _logger.w('⚠️ Could not pop dialog in finally: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// Toggle automatic background sync
  Future<void> _toggleAutoSync() async {
    try {
      if (_autoSyncEnabled) {
        // Disable auto sync
        await BackgroundSyncService.stopPeriodicSync();
        setState(() {
          _autoSyncEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sincronización automática desactivada'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Enable auto sync
        final success = await BackgroundSyncService.startPeriodicSync(
          interval: Duration(minutes: 15),
        );

        if (success) {
          setState(() {
            _autoSyncEnabled = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sincronización automática activada (cada 15 min)'),
              backgroundColor: successColor,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al activar sincronización automática'),
              backgroundColor: errorColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error toggling auto sync: $e', error: e, stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: errorColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Check auto sync status
  Future<void> _checkAutoSyncStatus() async {
    try {
      final isRunning = await BackgroundSyncService.isPeriodicSyncRunning();
      setState(() {
        _autoSyncEnabled = isRunning;
      });
      _logger.d('Auto sync status: $isRunning');
    } catch (e) {
      _logger.w('Error checking auto sync status: $e');
    }
  }

  /// Network diagnostic dialog
  Future<void> _showNetworkDiagnostic() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            Icon(Icons.network_check, color: secondaryColor),
            SizedBox(width: 10),
            Text('Diagnóstico de Red'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            SizedBox(height: 20),
            Text('Verificando conexión con Paperless...'),
          ],
        ),
      ),
    );

    try {
      // Get Paperless URL
      final apiClient = PaperlessApiClient();
      final baseUrl = apiClient.baseUrl;

      // Run diagnostics
      final hasInternet = await ConnectivityService.hasInternetConnection();
      final serverCheck = await ConnectivityService.validatePaperlessConnection(baseUrl);

      // Close loading dialog
      Navigator.pop(context);

      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Row(
            children: [
              Icon(
                serverCheck['error'] == null ? Icons.check_circle : Icons.error,
                color: serverCheck['error'] == null ? successColor : errorColor,
              ),
              SizedBox(width: 10),
              Text('Diagnóstico de Red'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDiagnosticRow(
                  'Internet',
                  hasInternet ? 'Conectado' : 'Sin conexión',
                  hasInternet,
                ),
                Divider(),
                _buildDiagnosticRow(
                  'Servidor Paperless',
                  baseUrl,
                  null,
                ),
                Divider(),
                _buildDiagnosticRow(
                  'Servidor alcanzable',
                  (serverCheck['serverReachable'] as bool) ? 'Sí' : 'No',
                  serverCheck['serverReachable'] as bool?,
                ),
                Divider(),
                _buildDiagnosticRow(
                  'Latencia',
                  serverCheck['error'] == null
                      ? '${serverCheck['latencyMs']} ms'
                      : 'N/A',
                  serverCheck['error'] == null,
                ),
                if (serverCheck['error'] != null) ...[
                  Divider(),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: errorColor),
                        ),
                        SizedBox(height: 5),
                        Text(
                          serverCheck['error'].toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: TextStyle(color: secondaryColor)),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error al ejecutar diagnóstico: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDiagnosticRow(String label, String value, bool? isSuccess) {
    return Row(
      children: [
        if (isSuccess != null)
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isSuccess ? successColor : errorColor,
            size: 20,
          ),
        if (isSuccess != null) SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    askPermission();
    getMasterData();
    _checkAutoSyncStatus();

    // Quick Action related
    quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case 'Normal Scan':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDocument(
                quickScan: false,
                directoryOS: DirectoryOS(),
              ),
            ),
          ).whenComplete(() {
            homeRefresh();
          });
          break;
        case 'Quick Scan':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDocument(
                quickScan: true,
                directoryOS: DirectoryOS(),
              ),
            ),
          ).whenComplete(() {
            homeRefresh();
          });
          break;
        case 'Import from Gallery':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDocument(
                directoryOS: DirectoryOS(),
                quickScan: false,
                fromGallery: true,
              ),
            ),
          ).whenComplete(() {
            homeRefresh();
          });
          break;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'Normal Scan',
        localizedTitle: 'Normal Scan',
        icon: 'normal_scan',
      ),
      ShortcutItem(
        type: 'Quick Scan',
        localizedTitle: 'Quick Scan',
        icon: 'quick_scan',
      ),
      ShortcutItem(
        type: 'Import from Gallery',
        localizedTitle: 'Import from Gallery',
        icon: 'gallery_action',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          title: RichText(
            text: TextSpan(
              text: 'Lumara ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: 'Scan', style: TextStyle(color: secondaryColor))
              ],
            ),
          ),
          actions: [
            // ✅ FASE 1: Server Configuration Button
            Tooltip(
              message: 'Configurar servidor',
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white70,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                        const ServerConfigScreen(),
                    ),
                  );
                },
              ),
            ),
            // Network Diagnostic Button
            Tooltip(
              message: 'Diagnóstico de red',
              child: IconButton(
                icon: Icon(
                  Icons.network_check,
                  color: Colors.white70,
                  size: 24,
                ),
                onPressed: _showNetworkDiagnostic,
              ),
            ),
            // Auto Sync Toggle Button
            Tooltip(
              message: _autoSyncEnabled ? 'Desactivar sync automático' : 'Activar sync automático',
              child: IconButton(
                icon: Icon(
                  _autoSyncEnabled ? Icons.sync : Icons.sync_disabled,
                  color: _autoSyncEnabled ? successColor : Colors.grey,
                  size: 26,
                ),
                onPressed: _toggleAutoSync,
              ),
            ),
            // Clean Documents Button (v4.4.3)
            Tooltip(
              message: 'Limpiar documentos',
              child: IconButton(
                icon: Icon(
                  Icons.delete_sweep,
                  color: Colors.orange,
                  size: 26,
                ),
                onPressed: _cleanAllDocuments,
              ),
            ),
            // Manual Sync Button
            Tooltip(
              message: 'Sincronizar ahora',
              child: IconButton(
                icon: _isSyncing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: secondaryColor,
                        ),
                      )
                    : Icon(
                        Icons.cloud_upload_outlined,
                        color: secondaryColor,
                        size: 28,
                      ),
                onPressed: _isSyncing ? null : _handleManualSync,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        drawer: Container(
          width: size.width * 0.55,
          color: primaryColor,
          child: Column(
            children: <Widget>[
              Spacer(),
              Image.asset(
                'assets/scan_g.jpeg',
                scale: 6,
              ),
              Spacer(),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AboutScreen.route);
                },
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Instrucciones de Uso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GettingStartedScreen(
                        showSkip: false,
                      ),
                    ),
                  );
                },
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white24,
              ),
              Spacer(
                flex: 9,
              ),
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
                color: secondaryColor,
              ),
              Spacer(),
            ],
          ),
        ),
        body: RefreshIndicator(
          backgroundColor: primaryColor,
          color: secondaryColor,
          onRefresh: homeRefresh,
          child: Column(
            children: <Widget>[
              // Sync Status Indicator
              Consumer<UploadService>(
                builder: (context, uploadService, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    color: primaryColor,
                    child: Center(
                      child: SyncStatusIndicator(
                        statusStream: uploadService.syncStatusStream,
                        currentStatus: uploadService.currentStatus,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Text(
                  'Drag down to refresh',
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: getMasterData(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.fromSwatch()
                              .copyWith(secondary: primaryColor)),
                      child: ListView.builder(
                        itemCount: masterDirectories.length,
                        itemBuilder: (context, index) {
                          return FocusedMenuHolder(
                            onPressed: () => {},
                            menuWidth: size.width * 0.44,
                            child: ListTile(
                              leading: Image.file(
                                File(masterDirectories[index].firstImgPath!),
                                width: 50,
                                height: 50,
                              ),
                              title: Text(
                                masterDirectories[index].newName ??
                                    masterDirectories[index].dirName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Last Modified: ${masterDirectories[index].lastModified!.day}-${masterDirectories[index].lastModified!.month}-${masterDirectories[index].lastModified!.year}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  Text(
                                    '${masterDirectories[index].imageCount} ${(masterDirectories[index].imageCount == 1) ? 'image' : 'images'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_right,
                                size: 30,
                                color: secondaryColor,
                              ),
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewDocument(
                                      directoryOS: masterDirectories[index],
                                    ),
                                  ),
                                ).whenComplete(() {
                                  homeRefresh();
                                });
                              },
                            ),
                            menuItems: [
                              FocusedMenuItem(
                                title: Text(
                                  'Rename',
                                  style: TextStyle(color: Colors.black),
                                ),
                                trailingIcon: Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  bool isEmptyError = false;
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      String? fileName;
                                      return StatefulBuilder(
                                        builder: (BuildContext context,
                                            void Function(void Function())
                                                setState) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                            ),
                                            title: Text('Rename File'),
                                            content: TextField(
                                              controller: TextEditingController(
                                                text: fileName ??
                                                    masterDirectories[index]
                                                        .newName,
                                              ),
                                              onChanged: (value) {
                                                fileName = value;
                                              },
                                              cursorColor: secondaryColor,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: InputDecoration(
                                                prefixStyle: TextStyle(
                                                    color: Colors.white),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor),
                                                ),
                                                errorText: isEmptyError
                                                    ? 'Error! File name cannot be empty'
                                                    : null,
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  fileName = fileName!.trim();
                                                  fileName = fileName!
                                                      .replaceAll('/', '');
                                                  if (fileName!.isNotEmpty) {
                                                    masterDirectories[index]
                                                        .newName = fileName;
                                                    database.renameDirectory(
                                                        directory:
                                                            masterDirectories[
                                                                index]);
                                                    Navigator.pop(context);
                                                    homeRefresh();
                                                  } else {
                                                    setState(() {
                                                      isEmptyError = true;
                                                    });
                                                  }
                                                },
                                                child: Text(
                                                  'Save',
                                                  style: TextStyle(
                                                      color: secondaryColor),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ).whenComplete(() {
                                    setState(() {});
                                  });
                                },
                              ),
                              FocusedMenuItem(
                                title: Text('Delete'),
                                trailingIcon: Icon(Icons.delete),
                                backgroundColor: Colors.redAccent,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        title: Text('Delete'),
                                        content: Text(
                                            'Do you really want to delete file?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Directory(masterDirectories[index]
                                                      .dirPath!)
                                                  .deleteSync(recursive: true);
                                              database.deleteDirectory(
                                                  dirPath:
                                                      masterDirectories[index]
                                                          .dirPath!);
                                              Navigator.pop(context);
                                              homeRefresh();
                                            },
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                  color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ).whenComplete(() {
                                    setState(() {});
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // ✅ v6.4.6: FAB restaurado con opciones de captura
        // La selección de persona se hace desde Dashboard → Capturar Documento
        floatingActionButton: FAB(
          normalScanOnPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewDocument(
                  directoryOS: DirectoryOS(),
                  quickScan: false,
                ),
              ),
            ).whenComplete(() {
              homeRefresh();
            });
          },
          quickScanOnPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewDocument(
                  directoryOS: DirectoryOS(),
                  quickScan: true,
                ),
              ),
            ).whenComplete(() {
              homeRefresh();
            });
          },
          galleryOnPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewDocument(
                  directoryOS: DirectoryOS(),
                  quickScan: false,
                  fromGallery: true,
                ),
              ),
            ).whenComplete(() {
              homeRefresh();
            });
          },
        ),
      ),
    );
  }
}
