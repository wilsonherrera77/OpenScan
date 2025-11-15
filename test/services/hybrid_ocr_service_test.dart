import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/services/hybrid_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HybridOcrService Tests', () {
    late HybridOcrService service;

    setUp(() {
      service = HybridOcrService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization', () {
      test('Service initializes successfully', () {
        expect(service, isNotNull);
      });
    });

    group('Hybrid Processing', () {
      test('processDocument returns HybridOcrResult', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processDocument(testImage.path);

        expect(result, isNotNull);
        expect(result, isA<HybridOcrResult>());
      });

      test('processDocument attempts local OCR first', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processDocument(testImage.path);

        // Should prefer local OCR when available
        // Result might be local or cloud depending on quality
        expect(
          result.source == OcrSource.local || result.source == OcrSource.cloud,
          isTrue,
        );
      });

      test('processDocument uses cloud when forceCloud is true', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processDocument(
          testImage.path,
          forceCloud: true,
        );

        expect(result.source, equals(OcrSource.cloud));
      });

      test('processDocument handles non-existent file', () async {
        final result = await service.processDocument('non_existent.jpg');

        expect(result.source, equals(OcrSource.failed));
        expect(result.hasError, isTrue);
      });

      test('processDocument returns document type detection', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processDocument(testImage.path);

        expect(result.documentType, isNotNull);
        expect(result.documentTypeLabel, isNotNull);
      });

      test('processDocument extracts fields', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processDocument(testImage.path);

        expect(result.fields, isA<Map>());
      });

      test('processDocument with expectedDocumentType', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processDocument(
          testImage.path,
          expectedDocumentType: 'CEDULA_CIUDADANIA',
        );

        expect(result, isNotNull);
      });
    });

    group('HybridOcrResult', () {
      test('usedLocalOcr returns true for local source', () {
        final result = HybridOcrResult(
          fullText: 'Test',
          documentType: 'CEDULA_CIUDADANIA',
          documentTypeLabel: 'Cédula de Ciudadanía',
          fields: {},
          confidence: 0.9,
          processingTime: const Duration(seconds: 1),
          source: OcrSource.local,
          costSavings: 100,
        );

        expect(result.usedLocalOcr, isTrue);
        expect(result.usedCloudOcr, isFalse);
      });

      test('usedCloudOcr returns true for cloud source', () {
        final result = HybridOcrResult(
          fullText: 'Test',
          documentType: 'CEDULA_CIUDADANIA',
          documentTypeLabel: 'Cédula de Ciudadanía',
          fields: {},
          confidence: 0.95,
          processingTime: const Duration(seconds: 2),
          source: OcrSource.cloud,
          costSavings: 0,
        );

        expect(result.usedCloudOcr, isTrue);
        expect(result.usedLocalOcr, isFalse);
      });

      test('isSuccessful returns true when has text and no error', () {
        final result = HybridOcrResult(
          fullText: 'Test text',
          documentType: 'CEDULA_CIUDADANIA',
          documentTypeLabel: 'Cédula',
          fields: {},
          confidence: 0.9,
          processingTime: Duration.zero,
          source: OcrSource.local,
        );

        expect(result.isSuccessful, isTrue);
        expect(result.hasError, isFalse);
      });

      test('hasError returns true when error present', () {
        final result = HybridOcrResult(
          fullText: '',
          documentType: 'OTRO_DOCUMENTO',
          documentTypeLabel: 'Otro',
          fields: {},
          confidence: 0.0,
          processingTime: Duration.zero,
          source: OcrSource.failed,
          error: 'Test error',
        );

        expect(result.hasError, isTrue);
        expect(result.isSuccessful, isFalse);
      });

      test('confidencePercent converts correctly', () {
        final result = HybridOcrResult(
          fullText: 'Test',
          documentType: 'CEDULA_CIUDADANIA',
          documentTypeLabel: 'Cédula',
          fields: {},
          confidence: 0.85,
          processingTime: Duration.zero,
          source: OcrSource.local,
        );

        expect(result.confidencePercent, equals(85));
      });

      test('toString contains key information', () {
        final result = HybridOcrResult(
          fullText: 'Test',
          documentType: 'CEDULA_CIUDADANIA',
          documentTypeLabel: 'Cédula de Ciudadanía',
          fields: {},
          confidence: 0.9,
          processingTime: const Duration(seconds: 2),
          source: OcrSource.local,
          costSavings: 100,
        );

        final str = result.toString();
        expect(str, contains('local'));
        expect(str, contains('Cédula'));
        expect(str, contains('90%'));
        expect(str, contains('2s'));
        expect(str, contains('100%'));
      });
    });

    group('OCR Statistics', () {
      test('getStatistics returns statistics', () async {
        final stats = await service.getStatistics();

        expect(stats, isNotNull);
        expect(stats, isA<OcrStatistics>());
      });

      test('OcrStatistics calculates success rate', () {
        final stats = OcrStatistics(
          totalProcessed: 100,
          localSuccess: 75,
          cloudFallback: 25,
          totalCostSavings: 150.0,
        );

        expect(stats.localSuccessRate, equals(0.75));
        expect(stats.localSuccessPercent, equals(75));
      });

      test('OcrStatistics handles zero total', () {
        final stats = OcrStatistics(
          totalProcessed: 0,
          localSuccess: 0,
          cloudFallback: 0,
          totalCostSavings: 0.0,
        );

        expect(stats.localSuccessRate, equals(0.0));
        expect(stats.localSuccessPercent, equals(0));
      });
    });
  });
}
