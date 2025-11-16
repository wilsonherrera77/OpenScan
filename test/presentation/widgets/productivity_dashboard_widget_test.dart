import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/presentation/widgets/productivity_dashboard_widget.dart';
import 'package:lumara_scan/services/reporting_service.dart';

void main() {
  group('ProductivityDashboardWidget Tests', () {
    late ProductivityMetrics testMetrics;
    late List<DailyStatistics> testTrends;

    setUp(() {
      testMetrics = ProductivityMetrics(
        totalDocuments: 150,
        totalPersons: 30,
        totalTimeHours: 25.5,
        avgQualityScore: 92.3,
        documentsPerHour: 5.88,
        documentsPerDay: 47.1,
        avgTimePerDocument: 10.2,
      );

      testTrends = [
        DailyStatistics(
          date: DateTime(2025, 1, 1),
          documentCount: 45,
          personCount: 9,
        ),
        DailyStatistics(
          date: DateTime(2025, 1, 2),
          documentCount: 52,
          personCount: 11,
        ),
        DailyStatistics(
          date: DateTime(2025, 1, 3),
          documentCount: 38,
          personCount: 8,
        ),
      ];
    });

    testWidgets('Renders dashboard with metrics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductivityDashboardWidget(
              metrics: testMetrics,
              weeklyTrends: testTrends,
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('Dashboard de Productividad'), findsOneWidget);

      // Verify metrics cards
      expect(find.text('Docs/Día'), findsOneWidget);
      expect(find.text('Tiempo Promedio'), findsOneWidget);
      expect(find.text('Calidad'), findsOneWidget);
      expect(find.text('Total Docs'), findsOneWidget);

      // Verify metric values
      expect(find.text('47.1'), findsOneWidget); // docs per day
      expect(find.text('10.2 min'), findsOneWidget); // avg time
      expect(find.text('92%'), findsOneWidget); // quality
      expect(find.text('150'), findsOneWidget); // total docs
    });

    testWidgets('Shows trend chart when trends provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductivityDashboardWidget(
              metrics: testMetrics,
              weeklyTrends: testTrends,
              showDetailedCharts: true,
            ),
          ),
        ),
      );

      expect(find.text('Tendencia Semanal'), findsOneWidget);
    });

    testWidgets('Hides trend chart when showDetailedCharts is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductivityDashboardWidget(
              metrics: testMetrics,
              weeklyTrends: testTrends,
              showDetailedCharts: false,
            ),
          ),
        ),
      );

      expect(find.text('Tendencia Semanal'), findsNothing);
    });

    testWidgets('Shows performance indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductivityDashboardWidget(
              metrics: testMetrics,
            ),
          ),
        ),
      );

      expect(find.text('Eficiencia'), findsOneWidget);
      expect(find.text('Consistencia'), findsOneWidget);
    });

    testWidgets('Calculates correct trend indicators',
        (WidgetTester tester) async {
      final highMetrics = ProductivityMetrics(
        totalDocuments: 200,
        totalPersons: 40,
        totalTimeHours: 20.0,
        avgQualityScore: 95.0,
        documentsPerHour: 12.0, // High (trend up)
        documentsPerDay: 96.0,
        avgTimePerDocument: 5.0, // Fast (trend up)
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductivityDashboardWidget(
              metrics: highMetrics,
            ),
          ),
        ),
      );

      // Should show trend indicators for high performance
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    });

    testWidgets('Handles empty trends gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductivityDashboardWidget(
              metrics: testMetrics,
              weeklyTrends: [],
              showDetailedCharts: true,
            ),
          ),
        ),
      );

      // Should not show trend chart
      expect(find.text('Tendencia Semanal'), findsNothing);
    });

    test('TrendDirection calculation works correctly', () {
      final widget = ProductivityDashboardWidget(
        metrics: testMetrics,
      );
      final state = (widget.createState()
          as _ProductivityDashboardWidgetState);

      // Test trend up
      expect(
        state._calculateTrend(12.0, 10.0),
        TrendDirection.up,
      );

      // Test trend down
      expect(
        state._calculateTrend(8.0, 10.0),
        TrendDirection.down,
      );

      // Test trend neutral
      expect(
        state._calculateTrend(10.0, 10.0),
        TrendDirection.neutral,
      );
    });

    test('Efficiency calculation is correct', () {
      final widget = ProductivityDashboardWidget(
        metrics: testMetrics,
      );
      final state = (widget.createState()
          as _ProductivityDashboardWidgetState);

      final efficiency = state._calculateEfficiency();

      // With 5.88 docs/hour vs target of 8, efficiency should be ~0.735
      expect(efficiency, greaterThan(0.7));
      expect(efficiency, lessThan(0.8));
    });

    test('Consistency calculation is correct', () {
      final widget = ProductivityDashboardWidget(
        metrics: testMetrics,
      );
      final state = (widget.createState()
          as _ProductivityDashboardWidgetState);

      final consistency = state._calculateConsistency();

      // With 92.3% quality, consistency should be 0.923
      expect(consistency, closeTo(0.923, 0.01));
    });
  });
}
