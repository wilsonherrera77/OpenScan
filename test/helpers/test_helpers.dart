import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Test Helpers
/// Utility functions for testing

/// Wrap widget with MaterialApp for testing
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Wrap widget with providers for testing
Widget createTestableWidgetWithProviders({
  required Widget child,
  required List<ChangeNotifierProvider> providers,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

/// Pump widget and settle
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

/// Find text containing substring
Finder findTextContaining(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.data != null && widget.data!.contains(text),
  );
}

/// Wait for async operation
Future<void> waitForAsync([Duration? duration]) async {
  await Future.delayed(duration ?? const Duration(milliseconds: 100));
}

/// Verify no errors in logs
void verifyNoErrors() {
  // Can be extended to capture and verify logs
}

/// Create mock date time for testing
DateTime createMockDateTime({
  int year = 2025,
  int month = 10,
  int day = 7,
}) {
  return DateTime(year, month, day);
}

/// Generate test ID
String generateTestId(String prefix) {
  return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}
