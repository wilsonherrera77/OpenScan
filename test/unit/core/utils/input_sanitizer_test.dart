import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_indigenas/core/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitize', () {
      test('should remove HTML tags', () {
        final input = '<script>alert("xss")</script>Hello';
        final result = InputSanitizer.sanitize(input);

        expect(result, 'Hello');
      });

      test('should remove dangerous characters', () {
        final input = "test<>'\"`; data";
        final result = InputSanitizer.sanitize(input);

        expect(result.contains('<'), false);
        expect(result.contains('>'), false);
        expect(result.contains("'"), false);
        expect(result.contains('"'), false);
        expect(result.contains('`'), false);
        expect(result.contains(';'), false);
      });

      test('should replace newlines with spaces', () {
        final input = 'line1\nline2\rline3';
        final result = InputSanitizer.sanitize(input);

        expect(result, 'line1 line2 line3');
      });

      test('should trim whitespace', () {
        final input = '  test  ';
        final result = InputSanitizer.sanitize(input);

        expect(result, 'test');
      });
    });

    group('sanitizeOptional', () {
      test('should return null for null input', () {
        final result = InputSanitizer.sanitizeOptional(null);
        expect(result, null);
      });

      test('should return null for empty input', () {
        final result = InputSanitizer.sanitizeOptional('');
        expect(result, null);
      });

      test('should sanitize non-empty input', () {
        final input = '<script>test</script>';
        final result = InputSanitizer.sanitizeOptional(input);

        expect(result, 'test');
      });
    });

    group('sanitizeDocumentNumber', () {
      test('should keep only digits', () {
        final input = 'ABC-123-456-XYZ';
        final result = InputSanitizer.sanitizeDocumentNumber(input);

        expect(result, '123456');
      });

      test('should return null for too short', () {
        final input = '12345'; // Less than 6 digits
        final result = InputSanitizer.sanitizeDocumentNumber(input);

        expect(result, null);
      });

      test('should return null for too long', () {
        final input = '1234567890123456'; // More than 15 digits
        final result = InputSanitizer.sanitizeDocumentNumber(input);

        expect(result, null);
      });

      test('should accept valid document number', () {
        final input = '1234567890';
        final result = InputSanitizer.sanitizeDocumentNumber(input);

        expect(result, '1234567890');
      });
    });

    group('isValidPersonId', () {
      test('should accept alphanumeric with underscore and dash', () {
        expect(InputSanitizer.isValidPersonId('P001'), true);
        expect(InputSanitizer.isValidPersonId('P_001'), true);
        expect(InputSanitizer.isValidPersonId('P-001'), true);
        expect(InputSanitizer.isValidPersonId('Person123'), true);
      });

      test('should reject special characters', () {
        expect(InputSanitizer.isValidPersonId('P@001'), false);
        expect(InputSanitizer.isValidPersonId('P 001'), false);
        expect(InputSanitizer.isValidPersonId('P#001'), false);
      });

      test('should reject empty string', () {
        expect(InputSanitizer.isValidPersonId(''), false);
      });
    });

    group('sanitizeFilename', () {
      test('should replace invalid characters with underscore', () {
        final input = 'file name!@#\$%.pdf';
        final result = InputSanitizer.sanitizeFilename(input);

        expect(result, 'file_name_____.pdf');
      });

      test('should remove double dots', () {
        final input = 'file..name.pdf';
        final result = InputSanitizer.sanitizeFilename(input);

        expect(result, 'file.name.pdf');
      });

      test('should trim whitespace', () {
        final input = '  filename.pdf  ';
        final result = InputSanitizer.sanitizeFilename(input);

        expect(result, 'filename.pdf');
      });
    });

    group('isValidUrl', () {
      test('should accept valid HTTPS URL', () {
        final result = InputSanitizer.isValidUrl('https://example.com');
        expect(result, true);
      });

      test('should accept valid HTTP URL', () {
        final result = InputSanitizer.isValidUrl('http://example.com');
        expect(result, true);
      });

      test('should reject URL without scheme', () {
        final result = InputSanitizer.isValidUrl('example.com');
        expect(result, false);
      });

      test('should reject invalid scheme', () {
        final result = InputSanitizer.isValidUrl('ftp://example.com');
        expect(result, false);
      });

      test('should reject malformed URL', () {
        final result = InputSanitizer.isValidUrl('not a url');
        expect(result, false);
      });
    });

    group('sanitizeForLogging', () {
      test('should redact tokens', () {
        final input = 'Auth token: abc123def456';
        final result = InputSanitizer.sanitizeForLogging(input);

        expect(result.contains('[REDACTED]'), true);
        expect(result.contains('abc123def456'), false);
      });

      test('should redact passwords', () {
        final input = 'password: secret123';
        final result = InputSanitizer.sanitizeForLogging(input);

        expect(result.contains('[REDACTED]'), true);
        expect(result.contains('secret123'), false);
      });

      test('should redact API keys', () {
        final input = 'api_key: xyz789';
        final result = InputSanitizer.sanitizeForLogging(input);

        expect(result.contains('[REDACTED]'), true);
        expect(result.contains('xyz789'), false);
      });

      test('should redact email addresses', () {
        final input = 'User: test@example.com';
        final result = InputSanitizer.sanitizeForLogging(input);

        expect(result.contains('[EMAIL_REDACTED]'), true);
        expect(result.contains('test@example.com'), false);
      });

      test('should handle multiple sensitive data', () {
        final input = 'Login token: abc123, email: user@test.com, password: pass';
        final result = InputSanitizer.sanitizeForLogging(input);

        expect(result.contains('[REDACTED]'), true);
        expect(result.contains('[EMAIL_REDACTED]'), true);
        expect(result.contains('abc123'), false);
        expect(result.contains('user@test.com'), false);
        expect(result.contains('pass'), false);
      });
    });
  });
}
