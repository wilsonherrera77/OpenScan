import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:lumara_scan/Utilities/Classes.dart';
import 'Utilities/constants.dart';
import 'screens/about_screen.dart';
import 'screens/getting_started_screen.dart';
import 'screens/home_screen.dart';
import 'screens/view_document.dart';
import 'screens/splash_screen.dart';

// Indigenous Communities Integration
import 'data/datasources/tejido_api_client.dart';
import 'data/datasources/census_data_source.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/census_repository.dart';
import 'data/repositories/document_repository.dart';
import 'data/repositories/assignment_repository.dart';
import 'data/local/database/app_database.dart';
import 'services/upload_service.dart';
import 'services/background_sync_service.dart';
import 'services/network_monitor.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/census_provider.dart';
import 'presentation/providers/assignment_provider.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/census/person_selection_screen.dart';
import 'presentation/document/upload_screen.dart';
import 'presentation/admin/admin_dashboard_screen.dart';
import 'presentation/digitizer/digitizer_dashboard_screen.dart';
import 'presentation/reviewer/reviewer_dashboard_screen.dart';
import 'presentation/viewer/viewer_dashboard_screen.dart';
import 'presentation/document/document_preview_screen.dart';
import 'presentation/assignment/assignment_list_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/reporting/dashboard_screen.dart';
import 'presentation/reporting/family_report_screen.dart';
import 'presentation/reporting/export_report_screen.dart';
import 'presentation/gap_analysis/gap_analysis_screen.dart';
import 'presentation/admin/admin_panel_screen.dart';
import 'core/monitoring/error_reporter.dart';
import 'core/config/production_config.dart';
import 'services/logging_service.dart'; // v6.3.4: LoggingService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // v6.3.4: Initialize LoggingService
  final loggingService = LoggingService();
  await loggingService.initialize(minLevel: LogLevel.INFO);
  loggingService.info(
    category: LogCategory.UI,
    message: "Lumara app started",
    context: {'version': '6.3.4'},
  );

  // Initialize foreground task communication port
  FlutterForegroundTask.initCommunicationPort();

  // Initialize error reporting (captures all errors)
  ErrorReporter.initialize();

  // Validate production configuration
  try {
    ProductionConfig.validateProductionConfig();
  } catch (e) {
    // Log config error but continue (will show warning in app)
    print('⚠️ Production config validation failed: $e');
  }

  // Initialize background sync service
  await BackgroundSyncService.initialize();

  // Initialize network monitor
  await NetworkMonitor().startMonitoring();

  // Initialize dependencies
  final database = AppDatabase();
  final apiClient = TejidoApiClient();
  final censusDataSource = CensusDataSource();

  // CRITICAL: Load auth from storage before creating services
  // This ensures uploads have valid authentication token
  await apiClient.loadAuthFromStorage();

  final authRepository = AuthRepository(apiClient);
  final censusRepository = CensusRepository(censusDataSource);
  final documentRepository = DocumentRepository(apiClient, database); // ⚡ FASE 2: Added database for caching
  final assignmentRepository = AssignmentRepository(apiClient.dio); // Multi-User: Assignment management
  final uploadService = UploadService(database, documentRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CensusProvider(censusRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AssignmentProvider(assignmentRepository),
        ),
        // Provide repositories and services for direct access
        Provider.value(value: authRepository),
        Provider.value(value: censusRepository),
        Provider.value(value: documentRepository),
        Provider.value(value: assignmentRepository),
        Provider.value(value: uploadService),
        Provider.value(value: database),
      ],
      child: Lumara(),
    ),
  );
}

class Lumara extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: primaryColor,
      statusBarBrightness: Brightness.light,
    ));
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          secondary: secondaryColor,
        ),
      ),
      home: const InitialRouteSelector(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        LoginScreen.route: (context) => const LoginScreen(),
        PersonSelectionScreen.route: (context) => const PersonSelectionScreen(),
        AssignmentListScreen.route: (context) => const AssignmentListScreen(),
        AdminDashboardScreen.route: (context) => const AdminDashboardScreen(),
        DigitizerDashboardScreen.route: (context) => const DigitizerDashboardScreen(),
        ReviewerDashboardScreen.route: (context) => const ReviewerDashboardScreen(),
        ViewerDashboardScreen.route: (context) => const ViewerDashboardScreen(),
        '/upload': (context) => const UploadScreen(),
        SplashScreen.route: (context) => SplashScreen(),
        GettingStartedScreen.route: (context) => GettingStartedScreen(),
        HomeScreen.route: (context) => HomeScreen(),
        // ViewDocument.route: (context) => ViewDocument(directoryOS: DirectoryOS()), // TODO: Restore original Lumara functionality
        AboutScreen.route: (context) => AboutScreen(),
        // Sprint 4: Advanced Features (temporarily disabled for APK build)
        // DashboardScreen.route: (context) => const DashboardScreen(),
        // FamilyReportScreen.route: (context) => const FamilyReportScreen(),
        // ExportReportScreen.route: (context) => const ExportReportScreen(),
        // GapAnalysisScreen.route: (context) => const GapAnalysisScreen(),
        // AdminPanelScreen.route: (context) => const AdminPanelScreen(),
      },
    );
  }
}

/// Initial Route Selector
/// Determines which screen to show first (onboarding vs login)
class InitialRouteSelector extends StatefulWidget {
  const InitialRouteSelector({super.key});

  @override
  State<InitialRouteSelector> createState() => _InitialRouteSelectorState();
}

class _InitialRouteSelectorState extends State<InitialRouteSelector> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;

    if (!onboardingCompleted) {
      // Show onboarding first
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    // Check if user is already authenticated
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      // Already logged in, go directly to person selection
      Navigator.pushReplacementNamed(context, PersonSelectionScreen.route);
    } else {
      // Not logged in, show login screen
      Navigator.pushReplacementNamed(context, LoginScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
