import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../services/logger_adapter.dart';

/// Image Quality Checker
/// Validates image quality before upload to ensure good OCR results
class ImageQualityChecker {
  final LoggerAdapter _logger = LoggerAdapter();

  // Quality thresholds
  static const int minWidth = 800;
  static const int minHeight = 600;
  static const int recommendedWidth = 1920;
  static const int recommendedHeight = 1440;
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const double minBrightnessScore = 30.0; // 0-255 scale
  static const double maxBrightnessScore = 225.0;
  static const double minSharpnessScore = 10.0; // Lower = blurrier

  /// Check image quality
  Future<ImageQualityResult> checkQuality(String filePath) async {
    try {
      _logger.d('📸 Checking image quality: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        return ImageQualityResult(
          isAcceptable: false,
          score: 0,
          issues: ['File not found'],
        );
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        return ImageQualityResult(
          isAcceptable: false,
          score: 0,
          issues: ['File size too large (${_formatBytes(fileSize)})'],
        );
      }

      // Load image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return ImageQualityResult(
          isAcceptable: false,
          score: 0,
          issues: ['Invalid image format'],
        );
      }

      final issues = <String>[];
      final warnings = <String>[];
      var score = 100.0;

      // Check resolution
      final resolutionCheck = _checkResolution(image);
      issues.addAll(resolutionCheck.issues);
      warnings.addAll(resolutionCheck.warnings);
      score *= resolutionCheck.score / 100;

      // Check brightness
      final brightnessCheck = _checkBrightness(image);
      issues.addAll(brightnessCheck.issues);
      warnings.addAll(brightnessCheck.warnings);
      score *= brightnessCheck.score / 100;

      // Check sharpness (blur detection)
      final sharpnessCheck = _checkSharpness(image);
      issues.addAll(sharpnessCheck.issues);
      warnings.addAll(sharpnessCheck.warnings);
      score *= sharpnessCheck.score / 100;

      // Check aspect ratio
      final aspectCheck = _checkAspectRatio(image);
      warnings.addAll(aspectCheck.warnings);
      score *= aspectCheck.score / 100;

      final isAcceptable = issues.isEmpty && score >= 50;

      _logger.i('Quality score: ${score.toInt()}% ${isAcceptable ? '✅' : '❌'}');

      return ImageQualityResult(
        isAcceptable: isAcceptable,
        score: score.toInt(),
        issues: issues,
        warnings: warnings,
        width: image.width,
        height: image.height,
        fileSize: fileSize,
      );
    } catch (e) {
      _logger.e('Error checking image quality: $e');
      return ImageQualityResult(
        isAcceptable: false,
        score: 0,
        issues: ['Error analyzing image: $e'],
      );
    }
  }

  /// Check image resolution
  QualityCheck _checkResolution(img.Image image) {
    final issues = <String>[];
    final warnings = <String>[];
    var score = 100.0;

    if (image.width < minWidth || image.height < minHeight) {
      issues.add(
        'Resolution too low (${image.width}x${image.height}). Minimum: ${minWidth}x$minHeight',
      );
      score = 0;
    } else if (image.width < recommendedWidth || image.height < recommendedHeight) {
      warnings.add(
        'Low resolution (${image.width}x${image.height}). Recommended: ${recommendedWidth}x$recommendedHeight for better OCR',
      );
      score = 70;
    }

    return QualityCheck(score: score, issues: issues, warnings: warnings);
  }

  /// Check image brightness
  QualityCheck _checkBrightness(img.Image image) {
    final issues = <String>[];
    final warnings = <String>[];
    var score = 100.0;

    // Sample pixels to calculate average brightness
    final sampleSize = (image.width * image.height / 1000).ceil();
    var totalBrightness = 0.0;

    for (var i = 0; i < sampleSize; i++) {
      final x = (i * 1000) % image.width;
      final y = ((i * 1000) ~/ image.width) % image.height;
      final pixel = image.getPixel(x, y);

      // Calculate luminance
      final r = pixel.r as num;
      final g = pixel.g as num;
      final b = pixel.b as num;
      final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
      totalBrightness += brightness;
    }

    final avgBrightness = totalBrightness / sampleSize;

    if (avgBrightness < minBrightnessScore) {
      issues.add(
        'Image too dark (brightness: ${avgBrightness.toInt()}/255). Use better lighting',
      );
      score = 0;
    } else if (avgBrightness > maxBrightnessScore) {
      issues.add(
        'Image overexposed (brightness: ${avgBrightness.toInt()}/255). Reduce lighting',
      );
      score = 0;
    } else if (avgBrightness < 60) {
      warnings.add('Image is somewhat dark. Better lighting may improve OCR quality');
      score = 70;
    } else if (avgBrightness > 195) {
      warnings.add('Image is very bright. This may affect OCR quality');
      score = 70;
    }

    return QualityCheck(score: score, issues: issues, warnings: warnings);
  }

  /// Check image sharpness (blur detection)
  QualityCheck _checkSharpness(img.Image image) {
    final warnings = <String>[];
    var score = 100.0;

    // Simplified Laplacian variance for blur detection
    // Higher variance = sharper image
    final variance = _calculateLaplacianVariance(image);

    if (variance < minSharpnessScore) {
      warnings.add(
        'Image appears blurry (sharpness: ${variance.toInt()}). Hold camera steady',
      );
      score = 50;
    }

    return QualityCheck(score: score, issues: [], warnings: warnings);
  }

  /// Calculate Laplacian variance (blur metric)
  double _calculateLaplacianVariance(img.Image image) {
    // Resize to small size for faster processing
    final small = img.copyResize(image, width: 200);

    var sum = 0.0;
    var sumSquared = 0.0;
    var count = 0;

    // Simple Laplacian kernel
    for (var y = 1; y < small.height - 1; y++) {
      for (var x = 1; x < small.width - 1; x++) {
        final center = _getGrayscale(small.getPixel(x, y));
        final top = _getGrayscale(small.getPixel(x, y - 1));
        final bottom = _getGrayscale(small.getPixel(x, y + 1));
        final left = _getGrayscale(small.getPixel(x - 1, y));
        final right = _getGrayscale(small.getPixel(x + 1, y));

        final laplacian = (4 * center - top - bottom - left - right).abs();

        sum += laplacian;
        sumSquared += laplacian * laplacian;
        count++;
      }
    }

    final mean = sum / count;
    final variance = (sumSquared / count) - (mean * mean);

    return variance;
  }

  /// Check aspect ratio
  QualityCheck _checkAspectRatio(img.Image image) {
    final warnings = <String>[];
    var score = 100.0;

    final aspectRatio = image.width / image.height;

    // Very wide or very tall images might be cut or poorly captured
    if (aspectRatio > 3 || aspectRatio < 0.33) {
      warnings.add(
        'Unusual aspect ratio (${aspectRatio.toStringAsFixed(2)}). Document might be cut',
      );
      score = 80;
    }

    return QualityCheck(score: score, issues: [], warnings: warnings);
  }

  /// Get grayscale value from pixel
  double _getGrayscale(img.Pixel pixel) {
    final r = pixel.r as num;
    final g = pixel.g as num;
    final b = pixel.b as num;
    return (0.299 * r + 0.587 * g + 0.114 * b);
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Quality Check Result
class QualityCheck {
  final double score;
  final List<String> issues;
  final List<String> warnings;

  QualityCheck({
    required this.score,
    required this.issues,
    required this.warnings,
  });
}

/// Image Quality Result
class ImageQualityResult {
  final bool isAcceptable;
  final int score; // 0-100
  final List<String> issues; // Critical issues (blocking)
  final List<String> warnings; // Non-critical warnings
  final int? width;
  final int? height;
  final int? fileSize;

  ImageQualityResult({
    required this.isAcceptable,
    required this.score,
    required this.issues,
    this.warnings = const [],
    this.width,
    this.height,
    this.fileSize,
  });

  /// Get quality level text
  String get qualityLevel {
    if (score >= 90) return 'Excelente';
    if (score >= 75) return 'Buena';
    if (score >= 60) return 'Aceptable';
    if (score >= 40) return 'Regular';
    return 'Mala';
  }

  /// Get quality color
  String get qualityColor {
    if (score >= 75) return 'green';
    if (score >= 60) return 'orange';
    return 'red';
  }

  /// Format for display
  String get summary {
    final parts = <String>[];

    if (width != null && height != null) {
      parts.add('${width}x$height px');
    }

    parts.add('Calidad: $qualityLevel ($score%)');

    return parts.join(' • ');
  }
}
