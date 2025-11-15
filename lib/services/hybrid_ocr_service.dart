import 'dart:io';
import '../services/logger_adapter.dart';
import 'local_ocr_service.dart';
import 'document_type_detector.dart';
import 'field_extractor.dart';

/// Hybrid OCR Service
/// Combines local OCR (Google ML Kit) with cloud OCR (OpenAI) fallback
///
/// Strategy:
/// 1. Try local OCR first (fast, free, offline)
/// 2. If confidence < 70%, fallback to cloud OCR
/// 3. Always prefer local for privacy and cost
///
/// Benefits:
/// - Works offline (critical for rural areas)
/// - Reduces API costs ~50-70%
/// - Faster processing (local)
/// - Better privacy (data doesn't leave device when local works)
class HybridOcrService {
  final LoggerAdapter _logger = LoggerAdapter();
  final LocalOcrService _localOcr;
  final DocumentTypeDetector _typeDetector;
  final FieldExtractor _fieldExtractor;

  // Configuration
  static const double minLocalConfidence = 0.70; // 70% minimum for local-only
  static const int maxRetries = 2;

  HybridOcrService({
    LocalOcrService? localOcr,
    DocumentTypeDetector? typeDetector,
    FieldExtractor? fieldExtractor,
  })  : _localOcr = localOcr ?? LocalOcrService(),
        _typeDetector = typeDetector ?? DocumentTypeDetector(),
        _fieldExtractor = fieldExtractor ?? FieldExtractor();

  /// Process document with hybrid approach
  Future<HybridOcrResult> processDocument(
    String imagePath, {
    String? expectedDocumentType,
    bool forceCloud = false,
  }) async {
    final startTime = DateTime.now();

    try {
      _logger.i('🔄 Starting hybrid OCR: $imagePath');

      // Step 1: Try local OCR first (unless forced to use cloud)
      if (!forceCloud) {
        _logger.i('📱 Attempting local OCR (Google ML Kit)...');
        final localResult = await _localOcr.processImage(imagePath);

        if (localResult.isSuccessful) {
          _logger.i('✅ Local OCR successful (${localResult.fullText.length} chars)');

          // Detect document type
          final typeDetection = _typeDetector.detectType(localResult);

          // Validate confidence
          final isConfident = localResult.confidence >= minLocalConfidence &&
              typeDetection.isConfident;

          if (isConfident) {
            _logger.i('✅ Local OCR confidence OK (${localResult.confidencePercent}%)');

            // Extract fields
            final fields = _fieldExtractor.extractFields(
              localResult,
              typeDetection.type,
            );

            final duration = DateTime.now().difference(startTime);

            return HybridOcrResult(
              fullText: localResult.fullText,
              documentType: typeDetection.type,
              documentTypeLabel: typeDetection.label,
              fields: fields,
              confidence: localResult.confidence,
              processingTime: duration,
              source: OcrSource.local,
              costSavings: 100, // 100% savings (didn't use cloud)
            );
          } else {
            _logger.w(
              '⚠️ Local OCR confidence too low (${localResult.confidencePercent}%), trying cloud...',
            );
          }
        } else {
          _logger.w('⚠️ Local OCR failed, trying cloud...');
        }
      } else {
        _logger.i('☁️ Cloud OCR forced by user');
      }

      // Step 2: Fallback to cloud OCR
      _logger.i('☁️ Using cloud OCR (OpenAI)...');
      final cloudResult = await _processWithCloudOcr(
        imagePath,
        expectedDocumentType,
      );

      final duration = DateTime.now().difference(startTime);

      return HybridOcrResult(
        fullText: cloudResult['text'] ?? '',
        documentType: cloudResult['document_type'] ?? 'OTRO_DOCUMENTO',
        documentTypeLabel: cloudResult['document_type_label'] ?? 'Otro Documento',
        fields: cloudResult['fields'] ?? {},
        confidence: 0.95, // Cloud OCR assumed high confidence
        processingTime: duration,
        source: OcrSource.cloud,
        costSavings: 0, // No savings (used cloud)
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Hybrid OCR failed', error: e, stackTrace: stackTrace);

      final duration = DateTime.now().difference(startTime);

      return HybridOcrResult(
        fullText: '',
        documentType: 'OTRO_DOCUMENTO',
        documentTypeLabel: 'Otro Documento',
        fields: {},
        confidence: 0.0,
        processingTime: duration,
        source: OcrSource.failed,
        error: e.toString(),
      );
    }
  }

  /// Process with cloud OCR (OpenAI)
  /// This would integrate with existing OpenAI implementation
  Future<Map<String, dynamic>> _processWithCloudOcr(
    String imagePath,
    String? expectedDocumentType,
  ) async {
    // TODO: Integrate with existing OpenAI OCR implementation
    // For now, return placeholder
    _logger.w('⚠️ Cloud OCR not yet integrated - returning placeholder');

    return {
      'text': 'Cloud OCR placeholder - Integration pending',
      'document_type': expectedDocumentType ?? 'OTRO_DOCUMENTO',
      'document_type_label': 'Otro Documento',
      'fields': {},
    };
  }

  /// Get statistics about OCR usage
  Future<OcrStatistics> getStatistics() async {
    // TODO: Implement statistics tracking
    return OcrStatistics(
      totalProcessed: 0,
      localSuccess: 0,
      cloudFallback: 0,
      totalCostSavings: 0.0,
    );
  }

  /// Dispose resources
  void dispose() {
    _localOcr.dispose();
  }
}

/// Hybrid OCR Result
class HybridOcrResult {
  final String fullText;
  final String documentType;
  final String documentTypeLabel;
  final Map<String, dynamic> fields;
  final double confidence;
  final Duration processingTime;
  final OcrSource source;
  final int costSavings; // Percentage saved (0-100)
  final String? error;

  HybridOcrResult({
    required this.fullText,
    required this.documentType,
    required this.documentTypeLabel,
    required this.fields,
    required this.confidence,
    required this.processingTime,
    required this.source,
    this.costSavings = 0,
    this.error,
  });

  bool get hasError => error != null;
  bool get isSuccessful => !hasError && fullText.isNotEmpty;
  bool get usedLocalOcr => source == OcrSource.local;
  bool get usedCloudOcr => source == OcrSource.cloud;

  int get confidencePercent => (confidence * 100).round();

  @override
  String toString() {
    return 'HybridOcrResult('
        'source: $source, '
        'type: $documentTypeLabel, '
        'confidence: $confidencePercent%, '
        'time: ${processingTime.inSeconds}s, '
        'savings: $costSavings%'
        ')';
  }
}

/// OCR Source
enum OcrSource {
  local, // Google ML Kit
  cloud, // OpenAI
  failed, // Both failed
}

/// OCR Statistics
class OcrStatistics {
  final int totalProcessed;
  final int localSuccess;
  final int cloudFallback;
  final double totalCostSavings; // In currency

  OcrStatistics({
    required this.totalProcessed,
    required this.localSuccess,
    required this.cloudFallback,
    required this.totalCostSavings,
  });

  double get localSuccessRate =>
      totalProcessed > 0 ? localSuccess / totalProcessed : 0.0;

  int get localSuccessPercent => (localSuccessRate * 100).round();

  @override
  String toString() {
    return 'OcrStatistics('
        'total: $totalProcessed, '
        'local: $localSuccess ($localSuccessPercent%), '
        'cloud: $cloudFallback, '
        'savings: \$${totalCostSavings.toStringAsFixed(2)}'
        ')';
  }
}
