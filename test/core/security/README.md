# Token Rotation Tests

## Overview

Comprehensive test suite for token rotation functionality in SecureConfigManager.

## Test Coverage

- **Token Rotation Timestamp**: Verifies timestamp recording on token updates
- **Token Rotation Detection**: Tests needsTokenRotation() logic
- **Days Calculation**: Tests getDaysSinceRotation() accuracy
- **Workflow Tests**: Complete rotation workflows and failure handling
- **Expiry Warnings**: Tests for imminent expiry detection
- **Edge Cases**: Invalid timestamps, clock skew, concurrent access
- **Production Scenarios**: Real-world usage patterns

## Running Tests

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Mocks

Token rotation tests use Mockito for mocking FlutterSecureStorage:

```bash
# Generate mock files
dart run build_runner build --delete-conflicting-outputs
```

This creates `token_rotation_test.mocks.dart` with mock implementations.

### 3. Run All Security Tests

```bash
# Run all tests in security folder
flutter test test/core/security/

# Run with coverage
flutter test --coverage test/core/security/
```

### 4. Run Token Rotation Tests Only

```bash
# Run specific test file
flutter test test/core/security/token_rotation_test.dart

# Run with verbose output
flutter test test/core/security/token_rotation_test.dart --reporter expanded
```

### 5. Run Specific Test Group

```bash
# Run only rotation detection tests
flutter test test/core/security/token_rotation_test.dart --name "Token Rotation Detection"

# Run only edge case tests
flutter test test/core/security/token_rotation_test.dart --name "Edge Cases"
```

## Test Organization

```
test/core/security/
├── README.md                      # This file
├── token_rotation_test.dart       # Main test file (150+ tests)
└── token_rotation_test.mocks.dart # Generated mocks (auto-generated)
```

## Key Test Scenarios

### Normal Operation

- Token rotation every 7 days
- Fresh tokens don't need rotation
- Mid-cycle checks return correct status

### Boundary Conditions

- Exactly 7 days (should not rotate)
- 7 days + 1 second (should rotate)
- Same-day rotation (0 days)
- 23 hours vs 25 hours (day calculation)

### Error Handling

- Never-rotated tokens
- Invalid timestamp format
- Storage read/write failures
- Concurrent rotation requests

### Production Scenarios

- 30+ day old tokens
- Multiple device token management
- Login/logout token handling

## Continuous Integration

These tests run automatically in CI pipeline:

```yaml
# .github/workflows/ci.yml
- name: Run Security Tests
  run: |
    dart run build_runner build --delete-conflicting-outputs
    flutter test test/core/security/ --coverage
```

## Troubleshooting

### Mock Generation Fails

If `build_runner` fails to generate mocks:

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Tests Fail with "MockFlutterSecureStorage not found"

Make sure you've generated the mocks:

```bash
dart run build_runner build
```

### Test Timeout

Token rotation tests use real DateTime calculations. If tests timeout:

```bash
# Increase timeout
flutter test test/core/security/token_rotation_test.dart --timeout 2m
```

## Expected Results

All token rotation tests should pass:

```
✓ should record timestamp when setting token
✓ should need rotation if never rotated
✓ should need rotation after 7 days
✓ should NOT need rotation within 7 days
✓ should calculate days correctly
✓ should handle edge cases gracefully
...

Tests passed: 50+
```

## Coverage Goals

Token rotation tests should maintain:

- **Line Coverage**: >90%
- **Branch Coverage**: >85%
- **Function Coverage**: 100%

Check coverage:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Next Steps

After token rotation tests pass:

1. ✅ Token rotation logic verified
2. ✅ Edge cases handled
3. ⏳ Integrate with background sync service
4. ⏳ Add UI warnings for expiring tokens
5. ⏳ Test on physical devices

## Related Files

- **Implementation**: `lib/core/security/secure_config_manager.dart`
- **Configuration**: `lib/core/config/production_config.dart`
- **CI Pipeline**: `.github/workflows/ci.yml`

## Contributing

When adding new token rotation features:

1. Add tests FIRST (TDD approach)
2. Ensure all existing tests pass
3. Maintain >90% coverage
4. Document edge cases
5. Update this README

## References

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Token Rotation Best Practices](https://owasp.org/www-community/controls/Session_Management_Cheat_Sheet)
