import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/presentation/widgets/advanced_search_widget.dart';
import 'package:lumara_scan/domain/entities/assignment.dart';

void main() {
  group('AdvancedSearchWidget Tests', () {
    late SearchCriteria capturedCriteria;

    setUp(() {
      capturedCriteria = SearchCriteria(query: '');
    });

    testWidgets('Renders search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Buscar personas, documentos...'),
        findsOneWidget,
      );
    });

    testWidgets('Shows filters when filter button tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Initially filters should not be visible
      expect(find.text('Filtros Avanzados'), findsNothing);

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Now filters should be visible
      expect(find.text('Filtros Avanzados'), findsOneWidget);
    });

    testWidgets('Search query triggers onSearch callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Enter search text
      await tester.enterText(
        find.byType(TextField),
        'Juan Perez',
      );
      await tester.pumpAndSettle();

      expect(capturedCriteria.query, 'Juan Perez');
    });

    testWidgets('Clear button clears search text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Text should be cleared
      expect(find.text('test'), findsNothing);
      expect(capturedCriteria.query, '');
    });

    testWidgets('Status filter chips work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Find and tap 'Pendiente' filter chip
      await tester.tap(find.text('Pendiente'));
      await tester.pumpAndSettle();

      expect(capturedCriteria.status, AssignmentStatus.pending);
    });

    testWidgets('Document type filter works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Tap document type filter
      await tester.tap(find.text('Cédula'));
      await tester.pumpAndSettle();

      expect(capturedCriteria.documentType, 'Cédula');
    });

    testWidgets('Clear filters button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('Pendiente'));
      await tester.pumpAndSettle();

      // Clear filters
      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();

      expect(capturedCriteria.status, null);
    });

    testWidgets('Fuzzy search toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Toggle fuzzy search off
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(capturedCriteria.fuzzySearch, false);
    });

    testWidgets('Quick presets work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
            ),
          ),
        ),
      );

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();

      // Tap 'Completados' preset
      await tester.tap(find.text('Completados'));
      await tester.pumpAndSettle();

      expect(capturedCriteria.status, AssignmentStatus.completed);
    });

    testWidgets('Search history displays correctly',
        (WidgetTester tester) async {
      final history = ['Juan Perez', 'Cédula', 'María Gómez'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
              searchHistory: history,
            ),
          ),
        ),
      );

      // History should be visible when search is empty
      expect(find.text('Búsquedas recientes'), findsOneWidget);
      expect(find.text('Juan Perez'), findsOneWidget);
      expect(find.text('Cédula'), findsOneWidget);
    });

    testWidgets('Tapping history item fills search field',
        (WidgetTester tester) async {
      final history = ['Juan Perez'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchWidget(
              onSearch: (criteria) {
                capturedCriteria = criteria;
              },
              searchHistory: history,
            ),
          ),
        ),
      );

      // Tap history item
      await tester.tap(find.text('Juan Perez').last);
      await tester.pumpAndSettle();

      expect(capturedCriteria.query, 'Juan Perez');
    });

    test('SearchCriteria hasFilters works correctly', () {
      final emptySearch = SearchCriteria(query: '');
      expect(emptySearch.hasFilters, false);

      final withStatus = SearchCriteria(
        query: '',
        status: AssignmentStatus.pending,
      );
      expect(withStatus.hasFilters, true);

      final withType = SearchCriteria(
        query: '',
        documentType: 'Cédula',
      );
      expect(withType.hasFilters, true);

      final withDate = SearchCriteria(
        query: '',
        dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ),
      );
      expect(withDate.hasFilters, true);
    });

    test('SearchCriteria isEmpty works correctly', () {
      final emptySearch = SearchCriteria(query: '');
      expect(emptySearch.isEmpty, true);

      final withQuery = SearchCriteria(query: 'Juan');
      expect(withQuery.isEmpty, false);

      final withFilter = SearchCriteria(
        query: '',
        status: AssignmentStatus.pending,
      );
      expect(withFilter.isEmpty, false);
    });
  });
}
