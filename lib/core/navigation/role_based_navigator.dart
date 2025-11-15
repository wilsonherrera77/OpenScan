import 'package:flutter/material.dart';
import '../../services/logger_adapter.dart';
import '../../domain/entities/user_profile.dart';
import '../../presentation/providers/assignment_provider.dart';
import '../../presentation/census/person_selection_screen.dart';
import '../../presentation/admin/admin_dashboard_screen.dart';
import '../../presentation/digitizer/digitizer_dashboard_screen.dart';
import '../../presentation/reviewer/reviewer_dashboard_screen.dart';
import '../../presentation/viewer/viewer_dashboard_screen.dart';

/// Role-Based Navigator
/// Handles navigation after login based on user role
class RoleBasedNavigator {
  static final LoggerAdapter _logger = LoggerAdapter();

  /// Navigate to appropriate screen based on user role
  ///
  /// Loads user profile and routes to:
  /// - ADMIN → Admin Dashboard with team management
  /// - DIGITALIZADOR → Digitizer Dashboard with personal assignments
  /// - REVISOR → Reviewer Dashboard with quality review queue
  /// - VIEWER → Viewer Dashboard with read-only reports and analytics
  static Future<void> navigateAfterLogin(
    BuildContext context,
    AssignmentProvider assignmentProvider,
  ) async {
    try {
      _logger.i('🧭 Loading user profile for role-based navigation');

      // Load user profile to get role
      final success = await assignmentProvider.loadUserProfile();

      if (!success || assignmentProvider.currentUserProfile == null) {
        _logger.e('❌ Failed to load user profile');
        _showErrorAndNavigateDefault(
          context,
          'No se pudo cargar el perfil de usuario',
        );
        return;
      }

      final userProfile = assignmentProvider.currentUserProfile!;
      _logger.i('✅ User profile loaded: ${userProfile.username} (${userProfile.role.label})');

      // Navigate based on role
      switch (userProfile.role) {
        case UserRole.admin:
          _navigateToAdminDashboard(context, assignmentProvider);
          break;

        case UserRole.digitalizador:
          _navigateToDigitizadorDashboard(context, assignmentProvider);
          break;

        case UserRole.revisor:
          _navigateToRevisorDashboard(context, assignmentProvider);
          break;

        case UserRole.viewer:
          _navigateToViewerDashboard(context, assignmentProvider);
          break;
      }
    } catch (e) {
      _logger.e('❌ Navigation error', error: e);
      _showErrorAndNavigateDefault(
        context,
        'Error al navegar: ${e.toString()}',
      );
    }
  }

  /// Navigate to Admin Dashboard
  static Future<void> _navigateToAdminDashboard(
    BuildContext context,
    AssignmentProvider assignmentProvider,
  ) async {
    _logger.i('🔄 Navigating to Admin Dashboard');

    // Load admin data
    await Future.wait([
      assignmentProvider.loadAllAssignments(),
      assignmentProvider.loadTeamStatistics(),
      assignmentProvider.loadDigitizers(),
    ]);

    if (!context.mounted) return;

    // Navigate to Admin Dashboard
    _logger.i('✅ Navigating to AdminDashboardScreen');
    Navigator.of(context).pushReplacementNamed(AdminDashboardScreen.route);

    // Show welcome message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '👋 Bienvenido, ${assignmentProvider.currentUserProfile?.username} (Administrador)',
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Navigate to Digitalizador Dashboard
  static Future<void> _navigateToDigitizadorDashboard(
    BuildContext context,
    AssignmentProvider assignmentProvider,
  ) async {
    _logger.i('🔄 Navigating to Digitalizador Dashboard');

    // Load digitizer data
    await Future.wait([
      assignmentProvider.loadMyAssignments(),
      assignmentProvider.loadMyProductivity(),
    ]);

    if (!context.mounted) return;

    // Navigate to Digitizer Dashboard
    _logger.i('✅ Navigating to DigitizerDashboardScreen');
    Navigator.of(context).pushReplacementNamed(DigitizerDashboardScreen.route);

    // Show welcome message with assignment count
    final assignmentCount = assignmentProvider.myAssignments.length;
    final pendingCount = assignmentProvider.myAssignments
        .where((a) => a.isPending || a.isInProgress)
        .length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '👋 Bienvenido, ${assignmentProvider.currentUserProfile?.username}\n'
          'Tienes $pendingCount asignaciones pendientes de $assignmentCount totales',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Navigate to Revisor Dashboard
  static Future<void> _navigateToRevisorDashboard(
    BuildContext context,
    AssignmentProvider assignmentProvider,
  ) async {
    _logger.i('🔄 Navigating to Revisor Dashboard');

    // Load reviewer data (assignments to review)
    await assignmentProvider.loadAllAssignments();

    if (!context.mounted) return;

    // Navigate to Reviewer Dashboard
    _logger.i('✅ Navigating to ReviewerDashboardScreen');
    Navigator.of(context).pushReplacementNamed(ReviewerDashboardScreen.route);

    // Show welcome message with pending review count
    final pendingReview = assignmentProvider.allAssignments
        .where((a) => a.isCompleted)
        .length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '👋 Bienvenido, ${assignmentProvider.currentUserProfile?.username} (Revisor)\n'
          'Tienes $pendingReview asignaciones para revisar',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Navigate to Viewer Dashboard
  static Future<void> _navigateToViewerDashboard(
    BuildContext context,
    AssignmentProvider assignmentProvider,
  ) async {
    _logger.i('🔄 Navigating to Viewer Dashboard');

    // Load viewer data (read-only statistics)
    await Future.wait([
      assignmentProvider.loadAllAssignments(),
      assignmentProvider.loadTeamStatistics(),
      assignmentProvider.loadDigitizers(),
    ]);

    if (!context.mounted) return;

    // Navigate to Viewer Dashboard
    _logger.i('✅ Navigating to ViewerDashboardScreen');
    Navigator.of(context).pushReplacementNamed(ViewerDashboardScreen.route);

    // Show welcome message with system overview
    final totalAssignments = assignmentProvider.allAssignments.length;
    final completedAssignments = assignmentProvider.allAssignments
        .where((a) => a.isCompleted)
        .length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '👋 Bienvenido, ${assignmentProvider.currentUserProfile?.username} (Visualizador)\n'
          'Sistema: $completedAssignments/$totalAssignments asignaciones completadas',
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show error and navigate to default screen
  static void _showErrorAndNavigateDefault(
    BuildContext context,
    String errorMessage,
  ) {
    _logger.w('⚠️ Navigating to default screen due to error');

    if (!context.mounted) return;

    // Navigate to default screen
    Navigator.of(context).pushReplacementNamed(PersonSelectionScreen.route);

    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get icon for user role
  static IconData getIconForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.digitalizador:
        return Icons.document_scanner;
      case UserRole.revisor:
        return Icons.fact_check;
      case UserRole.viewer:
        return Icons.visibility;
    }
  }

  /// Get color for user role
  static Color getColorForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.blue;
      case UserRole.digitalizador:
        return Colors.green;
      case UserRole.revisor:
        return Colors.orange;
      case UserRole.viewer:
        return Colors.purple;
    }
  }
}
