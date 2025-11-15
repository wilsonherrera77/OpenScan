import 'package:flutter/foundation.dart';
import '../../services/logger_adapter.dart';
import '../../data/repositories/census_repository.dart';
import '../../domain/entities/person.dart';

/// Census Provider
/// Manages census data and person selection state
class CensusProvider with ChangeNotifier {
  final CensusRepository _censusRepository;
  final LoggerAdapter _logger = LoggerAdapter();

  List<Person> _persons = [];
  List<Person> _filteredPersons = [];
  Person? _selectedPerson;
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Document metadata for current scan session
  String? _documentType;
  String? _documentNumber;

  CensusProvider(this._censusRepository) {
    _initialize();
  }

  // Getters
  List<Person> get persons => _filteredPersons.isEmpty && _searchQuery.isEmpty
      ? _persons
      : _filteredPersons;
  Person? get selectedPerson => _selectedPerson;
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelectedPerson => _selectedPerson != null;
  int get totalPersons => _persons.length;
  String get searchQuery => _searchQuery;
  String? get documentType => _documentType;
  String? get documentNumber => _documentNumber;

  /// Initialize by loading census data and restoring selection
  Future<void> _initialize() async {
    await loadPersons();
    await restoreSelection();
  }

  /// Load all persons from census
  Future<void> loadPersons() async {
    _setLoading(true);
    _clearError();

    try {
      _logger.i('📊 Loading census data');

      _persons = await _censusRepository.getAllPersons();
      _filteredPersons = [];
      _searchQuery = '';

      // Load statistics
      _statistics = await _censusRepository.getStatistics();

      _logger.i('✅ Loaded ${_persons.length} persons');

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Failed to load persons: $e');
      _setError('Error al cargar el censo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Search persons by query
  Future<void> searchPersons(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredPersons = [];
      notifyListeners();
      return;
    }

    try {
      _logger.d('🔍 Searching: $query');

      _filteredPersons = await _censusRepository.searchPersons(query);

      _logger.d('Found ${_filteredPersons.length} results');

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Search failed: $e');
      _setError('Error en la búsqueda: ${e.toString()}');
    }
  }

  /// Select a person
  Future<void> selectPerson(Person person) async {
    try {
      _logger.i('✅ Selecting person: ${person.fullName}');

      await _censusRepository.selectPerson(person);
      _selectedPerson = person;

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Failed to select person: $e');
      _setError('Error al seleccionar persona: ${e.toString()}');
    }
  }

  /// Clear person selection
  Future<void> clearSelection() async {
    try {
      _logger.i('🗑️ Clearing person selection');

      await _censusRepository.clearSelection();
      _selectedPerson = null;

      notifyListeners();
    } catch (e) {
      _logger.e('❌ Failed to clear selection: $e');
      _setError('Error al limpiar selección: ${e.toString()}');
    }
  }

  /// Restore previously selected person
  Future<void> restoreSelection() async {
    try {
      _selectedPerson = await _censusRepository.getSelectedPerson();

      if (_selectedPerson != null) {
        _logger.i('✅ Restored selection: ${_selectedPerson!.fullName}');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('❌ Failed to restore selection: $e');
    }
  }

  /// Get persons by family
  Future<List<Person>> getPersonsByFamily(String familyId) async {
    try {
      return await _censusRepository.getPersonsByFamily(familyId);
    } catch (e) {
      _logger.e('❌ Failed to get family members: $e');
      return [];
    }
  }

  /// Get family IDs
  Future<List<String>> getFamilyIds() async {
    try {
      return await _censusRepository.getFamilyIds();
    } catch (e) {
      _logger.e('❌ Failed to get family IDs: $e');
      return [];
    }
  }

  /// Reload census data
  Future<void> reload() async {
    await loadPersons();
  }

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

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredPersons = [];
    notifyListeners();
  }

  /// Set document metadata for current scan session
  void setDocumentMetadata({
    required String documentType,
    required String documentNumber,
  }) {
    _logger.i('📝 Setting document metadata: $documentType, number: $documentNumber');
    _documentType = documentType;
    _documentNumber = documentNumber;
    notifyListeners();
  }

  /// Clear document metadata
  void clearDocumentMetadata() {
    _logger.i('🗑️ Clearing document metadata');
    _documentType = null;
    _documentNumber = null;
    notifyListeners();
  }
}
