import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_indigenas/core/accessibility/accessibility_helper.dart';

void main() {
  group('Accessibility Widgets Tests', () {
    testWidgets('AccessibleButton should have semantic label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Should render button
      expect(find.text('Test Button'), findsOneWidget);

      // Should have semantic label
      final semantics = tester.getSemantics(find.text('Test Button'));
      expect(semantics.label, contains('Test Button'));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('AccessibleButton with icon should display icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Upload',
              icon: Icons.upload,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('AccessibleButton shows loading indicator when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AccessibleButton should be disabled when loading',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('AccessibleTextField should have semantic label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Email',
              required: true,
            ),
          ),
        ),
      );

      expect(find.text('Email *'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(TextField));
      expect(semantics.label, contains('Email'));
      expect(semantics.hasFlag(SemanticsFlag.isTextField), isTrue);
    });

    testWidgets('AccessibleTextField should show prefix icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Search',
              prefixIcon: Icons.search,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('AccessibleIconButton should have semantic label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.delete,
              label: 'Delete item',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(IconButton));
      expect(semantics.label, contains('Delete item'));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('AccessibleProgressIndicator should show progress value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleProgressIndicator(
              value: 0.75,
              label: 'Uploading',
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final progressIndicator =
          tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressIndicator.value, 0.75);
    });

    testWidgets('AccessibleListTile should have position indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleListTile(
              title: 'Juan Pérez',
              subtitle: 'Cédula: 123456',
              position: 1,
              total: 10,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('Cédula: 123456'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(ListTile));
      expect(semantics.label, contains('Elemento 1 de 10'));
    });

    testWidgets('AccessibleImage should have semantic description',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleImage(
              image: const AssetImage('assets/test.png'),
              semanticLabel: 'Document scan preview',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(Image));
      expect(semantics.label, contains('Document scan preview'));
      expect(semantics.hasFlag(SemanticsFlag.isImage), isTrue);
    });

    testWidgets('AccessibleCard should have semantic label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Person information card',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(Card));
      expect(semantics.label, 'Person information card');
    });
  });

  group('AccessibilityHelper Tests', () {
    test('buttonLabel should create proper semantic label', () {
      expect(
        AccessibilityHelper.buttonLabel('Save'),
        'Save. Botón',
      );

      expect(
        AccessibilityHelper.buttonLabel('Delete', hint: 'Removes the item'),
        'Delete. Removes the item',
      );
    });

    test('textFieldLabel should indicate required fields', () {
      expect(
        AccessibilityHelper.textFieldLabel('Name', required: true),
        'Name. Campo requerido',
      );

      expect(
        AccessibilityHelper.textFieldLabel('Notes', required: false),
        'Notes. Campo de texto',
      );
    });

    test('imageLabel should include description', () {
      expect(
        AccessibilityHelper.imageLabel('Photo of document'),
        'Imagen. Photo of document',
      );
    });

    test('progressLabel should include percentage and action', () {
      expect(
        AccessibilityHelper.progressLabel(75),
        'Progreso: 75 porciento',
      );

      expect(
        AccessibilityHelper.progressLabel(50, action: 'Uploading file'),
        'Uploading file. Progreso: 50 porciento',
      );
    });

    test('listItemLabel should include position if provided', () {
      expect(
        AccessibilityHelper.listItemLabel('Item'),
        'Item',
      );

      expect(
        AccessibilityHelper.listItemLabel('Item', position: 3, total: 10),
        'Item. Elemento 3 de 10',
      );
    });
  });
}
