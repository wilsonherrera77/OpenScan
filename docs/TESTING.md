# Testing Guide - Lumara Indígenas

## 📋 Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

This project follows a comprehensive testing strategy aligned with the **Test Pyramid**:

- **60% Unit Tests**: Fast, isolated tests for business logic
- **30% Widget Tests**: UI component tests
- **10% Integration Tests**: End-to-end flow tests

### Testing Stack

- **Framework**: `flutter_test` (built-in Flutter testing)
- **Mocking**: `mockito` with code generation
- **Code Generation**: `build_runner` for mocks
- **Coverage**: `lcov` for coverage reports
- **CI/CD**: GitHub Actions

## Test Structure

```
test/
├── unit/                           # Unit tests (60%)
│   ├── core/
│   │   ├── config/                # Configuration tests
│   │   ├── security/              # Security feature tests
│   │   │   ├── rate_limiter_test.dart
│   │   │   ├── secure_config_manager_test.dart
│   │   │   └── certificate_pinner_test.dart
│   │   └── utils/                 # Utility tests
│   │       └── input_sanitizer_test.dart
│   ├── data/
│   │   ├── datasources/           # Data source tests
│   │   ├── repositories/          # Repository tests
│   │   │   ├── auth_repository_test.dart
│   │   │   ├── census_repository_test.dart
│   │   │   └── document_repository_test.dart
│   │   └── local/                 # Local database tests
│   ├── domain/
│   │   └── entities/              # Domain entity tests
│   └── presentation/
│       └── providers/             # State management tests
│           ├── auth_provider_test.dart
│           └── census_provider_test.dart
│
├── widget/                         # Widget tests (30%)
│   ├── auth/
│   │   └── login_screen_test.dart
│   ├── census/
│   │   └── person_selection_screen_test.dart
│   ├── document/
│   │   └── upload_screen_test.dart
│   └── widgets/
│       └── upload_queue_indicator_test.dart
│
├── integration/                    # Integration tests (10%)
│   ├── auth_flow_test.dart
│   ├── upload_flow_test.dart
│   └── offline_sync_test.dart
│
├── mocks/                          # Generated mock classes
│   ├── mock_repositories.dart
│   ├── mock_repositories.mocks.dart
│   ├── mock_api_client.dart
│   ├── mock_api_client.mocks.dart
│   ├── mock_database.dart
│   └── mock_database.mocks.dart
│
└── helpers/                        # Test utilities
    ├── test_helpers.dart          # Reusable test functions
    └── fixtures.dart              # Test data factories
```

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run with Coverage

```bash
flutter test --coverage
```

### Run Specific Test File

```bash
flutter test test/unit/core/security/rate_limiter_test.dart
```

### Run Tests by Pattern

```bash
# Run all unit tests
flutter test test/unit/

# Run all security tests
flutter test test/unit/core/security/

# Run tests matching a name pattern
flutter test --name "RateLimiter"
```

### Run with Verbose Output

```bash
flutter test --reporter expanded
```

### Generate and View Coverage Report

```bash
# Install lcov (Linux/Mac)
sudo apt-get install lcov  # Ubuntu/Debian
brew install lcov          # macOS

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## Test Coverage

### Current Coverage Status

```
Total Coverage: 25.2% (615/2439 lines)
Target Coverage: ≥70%
```

### Coverage by Layer

| Layer | Files | Coverage | Status |
|-------|-------|----------|--------|
| Core Utils | 1 | 100% | ✅ Complete |
| Core Security | 4 | 76% | ✅ Good |
| Data Repositories | 3 | 74% | ✅ Good |
| Presentation Providers | 2 | 85% | ✅ Good |
| Data Sources | 2 | 0% | ⏳ Pending |
| Domain Entities | 5 | 12% | ⏳ Pending |
| UI Screens | 4 | 0% | ⏳ Pending |

### Coverage Requirements

- **Minimum**: 70% overall coverage (enforced in CI)
- **Critical Paths**: 90%+ coverage for:
  - Security features (`lib/core/security/`)
  - Authentication (`lib/data/repositories/auth_repository.dart`)
  - Upload logic (`lib/services/upload_service.dart`)

## Writing Tests

### 1. Unit Tests

**Example: Testing a Repository**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumara_indigenas/data/repositories/auth_repository.dart';
import '../../mocks/mock_api_client.mocks.dart';
import '../../helpers/fixtures.dart';

void main() {
  late AuthRepository repository;
  late MockTejidoApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockTejidoApiClient();
    repository = AuthRepository(mockApiClient);
  });

  group('AuthRepository - login', () {
    test('should successfully login with valid credentials', () async {
      // Arrange
      final mockToken = Fixtures.createMockAuthToken();
      when(mockApiClient.login(
        username: 'testuser',
        password: 'testpass',
      )).thenAnswer((_) async => {'token': mockToken.token});

      // Act
      final result = await repository.login(
        username: 'testuser',
        password: 'testpass',
      );

      // Assert
      expect(result.token, mockToken.token);
      verify(mockApiClient.login(
        username: 'testuser',
        password: 'testpass',
      )).called(1);
    });
  });
}
```

### 2. Widget Tests

**Example: Testing a UI Component**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_indigenas/presentation/widgets/upload_queue_indicator.dart';
import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('should display upload count', (WidgetTester tester) async {
    // Arrange
    const uploadCount = 5;
    final widget = UploadQueueIndicator(uploadCount: uploadCount);

    // Act
    await tester.pumpWidget(createTestableWidget(widget));

    // Assert
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
  });
}
```

### 3. Integration Tests

**Example: Testing Complete Flow**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumara_indigenas/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete authentication flow', (WidgetTester tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byKey(Key('username')), 'testuser');
    await tester.enterText(find.byKey(Key('password')), 'testpass');

    // Tap login button
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // Verify navigation to home screen
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

### Using Test Helpers

**Fixtures for Test Data**

```dart
import 'package:lumara_indigenas/domain/entities/person.dart';
import '../../helpers/fixtures.dart';

// Create mock person
final person = Fixtures.createMockPerson(
  personId: 'P001',
  fullName: 'Juan Pérez',
  familyId: 'F001',
);

// Create mock auth token
final token = Fixtures.createMockAuthToken(
  username: 'testuser',
);

// Create mock document
final doc = Fixtures.createMockDocument(
  personId: 'P001',
  documentType: 'CEDULA_CIUDADANIA',
);
```

**Widget Test Helpers**

```dart
import '../../helpers/test_helpers.dart';

// Wrap widget in MaterialApp
final widget = createTestableWidget(MyWidget());

// Pump widget and wait for animations
await pumpTestWidget(tester, MyWidget());

// Find text containing partial string
final finder = findTextContaining('partial');

// Find widget by type and property
final finder = findWidgetByProperty<Text>(
  (widget) => widget.data == 'expected',
);
```

## CI/CD Integration

### GitHub Actions Workflow

The project includes automated testing via GitHub Actions (`.github/workflows/test.yml`):

**On Every Push/PR**:
1. Setup Flutter environment
2. Install dependencies (`flutter pub get`)
3. Generate code (`build_runner`)
4. Run static analysis (`flutter analyze`)
5. Check code formatting (`dart format`)
6. Run all tests with coverage
7. Verify ≥70% coverage threshold
8. Upload coverage to Codecov
9. Generate coverage artifacts

### Coverage Enforcement

```yaml
- name: Check coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
    echo "Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 70" | bc -l) )); then
      echo "ERROR: Coverage $COVERAGE% is below 70% threshold"
      exit 1
    fi
    echo "✅ Coverage $COVERAGE% meets 70% threshold"
```

### Running CI Locally

```bash
# Run the same checks as CI
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-infos
dart format --set-exit-if-changed .
flutter test --coverage
```

## Best Practices

### 1. Test Organization

✅ **DO**: Group related tests
```dart
group('AuthRepository - login', () {
  test('should successfully login with valid credentials', () {});
  test('should throw exception on invalid credentials', () {});
});
```

❌ **DON'T**: Put all tests in one file without grouping

### 2. Test Naming

✅ **DO**: Use descriptive names
```dart
test('should return null when person not found', () {});
```

❌ **DON'T**: Use vague names
```dart
test('test1', () {});
```

### 3. AAA Pattern

Always follow **Arrange-Act-Assert**:

```dart
test('example test', () {
  // Arrange: Set up test data and mocks
  final repository = AuthRepository(mockClient);
  when(mockClient.login()).thenAnswer((_) => mockToken);

  // Act: Execute the code under test
  final result = await repository.login(username, password);

  // Assert: Verify the results
  expect(result.token, equals(expectedToken));
  verify(mockClient.login()).called(1);
});
```

### 4. Mock Generation

Always annotate mock classes:

```dart
import 'package:mockito/annotations.dart';
import 'package:lumara_indigenas/data/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
void main() {}
```

Then generate mocks:

```bash
dart pub run build_runner build --delete-conflicting-outputs
```

### 5. Async Testing

Use `async`/`await` properly:

```dart
test('async operation', () async {
  final result = await repository.fetchData();
  expect(result, isNotEmpty);
});
```

### 6. Test Isolation

✅ **DO**: Reset state between tests
```dart
setUp(() {
  mockClient = MockApiClient();
  repository = AuthRepository(mockClient);
});

tearDown(() {
  repository.dispose();
});
```

### 7. Matcher Usage

Use specific matchers:

```dart
// Good
expect(result, isA<Person>());
expect(list, isEmpty);
expect(value, isNull);
expect(error, throwsException);

// Better
expect(result, isA<Person>().having((p) => p.id, 'id', 'P001'));
```

## Troubleshooting

### Common Issues

#### 1. Mock Generation Fails

**Problem**: `build_runner` fails to generate mocks

**Solution**:
```bash
# Clean and regenerate
flutter clean
flutter pub get
dart pub run build_runner build --delete-conflicting-outputs
```

#### 2. Tests Fail on CI but Pass Locally

**Problem**: Different environments

**Solutions**:
- Ensure all dependencies are in `pubspec.yaml`
- Check Flutter version matches CI (`.github/workflows/test.yml`)
- Mock external dependencies (network, file system, time)
- Use `FlutterSecureStorage.setMockInitialValues({})` in tests

#### 3. Coverage Not Generated

**Problem**: `coverage/lcov.info` is empty

**Solutions**:
```bash
# Make sure you're running with --coverage flag
flutter test --coverage

# Check if tests are actually executing
flutter test --reporter expanded

# Verify lcov is installed
lcov --version
```

#### 4. Widget Tests Fail with "Null check operator"

**Problem**: Widget needs data that's null in tests

**Solution**:
```dart
testWidgets('example', (tester) async {
  // Provide all required data
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(
        requiredData: mockData,  // Don't forget this!
      ),
    ),
  );
});
```

#### 5. "Bad state: No element" in Tests

**Problem**: Finder doesn't find expected widget

**Solutions**:
```dart
// Wait for async operations
await tester.pumpAndSettle();

// Check what's actually rendered
debugDumpApp();

// Use find.byType instead of find.byIcon
expect(find.byType(Icon), findsWidgets);
```

## Test Execution Summary

### Current Test Suite

| Category | Count | Status |
|----------|-------|--------|
| **Unit Tests** | 103 | ✅ |
| - Core Security | 20 | ✅ |
| - Core Utils | 47 | ✅ |
| - Data Repositories | 37 | ✅ |
| - Presentation Providers | 16 | ✅ (blocked by compilation) |
| **Widget Tests** | 0 | ⏳ Pending |
| **Integration Tests** | 0 | ⏳ Pending |
| **Total** | 103 | ⏳ In Progress |

### Next Steps

1. ✅ Fix compilation errors in `document_repository.dart`
2. ⏳ Add widget tests for key screens
3. ⏳ Add integration tests for critical flows
4. ⏳ Reach 70% code coverage
5. ⏳ Enable coverage checks in CI

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Test Coverage Guide](https://docs.flutter.dev/testing/code-coverage)

---

**Last Updated**: 2025-10-07
**Coverage**: 25.2% (615/2439 lines)
**Target**: 70%
**Tests Passing**: 80/99 (19 blocked by compilation errors)
