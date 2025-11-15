import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../services/logger_adapter.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/person.dart';

/// Census Data Source
/// Loads and parses census data from CSV file
class CensusDataSource {
  final LoggerAdapter _logger = LoggerAdapter();
  List<Person>? _cachedPersons;

  /// Load all persons from census CSV
  Future<List<Person>> loadPersons() async {
    // Return cached data if available
    if (_cachedPersons != null) {
      _logger.d('📋 Returning ${_cachedPersons!.length} cached persons');
      return _cachedPersons!;
    }

    try {
      _logger.i('📊 Loading census data from ${ApiConstants.censusFilePath}');

      // Load CSV file from assets
      final csvString = await rootBundle.loadString(ApiConstants.censusFilePath);

      // Parse CSV
      // DO NOT specify eol - let the parser auto-detect line endings
      // This handles both \n (Unix) and \r\n (Windows) correctly
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',',
      ).convert(csvString);

      if (csvData.isEmpty) {
        _logger.w('⚠️ Census CSV is empty');
        return [];
      }

      // Extract headers (first row)
      final headers = csvData[0].map((e) => e.toString()).toList();
      _logger.d('CSV Headers: $headers');

      // Parse data rows
      final persons = <Person>[];
      int successCount = 0;
      int failCount = 0;

      _logger.i('📊 Starting to parse ${csvData.length - 1} data rows...');

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];

        // Create map from headers and row data
        final rowMap = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowMap[headers[j]] = row[j];
        }

        try {
          final person = Person.fromCsvRow(rowMap);
          persons.add(person);
          successCount++;

          // Log first 5 and every 500th person
          if (successCount <= 5 || successCount % 500 == 0) {
            _logger.i('✓ [$i] Parsed: ${person.personId} - ${person.fullName}');
          }
        } catch (e, stackTrace) {
          failCount++;
          // Log FIRST 10 failures in detail
          if (failCount <= 10) {
            _logger.e('❌ [$i] PARSE FAILED: $e');
            _logger.e('   Row data: ${rowMap.toString().substring(0, 200)}');
            _logger.e('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
          }
          // Continue parsing other rows
        }
      }

      _logger.i('✅ CENSUS LOAD COMPLETE:');
      _logger.i('   ✓ Success: $successCount persons');
      _logger.i('   ✗ Failed: $failCount rows');
      _logger.i('   📊 Total loaded: ${persons.length} persons');

      // Cache the results
      _cachedPersons = persons;

      return persons;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to load census data: $e');
      _logger.e('Stack trace', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Find person by ID
  Future<Person?> findPersonById(String personId) async {
    final persons = await loadPersons();
    try {
      return persons.firstWhere((p) => p.personId == personId);
    } catch (e) {
      _logger.w('⚠️ Person not found: $personId');
      return null;
    }
  }

  /// Search persons by name, ID, family, or document number
  Future<List<Person>> searchPersons(String query) async {
    final persons = await loadPersons();

    if (query.isEmpty) return persons;

    final queryLower = query.toLowerCase();

    return persons.where((person) {
      return person.fullName.toLowerCase().contains(queryLower) ||
          person.personId.toLowerCase().contains(queryLower) ||
          (person.familyId?.toLowerCase().contains(queryLower) ?? false) ||
          person.firstName.toLowerCase().contains(queryLower) ||
          person.lastName.toLowerCase().contains(queryLower) ||
          (person.documentNumber?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Get persons by family ID
  Future<List<Person>> getPersonsByFamily(String familyId) async {
    final persons = await loadPersons();
    return persons.where((p) => p.familyId == familyId).toList();
  }

  /// Get total count of persons
  Future<int> getPersonsCount() async {
    final persons = await loadPersons();
    return persons.length;
  }

  /// Get unique family IDs
  Future<List<String>> getUniqueFamilyIds() async {
    final persons = await loadPersons();
    final familyIds = persons
        .map((p) => p.familyId)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    familyIds.sort();
    return familyIds;
  }

  /// Clear cache
  void clearCache() {
    _cachedPersons = null;
    _logger.d('🗑️ Census cache cleared');
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final persons = await loadPersons();
    final familyIds = await getUniqueFamilyIds();

    final totalDocuments = persons.fold<int>(
      0,
      (sum, person) => sum + person.requiredDocumentsCount,
    );

    return {
      'total_persons': persons.length,
      'total_families': familyIds.length,
      'total_documents_required': totalDocuments,
      'avg_documents_per_person': persons.isEmpty
          ? 0.0
          : totalDocuments / persons.length,
      'avg_family_size': familyIds.isEmpty
          ? 0.0
          : persons.length / familyIds.length,
    };
  }
}
