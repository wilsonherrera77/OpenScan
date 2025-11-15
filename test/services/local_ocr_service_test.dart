import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/services/local_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalOcrService Tests', () {
    late LocalOcrService service;

    setUp(() {
      service = LocalOcrService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization', () {
      test('Service initializes successfully', () {
        expect(service, isNotNull);
      });

      test('isAvailable returns true', () async {
        final available = await service.isAvailable();
        expect(available, isTrue);
      });
    });

    group('OCR Processing', () {
      test('processImage returns OcrResult', () async {
        // Skip if test image doesn't exist
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processImage(testImage.path);

        expect(result, isNotNull);
        expect(result, isA<OcrResult>());
      });

      test('processImage extracts text from image', () async {
        final testImage = File('test_assets/sample_cedula.jpg');
        if (!await testImage.exists()) {
          return;
        }

        final result = await service.processImage(testImage.path);

        expect(result.fullText, isNotEmpty);
        expect(result.isSuccessful, isTrue);
      });

      test('processImage handles non-existent file', () async {
        final result = await service.processImage('non_existent.jpg');

        expect(result.hasError, isTrue);
        expect(result.error, isNotNull);
      });

      test('processImage handles corrupt file', () async {
        // Create corrupt file
        final corruptFile = File('test_assets/corrupt.jpg');
        await corruptFile.create(recursive: true);
        await corruptFile.writeAsString('Not an image');

        final result = await service.processImage(corruptFile.path);

        // Should either error or return empty result
        expect(result.hasError || result.isEmpty, isTrue);

        // Cleanup
        if (await corruptFile.exists()) {
          await corruptFile.delete();
        }
      });
    });

    group('OcrResult', () {
      test('OcrResult isEmpty when fullText is empty', () {
        final result = OcrResult(
          fullText: '',
          confidence: 0.0,
          processingTime: Duration.zero,
        );

        expect(result.isEmpty, isTrue);
        expect(result.isSuccessful, isFalse);
      });

      test('OcrResult isSuccessful when has text and no error', () {
        final result = OcrResult(
          fullText: 'Test text',
          confidence: 0.9,
          processingTime: const Duration(seconds: 1),
        );

        expect(result.isEmpty, isFalse);
        expect(result.hasError, isFalse);
        expect(result.isSuccessful, isTrue);
      });

      test('OcrResult confidencePercent converts correctly', () {
        final result = OcrResult(
          fullText: 'Test',
          confidence: 0.75,
          processingTime: Duration.zero,
        );

        expect(result.confidencePercent, equals(75));
      });

      test('OcrResult toString contains key information', () {
        final result = OcrResult(
          fullText: 'Test text',
          confidence: 0.85,
          processingTime: const Duration(milliseconds: 500),
        );

        final str = result.toString();
        expect(str, contains('chars:'));
        expect(str, contains('confidence:'));
        expect(str, contains('85%'));
        expect(str, contains('500ms'));
      });
    });
  });
}
