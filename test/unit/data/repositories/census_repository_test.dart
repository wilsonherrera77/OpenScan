import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openscan_indigenas/core/constants/api_constants.dart';
import 'package:openscan_indigenas/data/repositories/census_repository.dart';
import 'package:openscan_indigenas/data/datasources/census_data_source.dart';
import 'package:openscan_indigenas/domain/entities/person.dart';
import '../../../helpers/fixtures.dart';

@GenerateMocks([CensusDataSource])
import 'census_repository_test.mocks.dart';

void main() {
  late CensusRepository repository;
  late MockCensusDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockCensusDataSource();
    repository = CensusRepository(mockDataSource);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  group('CensusRepository - getAllPersons', () {
    test('should return list of persons from data source', () async {
      // Arrange
      final mockPersons = [
        Fixtures.createMockPerson(personId: 'P001', fullName: 'Juan Pérez'),
        Fixtures.createMockPerson(personId: 'P002', fullName: 'María García'),
      ];

      when(mockDataSource.loadPersons())
          .thenAnswer((_) async => mockPersons);

      // Act
      final result = await repository.getAllPersons();

      // Assert
      expect(result, mockPersons);
      expect(result.length, 2);
      verify(mockDataSource.loadPersons()).called(1);
    });

    test('should throw exception when data source fails', () async {
      // Arrange
      when(mockDataSource.loadPersons())
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => repository.getAllPersons(),
        throwsException,
      );
    });
  });

  group('CensusRepository - searchPersons', () {
    test('should return filtered persons matching query', () async {
      // Arrange
      const query = 'Juan';
      final mockPersons = [
        Fixtures.createMockPerson(personId: 'P001', fullName: 'Juan Pérez'),
      ];

      when(mockDataSource.searchPersons(query))
          .thenAnswer((_) async => mockPersons);

      // Act
      final result = await repository.searchPersons(query);

      // Assert
      expect(result, mockPersons);
      expect(result.length, 1);
      expect(result.first.fullName, contains('Juan'));
      verify(mockDataSource.searchPersons(query)).called(1);
    });

    test('should return empty list when no matches found', () async {
      // Arrange
      const query = 'NonExistent';
      when(mockDataSource.searchPersons(query))
          .thenAnswer((_) async => []);

      // Act
      final result = await repository.searchPersons(query);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('CensusRepository - getPersonById', () {
    test('should return person when found', () async {
      // Arrange
      const personId = 'P001';
      final mockPerson = Fixtures.createMockPerson(personId: personId);

      when(mockDataSource.findPersonById(personId))
          .thenAnswer((_) async => mockPerson);

      // Act
      final result = await repository.getPersonById(personId);

      // Assert
      expect(result, mockPerson);
      expect(result?.personId, personId);
      verify(mockDataSource.findPersonById(personId)).called(1);
    });

    test('should return null when person not found', () async {
      // Arrange
      const personId = 'NONEXISTENT';
      when(mockDataSource.findPersonById(personId))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getPersonById(personId);

      // Assert
      expect(result, null);
    });
  });

  group('CensusRepository - getPersonsByFamily', () {
    test('should return all persons in family', () async {
      // Arrange
      const familyId = 'F001';
      final mockFamilyMembers = [
        Fixtures.createMockPerson(personId: 'P001', familyId: familyId),
        Fixtures.createMockPerson(personId: 'P002', familyId: familyId),
      ];

      when(mockDataSource.getPersonsByFamily(familyId))
          .thenAnswer((_) async => mockFamilyMembers);

      // Act
      final result = await repository.getPersonsByFamily(familyId);

      // Assert
      expect(result.length, 2);
      expect(result.every((p) => p.familyId == familyId), true);
      verify(mockDataSource.getPersonsByFamily(familyId)).called(1);
    });
  });

  group('CensusRepository - selectPerson', () {
    test('should select person and save to preferences', () async {
      // Arrange
      final mockPerson = Fixtures.createMockPerson(personId: 'P001');

      // Act
      await repository.selectPerson(mockPerson);

      // Assert
      expect(repository.hasSelectedPerson, true);
      expect(repository.currentSelectedPerson, mockPerson);

      // Verify it was saved
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(ApiConstants.selectedPersonIdKey);
      expect(savedId, mockPerson.personId);
    });

    test('should update selection when selecting different person', () async {
      // Arrange
      final person1 = Fixtures.createMockPerson(personId: 'P001');
      final person2 = Fixtures.createMockPerson(personId: 'P002');

      // Act
      await repository.selectPerson(person1);
      expect(repository.currentSelectedPerson?.personId, 'P001');

      await repository.selectPerson(person2);

      // Assert
      expect(repository.currentSelectedPerson?.personId, 'P002');
    });
  });

  group('CensusRepository - getSelectedPerson', () {
    test('should return cached selected person if available', () async {
      // Arrange
      final mockPerson = Fixtures.createMockPerson(personId: 'P001');
      await repository.selectPerson(mockPerson);

      // Act
      final result = await repository.getSelectedPerson();

      // Assert
      expect(result, mockPerson);
      verifyNever(mockDataSource.findPersonById(any));
    });

    test('should return null when no person selected', () async {
      // Act
      final result = await repository.getSelectedPerson();

      // Assert
      expect(result, null);
    });

    test('should restore from preferences if not cached', () async {
      // Arrange
      const personId = 'P001';
      final mockPerson = Fixtures.createMockPerson(personId: personId);

      // Save to preferences directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.selectedPersonIdKey, personId);

      when(mockDataSource.findPersonById(personId))
          .thenAnswer((_) async => mockPerson);

      // Create new repository instance (no cache)
      final newRepository = CensusRepository(mockDataSource);

      // Act
      final result = await newRepository.getSelectedPerson();

      // Assert
      expect(result, mockPerson);
      verify(mockDataSource.findPersonById(personId)).called(1);
    });
  });

  group('CensusRepository - clearSelection', () {
    test('should clear selected person and preferences', () async {
      // Arrange
      final mockPerson = Fixtures.createMockPerson(personId: 'P001');
      await repository.selectPerson(mockPerson);
      expect(repository.hasSelectedPerson, true);

      // Act
      await repository.clearSelection();

      // Assert
      expect(repository.hasSelectedPerson, false);
      expect(repository.currentSelectedPerson, null);

      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(ApiConstants.selectedPersonIdKey);
      expect(savedId, null);
    });
  });

  group('CensusRepository - getStatistics', () {
    test('should return census statistics from data source', () async {
      // Arrange
      final mockStats = {
        'totalPersons': 100,
        'totalFamilies': 25,
        'documentsPerPerson': 3.5,
      };

      when(mockDataSource.getStatistics())
          .thenAnswer((_) async => mockStats);

      // Act
      final result = await repository.getStatistics();

      // Assert
      expect(result, mockStats);
      expect(result['totalPersons'], 100);
      verify(mockDataSource.getStatistics()).called(1);
    });
  });

  group('CensusRepository - getFamilyIds', () {
    test('should return list of unique family IDs', () async {
      // Arrange
      final mockFamilyIds = ['F001', 'F002', 'F003'];

      when(mockDataSource.getUniqueFamilyIds())
          .thenAnswer((_) async => mockFamilyIds);

      // Act
      final result = await repository.getFamilyIds();

      // Assert
      expect(result, mockFamilyIds);
      expect(result.length, 3);
      verify(mockDataSource.getUniqueFamilyIds()).called(1);
    });
  });

  group('CensusRepository - hasSelectedPerson', () {
    test('should return false when no person selected', () {
      // Act & Assert
      expect(repository.hasSelectedPerson, false);
    });

    test('should return true when person is selected', () async {
      // Arrange
      final mockPerson = Fixtures.createMockPerson(personId: 'P001');

      // Act
      await repository.selectPerson(mockPerson);

      // Assert
      expect(repository.hasSelectedPerson, true);
    });
  });
}
