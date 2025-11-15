import '../services/logger_adapter.dart';
import '../data/local/database/app_database.dart';
import '../domain/entities/person.dart';

/// Reporting Service
///
/// Generates comprehensive reports and analytics for document digitization progress
///
/// Features:
/// - Overall progress statistics
/// - Family-level reports
/// - Community-level reports
/// - Document type distribution
/// - Time-based trends
/// - Export to PDF/Excel
class ReportingService {
  final AppDatabase _database;
  final LoggerAdapter _logger = LoggerAdapter();

  ReportingService(this._database);

  /// Get overall digitization statistics
  Future<OverallStatistics> getOverallStatistics() async {
    try {
      _logger.i('📊 Generating overall statistics...');

      // Query completed uploads from history
      final completedUploads = await _database.getUploadHistory(limit: 10000);
      final pendingUploads = await _database.getPendingUploads();
      final failedUploads = await _database.getFailedUploads();

      // Calculate totals
      final totalDocuments = completedUploads.length;
      final pendingDocuments = pendingUploads.length;
      final failedDocuments = failedUploads.length;
      final totalSize = completedUploads.fold<int>(0, (sum, u) => sum + u.fileSize);

      // Calculate unique persons
      final uniquePersons = completedUploads.map((u) => u.personId).toSet().length;

      // Calculate unique families - extract from personId (format: FAMILY-XXX-PERSON-YYY)
      final uniqueFamilies = completedUploads
          .map((u) => u.personId.split('-').take(2).join('-'))
          .toSet()
          .length;

      // Calculate average processing time
      final processingTimes = completedUploads
          .where((u) => u.uploadDurationMs > 0)
          .map((u) => u.uploadDurationMs ~/ 1000) // Convert to seconds
          .toList();

      final avgProcessingTime = processingTimes.isNotEmpty
          ? processingTimes.reduce((a, b) => a + b) / processingTimes.length
          : 0.0;

      // Calculate success rate
      final totalAttempts = totalDocuments + pendingDocuments + failedDocuments;
      final successRate = totalAttempts > 0 ? (totalDocuments / totalAttempts) * 100 : 0.0;

      // Recent activity (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentUploads = completedUploads
          .where((u) => u.uploadedAt != null && u.uploadedAt!.isAfter(sevenDaysAgo))
          .length;

      _logger.i('✅ Statistics generated: $totalDocuments documents, $uniquePersons persons');

      return OverallStatistics(
        totalDocuments: totalDocuments,
        pendingDocuments: pendingDocuments,
        failedDocuments: failedDocuments,
        totalSize: totalSize,
        uniquePersons: uniquePersons,
        uniqueFamilies: uniqueFamilies,
        averageProcessingTimeSeconds: avgProcessingTime,
        successRate: successRate,
        recentUploadsLast7Days: recentUploads,
        generatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate overall statistics: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get family-level statistics
  Future<List<FamilyStatistics>> getFamilyStatistics() async {
    try {
      _logger.i('📊 Generating family statistics...');

      final completedUploads = await _database.getUploadHistory(limit: 10000);

      // Group by family (extract from personId format: FAMILY-XXX-PERSON-YYY)
      final familyGroups = <String, List<UploadHistoryData>>{};
      for (var upload in completedUploads) {
        final familyId = upload.personId.split('-').take(2).join('-');
        familyGroups.putIfAbsent(familyId, () => []).add(upload);
      }

      // Calculate statistics for each family
      final familyStats = <FamilyStatistics>[];
      for (var entry in familyGroups.entries) {
        final familyId = entry.key;
        final uploads = entry.value;

        final uniquePersons = uploads.map((u) => u.personId).toSet().length;
        final totalDocuments = uploads.length;
        final totalSize = uploads.fold<int>(0, (sum, u) => sum + (u.fileSize ?? 0));

        // Get latest upload
        final sortedByDate = uploads.toList()
          ..sort((a, b) => (b.uploadedAt ?? DateTime(1970)).compareTo(a.uploadedAt ?? DateTime(1970)));
        final lastUploadDate = sortedByDate.first.uploadedAt;

        familyStats.add(FamilyStatistics(
          familyId: familyId,
          totalDocuments: totalDocuments,
          uniquePersons: uniquePersons,
          totalSize: totalSize,
          lastUploadDate: lastUploadDate,
        ));
      }

      // Sort by document count (descending)
      familyStats.sort((a, b) => b.totalDocuments.compareTo(a.totalDocuments));

      _logger.i('✅ Family statistics generated: ${familyStats.length} families');
      return familyStats;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate family statistics: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get person-level statistics
  Future<List<PersonStatistics>> getPersonStatistics({String? familyId}) async {
    try {
      _logger.i('📊 Generating person statistics...');

      final allUploads = await _database.getUploadHistory(limit: 10000);
      var completedUploads = allUploads.where((u) => u.status == 'completed').toList();

      // Filter by family if specified
      if (familyId != null) {
        completedUploads = completedUploads.where((u) => u.personId.split('-').take(2).join('-') == familyId).toList();
      }

      // Group by person
      final personGroups = <String, List<UploadHistoryData>>{};
      for (var upload in completedUploads) {
        personGroups.putIfAbsent(upload.personId, () => []).add(upload);
      }

      // Calculate statistics for each person
      final personStats = <PersonStatistics>[];
      for (var entry in personGroups.entries) {
        final personId = entry.key;
        final uploads = entry.value;

        final personName = uploads.first.personName;
        final familyId = uploads.first.personId.split('-').take(2).join('-');
        final totalDocuments = uploads.length;
        final totalSize = uploads.fold<int>(0, (sum, u) => sum + (u.fileSize ?? 0));

        // Get latest upload
        final sortedByDate = uploads.toList()
          ..sort((a, b) => (b.uploadedAt ?? DateTime(1970)).compareTo(a.uploadedAt ?? DateTime(1970)));
        final lastUploadDate = sortedByDate.first.uploadedAt;

        personStats.add(PersonStatistics(
          personId: personId,
          personName: personName,
          familyId: familyId,
          totalDocuments: totalDocuments,
          totalSize: totalSize,
          lastUploadDate: lastUploadDate,
        ));
      }

      // Sort by document count (descending)
      personStats.sort((a, b) => b.totalDocuments.compareTo(a.totalDocuments));

      _logger.i('✅ Person statistics generated: ${personStats.length} persons');
      return personStats;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate person statistics: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get time-based trends
  Future<List<DailyStatistics>> getDailyTrends({int days = 30}) async {
    try {
      _logger.i('📊 Generating daily trends for last $days days...');

      final allUploads = await _database.getUploadHistory(limit: 10000);
      final completedUploads = allUploads.where((u) => u.status == 'completed').toList();

      // Group by date
      final dateGroups = <String, List<UploadHistoryData>>{};
      final now = DateTime.now();

      for (var i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _formatDate(date);
        dateGroups[dateKey] = [];
      }

      for (var upload in completedUploads) {
        if (upload.uploadedAt != null) {
          final dateKey = _formatDate(upload.uploadedAt!);
          if (dateGroups.containsKey(dateKey)) {
            dateGroups[dateKey]!.add(upload);
          }
        }
      }

      // Calculate daily statistics
      final dailyStats = <DailyStatistics>[];
      for (var entry in dateGroups.entries) {
        final dateKey = entry.key;
        final uploads = entry.value;

        final date = DateTime.parse(dateKey);
        final documentCount = uploads.length;
        final totalSize = uploads.fold<int>(0, (sum, u) => sum + (u.fileSize ?? 0));
        final uniquePersons = uploads.map((u) => u.personId).toSet().length;

        dailyStats.add(DailyStatistics(
          date: date,
          documentCount: documentCount,
          totalSize: totalSize,
          uniquePersons: uniquePersons,
        ));
      }

      // Sort by date (ascending)
      dailyStats.sort((a, b) => a.date.compareTo(b.date));

      _logger.i('✅ Daily trends generated: ${dailyStats.length} days');
      return dailyStats;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate daily trends: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get document type distribution
  Future<Map<String, int>> getDocumentTypeDistribution() async {
    try {
      _logger.i('📊 Generating document type distribution...');

      final allUploads = await _database.getUploadHistory(limit: 10000);
      final completedUploads = allUploads.where((u) => u.status == 'completed').toList();

      // Count by document type
      final distribution = <String, int>{};
      for (var upload in completedUploads) {
        final docType = upload.documentType;
        distribution[docType] = (distribution[docType] ?? 0) + 1;
      }

      _logger.i('✅ Document type distribution generated: ${distribution.length} types');
      return distribution;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate document type distribution: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get top performers (users with most uploads)
  Future<List<PerformerStatistics>> getTopPerformers({int limit = 10}) async {
    try {
      _logger.i('📊 Generating top performers...');

      final allUploads = await _database.getUploadHistory(limit: 10000);
      final completedUploads = allUploads.where((u) => u.status == 'completed').toList();

      // Group by digitizer
      // Note: UploadHistory doesn't store metadata, so digitizer info is not available
      final digitizerGroups = <String, List<UploadHistoryData>>{};
      for (var upload in completedUploads) {
        final digitizer = 'Desconocido'; // Metadata not available in UploadHistory
        digitizerGroups.putIfAbsent(digitizer, () => []).add(upload);
      }

      // Calculate statistics for each digitizer
      final performers = <PerformerStatistics>[];
      for (var entry in digitizerGroups.entries) {
        final digitizer = entry.key;
        final uploads = entry.value;

        final documentCount = uploads.length;
        final totalSize = uploads.fold<int>(0, (sum, u) => sum + (u.fileSize ?? 0));
        final uniquePersons = uploads.map((u) => u.personId).toSet().length;

        performers.add(PerformerStatistics(
          digitizerName: digitizer,
          documentCount: documentCount,
          totalSize: totalSize,
          uniquePersons: uniquePersons,
        ));
      }

      // Sort by document count (descending)
      performers.sort((a, b) => b.documentCount.compareTo(a.documentCount));

      // Limit results
      final topPerformers = performers.take(limit).toList();

      _logger.i('✅ Top performers generated: ${topPerformers.length} performers');
      return topPerformers;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to generate top performers: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Overall Statistics Model
class OverallStatistics {
  final int totalDocuments;
  final int pendingDocuments;
  final int failedDocuments;
  final int totalSize;
  final int uniquePersons;
  final int uniqueFamilies;
  final double averageProcessingTimeSeconds;
  final double successRate;
  final int recentUploadsLast7Days;
  final DateTime generatedAt;

  OverallStatistics({
    required this.totalDocuments,
    required this.pendingDocuments,
    required this.failedDocuments,
    required this.totalSize,
    required this.uniquePersons,
    required this.uniqueFamilies,
    required this.averageProcessingTimeSeconds,
    required this.successRate,
    required this.recentUploadsLast7Days,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'total_documents': totalDocuments,
        'pending_documents': pendingDocuments,
        'failed_documents': failedDocuments,
        'total_size': totalSize,
        'total_size_formatted': ReportingService.formatBytes(totalSize),
        'unique_persons': uniquePersons,
        'unique_families': uniqueFamilies,
        'average_processing_time_seconds': averageProcessingTimeSeconds,
        'success_rate': successRate,
        'recent_uploads_last_7_days': recentUploadsLast7Days,
        'generated_at': generatedAt.toIso8601String(),
      };
}

/// Family Statistics Model
class FamilyStatistics {
  final String familyId;
  final int totalDocuments;
  final int uniquePersons;
  final int totalSize;
  final DateTime? lastUploadDate;

  FamilyStatistics({
    required this.familyId,
    required this.totalDocuments,
    required this.uniquePersons,
    required this.totalSize,
    this.lastUploadDate,
  });

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'total_documents': totalDocuments,
        'unique_persons': uniquePersons,
        'total_size': totalSize,
        'total_size_formatted': ReportingService.formatBytes(totalSize),
        'last_upload_date': lastUploadDate?.toIso8601String(),
      };
}

/// Person Statistics Model
class PersonStatistics {
  final String personId;
  final String personName;
  final String familyId;
  final int totalDocuments;
  final int totalSize;
  final DateTime? lastUploadDate;

  PersonStatistics({
    required this.personId,
    required this.personName,
    required this.familyId,
    required this.totalDocuments,
    required this.totalSize,
    this.lastUploadDate,
  });

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'person_name': personName,
        'family_id': familyId,
        'total_documents': totalDocuments,
        'total_size': totalSize,
        'total_size_formatted': ReportingService.formatBytes(totalSize),
        'last_upload_date': lastUploadDate?.toIso8601String(),
      };
}

/// Daily Statistics Model
class DailyStatistics {
  final DateTime date;
  final int documentCount;
  final int totalSize;
  final int uniquePersons;

  DailyStatistics({
    required this.date,
    required this.documentCount,
    required this.totalSize,
    required this.uniquePersons,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T')[0],
        'document_count': documentCount,
        'total_size': totalSize,
        'total_size_formatted': ReportingService.formatBytes(totalSize),
        'unique_persons': uniquePersons,
      };
}

/// Performer Statistics Model
class PerformerStatistics {
  final String digitizerName;
  final int documentCount;
  final int totalSize;
  final int uniquePersons;

  PerformerStatistics({
    required this.digitizerName,
    required this.documentCount,
    required this.totalSize,
    required this.uniquePersons,
  });

  Map<String, dynamic> toJson() => {
        'digitizer_name': digitizerName,
        'document_count': documentCount,
        'total_size': totalSize,
        'total_size_formatted': ReportingService.formatBytes(totalSize),
        'unique_persons': uniquePersons,
      };
}
