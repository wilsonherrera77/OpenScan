import '../services/logger_adapter.dart';
import 'local_ocr_service.dart';

/// Field Extractor
/// Extracts specific fields from OCR text based on document type
///
/// Supported fields:
/// - Document number (números de identificación)
/// - Names (nombres completos)
/// - Dates (fechas de nacimiento, expedición)
/// - Places (lugares de nacimiento, expedición)
class FieldExtractor {
  final LoggerAdapter _logger = LoggerAdapter();

  /// Extract fields based on document type
  Map<String, dynamic> extractFields(OcrResult ocrResult, String documentType) {
    final text = ocrResult.fullText;
    final lines = ocrResult.lines;

    _logger.d('🔍 Extracting fields for $documentType');

    final fields = <String, dynamic>{};

    // Extract common fields
    fields['document_number'] = _extractDocumentNumber(text, documentType);
    fields['names'] = _extractNames(text, lines);
    fields['dates'] = _extractDates(text);
    fields['places'] = _extractPlaces(text);

    // Document-specific extractions
    switch (documentType) {
      case 'CEDULA_CIUDADANIA':
      case 'TARJETA_IDENTIDAD':
        fields['identification_number'] = _extractIdentificationNumber(text);
        fields['expedition_date'] = _extractExpeditionDate(text);
        fields['expedition_place'] = _extractExpeditionPlace(text);
        break;

      case 'REGISTRO_CIVIL':
        fields['birth_date'] = _extractBirthDate(text);
        fields['birth_place'] = _extractBirthPlace(text);
        fields['parents'] = _extractParents(text, lines);
        break;

      case 'CERTIFICADO_AFILIACION_EPS':
        fields['eps_name'] = _extractEpsName(text);
        fields['regime'] = _extractRegime(text);
        fields['affiliation_date'] = _extractAffiliationDate(text);
        break;
    }

    _logger.i('✅ Extracted ${fields.length} fields');
    return fields;
  }

  /// Extract document number (generic)
  String? _extractDocumentNumber(String text, String documentType) {
    // Pattern for Colombian ID numbers (6-10 digits)
    final patterns = [
      RegExp(r'\b(\d{6,10})\b'),
      RegExp(r'(?:no\.?|número|numero|doc\.?)\s*[:.]?\s*(\d{6,10})', caseSensitive: false),
      RegExp(r'nuip\s*[:.]?\s*(\d{6,10})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Extract identification number (specific for cédula/tarjeta)
  String? _extractIdentificationNumber(String text) {
    final patterns = [
      RegExp(r'(?:cédula|cedula|cc)\s*(?:no\.?|número|numero)?\s*[:.]?\s*(\d{6,10})', caseSensitive: false),
      RegExp(r'\b(\d{8,10})\b'), // 8-10 digit numbers (most cédulas)
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final number = match.group(1)!;
        // Validate length (Colombian cédulas are 6-10 digits)
        if (number.length >= 6 && number.length <= 10) {
          return number;
        }
      }
    }

    return null;
  }

  /// Extract names (full names)
  List<String> _extractNames(String text, List<String> lines) {
    final names = <String>[];

    // Pattern for name lines (typically after "nombre" or "nombres")
    final namePatterns = [
      RegExp(r'(?:nombre|nombres|apellidos?)\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s]{3,50})', caseSensitive: false),
      RegExp(r'(?:titular|beneficiario)\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s]{3,50})', caseSensitive: false),
    ];

    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length >= 3) {
          names.add(name);
        }
      }
    }

    return names;
  }

  /// Extract dates (generic date extraction)
  List<String> _extractDates(String text) {
    final dates = <String>[];

    // Common date patterns in Colombia
    final datePatterns = [
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'), // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'\b(\d{1,2})\s+de\s+([a-záéíóúñ]+)\s+de\s+(\d{4})\b', caseSensitive: false), // DD de MONTH de YYYY
    ];

    for (final pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        dates.add(match.group(0)!);
      }
    }

    return dates;
  }

  /// Extract birth date
  String? _extractBirthDate(String text) {
    final pattern = RegExp(
      r'(?:fecha\s+de\s+)?nac(?:imiento)?\s*[:.]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  /// Extract expedition date
  String? _extractExpeditionDate(String text) {
    final pattern = RegExp(
      r'(?:fecha\s+de\s+)?exp(?:edición|edicion)?\s*[:.]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  /// Extract affiliation date (for EPS)
  String? _extractAffiliationDate(String text) {
    final pattern = RegExp(
      r'(?:fecha\s+de\s+)?afiliación\s*[:.]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  /// Extract places (generic)
  List<String> _extractPlaces(String text) {
    final places = <String>[];

    // Common Colombian cities and departments
    final placePattern = RegExp(
      r'\b(bogotá|medellín|cali|barranquilla|cartagena|cúcuta|bucaramanga|pereira|'
      r'antioquia|cundinamarca|valle|atlántico|bolívar|santander|risaralda)\b',
      caseSensitive: false,
    );

    final matches = placePattern.allMatches(text);
    for (final match in matches) {
      places.add(match.group(0)!);
    }

    return places;
  }

  /// Extract birth place
  String? _extractBirthPlace(String text) {
    final pattern = RegExp(
      r'(?:lugar\s+de\s+)?nac(?:imiento)?\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s,]{3,50})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Extract expedition place
  String? _extractExpeditionPlace(String text) {
    final pattern = RegExp(
      r'(?:lugar\s+de\s+)?exp(?:edición|edicion)?\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s,]{3,50})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Extract parents (for registro civil)
  Map<String, String?> _extractParents(String text, List<String> lines) {
    final parents = <String, String?>{
      'mother': null,
      'father': null,
    };

    // Pattern for mother
    final motherPattern = RegExp(
      r'(?:madre|mamá)\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s]{3,50})',
      caseSensitive: false,
    );
    final motherMatch = motherPattern.firstMatch(text);
    if (motherMatch != null) {
      parents['mother'] = motherMatch.group(1)?.trim();
    }

    // Pattern for father
    final fatherPattern = RegExp(
      r'(?:padre|papá)\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s]{3,50})',
      caseSensitive: false,
    );
    final fatherMatch = fatherPattern.firstMatch(text);
    if (fatherMatch != null) {
      parents['father'] = fatherMatch.group(1)?.trim();
    }

    return parents;
  }

  /// Extract EPS name
  String? _extractEpsName(String text) {
    final pattern = RegExp(
      r'(?:eps|entidad)\s*[:.]?\s*([A-ZÁÉÍÓÚÑ\s]{3,50})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Extract regime (contributivo/subsidiado)
  String? _extractRegime(String text) {
    if (text.toLowerCase().contains('contributivo')) {
      return 'Contributivo';
    } else if (text.toLowerCase().contains('subsidiado')) {
      return 'Subsidiado';
    }
    return null;
  }
}
