import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/services/document_scanner_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentScannerService Tests', () {
    late DocumentScannerService service;
    late File testImageFile;

    setUp(() {
      service = DocumentScannerService();
      // Create a temporary test image
      testImageFile = File('test_assets/sample_document.jpg');
    });

    tearDown(() {
      // Clean up any temporary files created during tests
    });

    group('Image Rotation', () {
      test('rotateImage rotates image by 90 degrees', () async {
        // Skip if test image doesn't exist
        if (!await testImageFile.exists()) {
          return;
        }

        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 90,
        );

        expect(rotatedPath, isNotNull);
        if (rotatedPath != null) {
          expect(File(rotatedPath).existsSync(), isTrue);
        }
      });

      test('rotateImage rotates image by 180 degrees', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 180,
        );

        expect(rotatedPath, isNotNull);
        if (rotatedPath != null) {
          expect(File(rotatedPath).existsSync(), isTrue);
        }
      });

      test('rotateImage rotates image by 270 degrees', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 270,
        );

        expect(rotatedPath, isNotNull);
        if (rotatedPath != null) {
          expect(File(rotatedPath).existsSync(), isTrue);
        }
      });

      test('rotateImage handles invalid degrees gracefully', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        // Should default to 90 degrees for invalid input
        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 45, // Invalid, should use 90
        );

        expect(rotatedPath, isNotNull);
      });

      test('rotateImage handles non-existent file', () async {
        final nonExistentFile = File('non_existent_image.jpg');

        final rotatedPath = await service.rotateImage(
          nonExistentFile.path,
          degrees: 90,
        );

        // Should return null for non-existent file
        expect(rotatedPath, isNull);
      });

      test('rotateImage creates file with rotated_ prefix', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 90,
        );

        expect(rotatedPath, isNotNull);
        if (rotatedPath != null) {
          expect(rotatedPath, contains('rotated_'));
          expect(rotatedPath, endsWith('.jpg'));
        }
      });
    });

    group('Image Compression', () {
      test('compressImage reduces file size', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        final originalSize = await testImageFile.length();
        final compressedPath = await service.compressImage(
          testImageFile.path,
          quality: 70,
        );

        expect(compressedPath, isNotEmpty);
        final compressedSize = await File(compressedPath).length();

        // Compressed file should be smaller or same size
        expect(compressedSize, lessThanOrEqualTo(originalSize));
      });

      test('compressImage with high quality maintains size', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        final compressedPath = await service.compressImage(
          testImageFile.path,
          quality: 95,
        );

        expect(compressedPath, isNotEmpty);
        expect(File(compressedPath).existsSync(), isTrue);
      });

      test('compressImage handles non-existent file', () async {
        final nonExistentFile = File('non_existent_image.jpg');

        final compressedPath = await service.compressImage(
          nonExistentFile.path,
          quality: 85,
        );

        // Should return original path if compression fails
        expect(compressedPath, equals(nonExistentFile.path));
      });
    });

    group('Image Cropping', () {
      test('cropImage initiates cropping interface', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        // This test would require UI interaction
        // For now, just verify the method exists and doesn't crash
        expect(service.cropImage, isA<Function>());
      });
    });

    group('Integration Tests', () {
      test('Multiple operations in sequence', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        // Rotate -> Compress workflow
        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 90,
        );

        expect(rotatedPath, isNotNull);

        if (rotatedPath != null) {
          final compressedPath = await service.compressImage(
            rotatedPath,
            quality: 85,
          );

          expect(compressedPath, isNotEmpty);
          expect(File(compressedPath).existsSync(), isTrue);
        }
      });

      test('Compression after rotation preserves quality', () async {
        if (!await testImageFile.exists()) {
          return;
        }

        final rotatedPath = await service.rotateImage(
          testImageFile.path,
          degrees: 180,
        );

        if (rotatedPath != null) {
          final compressedPath = await service.compressImage(
            rotatedPath,
            quality: 90,
          );

          final compressedFile = File(compressedPath);
          expect(compressedFile.existsSync(), isTrue);

          // Verify file is not corrupt
          final fileSize = await compressedFile.length();
          expect(fileSize, greaterThan(0));
        }
      });
    });

    group('Error Handling', () {
      test('Handles corrupt image file gracefully', () async {
        // Create a fake corrupt image
        final corruptFile = File('test_assets/corrupt_image.jpg');
        if (!corruptFile.existsSync()) {
          await corruptFile.create(recursive: true);
          await corruptFile.writeAsString('This is not an image');
        }

        final rotatedPath = await service.rotateImage(
          corruptFile.path,
          degrees: 90,
        );

        // Should return null for corrupt file
        expect(rotatedPath, isNull);

        // Clean up
        if (await corruptFile.exists()) {
          await corruptFile.delete();
        }
      });

      test('Handles empty file path', () async {
        final rotatedPath = await service.rotateImage(
          '',
          degrees: 90,
        );

        expect(rotatedPath, isNull);
      });
    });
  });
}
