import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/services/field_extractor.dart';
import 'package:lumara_scan/services/local_ocr_service.dart';

void main() {
  group('FieldExtractor Tests', () {
    late FieldExtractor extractor;

    setUp(() {
      extractor = FieldExtractor();
    });

    group('Document Number Extraction', () {
      test('Extracts 8-digit cédula number', () {
        final text = 'Cédula de Ciudadanía No. 12345678';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['identification_number'], equals('12345678'));
      });

      test('Extracts 10-digit cédula number', () {
        final text = 'CC 1023456789';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['identification_number'], equals('1023456789'));
      });

      test('Extracts NUIP number', () {
        final text = 'NUIP: 1234567890';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['document_number'], equals('1234567890'));
      });
    });

    group('Date Extraction', () {
      test('Extracts DD/MM/YYYY format', () {
        final text = 'Fecha de nacimiento: 15/08/1990';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'REGISTRO_CIVIL',
        );

        expect(fields['birth_date'], equals('15/08/1990'));
      });

      test('Extracts DD-MM-YYYY format', () {
        final text = 'Fecha exp: 20-05-2020';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['expedition_date'], equals('20-05-2020'));
      });

      test('Extracts date in Spanish format', () {
        final text = 'Fecha: 15 de agosto de 2020';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'REGISTRO_CIVIL',
        );

        expect(fields['dates'], isNotEmpty);
      });
    });

    group('Name Extraction', () {
      test('Extracts name after "Nombre" label', () {
        final text = 'Nombre: JUAN CARLOS PÉREZ GARCÍA';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['names'], contains('JUAN CARLOS PÉREZ GARCÍA'));
      });

      test('Extracts multiple names', () {
        final text = 'Nombres: MARÍA JOSÉ\nApellidos: LÓPEZ MARTÍNEZ';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['names'], isA<List>());
        expect((fields['names'] as List).length, greaterThan(0));
      });
    });

    group('Place Extraction', () {
      test('Extracts Colombian city names', () {
        final text = 'Lugar de expedición: BOGOTÁ D.C.';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        expect(fields['places'], isNotEmpty);
      });

      test('Detects multiple cities', () {
        final text = 'Nació en medellín, expedido en bogotá';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CEDULA_CIUDADANIA',
        );

        final places = fields['places'] as List;
        expect(places.length, equals(2));
      });
    });

    group('Parents Extraction (Registro Civil)', () {
      test('Extracts mother name', () {
        final text = 'Madre: MARÍA LÓPEZ GARCÍA';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'REGISTRO_CIVIL',
        );

        expect(fields['parents'], isA<Map>());
        final parents = fields['parents'] as Map;
        expect(parents['mother'], equals('MARÍA LÓPEZ GARCÍA'));
      });

      test('Extracts father name', () {
        final text = 'Padre: JUAN PÉREZ MARTÍNEZ';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'REGISTRO_CIVIL',
        );

        final parents = fields['parents'] as Map;
        expect(parents['father'], equals('JUAN PÉREZ MARTÍNEZ'));
      });

      test('Extracts both parents', () {
        final text = 'Madre: MARÍA LÓPEZ\nPadre: JUAN PÉREZ';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'REGISTRO_CIVIL',
        );

        final parents = fields['parents'] as Map;
        expect(parents['mother'], isNotNull);
        expect(parents['father'], isNotNull);
      });
    });

    group('EPS Fields Extraction', () {
      test('Extracts EPS name', () {
        final text = 'EPS: SURA SALUD';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CERTIFICADO_AFILIACION_EPS',
        );

        expect(fields['eps_name'], equals('SURA SALUD'));
      });

      test('Detects contributivo regime', () {
        final text = 'Régimen contributivo afiliado';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CERTIFICADO_AFILIACION_EPS',
        );

        expect(fields['regime'], equals('Contributivo'));
      });

      test('Detects subsidiado regime', () {
        final text = 'Régimen subsidiado beneficiario';
        final fields = extractor.extractFields(
          _createOcrResult(text),
          'CERTIFICADO_AFILIACION_EPS',
        );

        expect(fields['regime'], equals('Subsidiado'));
      });
    });

    group('Edge Cases', () {
      test('Handles empty text', () {
        final fields = extractor.extractFields(
          _createOcrResult(''),
          'CEDULA_CIUDADANIA',
        );

        expect(fields, isNotNull);
        expect(fields, isA<Map>());
      });

      test('Handles text with no recognizable fields', () {
        final fields = extractor.extractFields(
          _createOcrResult('random text with no fields'),
          'CEDULA_CIUDADANIA',
        );

        expect(fields, isNotNull);
        // Most fields should be null or empty
      });

      test('Handles unknown document type', () {
        final fields = extractor.extractFields(
          _createOcrResult('some text'),
          'UNKNOWN_TYPE',
        );

        expect(fields, isNotNull);
        expect(fields['document_number'], isNull);
      });
    });
  });
}

/// Helper to create OcrResult for testing
OcrResult _createOcrResult(String text) {
  return OcrResult(
    fullText: text,
    lines: text.split('\n'),
    confidence: 0.9,
    processingTime: Duration.zero,
  );
}
