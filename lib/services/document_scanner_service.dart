import 'dart:io';
import 'package:flutter/material.dart';
import '../services/logger_adapter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

/// Document Scanner Service
/// Provides document cropping, compression and optimization functionality
class DocumentScannerService {
  final LoggerAdapter _logger = LoggerAdapter();

  /// Process image with interactive cropping
  Future<String?> cropImage(String imagePath) async {
    try {
      _logger.i('🖼️ Starting image crop: $imagePath');

      // Launch interactive cropper
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Documento',
            toolbarColor: const Color(0xFF1A237E), // Lumara primary color
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            activeControlsWidgetColor: const Color(0xFF00BCD4), // Lumara secondary
            hideBottomControls: false,
            cropGridColumnCount: 3,
            cropGridRowCount: 3,
            cropGridColor: Colors.white,
            cropGridStrokeWidth: 1,
            cropFrameColor: const Color(0xFF00BCD4),
            cropFrameStrokeWidth: 3,
          ),
          IOSUiSettings(
            title: 'Recortar Documento',
            doneButtonTitle: 'Listo',
            cancelButtonTitle: 'Cancelar',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null) {
        _logger.i('✅ Image cropped successfully: ${croppedFile.path}');

        // Optionally compress after cropping
        final compressed = await compressImage(croppedFile.path, quality: 90);
        return compressed;
      } else {
        _logger.w('⚠️ Cropping cancelled by user');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to crop image: $e', error: e, stackTrace: stackTrace);

      // Fallback: compress original image
      _logger.i('📦 Falling back to compression only');
      return await compressImage(imagePath, quality: 90);
    }
  }

  /// Compress an image
  Future<String> compressImage(String imagePath, {int quality = 85}) async {
    try {
      _logger.i('🗜️ Compressing image: $imagePath (quality: $quality)');

      // Read the image
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        _logger.e('❌ Failed to decode image');
        return imagePath;
      }

      // Resize if too large (max 1920px width)
      img.Image resized = image;
      if (image.width > 1920) {
        resized = img.copyResize(image, width: 1920);
        _logger.d('Resized image from ${image.width}x${image.height} to ${resized.width}x${resized.height}');
      }

      // Compress the image
      final compressed = img.encodeJpg(resized, quality: quality);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File('${tempDir.path}/$fileName');
      await compressedFile.writeAsBytes(compressed);

      final originalSize = await File(imagePath).length();
      final compressedSize = await compressedFile.length();
      final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      _logger.i('✅ Image compressed: ${compressedFile.path} (reduced by $reduction%)');
      return compressedFile.path;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to compress image: $e', error: e, stackTrace: stackTrace);
      return imagePath;
    }
  }

  /// Rotate an image
  Future<String?> rotateImage(String imagePath, {int degrees = 90}) async {
    try {
      _logger.i('🔄 Rotating image: $imagePath by $degrees°');

      // Read the image
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        _logger.e('❌ Failed to decode image');
        return null;
      }

      // Rotate image
      img.Image rotated;
      switch (degrees % 360) {
        case 90:
          rotated = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotated = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotated = img.copyRotate(image, angle: 270);
          break;
        default:
          _logger.w('⚠️ Invalid rotation angle: $degrees, using 90°');
          rotated = img.copyRotate(image, angle: 90);
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rotatedFile = File('${tempDir.path}/$fileName');

      // Encode and save
      final encoded = img.encodeJpg(rotated, quality: 90);
      await rotatedFile.writeAsBytes(encoded);

      _logger.i('✅ Image rotated: ${rotatedFile.path}');
      return rotatedFile.path;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to rotate image: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Process and compress an image
  Future<String?> cropAndCompress(String imagePath, {int quality = 85}) async {
    return await compressImage(imagePath, quality: quality);
  }
}
