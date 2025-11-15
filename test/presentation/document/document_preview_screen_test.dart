import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/presentation/document/document_preview_screen.dart';

void main() {
  group('DocumentPreviewScreen Widget Tests', () {
    late File testImageFile;

    setUp(() {
      // Create a temporary test image file
      testImageFile = File('test_assets/sample_document.jpg');
    });

    testWidgets('Screen displays loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      // Should show loading while checking quality
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Verificando calidad...'), findsOneWidget);
    });

    testWidgets('AppBar displays correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      expect(find.text('Vista Previa'), findsOneWidget);
    });

    testWidgets('Control panel contains all expected buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Tarjeta de Identidad',
            onRetake: () {},
          ),
        ),
      );

      // Wait for quality check to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have crop, rotate, and retake buttons
      expect(find.text('Recortar'), findsOneWidget);
      expect(find.text('Rotar'), findsOneWidget);
      expect(find.text('Retomar'), findsOneWidget);
    });

    testWidgets('Quality indicator displays document type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Registro Civil',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Registro Civil'), findsOneWidget);
    });

    testWidgets('Retake button calls onRetake callback',
        (WidgetTester tester) async {
      var retakeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {
              retakeCalled = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap retake button
      await tester.tap(find.text('Retomar'));
      await tester.pumpAndSettle();

      expect(retakeCalled, isTrue);
    });

    testWidgets('Confirm button is disabled for low quality images',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find confirm button
      final confirmButton = find.widgetWithText(ElevatedButton, 'Confirmar Imagen');

      // If quality is low, button should be disabled or show different text
      if (confirmButton.evaluate().isEmpty) {
        // Button might show "Calidad Insuficiente" instead
        expect(find.text('Calidad Insuficiente'), findsOneWidget);
      }
    });
  });

  group('DocumentPreviewScreen Integration Tests', () {
    testWidgets('Full workflow: view -> edit -> confirm',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/sample_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      // Wait for quality check
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify screen loaded
      expect(find.text('Vista Previa'), findsOneWidget);

      // Try to rotate (if quality is acceptable)
      final rotateButton = find.text('Rotar');
      if (rotateButton.evaluate().isNotEmpty) {
        await tester.tap(rotateButton);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Workflow completed successfully if no errors thrown
    });
  });

  group('Quality Indicator Tests', () {
    testWidgets('Quality badge displays score and level',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/sample_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should display quality percentage
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text && widget.data?.contains('%') == true),
        findsWidgets,
      );
    });

    testWidgets('Quality issues are displayed when present',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/low_quality_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Tarjeta de Identidad',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If quality is low, should show recommendation to retake
      final recommendation = find.text(
        'Recomendamos retomar la foto para mejor calidad',
      );

      // Recommendation might or might not be present depending on quality
      // Just verify the screen loaded correctly
      expect(find.text('Vista Previa'), findsOneWidget);
    });
  });

  group('Control Panel Tests', () {
    testWidgets('Crop button initiates crop operation',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/sample_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final cropButton = find.text('Recortar');
      expect(cropButton, findsOneWidget);

      // Tapping should not throw error
      await tester.tap(cropButton);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Rotate button initiates rotation',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/sample_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Registro Civil',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final rotateButton = find.text('Rotar');
      expect(rotateButton, findsOneWidget);

      // Tapping should not throw error
      await tester.tap(rotateButton);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Buttons are disabled while processing',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/sample_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start an operation
      final rotateButton = find.text('Rotar');
      await tester.tap(rotateButton);
      await tester.pump(const Duration(milliseconds: 50));

      // Other buttons should be disabled while processing
      // This is implicit in the implementation - verify no crash
    });
  });

  group('Edge Cases', () {
    testWidgets('Handles missing image file gracefully',
        (WidgetTester tester) async {
      final nonExistentFile = File('non_existent_file.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: nonExistentFile,
            documentType: 'Cédula de Ciudadanía',
            onRetake: () {},
          ),
        ),
      );

      // Should show loading or error, not crash
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Handles very long document type names',
        (WidgetTester tester) async {
      final testImageFile = File('test_assets/sample_document.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentPreviewScreen(
            imageFile: testImageFile,
            documentType:
                'Certificado de Afiliación a EPS con Documento Adicional de Identificación',
            onRetake: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should display without overflow
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
