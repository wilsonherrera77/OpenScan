import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openscan_indigenas/presentation/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    setUp(() {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display all 4 onboarding pages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Should start on first page
      expect(find.text('Bienvenido a OpenScan Indígenas'), findsOneWidget);
      expect(find.text('Digitaliza documentos de tu comunidad de forma fácil, segura y gratuita.'),
          findsOneWidget);

      // Should have 4 page indicators
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('should navigate between pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Find and tap the "Siguiente" button
      final nextButton = find.text('Siguiente');
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Should be on second page
      expect(find.text('Captura y Organiza'), findsOneWidget);
    });

    testWidgets('should show "Comenzar" on last page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text(i < 2 ? 'Siguiente' : 'Siguiente'));
        await tester.pumpAndSettle();
      }

      // Should show "Comenzar" button on last page
      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Siguiente'), findsNothing);
    });

    testWidgets('should show skip button on all pages except last',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Should show skip button on first page
      expect(find.text('Saltar'), findsOneWidget);

      // Navigate through pages
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Saltar'), findsOneWidget);
      }

      // Navigate to last page
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Should NOT show skip button on last page
      expect(find.text('Saltar'), findsNothing);
    });

    testWidgets('should display correct icons for each page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Page 1: document_scanner icon
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);

      // Navigate to page 2
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // Navigate to page 3
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Navigate to page 4
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('should have colored page indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Find page indicators
      final indicators = find.byType(AnimatedContainer);
      expect(indicators, findsNWidgets(4));

      // First indicator should be active (wider)
      final firstIndicator =
          tester.widget<AnimatedContainer>(indicators.first);
      expect(firstIndicator.constraints?.maxWidth, 24);
    });

    testWidgets('page indicator should update when swiping',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Swipe to next page
      await tester.drag(
        find.byType(PageView),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      // Should be on page 2
      expect(find.text('Captura y Organiza'), findsOneWidget);
    });
  });
}
