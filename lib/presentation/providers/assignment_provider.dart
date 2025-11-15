import 'package:flutter/foundation.dart';
import '../../services/logger_adapter.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/user_profile.dart';

/// Assignment Provider
/// Manages assignment state and multi-user functionality using Provider pattern
class AssignmentProvider with ChangeNotifier {
  final AssignmentRepository _assignmentRepository;
  final LoggerAdapter _logger = LoggerAdapter();

  // State variables
  UserProfile? _currentUserProfile;
  List<PersonAssignment> _myAssignments = [];
  List<PersonAssignment> _allAssignments = [];
  ProductivityMetrics? _myProductivity;
  TeamStatistics? _teamStatistics;
  List<UserProfile> _digitizers = [];

  // Session tracking state (H2)
  int? _currentSessionId;
  List<Map<String, dynamic>> _mySessions = [];
  bool _isLoadingSessions = false;

  // Review state (H3)
  Map<int, Map<String, dynamic>> _assignmentReviews = {}; // assignment_id -> review data
  bool _isLoadingReviews = false;

  bool _isLoading = false;
  bool _isLoadingAssignments = false;
  bool _isLoadingProductivity = false;
  bool _isLoadingTeamStats = false;
  String? _error;

  AssignmentProvider(this._assignmentRepository);

  // Getters
  UserProfile? get currentUserProfile => _currentUserProfile;
  List<PersonAssignment> get myAssignments => _myAssignments;
  List<PersonAssignment> get allAssignments => _allAssignments;
  ProductivityMetrics? get myProductivity => _myProductivity;
  TeamStatistics? get teamStatistics => _teamStatistics;
  List<UserProfile> get digitizers => _digitizers;

  // Session tracking getters
  int? get currentSessionId => _currentSessionId;
  List<Map<String, dynamic>> get mySessions => _mySessions;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get hasActiveSession => _currentSessionId != null;

  // Review getters
  Map<int, Map<String, dynamic>> get assignmentReviews => _assignmentReviews;
  bool get isLoadingReviews => _isLoadingReviews;

  bool get isLoading => _isLoading;
  bool get isLoadingAssignments => _isLoadingAssignments;
  bool get isLoadingProductivity => _isLoadingProductivity;
  bool get isLoadingTeamStats => _isLoadingTeamStats;
  String? get error => _error;

  // User role helpers
  bool get isAdmin => _currentUserProfile?.isAdmin ?? false;
  bool get isDigitizer => _currentUserProfile?.isDigitizer ?? false;
  bool get canDigitize => _currentUserProfile?.canDigitize ?? false;
  bool get canManageAssignments => _currentUserProfile?.canManageAssignments ?? false;

  /// Load current user's profile
  Future<bool> loadUserProfile() async {
    _setLoading(true);
    _clearError();

    try {
      _logger.i('👤 Loading user profile');

      _currentUserProfile = await _assignmentRepository.getMyProfile();

      _logger.i('✅ User profile loaded: ${_currentUserProfile?.username} (${_currentUserProfile?.role.label})');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load user profile', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load my assignments
  Future<bool> loadMyAssignments({String? status}) async {
    _isLoadingAssignments = true;
    _clearError();
    notifyListeners();

    try {
      _logger.i('📥 Loading my assignments (status: $status)');

      _myAssignments = await _assignmentRepository.getMyAssignments(status: status);

      _logger.i('✅ Loaded ${_myAssignments.length} assignments');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load assignments', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }

  /// Load all assignments (admin only)
  Future<bool> loadAllAssignments({
    String? status,
    int? digitizerId,
  }) async {
    if (!isAdmin) {
      _logger.w('⚠️ Non-admin user attempted to load all assignments');
      return false;
    }

    _isLoadingAssignments = true;
    _clearError();
    notifyListeners();

    try {
      _logger.i('📥 Loading all assignments (admin)');

      _allAssignments = await _assignmentRepository.getAllAssignments(
        status: status,
        digitizerId: digitizerId,
      );

      _logger.i('✅ Loaded ${_allAssignments.length} assignments');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load all assignments', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }

  /// Create bulk assignments (admin only)
  Future<bool> createBulkAssignments({
    required int digitizerId,
    required List<String> personIds,
    int requiredDocuments = 5,
  }) async {
    if (!canManageAssignments) {
      _logger.w('⚠️ User without permissions attempted to create assignments');
      _setError('No tienes permisos para crear asignaciones');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _logger.i('📤 Creating ${personIds.length} assignments');

      final newAssignments = await _assignmentRepository.createBulkAssignments(
        digitizerId: digitizerId,
        personIds: personIds,
        requiredDocuments: requiredDocuments,
      );

      _logger.i('✅ Created ${newAssignments.length} assignments');

      // Refresh assignments list
      await loadAllAssignments();

      return true;
    } catch (e) {
      _logger.e('❌ Failed to create assignments', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark assignment as started
  Future<bool> markAssignmentStarted(int assignmentId) async {
    _setLoading(true);
    _clearError();

    try {
      _logger.i('📝 Marking assignment $assignmentId as started');

      final updatedAssignment = await _assignmentRepository.markAssignmentStarted(assignmentId);

      // Update local state
      _updateAssignmentInList(updatedAssignment);

      _logger.i('✅ Assignment marked as started');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to mark assignment started', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mark assignment as completed
  Future<bool> markAssignmentCompleted(int assignmentId) async {
    _setLoading(true);
    _clearError();

    try {
      _logger.i('📝 Marking assignment $assignmentId as completed');

      final updatedAssignment = await _assignmentRepository.markAssignmentCompleted(assignmentId);

      // Update local state
      _updateAssignmentInList(updatedAssignment);

      _logger.i('✅ Assignment marked as completed');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to mark assignment completed', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load my productivity metrics
  Future<bool> loadMyProductivity({String period = 'week'}) async {
    _isLoadingProductivity = true;
    _clearError();
    notifyListeners();

    try {
      _logger.i('📊 Loading productivity metrics (period: $period)');

      _myProductivity = await _assignmentRepository.getMyProductivity(period: period);

      _logger.i('✅ Productivity metrics loaded: ${_myProductivity?.totalDocuments} docs');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load productivity', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _isLoadingProductivity = false;
      notifyListeners();
    }
  }

  /// Load team statistics (admin only)
  Future<bool> loadTeamStatistics() async {
    if (!isAdmin) {
      _logger.w('⚠️ Non-admin user attempted to load team statistics');
      return false;
    }

    _isLoadingTeamStats = true;
    _clearError();
    notifyListeners();

    try {
      _logger.i('📊 Loading team statistics (admin)');

      _teamStatistics = await _assignmentRepository.getTeamStatistics();

      _logger.i('✅ Team statistics loaded: ${_teamStatistics?.totalDigitizers} digitizers');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load team statistics', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _isLoadingTeamStats = false;
      notifyListeners();
    }
  }

  /// Log digitization event
  Future<bool> logDigitization({
    required int documentId,
    required String documentType,
    required String personId,
    required String personName,
    int? imageQualityScore,
    bool ocrUsed = false,
    String ocrMethod = 'NONE',
    int? ocrConfidence,
    bool isReplacement = false,
    int? replacedDocumentId,
  }) async {
    try {
      _logger.i('📝 Logging digitization for person $personId');

      await _assignmentRepository.logDigitization(
        documentId: documentId,
        documentType: documentType,
        personId: personId,
        personName: personName,
        imageQualityScore: imageQualityScore,
        ocrUsed: ocrUsed,
        ocrMethod: ocrMethod,
        ocrConfidence: ocrConfidence,
        isReplacement: isReplacement,
        replacedDocumentId: replacedDocumentId,
      );

      _logger.i('✅ Digitization logged successfully');

      // Refresh assignments to update progress
      if (isDigitizer) {
        await loadMyAssignments();
      }

      return true;
    } catch (e) {
      _logger.e('❌ Failed to log digitization', error: e);
      // Don't set error here - logging failures shouldn't block workflow
      return false;
    }
  }

  /// Load digitizers list (admin only)
  Future<bool> loadDigitizers() async {
    if (!canManageAssignments) {
      _logger.w('⚠️ User without permissions attempted to load digitizers');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _logger.i('📥 Loading digitizers list');

      _digitizers = await _assignmentRepository.getDigitizers();

      _logger.i('✅ Loaded ${_digitizers.length} digitizers');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load digitizers', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await loadUserProfile();

    if (isDigitizer) {
      await loadMyAssignments();
      await loadMyProductivity();
    }

    if (isAdmin) {
      await loadAllAssignments();
      await loadTeamStatistics();
      await loadDigitizers();
    }
  }

  // ============================================================================
  // SESSION TRACKING METHODS (H2)
  // ============================================================================

  /// Start a new digitization session
  Future<bool> startDigitizationSession({int? assignmentId}) async {
    try {
      _logger.i('🎬 Starting digitization session');

      final response = await _assignmentRepository.startSession(
        assignmentId: assignmentId,
      );

      _currentSessionId = response['session_id'] as int?;

      _logger.i('✅ Session started: $_currentSessionId');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to start session', error: e);
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  /// End current digitization session
  Future<bool> endDigitizationSession() async {
    try {
      _logger.i('🏁 Ending digitization session');

      await _assignmentRepository.endSession(sessionId: _currentSessionId);

      _currentSessionId = null;

      _logger.i('✅ Session ended successfully');

      // Refresh productivity metrics
      await loadMyProductivity();

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to end session', error: e);
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  /// Increment document count in current session
  Future<void> incrementSessionDocuments() async {
    if (_currentSessionId == null) {
      _logger.w('⚠️ No active session to increment');
      return;
    }

    try {
      await _assignmentRepository.incrementSessionDocuments(
        sessionId: _currentSessionId,
      );
      _logger.d('✅ Session document count incremented');
    } catch (e) {
      _logger.e('❌ Failed to increment session documents', error: e);
      // Don't throw - this shouldn't block digitization workflow
    }
  }

  /// Load my digitization sessions
  Future<bool> loadMySessions({String? period, bool? activeOnly}) async {
    _isLoadingSessions = true;
    _clearError();
    notifyListeners();

    try {
      _logger.i('📥 Loading my sessions');

      _mySessions = await _assignmentRepository.getMySessions(
        period: period,
        activeOnly: activeOnly,
      );

      _logger.i('✅ Loaded ${_mySessions.length} sessions');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to load sessions', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // REVIEW METHODS (H3)
  // ============================================================================

  /// Approve an assignment (reviewer only)
  Future<bool> approveAssignment({
    required int assignmentId,
    int? qualityScore,
    String? feedback,
  }) async {
    if (!(_currentUserProfile?.canReview ?? false)) {
      _logger.w('⚠️ User without permissions attempted to approve assignment');
      _setError('No tienes permisos para aprobar asignaciones');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _logger.i('✅ Approving assignment $assignmentId');

      final response = await _assignmentRepository.approveAssignment(
        assignmentId: assignmentId,
        qualityScore: qualityScore,
        feedback: feedback,
      );

      // Store review data
      _assignmentReviews[assignmentId] = response['review'];

      // Update assignment in lists if present
      final updatedAssignment = response['assignment'];
      if (updatedAssignment != null) {
        // You might want to parse this back to PersonAssignment
        // For now just refresh the lists
        await loadAllAssignments();
      }

      _logger.i('✅ Assignment approved successfully');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to approve assignment', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reject an assignment (reviewer only)
  Future<bool> rejectAssignment({
    required int assignmentId,
    required String feedback,
    String? issuesFound,
  }) async {
    if (!(_currentUserProfile?.canReview ?? false)) {
      _logger.w('⚠️ User without permissions attempted to reject assignment');
      _setError('No tienes permisos para rechazar asignaciones');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _logger.i('❌ Rejecting assignment $assignmentId');

      final response = await _assignmentRepository.rejectAssignment(
        assignmentId: assignmentId,
        feedback: feedback,
        issuesFound: issuesFound,
      );

      // Store review data
      _assignmentReviews[assignmentId] = response['review'];

      // Refresh assignments
      await loadAllAssignments();

      _logger.i('✅ Assignment rejected successfully');

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('❌ Failed to reject assignment', error: e);
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load review for an assignment
  Future<Map<String, dynamic>?> loadAssignmentReview(int assignmentId) async {
    try {
      _logger.i('📥 Loading review for assignment $assignmentId');

      final review = await _assignmentRepository.getAssignmentReview(assignmentId);

      if (review != null) {
        _assignmentReviews[assignmentId] = review;
        notifyListeners();
      }

      return review;
    } catch (e) {
      _logger.e('❌ Failed to load review', error: e);
      return null;
    }
  }

  /// Update assignment in local lists
  void _updateAssignmentInList(PersonAssignment updatedAssignment) {
    // Update in myAssignments
    final myIndex = _myAssignments.indexWhere((a) => a.id == updatedAssignment.id);
    if (myIndex != -1) {
      _myAssignments[myIndex] = updatedAssignment;
    }

    // Update in allAssignments
    final allIndex = _allAssignments.indexWhere((a) => a.id == updatedAssignment.id);
    if (allIndex != -1) {
      _allAssignments[allIndex] = updatedAssignment;
    }
  }

  /// Clear all state (on logout)
  void clear() {
    _currentUserProfile = null;
    _myAssignments = [];
    _allAssignments = [];
    _myProductivity = null;
    _teamStatistics = null;
    _digitizers = [];
    _currentSessionId = null;
    _mySessions = [];
    _assignmentReviews = {};
    _error = null;
    _isLoading = false;
    _isLoadingAssignments = false;
    _isLoadingProductivity = false;
    _isLoadingTeamStats = false;
    _isLoadingSessions = false;
    _isLoadingReviews = false;
    notifyListeners();
  }

  // Helper methods

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
  }

  /// Extract error message from exception
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No se puede conectar con el servidor. Verifica tu conexión.';
    } else if (error.toString().contains('401')) {
      return 'No autorizado. Inicia sesión nuevamente.';
    } else if (error.toString().contains('403')) {
      return 'No tienes permisos para realizar esta acción.';
    } else if (error.toString().contains('404')) {
      return 'Recurso no encontrado.';
    } else if (error.toString().contains('500')) {
      return 'Error en el servidor. Intenta más tarde.';
    } else {
      return 'Error: ${error.toString()}';
    }
  }
}
