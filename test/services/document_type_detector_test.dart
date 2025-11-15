import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/services/document_type_detector.dart';
import 'package:lumara_scan/services/local_ocr_service.dart';

void main() {
  group('DocumentTypeDetector Tests', () {
    late DocumentTypeDetector detector;

    setUp(() {
      detector = DocumentTypeDetector();
    });

    group('Cédula de Ciudadanía Detection', () {
      test('Detects cédula from typical text', () {
        final ocrResult = OcrResult(
          fullText: 'república de colombia\ncédula de ciudadanía\nregistraduría nacional\nnuip 1234567890',
          lines: ['república de colombia', 'cédula de ciudadanía'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('CEDULA_CIUDADANIA'));
        expect(detection.isConfident, isTrue);
      });

      test('Detects cédula with alternate spellings', () {
        final ocrResult = OcrResult(
          fullText: 'cedula de ciudadania colombia registraduria',
          lines: ['cedula de ciudadania'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('CEDULA_CIUDADANIA'));
      });
    });

    group('Tarjeta de Identidad Detection', () {
      test('Detects tarjeta de identidad', () {
        final ocrResult = OcrResult(
          fullText: 'república de colombia\ntarjeta de identidad\nmenor de edad',
          lines: ['tarjeta de identidad'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('TARJETA_IDENTIDAD'));
        expect(detection.label, equals('Tarjeta de Identidad'));
      });
    });

    group('Registro Civil Detection', () {
      test('Detects registro civil de nacimiento', () {
        final ocrResult = OcrResult(
          fullText: 'registro civil de nacimiento\nrepública de colombia\nregistraduría nacional',
          lines: ['registro civil', 'nacimiento'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('REGISTRO_CIVIL'));
      });
    });

    group('Certificado Matrimonio Detection', () {
      test('Detects certificado de matrimonio', () {
        final ocrResult = OcrResult(
          fullText: 'registro civil de matrimonio\ncontrayentes\nesposo esposa',
          lines: ['matrimonio', 'registro'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('CERTIFICADO_MATRIMONIO'));
      });
    });

    group('Certificado Defunción Detection', () {
      test('Detects certificado de defunción', () {
        final ocrResult = OcrResult(
          fullText: 'registro civil de defunción\nfallecimiento',
          lines: ['defunción', 'registro'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('CERTIFICADO_DEFUNCION'));
      });
    });

    group('Certificado EPS Detection', () {
      test('Detects certificado EPS', () {
        final ocrResult = OcrResult(
          fullText: 'eps salud afiliación entidad promotora régimen subsidiado',
          lines: ['eps', 'salud', 'afiliación'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('CERTIFICADO_AFILIACION_EPS'));
      });
    });

    group('Certificado Estudio Detection', () {
      test('Detects certificado de estudio', () {
        final ocrResult = OcrResult(
          fullText: 'certificado de estudios\ninstitución educativa\ncolegio grado curso',
          lines: ['certificado', 'estudio'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('CERTIFICADO_ESTUDIO'));
      });
    });

    group('Unknown Document Detection', () {
      test('Returns OTRO_DOCUMENTO for unknown text', () {
        final ocrResult = OcrResult(
          fullText: 'random text that does not match any document type',
          lines: ['random text'],
          confidence: 0.9,
          processingTime: Duration.zero,
        );

        final detection = detector.detectType(ocrResult);

        expect(detection.type, equals('OTRO_DOCUMENTO'));
        expect(detection.confidence, equals(0.0));
      });
    });

    group('DocumentTypeDetection', () {
      test('isConfident returns true for high confidence', () {
        final detection = DocumentTypeDetection(
          type: 'CEDULA_CIUDADANIA',
          confidence: 0.8,
          keywords: [],
        );

        expect(detection.isConfident, isTrue);
      });

      test('isConfident returns false for low confidence', () {
        final detection = DocumentTypeDetection(
          type: 'OTRO_DOCUMENTO',
          confidence: 0.5,
          keywords: [],
        );

        expect(detection.isConfident, isFalse);
      });

      test('confidencePercent converts correctly', () {
        final detection = DocumentTypeDetection(
          type: 'CEDULA_CIUDADANIA',
          confidence: 0.85,
          keywords: [],
        );

        expect(detection.confidencePercent, equals(85));
      });

      test('label returns human-readable name', () {
        final detection = DocumentTypeDetection(
          type: 'CEDULA_CIUDADANIA',
          confidence: 0.9,
          keywords: [],
        );

        expect(detection.label, equals('Cédula de Ciudadanía'));
      });
    });
  });
}
