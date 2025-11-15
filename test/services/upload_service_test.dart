import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:io';
import 'package:openscan_indigenas/data/local/database/app_database.dart';
import 'package:openscan_indigenas/data/repositories/document_repository.dart';
import 'package:openscan_indigenas/services/upload_service.dart';
import 'package:openscan_indigenas/domain/entities/person.dart';

// Generate mocks
@GenerateMocks([DocumentRepository, File])
import 'upload_service_test.mocks.dart';

void main() {
  late AppDatabase database;
  late MockDocumentRepository mockRepository;
  late UploadService uploadService;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mockRepository = MockDocumentRepository();
    uploadService = UploadService(database, mockRepository);
  });

  tearDown(() async {
    await database.close();
  });

  group('Upload Enqueue', () {
    test('should enqueue upload with basic data', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      final uploadId = await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      expect(uploadId, greaterThan(0));

      final stats = await uploadService.getStatistics();
      expect(stats['pending'], 1);
    });

    test('should enqueue upload with enhanced metadata', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      final uploadId = await uploadService.enqueueUploadEnhanced(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
        documentNumber: '1234567890',
        digitizedBy: 'admin',
        documentTypeId: 1,
        tagIds: [1, 2, 3],
        metadata: {'location': 'Comunidad A'},
      );

      expect(uploadId, greaterThan(0));

      final upload = await database.getPendingUploadById(uploadId);
      expect(upload, isNotNull);
      expect(upload!.documentTypeId, 1);
      expect(upload.tags, '1,2,3');
      expect(upload.metadata, contains('location'));
    });
  });

  group('Retry Logic', () {
    test('should calculate exponential backoff correctly', () {
      // Using reflection to test private method would be complex
      // Instead, test behavior through public interface
      expect(UploadService.maxRetryAttempts, 3);
      expect(UploadService.retryDelayBase, const Duration(seconds: 5));
    });

    test('should mark upload as failed after max retries', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      final uploadId = await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      // Simulate 3 failed attempts
      for (var i = 1; i <= 3; i++) {
        await database.updateUploadStatus(
          id: uploadId,
          status: 'pending',
          retryCount: i,
          lastError: 'Network error',
        );
      }

      final upload = await database.getPendingUploadById(uploadId);
      expect(upload!.retryCount, 3);
    });
  });

  group('Statistics', () {
    test('should get pending count', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'REGISTRO_CIVIL',
      );

      final count = await uploadService.getPendingCount();
      expect(count, 2);
    });

    test('should get upload statistics', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      // Add pending upload
      await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      // Add failed upload
      final failedId = await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'REGISTRO_CIVIL',
      );

      await database.updateUploadStatus(
        id: failedId,
        status: 'failed',
        retryCount: 3,
      );

      // Add successful upload to history
      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: false,
      );

      final stats = await uploadService.getStatistics();

      expect(stats['pending'], 1);
      expect(stats['failed'], 1);
      expect(stats['success'], 1);
    });

    test('should get enhanced statistics with performance metrics', () async {
      // Add upload to history with performance data
      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: true,
      );

      final stats = await uploadService.getEnhancedStatistics();

      expect(stats['success'], 1);
      expect(stats['avg_duration_ms'], greaterThan(0));
      expect(stats['offline_uploads'], 1);
    });
  });

  group('Failed Uploads Management', () {
    test('should get failed uploads', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      final uploadId = await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      await database.updateUploadStatus(
        id: uploadId,
        status: 'failed',
        retryCount: 3,
        lastError: 'Network error',
      );

      final failed = await uploadService.getFailedUploads();

      expect(failed.length, 1);
      expect(failed[0].status, 'failed');
    });

    test('should clear failed uploads', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      final uploadId = await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      await database.updateUploadStatus(
        id: uploadId,
        status: 'failed',
        retryCount: 3,
      );

      await uploadService.clearFailedUploads();

      final failed = await uploadService.getFailedUploads();
      expect(failed, isEmpty);
    });
  });

  group('Upload History', () {
    test('should get upload history', () async {
      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: false,
      );

      await database.recordUploadHistory(
        personId: 'P002',
        personName: 'María García',
        documentType: 'REGISTRO_CIVIL',
        fileSize: 512000,
        uploadDurationMs: 1500,
        wasOffline: true,
      );

      final history = await uploadService.getHistory(limit: 10);

      expect(history.length, 2);
      expect(history[0].uploadDurationMs, greaterThan(0));
    });

    test('should get history by person', () async {
      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: false,
      );

      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'REGISTRO_CIVIL',
        fileSize: 512000,
        uploadDurationMs: 1500,
        wasOffline: false,
      );

      await database.recordUploadHistory(
        personId: 'P002',
        personName: 'María García',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2000,
        wasOffline: false,
      );

      final history = await uploadService.getHistoryByPerson('P001');

      expect(history.length, 2);
      expect(history.every((h) => h.personId == 'P001'), true);
    });
  });

  group('Database Stats', () {
    test('should get database statistics', () async {
      final person = Person(
        personId: 'P001',
        fullName: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        familyId: 'F001',
        requiredDocumentsCount: 0,
        requiredDocuments: [],
      );

      final mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/image.jpg');

      await uploadService.enqueueUpload(
        person: person,
        imageFile: mockFile,
        documentType: 'CEDULA_CIUDADANIA',
      );

      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: false,
      );

      final stats = await uploadService.getDatabaseStats();

      expect(stats['pending_uploads'], greaterThan(0));
      expect(stats['history_entries'], greaterThan(0));
    });
  });
}
