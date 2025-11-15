import '../services/logger_adapter.dart';
import 'local_ocr_service.dart';

/// Document Type Detector
/// Analyzes OCR text to automatically detect document type
///
/// Supported document types:
/// - Cédula de Ciudadanía
/// - Tarjeta de Identidad
/// - Registro Civil de Nacimiento
/// - Registro Civil de Matrimonio
/// - Registro Civil de Defunción
/// - Certificado EPS
/// - Certificado de Estudio
class DocumentTypeDetector {
  final LoggerAdapter _logger = LoggerAdapter();

  /// Detect document type from OCR result
  DocumentTypeDetection detectType(OcrResult ocrResult) {
    final text = ocrResult.fullText.toLowerCase();
    final lines = ocrResult.lines.map((l) => l.toLowerCase()).toList();

    _logger.d('🔍 Detecting document type from ${text.length} chars');

    // Check each document type
    for (final detector in _detectors) {
      final confidence = detector.match(text, lines);
      if (confidence > 0.5) {
        _logger.i('✅ Detected: ${detector.type} (${(confidence * 100).toInt()}%)');
        return DocumentTypeDetection(
          type: detector.type,
          confidence: confidence,
          keywords: detector.keywords,
        );
      }
    }

    _logger.w('⚠️ Could not detect document type');
    return DocumentTypeDetection(
      type: 'OTRO_DOCUMENTO',
      confidence: 0.0,
      keywords: [],
    );
  }

  /// List of document type detectors
  static final List<_DocumentTypeDetector> _detectors = [
    _DocumentTypeDetector(
      type: 'CEDULA_CIUDADANIA',
      keywords: [
        'república de colombia',
        'cédula de ciudadanía',
        'cedula de ciudadania',
        'registraduría',
        'registraduria',
        'nuip',
        'documento de identidad',
      ],
      requiredKeywords: ['cédula', 'cedula', 'ciudadanía', 'ciudadania'],
      minMatches: 2,
    ),
    _DocumentTypeDetector(
      type: 'TARJETA_IDENTIDAD',
      keywords: [
        'tarjeta de identidad',
        'república de colombia',
        'registraduría',
        'registraduria',
        'menor de edad',
      ],
      requiredKeywords: ['tarjeta', 'identidad'],
      minMatches: 2,
    ),
    _DocumentTypeDetector(
      type: 'REGISTRO_CIVIL',
      keywords: [
        'registro civil',
        'nacimiento',
        'registraduría',
        'registraduria',
        'república de colombia',
        'registro nacional',
      ],
      requiredKeywords: ['registro', 'civil'],
      minMatches: 2,
    ),
    _DocumentTypeDetector(
      type: 'CERTIFICADO_MATRIMONIO',
      keywords: [
        'registro civil',
        'matrimonio',
        'acta de matrimonio',
        'contrayentes',
        'registraduría',
        'esposo',
        'esposa',
      ],
      requiredKeywords: ['matrimonio'],
      minMatches: 2,
    ),
    _DocumentTypeDetector(
      type: 'CERTIFICADO_DEFUNCION',
      keywords: [
        'registro civil',
        'defunción',
        'defuncion',
        'acta de defunción',
        'fallecimiento',
        'registraduría',
      ],
      requiredKeywords: ['defunción', 'defuncion', 'fallecimiento'],
      minMatches: 2,
    ),
    _DocumentTypeDetector(
      type: 'CERTIFICADO_AFILIACION_EPS',
      keywords: [
        'eps',
        'salud',
        'afiliación',
        'afiliacion',
        'certificado',
        'entidad promotora',
        'régimen',
        'regimen',
        'subsidiado',
        'contributivo',
      ],
      requiredKeywords: ['eps', 'salud', 'afiliación', 'afiliacion'],
      minMatches: 2,
    ),
    _DocumentTypeDetector(
      type: 'CERTIFICADO_ESTUDIO',
      keywords: [
        'certificado',
        'estudio',
        'estudios',
        'institución',
        'institucion',
        'educativa',
        'colegio',
        'escuela',
        'universidad',
        'grado',
        'curso',
      ],
      requiredKeywords: ['certificado', 'estudio', 'estudios'],
      minMatches: 2,
    ),
  ];
}

/// Internal document type detector
class _DocumentTypeDetector {
  final String type;
  final List<String> keywords;
  final List<String> requiredKeywords;
  final int minMatches;

  _DocumentTypeDetector({
    required this.type,
    required this.keywords,
    this.requiredKeywords = const [],
    this.minMatches = 2,
  });

  /// Calculate match confidence (0.0 to 1.0)
  double match(String fullText, List<String> lines) {
    var matchCount = 0;
    var requiredMatchCount = 0;

    // Check all keywords
    for (final keyword in keywords) {
      if (fullText.contains(keyword)) {
        matchCount++;
      }
    }

    // Check required keywords
    for (final required in requiredKeywords) {
      if (fullText.contains(required)) {
        requiredMatchCount++;
      }
    }

    // Must have at least one required keyword
    if (requiredKeywords.isNotEmpty && requiredMatchCount == 0) {
      return 0.0;
    }

    // Must have minimum matches
    if (matchCount < minMatches) {
      return 0.0;
    }

    // Calculate confidence based on match ratio
    final confidence = matchCount / keywords.length;

    // Boost confidence if has required keywords
    final boostedConfidence = requiredMatchCount > 0
        ? confidence * (1.0 + (requiredMatchCount / requiredKeywords.length) * 0.5)
        : confidence;

    return boostedConfidence.clamp(0.0, 1.0);
  }
}

/// Document type detection result
class DocumentTypeDetection {
  final String type;
  final double confidence;
  final List<String> keywords;

  DocumentTypeDetection({
    required this.type,
    required this.confidence,
    required this.keywords,
  });

  bool get isConfident => confidence >= 0.7;
  int get confidencePercent => (confidence * 100).round();

  /// Get human-readable label
  String get label {
    const typeLabels = {
      'CEDULA_CIUDADANIA': 'Cédula de Ciudadanía',
      'TARJETA_IDENTIDAD': 'Tarjeta de Identidad',
      'REGISTRO_CIVIL': 'Registro Civil de Nacimiento',
      'CERTIFICADO_MATRIMONIO': 'Registro Civil de Matrimonio',
      'CERTIFICADO_DEFUNCION': 'Registro Civil de Defunción',
      'CERTIFICADO_AFILIACION_EPS': 'Certificado EPS',
      'CERTIFICADO_ESTUDIO': 'Certificado de Estudio',
      'OTRO_DOCUMENTO': 'Otro Documento',
    };

    return typeLabels[type] ?? type;
  }

  @override
  String toString() {
    return 'DocumentTypeDetection(type: $label, confidence: $confidencePercent%)';
  }
}
