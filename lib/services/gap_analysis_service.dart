import '../services/logger_adapter.dart';
import '../data/local/database/app_database.dart';
import '../domain/entities/person.dart';

/// Gap Analysis Service
///
/// Analyzes document gaps and identifies missing documents for persons and families
///
/// Features:
/// - Required document types configuration
/// - Gap detection per person
/// - Family-level gap analysis
/// - Priority recommendations
/// - Completion percentage tracking
class GapAnalysisService {
  final AppDatabase _database;
  final LoggerAdapter _logger = LoggerAdapter();

  GapAnalysisService(this._database);

  /// Required document types for indigenous communities
  static const List<String> requiredDocuments = [
    'Cédula de Ciudadanía',
    'Registro Civil',
    'Tarjeta de Identidad',
    'Certificado de Afiliación EPS',
    'Certificado de Censo',
  ];

  /// Optional but recommended documents
  static const List<String> recommendedDocuments = [
    'Carné de Vacunación',
    'Certificado de Estudios',
    'Certificado de Propiedad',
    'Acta de Matrimonio',
  ];

  /// Analyze gaps for a specific person
  Future<PersonGapAnalysis> analyzePersonGaps(String personId) async {
    try {
      _logger.i('📊 Analyzing document gaps for person: $personId');

      // Get all uploads for this person
      final allUploads = await _database.getUploadHistory(limit: 10000);
      final personUploads = allUploads
          .where((u) => u.personId == personId && u.status == 'completed')
          .toList();

      // Extract document types that exist
      final existingDocTypes = personUploads
          .map((u) => u.documentType)
          .toSet();

      // Identify missing required documents
      final missingRequired = requiredDocuments
          .where((doc) => !existingDocTypes.contains(doc))
          .toList();

      // Identify missing recommended documents
      final missingRecommended = recommendedDocuments
          .where((doc) => !existingDocTypes.contains(doc))
          .toList();

      // Calculate completion percentage
      final totalRequired = requiredDocuments.length;
      final completed = totalRequired - missingRequired.length;
      final completionPercentage = (completed / totalRequired * 100).toDouble();

      // Determine priority level
      final priorityLevel = _calculatePriorityLevel(completionPercentage);

      // Get person details
      final personName = personUploads.isNotEmpty
          ? personUploads.first.personName
          : 'Desconocido';
      final familyId = personUploads.isNotEmpty
          ? personUploads.first.personId.split('-').take(2).join('-')
          : '';

      _logger.i('✅ Gap analysis complete: ${missingRequired.length} missing required docs');

      return PersonGapAnalysis(
        personId: personId,
        personName: personName,
        familyId: familyId,
        existingDocuments: existingDocTypes.toList().cast<String>(),
        missingRequiredDocuments: missingRequired,
        missingRecommendedDocuments: missingRecommended,
        completionPercentage: completionPercentage,
        priorityLevel: priorityLevel,
        totalDocuments: personUploads.length,
        analyzedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to analyze person gaps: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Analyze gaps for all persons
  Future<List<PersonGapAnalysis>> analyzeAllGaps() async {
    try {
      _logger.i('📊 Analyzing document gaps for all persons...');

      // Get all unique person IDs
      final completedUploads = await _database.getUploadHistory(limit: 10000);
      final personIds = completedUploads
          .where((u) => u.status == 'completed')
          .map((u) => u.personId)
          .toSet()
          .toList();

      _logger.i('   Found ${personIds.length} unique persons');

      // Analyze each person
      final analyses = <PersonGapAnalysis>[];
      for (var personId in personIds) {
        final analysis = await analyzePersonGaps(personId);
        analyses.add(analysis);
      }

      // Sort by priority and completion percentage
      analyses.sort((a, b) {
        // First by priority (High -> Medium -> Low)
        final priorityComparison = _priorityValue(a.priorityLevel).compareTo(_priorityValue(b.priorityLevel));
        if (priorityComparison != 0) return priorityComparison;

        // Then by completion percentage (ascending - least complete first)
        return a.completionPercentage.compareTo(b.completionPercentage);
      });

      _logger.i('✅ All gap analyses complete: ${analyses.length} persons analyzed');
      return analyses;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to analyze all gaps: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Analyze gaps at family level
  Future<List<FamilyGapAnalysis>> analyzeFamilyGaps() async {
    try {
      _logger.i('📊 Analyzing document gaps by family...');

      final personAnalyses = await analyzeAllGaps();

      // Group by family
      final familyGroups = <String, List<PersonGapAnalysis>>{};
      for (var analysis in personAnalyses) {
        familyGroups.putIfAbsent(analysis.familyId, () => []).add(analysis);
      }

      // Calculate family-level statistics
      final familyAnalyses = <FamilyGapAnalysis>[];
      for (var entry in familyGroups.entries) {
        final familyId = entry.key;
        final persons = entry.value;

        final totalPersons = persons.length;
        final personsWithGaps = persons.where((p) => p.missingRequiredDocuments.isNotEmpty).length;
        final averageCompletion = persons.isEmpty
            ? 0.0
            : persons.map((p) => p.completionPercentage).reduce((a, b) => a + b) / persons.length;

        // Find most common missing documents in family
        final allMissingDocs = <String>[];
        for (var person in persons) {
          allMissingDocs.addAll(person.missingRequiredDocuments);
        }

        final missingDocCounts = <String, int>{};
        for (var doc in allMissingDocs) {
          missingDocCounts[doc] = (missingDocCounts[doc] ?? 0) + 1;
        }

        final sortedMissing = missingDocCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final mostCommonMissing = sortedMissing.take(3).map((e) => e.key).toList();

        // Determine family priority
        final priorityLevel = personsWithGaps >= totalPersons * 0.5
            ? 'Alta'
            : personsWithGaps >= totalPersons * 0.25
                ? 'Media'
                : 'Baja';

        familyAnalyses.add(FamilyGapAnalysis(
          familyId: familyId,
          totalPersons: totalPersons,
          personsWithGaps: personsWithGaps,
          averageCompletionPercentage: averageCompletion,
          mostCommonMissingDocuments: mostCommonMissing,
          priorityLevel: priorityLevel,
          personAnalyses: persons,
        ));
      }

      // Sort by priority and persons with gaps
      familyAnalyses.sort((a, b) {
        final priorityComparison = _priorityValue(a.priorityLevel).compareTo(_priorityValue(b.priorityLevel));
        if (priorityComparison != 0) return priorityComparison;
        return b.personsWithGaps.compareTo(a.personsWithGaps);
      });

      _logger.i('✅ Family gap analyses complete: ${familyAnalyses.length} families analyzed');
      return familyAnalyses;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to analyze family gaps: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get overall gap statistics
  Future<GapStatistics> getGapStatistics() async {
    try {
      _logger.i('📊 Calculating overall gap statistics...');

      final personAnalyses = await analyzeAllGaps();

      final totalPersons = personAnalyses.length;
      final personsComplete = personAnalyses.where((p) => p.missingRequiredDocuments.isEmpty).length;
      final personsWithGaps = totalPersons - personsComplete;

      final highPriority = personAnalyses.where((p) => p.priorityLevel == 'Alta').length;
      final mediumPriority = personAnalyses.where((p) => p.priorityLevel == 'Media').length;
      final lowPriority = personAnalyses.where((p) => p.priorityLevel == 'Baja').length;

      final averageCompletion = personAnalyses.isEmpty
          ? 0.0
          : personAnalyses.map((p) => p.completionPercentage).reduce((a, b) => a + b) / personAnalyses.length;

      // Find most common missing document
      final allMissingDocs = <String>[];
      for (var person in personAnalyses) {
        allMissingDocs.addAll(person.missingRequiredDocuments);
      }

      final missingDocCounts = <String, int>{};
      for (var doc in allMissingDocs) {
        missingDocCounts[doc] = (missingDocCounts[doc] ?? 0) + 1;
      }

      final sortedMissing = missingDocCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final mostCommonMissing = sortedMissing.isNotEmpty ? sortedMissing.first.key : null;

      _logger.i('✅ Gap statistics calculated: $personsWithGaps/$totalPersons persons with gaps');

      return GapStatistics(
        totalPersons: totalPersons,
        personsComplete: personsComplete,
        personsWithGaps: personsWithGaps,
        highPriorityPersons: highPriority,
        mediumPriorityPersons: mediumPriority,
        lowPriorityPersons: lowPriority,
        averageCompletionPercentage: averageCompletion,
        mostCommonMissingDocument: mostCommonMissing,
        totalMissingDocuments: allMissingDocs.length,
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to calculate gap statistics: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calculate priority level based on completion percentage
  String _calculatePriorityLevel(double completionPercentage) {
    if (completionPercentage < 40) return 'Alta';
    if (completionPercentage < 70) return 'Media';
    return 'Baja';
  }

  /// Get priority value for sorting (lower = higher priority)
  int _priorityValue(String priority) {
    switch (priority) {
      case 'Alta':
        return 0;
      case 'Media':
        return 1;
      case 'Baja':
        return 2;
      default:
        return 3;
    }
  }
}

/// Person Gap Analysis Model
class PersonGapAnalysis {
  final String personId;
  final String personName;
  final String familyId;
  final List<String> existingDocuments;
  final List<String> missingRequiredDocuments;
  final List<String> missingRecommendedDocuments;
  final double completionPercentage;
  final String priorityLevel; // 'Alta', 'Media', 'Baja'
  final int totalDocuments;
  final DateTime analyzedAt;

  PersonGapAnalysis({
    required this.personId,
    required this.personName,
    required this.familyId,
    required this.existingDocuments,
    required this.missingRequiredDocuments,
    required this.missingRecommendedDocuments,
    required this.completionPercentage,
    required this.priorityLevel,
    required this.totalDocuments,
    required this.analyzedAt,
  });

  bool get isComplete => missingRequiredDocuments.isEmpty;

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'person_name': personName,
        'family_id': familyId,
        'existing_documents': existingDocuments,
        'missing_required_documents': missingRequiredDocuments,
        'missing_recommended_documents': missingRecommendedDocuments,
        'completion_percentage': completionPercentage,
        'priority_level': priorityLevel,
        'total_documents': totalDocuments,
        'is_complete': isComplete,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}

/// Family Gap Analysis Model
class FamilyGapAnalysis {
  final String familyId;
  final int totalPersons;
  final int personsWithGaps;
  final double averageCompletionPercentage;
  final List<String> mostCommonMissingDocuments;
  final String priorityLevel;
  final List<PersonGapAnalysis> personAnalyses;

  FamilyGapAnalysis({
    required this.familyId,
    required this.totalPersons,
    required this.personsWithGaps,
    required this.averageCompletionPercentage,
    required this.mostCommonMissingDocuments,
    required this.priorityLevel,
    required this.personAnalyses,
  });

  int get personsComplete => totalPersons - personsWithGaps;

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'total_persons': totalPersons,
        'persons_with_gaps': personsWithGaps,
        'persons_complete': personsComplete,
        'average_completion_percentage': averageCompletionPercentage,
        'most_common_missing_documents': mostCommonMissingDocuments,
        'priority_level': priorityLevel,
      };
}

/// Gap Statistics Model
class GapStatistics {
  final int totalPersons;
  final int personsComplete;
  final int personsWithGaps;
  final int highPriorityPersons;
  final int mediumPriorityPersons;
  final int lowPriorityPersons;
  final double averageCompletionPercentage;
  final String? mostCommonMissingDocument;
  final int totalMissingDocuments;

  GapStatistics({
    required this.totalPersons,
    required this.personsComplete,
    required this.personsWithGaps,
    required this.highPriorityPersons,
    required this.mediumPriorityPersons,
    required this.lowPriorityPersons,
    required this.averageCompletionPercentage,
    this.mostCommonMissingDocument,
    required this.totalMissingDocuments,
  });

  Map<String, dynamic> toJson() => {
        'total_persons': totalPersons,
        'persons_complete': personsComplete,
        'persons_with_gaps': personsWithGaps,
        'high_priority_persons': highPriorityPersons,
        'medium_priority_persons': mediumPriorityPersons,
        'low_priority_persons': lowPriorityPersons,
        'average_completion_percentage': averageCompletionPercentage,
        'most_common_missing_document': mostCommonMissingDocument,
        'total_missing_documents': totalMissingDocuments,
      };
}
