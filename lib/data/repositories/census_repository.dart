import '../../services/logger_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/person.dart';
import '../datasources/census_data_source.dart';

/// Census Repository
/// Manages census data and person selection
class CensusRepository {
  final CensusDataSource _dataSource;
  final LoggerAdapter _logger = LoggerAdapter();

  Person? _selectedPerson;

  CensusRepository(this._dataSource);

  /// Load all persons from census
  Future<List<Person>> getAllPersons() async {
    try {
      _logger.i('📊 Loading all persons from census');
      return await _dataSource.loadPersons();
    } catch (e) {
      _logger.e('❌ Failed to load persons: $e');
      rethrow;
    }
  }

  /// Search persons by query
  Future<List<Person>> searchPersons(String query) async {
    try {
      _logger.d('🔍 Searching persons: $query');
      return await _dataSource.searchPersons(query);
    } catch (e) {
      _logger.e('❌ Search failed: $e');
      rethrow;
    }
  }

  /// Get person by ID
  Future<Person?> getPersonById(String personId) async {
    try {
      _logger.d('🔍 Finding person: $personId');
      return await _dataSource.findPersonById(personId);
    } catch (e) {
      _logger.e('❌ Failed to find person: $e');
      rethrow;
    }
  }

  /// Get persons by family
  Future<List<Person>> getPersonsByFamily(String familyId) async {
    try {
      _logger.d('👨‍👩‍👧‍👦 Getting family members: $familyId');
      return await _dataSource.getPersonsByFamily(familyId);
    } catch (e) {
      _logger.e('❌ Failed to get family members: $e');
      rethrow;
    }
  }

  /// Select a person for document association
  Future<void> selectPerson(Person person) async {
    try {
      _selectedPerson = person;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ApiConstants.selectedPersonIdKey,
        person.personId,
      );

      _logger.i('✅ Person selected: ${person.fullName} (${person.personId})');
    } catch (e) {
      _logger.e('❌ Failed to select person: $e');
      rethrow;
    }
  }

  /// Get currently selected person
  Future<Person?> getSelectedPerson() async {
    // Return cached if available
    if (_selectedPerson != null) {
      return _selectedPerson;
    }

    try {
      // Try to restore from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final personId = prefs.getString(ApiConstants.selectedPersonIdKey);

      if (personId == null) {
        _logger.d('No person selected');
        return null;
      }

      // Load the person
      _selectedPerson = await _dataSource.findPersonById(personId);

      if (_selectedPerson != null) {
        _logger.d('✅ Restored selected person: ${_selectedPerson!.fullName}');
      }

      return _selectedPerson;
    } catch (e) {
      _logger.e('❌ Failed to get selected person: $e');
      return null;
    }
  }

  /// Clear person selection
  Future<void> clearSelection() async {
    try {
      _selectedPerson = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.selectedPersonIdKey);

      _logger.i('🗑️ Person selection cleared');
    } catch (e) {
      _logger.e('❌ Failed to clear selection: $e');
      rethrow;
    }
  }

  /// Get census statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      _logger.d('📊 Getting census statistics');
      return await _dataSource.getStatistics();
    } catch (e) {
      _logger.e('❌ Failed to get statistics: $e');
      rethrow;
    }
  }

  /// Get unique family IDs
  Future<List<String>> getFamilyIds() async {
    try {
      return await _dataSource.getUniqueFamilyIds();
    } catch (e) {
      _logger.e('❌ Failed to get family IDs: $e');
      rethrow;
    }
  }

  /// Check if a person is selected
  bool get hasSelectedPerson => _selectedPerson != null;

  /// Get current selected person (cached)
  Person? get currentSelectedPerson => _selectedPerson;
}
