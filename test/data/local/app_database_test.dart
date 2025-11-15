import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:openscan_indigenas/data/local/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('PendingUploads Table', () {
    test('should enqueue upload with metadata', () async {
      final uploadId = await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
        familyId: 'F001',
        docNumber: '1234567890',
        documentTypeId: 1,
        tagIds: [1, 2, 3],
        metadata: {'location': 'Comunidad A', 'notes': 'Test upload'},
      );

      expect(uploadId, greaterThan(0));

      final upload = await database.getPendingUploadById(uploadId);

      expect(upload, isNotNull);
      expect(upload!.personId, 'P001');
      expect(upload.personName, 'Juan Pérez');
      expect(upload.familyId, 'F001');
      expect(upload.documentNumber, '1234567890');
      expect(upload.documentTypeId, 1);
      expect(upload.tags, '1,2,3');
      expect(upload.metadata, contains('location'));
      expect(upload.status, 'pending');
      expect(upload.retryCount, 0);
    });

    test('should retrieve all pending uploads', () async {
      // Enqueue multiple uploads
      await database.enqueueUpload(
        filePath: '/test/image1.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.enqueueUpload(
        filePath: '/test/image2.jpg',
        personId: 'P002',
        personName: 'María García',
      );

      final pending = await database.getAllPendingUploads();

      expect(pending.length, 2);
      expect(pending[0].status, 'pending');
    });

    test('should update upload status', () async {
      final uploadId = await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.updateUploadStatus(
        id: uploadId,
        status: 'uploading',
      );

      final upload = await database.getPendingUploadById(uploadId);

      expect(upload!.status, 'uploading');
      expect(upload.lastAttemptAt, isNotNull);
    });

    test('should increment retry count', () async {
      final uploadId = await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.updateUploadStatus(
        id: uploadId,
        status: 'pending',
        retryCount: 1,
        lastError: 'Network error',
      );

      final upload = await database.getPendingUploadById(uploadId);

      expect(upload!.retryCount, 1);
      expect(upload.lastError, 'Network error');
    });

    test('should delete pending upload', () async {
      final uploadId = await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.deletePendingUpload(uploadId);

      final upload = await database.getPendingUploadById(uploadId);

      expect(upload, isNull);
    });

    test('should count pending uploads', () async {
      await database.enqueueUpload(
        filePath: '/test/image1.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.enqueueUpload(
        filePath: '/test/image2.jpg',
        personId: 'P002',
        personName: 'María García',
      );

      final count = await database.countPendingUploads();

      expect(count, 2);
    });

    test('should retrieve failed uploads', () async {
      final uploadId = await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.updateUploadStatus(
        id: uploadId,
        status: 'failed',
        retryCount: 3,
        lastError: 'Max retries exceeded',
      );

      final failed = await database.getFailedUploads();

      expect(failed.length, 1);
      expect(failed[0].status, 'failed');
      expect(failed[0].retryCount, 3);
    });
  });

  group('UploadHistory Table', () {
    test('should record upload history with performance metrics', () async {
      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        paperlessDocumentId: 123,
        fileSize: 1024000, // 1MB
        uploadDurationMs: 2500, // 2.5 seconds
        wasOffline: true,
      );

      final history = await database.getUploadHistory(limit: 10);

      expect(history.length, 1);
      expect(history[0].personId, 'P001');
      expect(history[0].documentType, 'CEDULA_CIUDADANIA');
      expect(history[0].paperlessDocumentId, 123);
      expect(history[0].fileSize, 1024000);
      expect(history[0].uploadDurationMs, 2500);
      expect(history[0].wasOffline, true);
    });

    test('should retrieve history by person', () async {
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

      final history = await database.getHistoryByPerson('P001');

      expect(history.length, 2);
      expect(history.every((h) => h.personId == 'P001'), true);
    });
  });

  group('Statistics', () {
    test('should get upload statistics', () async {
      // Add pending uploads
      await database.enqueueUpload(
        filePath: '/test/image1.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      final uploadId2 = await database.enqueueUpload(
        filePath: '/test/image2.jpg',
        personId: 'P002',
        personName: 'María García',
      );

      // Mark one as failed
      await database.updateUploadStatus(
        id: uploadId2,
        status: 'failed',
        retryCount: 3,
      );

      // Add successful upload to history
      await database.recordUploadHistory(
        personId: 'P003',
        personName: 'Carlos López',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: false,
      );

      final stats = await database.getUploadStats();

      expect(stats['pending'], 1);
      expect(stats['failed'], 1);
      expect(stats['success'], 1);
      expect(stats['total'], 3);
    });

    test('should get enhanced statistics with performance metrics', () async {
      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: true,
      );

      await database.recordUploadHistory(
        personId: 'P002',
        personName: 'María García',
        documentType: 'REGISTRO_CIVIL',
        fileSize: 512000,
        uploadDurationMs: 1500,
        wasOffline: false,
      );

      final stats = await database.getEnhancedUploadStats();

      expect(stats['success'], 2);
      expect(stats['avg_duration_ms'], greaterThan(0));
      expect(stats['offline_uploads'], 1);
    });
  });

  group('Persons Cache', () {
    test('should sync persons from CSV data', () async {
      final persons = [
        {
          'id': 'P001',
          'name': 'Juan Pérez',
          'census_id': 'C001',
          'birth_date': '1990-01-01',
          'life_stage': 'Adulto',
          'family_role': 'Padre',
          'community': 'Comunidad A',
        },
        {
          'id': 'P002',
          'name': 'María García',
          'census_id': 'C002',
          'birth_date': '1985-05-15',
          'life_stage': 'Adulto',
          'family_role': 'Madre',
          'community': 'Comunidad B',
        },
      ];

      await database.syncPersons(persons);

      final count = await database.countPersons();
      expect(count, 2);
    });

    test('should search persons by name', () async {
      final persons = [
        {'id': 'P001', 'name': 'Juan Pérez'},
        {'id': 'P002', 'name': 'María García'},
        {'id': 'P003', 'name': 'Juan López'},
      ];

      await database.syncPersons(persons);

      final results = await database.searchPersons('Juan');

      expect(results.length, 2);
      expect(results.every((p) => p.name.contains('Juan')), true);
    });

    test('should get person by ID', () async {
      final persons = [
        {'id': 'P001', 'name': 'Juan Pérez'},
      ];

      await database.syncPersons(persons);

      final person = await database.getPersonById('P001');

      expect(person, isNotNull);
      expect(person!.name, 'Juan Pérez');
    });
  });

  group('Maintenance Operations', () {
    test('should clear failed uploads', () async {
      final uploadId = await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.updateUploadStatus(
        id: uploadId,
        status: 'failed',
        retryCount: 3,
      );

      await database.clearAllFailed();

      final failed = await database.getFailedUploads();

      expect(failed, isEmpty);
    });

    test('should get database stats', () async {
      await database.enqueueUpload(
        filePath: '/test/image.jpg',
        personId: 'P001',
        personName: 'Juan Pérez',
      );

      await database.recordUploadHistory(
        personId: 'P001',
        personName: 'Juan Pérez',
        documentType: 'CEDULA_CIUDADANIA',
        fileSize: 1024000,
        uploadDurationMs: 2500,
        wasOffline: false,
      );

      final stats = await database.getDatabaseStats();

      expect(stats['pending_uploads'], 1);
      expect(stats['history_entries'], 1);
      expect(stats['total_records'], 2);
    });
  });
}
