import 'package:dio/dio.dart';
import '../../services/logger_adapter.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/digitization_session.dart';
import '../../domain/entities/document_review.dart';

/// Assignment Repository
/// Handles API calls for assignments, productivity, and team statistics
class AssignmentRepository {
  final Dio _dio;
  final LoggerAdapter _logger = LoggerAdapter();

  AssignmentRepository(this._dio);

  /// Get current user's profile
  Future<UserProfile> getMyProfile() async {
    try {
      _logger.i('📥 Fetching user profile');

      final response = await _dio.get('/api/auth/me/');

      if (response.statusCode == 200) {
        _logger.i('✅ Profile fetched successfully');
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch profile', error: e);
      rethrow;
    }
  }

  /// Get my assignments
  Future<List<PersonAssignment>> getMyAssignments({String? status}) async {
    try {
      _logger.i('📥 Fetching my assignments (status: $status)');

      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/api/auth/my-assignments/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final assignments = data.map((json) => PersonAssignment.fromJson(json)).toList();

        _logger.i('✅ Fetched ${assignments.length} assignments');
        return assignments;
      } else {
        throw Exception('Failed to fetch assignments: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch assignments', error: e);
      rethrow;
    }
  }

  /// Get all assignments (admin only)
  Future<List<PersonAssignment>> getAllAssignments({
    String? status,
    int? digitizerId,
  }) async {
    try {
      _logger.i('📥 Fetching all assignments');

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (digitizerId != null) queryParams['digitizer_id'] = digitizerId;

      final response = await _dio.get(
        '/api/auth/assignments/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final assignments = data.map((json) => PersonAssignment.fromJson(json)).toList();

        _logger.i('✅ Fetched ${assignments.length} assignments');
        return assignments;
      } else {
        throw Exception('Failed to fetch assignments: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch assignments', error: e);
      rethrow;
    }
  }

  /// Create bulk assignments (admin only)
  Future<List<PersonAssignment>> createBulkAssignments({
    required int digitizerId,
    required List<String> personIds,
    int requiredDocuments = 5,
  }) async {
    try {
      _logger.i('📤 Creating bulk assignments for ${personIds.length} persons');

      final response = await _dio.post(
        '/api/auth/assignments/bulk_create/',
        data: {
          'digitizer_id': digitizerId,
          'person_ids': personIds,
          'required_documents': requiredDocuments,
        },
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data['assignments'];
        final assignments = data.map((json) => PersonAssignment.fromJson(json)).toList();

        _logger.i('✅ Created ${assignments.length} assignments');
        return assignments;
      } else {
        throw Exception('Failed to create assignments: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to create assignments', error: e);
      rethrow;
    }
  }

  /// Mark assignment as started
  Future<PersonAssignment> markAssignmentStarted(int assignmentId) async {
    try {
      _logger.i('📝 Marking assignment $assignmentId as started');

      final response = await _dio.post(
        '/api/auth/assignments/$assignmentId/mark_started/',
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Assignment marked as started');
        return PersonAssignment.fromJson(response.data);
      } else {
        throw Exception('Failed to mark started: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to mark assignment started', error: e);
      rethrow;
    }
  }

  /// Mark assignment as completed
  Future<PersonAssignment> markAssignmentCompleted(int assignmentId) async {
    try {
      _logger.i('📝 Marking assignment $assignmentId as completed');

      final response = await _dio.post(
        '/api/auth/assignments/$assignmentId/mark_completed/',
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Assignment marked as completed');
        return PersonAssignment.fromJson(response.data);
      } else {
        throw Exception('Failed to mark completed: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to mark assignment completed', error: e);
      rethrow;
    }
  }

  /// Get my productivity metrics
  Future<ProductivityMetrics> getMyProductivity({String period = 'week'}) async {
    try {
      _logger.i('📊 Fetching productivity metrics (period: $period)');

      final response = await _dio.get(
        '/api/auth/my-productivity/',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Productivity metrics fetched');
        return ProductivityMetrics.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch productivity: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch productivity', error: e);
      rethrow;
    }
  }

  /// Get team statistics (admin only)
  Future<TeamStatistics> getTeamStatistics() async {
    try {
      _logger.i('📊 Fetching team statistics');

      final response = await _dio.get('/api/auth/team-statistics/');

      if (response.statusCode == 200) {
        _logger.i('✅ Team statistics fetched');
        return TeamStatistics.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch team stats: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch team statistics', error: e);
      rethrow;
    }
  }

  /// Log digitization event
  Future<void> logDigitization({
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
      _logger.i('📝 Logging digitization event');

      await _dio.post(
        '/api/auth/logs/log_digitization/',
        data: {
          'document_id': documentId,
          'document_type': documentType,
          'person_id': personId,
          'person_name': personName,
          'image_quality_score': imageQualityScore,
          'ocr_used': ocrUsed,
          'ocr_method': ocrMethod,
          'ocr_confidence': ocrConfidence,
          'is_replacement': isReplacement,
          'replaced_document_id': replacedDocumentId,
        },
      );

      _logger.i('✅ Digitization logged successfully');
    } catch (e) {
      _logger.e('❌ Failed to log digitization', error: e);
      rethrow;
    }
  }

  /// Get all digitizers (for admin assignment creation)
  Future<List<UserProfile>> getDigitizers() async {
    try {
      _logger.i('📥 Fetching digitizers');

      final response = await _dio.get('/api/auth/profiles/digitizers/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final digitizers = data.map((json) => UserProfile.fromJson(json)).toList();

        _logger.i('✅ Fetched ${digitizers.length} digitizers');
        return digitizers;
      } else {
        throw Exception('Failed to fetch digitizers: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch digitizers', error: e);
      rethrow;
    }
  }

  // ============================================================================
  // SESSION TRACKING ENDPOINTS (H2)
  // ============================================================================

  /// Start a new digitization session
  Future<Map<String, dynamic>> startSession({int? assignmentId}) async {
    try {
      _logger.i('🎬 Starting digitization session');

      final response = await _dio.post(
        '/api/auth/start-session/',
        data: {
          if (assignmentId != null) 'assignment_id': assignmentId,
        },
      );

      if (response.statusCode == 201) {
        _logger.i('✅ Session started: ${response.data['session_id']}');
        return response.data;
      } else {
        throw Exception('Failed to start session: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to start session', error: e);
      rethrow;
    }
  }

  /// End current digitization session
  Future<Map<String, dynamic>> endSession({int? sessionId}) async {
    try {
      _logger.i('🏁 Ending digitization session');

      final response = await _dio.post(
        '/api/auth/end-session/',
        data: {
          if (sessionId != null) 'session_id': sessionId,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Session ended successfully');
        return response.data;
      } else {
        throw Exception('Failed to end session: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to end session', error: e);
      rethrow;
    }
  }

  /// Increment document count in current session
  Future<void> incrementSessionDocuments({int? sessionId}) async {
    try {
      _logger.d('➕ Incrementing session document count');

      await _dio.post(
        '/api/auth/increment-session-documents/',
        data: {
          if (sessionId != null) 'session_id': sessionId,
        },
      );

      _logger.d('✅ Session document count incremented');
    } catch (e) {
      _logger.e('❌ Failed to increment session documents', error: e);
      rethrow;
    }
  }

  /// Get my digitization sessions
  Future<List<Map<String, dynamic>>> getMySessions({
    String? period,
    bool? activeOnly,
  }) async {
    try {
      _logger.i('📥 Fetching my sessions');

      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (activeOnly != null) queryParams['active_only'] = activeOnly;

      final response = await _dio.get(
        '/api/auth/my-sessions/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _logger.i('✅ Fetched ${data.length} sessions');
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch sessions: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch sessions', error: e);
      rethrow;
    }
  }

  // ============================================================================
  // REVIEW ENDPOINTS (H3)
  // ============================================================================

  /// Approve an assignment (reviewer only)
  Future<Map<String, dynamic>> approveAssignment({
    required int assignmentId,
    int? qualityScore,
    String? feedback,
  }) async {
    try {
      _logger.i('✅ Approving assignment $assignmentId');

      final response = await _dio.post(
        '/api/auth/assignments/$assignmentId/approve/',
        data: {
          if (qualityScore != null) 'quality_score': qualityScore,
          if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Assignment approved successfully');
        return response.data;
      } else {
        throw Exception('Failed to approve assignment: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to approve assignment', error: e);
      rethrow;
    }
  }

  /// Reject an assignment (reviewer only)
  Future<Map<String, dynamic>> rejectAssignment({
    required int assignmentId,
    required String feedback,
    String? issuesFound,
  }) async {
    try {
      _logger.i('❌ Rejecting assignment $assignmentId');

      final response = await _dio.post(
        '/api/auth/assignments/$assignmentId/reject/',
        data: {
          'feedback': feedback,
          if (issuesFound != null && issuesFound.isNotEmpty) 'issues_found': issuesFound,
        },
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Assignment rejected successfully');
        return response.data;
      } else {
        throw Exception('Failed to reject assignment: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to reject assignment', error: e);
      rethrow;
    }
  }

  /// Get review for an assignment
  Future<Map<String, dynamic>?> getAssignmentReview(int assignmentId) async {
    try {
      _logger.i('📥 Fetching review for assignment $assignmentId');

      final response = await _dio.get(
        '/api/auth/assignments/$assignmentId/review/',
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Review fetched successfully');
        return response.data;
      } else if (response.statusCode == 404) {
        // No review exists yet
        return null;
      } else {
        throw Exception('Failed to fetch review: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch review', error: e);
      rethrow;
    }
  }

  // ============================================================================
  // EXPORT ENDPOINTS (H4)
  // ============================================================================

  /// Export assignments to CSV (viewer/admin only)
  Future<String> exportAssignmentsCSV({String? status}) async {
    try {
      _logger.i('📊 Exporting assignments to CSV');

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/api/auth/export-assignments-csv/',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Assignments CSV exported successfully');
        return response.data as String;
      } else {
        throw Exception('Failed to export assignments: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to export assignments CSV', error: e);
      rethrow;
    }
  }

  /// Export productivity data to CSV (viewer/admin only)
  Future<String> exportProductivityCSV({
    String? period,
    int? userId,
  }) async {
    try {
      _logger.i('📊 Exporting productivity to CSV');

      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (userId != null) queryParams['user_id'] = userId;

      final response = await _dio.get(
        '/api/auth/export-productivity-csv/',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Productivity CSV exported successfully');
        return response.data as String;
      } else {
        throw Exception('Failed to export productivity: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to export productivity CSV', error: e);
      rethrow;
    }
  }

  /// Export team summary to CSV (viewer/admin only)
  Future<String> exportTeamSummaryCSV() async {
    try {
      _logger.i('📊 Exporting team summary to CSV');

      final response = await _dio.get(
        '/api/auth/export-team-summary-csv/',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Team summary CSV exported successfully');
        return response.data as String;
      } else {
        throw Exception('Failed to export team summary: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to export team summary CSV', error: e);
      rethrow;
    }
  }

  // ============================================================================
  // PAGINATION SUPPORT (M5)
  // ============================================================================

  /// Get assignments with pagination
  Future<Map<String, dynamic>> getAssignmentsPaginated({
    int page = 1,
    int pageSize = 50,
    String? status,
    int? digitizerId,
  }) async {
    try {
      _logger.i('📥 Fetching assignments page $page (size: $pageSize)');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (status != null) queryParams['status'] = status;
      if (digitizerId != null) queryParams['digitizer_id'] = digitizerId;

      final response = await _dio.get(
        '/api/auth/assignments/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Fetched page $page successfully');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch assignments: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('❌ Failed to fetch paginated assignments', error: e);
      rethrow;
    }
  }
}
