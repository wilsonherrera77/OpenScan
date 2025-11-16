import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_scan/core/validation/input_validators.dart';

void main() {
  group('InputValidators - Security Tests', () {
    group('Username Validator', () {
      test('should accept valid username', () {
        expect(InputValidators.username('admin'), isNull);
        expect(InputValidators.username('user123'), isNull);
        expect(InputValidators.username('test_user'), isNull);
        expect(InputValidators.username('user-name'), isNull);
      });

      test('should reject username with SQL injection patterns', () {
        expect(InputValidators.username("admin'--"), isNotNull);
        expect(InputValidators.username("admin' OR '1'='1"), isNotNull);
        expect(InputValidators.username("admin'; DROP TABLE users--"), isNotNull);
      });

      test('should reject username with invalid characters', () {
        expect(InputValidators.username('admin@test'), isNotNull);
        expect(InputValidators.username('user name'), isNotNull);
        expect(InputValidators.username('admin<script>'), isNotNull);
      });

      test('should reject username that is too short', () {
        expect(InputValidators.username('ab'), isNotNull);
        expect(InputValidators.username('a'), isNotNull);
      });

      test('should reject username that is too long', () {
        final longUsername = 'a' * 31;
        expect(InputValidators.username(longUsername), isNotNull);
      });

      test('should reject empty username', () {
        expect(InputValidators.username(''), isNotNull);
        expect(InputValidators.username(null), isNotNull);
      });
    });

    group('Password Validator', () {
      test('should accept strong password', () {
        expect(InputValidators.password('Admin123!'), isNull);
        expect(InputValidators.password('P@ssw0rd'), isNull);
        expect(InputValidators.password('MyP@ss123'), isNull);
      });

      test('should reject password without uppercase', () {
        expect(InputValidators.password('password123!'), isNotNull);
      });

      test('should reject password without lowercase', () {
        expect(InputValidators.password('PASSWORD123!'), isNotNull);
      });

      test('should reject password without digit', () {
        expect(InputValidators.password('Password!'), isNotNull);
      });

      test('should reject password without special character', () {
        expect(InputValidators.password('Password123'), isNotNull);
      });

      test('should reject password that is too short', () {
        expect(InputValidators.password('Pass1!'), isNotNull);
      });

      test('should reject empty password', () {
        expect(InputValidators.password(''), isNotNull);
        expect(InputValidators.password(null), isNotNull);
      });
    });

    group('URL Validator', () {
      test('should accept valid HTTP URL', () {
        expect(InputValidators.url('http://192.168.1.100:8000'), isNull);
        expect(InputValidators.url('http://localhost:8001'), isNull);
      });

      test('should accept valid HTTPS URL', () {
        expect(InputValidators.url('https://example.com'), isNull);
        expect(InputValidators.url('https://api.example.com:8443'), isNull);
      });

      test('should reject URL with XSS patterns', () {
        expect(InputValidators.url('http://example.com/<script>alert(1)</script>'), isNotNull);
        expect(InputValidators.url('http://example.com/javascript:void(0)'), isNotNull);
      });

      test('should reject URL without scheme', () {
        expect(InputValidators.url('example.com'), isNotNull);
        expect(InputValidators.url('192.168.1.100'), isNotNull);
      });

      test('should reject URL with invalid scheme', () {
        expect(InputValidators.url('ftp://example.com'), isNotNull);
        expect(InputValidators.url('file:///etc/passwd'), isNotNull);
      });

      test('should reject empty URL', () {
        expect(InputValidators.url(''), isNotNull);
        expect(InputValidators.url(null), isNotNull);
      });
    });

    group('HTTPS URL Validator', () {
      test('should accept valid HTTPS URL', () {
        expect(InputValidators.httpsUrl('https://example.com'), isNull);
        expect(InputValidators.httpsUrl('https://api.example.com:8443'), isNull);
      });

      test('should reject HTTP URL', () {
        expect(InputValidators.httpsUrl('http://example.com'), isNotNull);
      });

      test('should reject URL without scheme', () {
        expect(InputValidators.httpsUrl('example.com'), isNotNull);
      });
    });

    group('Email Validator', () {
      test('should accept valid email', () {
        expect(InputValidators.email('user@example.com'), isNull);
        expect(InputValidators.email('test.user+tag@example.co.uk'), isNull);
        expect(InputValidators.email('admin@localhost'), isNull);
      });

      test('should reject email with XSS patterns', () {
        expect(InputValidators.email('user<script>@example.com'), isNotNull);
        expect(InputValidators.email('user@example.com<script>'), isNotNull);
      });

      test('should reject invalid email format', () {
        expect(InputValidators.email('invalid-email'), isNotNull);
        expect(InputValidators.email('user@'), isNotNull);
        expect(InputValidators.email('@example.com'), isNotNull);
        expect(InputValidators.email('user @example.com'), isNotNull);
      });

      test('should reject email that is too long', () {
        final longEmail = '${'a' * 250}@example.com';
        expect(InputValidators.email(longEmail), isNotNull);
      });

      test('should reject empty email', () {
        expect(InputValidators.email(''), isNotNull);
        expect(InputValidators.email(null), isNotNull);
      });
    });

    group('Name Validator', () {
      test('should accept valid names', () {
        expect(InputValidators.name('Juan Pérez'), isNull);
        expect(InputValidators.name('María José García'), isNull);
        expect(InputValidators.name("O'Connor"), isNull);
        expect(InputValidators.name('José-Luis'), isNull);
      });

      test('should reject name with XSS patterns', () {
        expect(InputValidators.name('Juan<script>alert(1)</script>'), isNotNull);
      });

      test('should reject name with numbers', () {
        expect(InputValidators.name('Juan123'), isNotNull);
      });

      test('should reject name with special characters', () {
        expect(InputValidators.name('Juan@Pérez'), isNotNull);
        expect(InputValidators.name('Juan#Pérez'), isNotNull);
      });

      test('should reject name that is too short', () {
        expect(InputValidators.name('A'), isNotNull);
      });

      test('should reject name that is too long', () {
        final longName = 'A' * 101;
        expect(InputValidators.name(longName), isNotNull);
      });
    });

    group('Document Number Validator', () {
      test('should accept valid Colombian document numbers', () {
        expect(InputValidators.documentNumber('123456'), isNull);
        expect(InputValidators.documentNumber('1234567890'), isNull);
        expect(InputValidators.documentNumber('12345678'), isNull);
      });

      test('should reject document number with letters', () {
        expect(InputValidators.documentNumber('123ABC'), isNotNull);
      });

      test('should reject document number that is too short', () {
        expect(InputValidators.documentNumber('12345'), isNotNull);
      });

      test('should reject document number that is too long', () {
        expect(InputValidators.documentNumber('12345678901'), isNotNull);
      });

      test('should reject empty document number', () {
        expect(InputValidators.documentNumber(''), isNotNull);
        expect(InputValidators.documentNumber(null), isNotNull);
      });
    });

    group('Security Helpers', () {
      test('should sanitize dangerous input', () {
        final dangerous = 'Hello<script>alert(1)</script>World';
        final sanitized = InputValidators.sanitize(dangerous);
        expect(sanitized, isNot(contains('<script>')));
      });

      test('should remove control characters', () {
        final withControl = 'Hello\x00\x01\x02World';
        final sanitized = InputValidators.sanitize(withControl);
        expect(sanitized, 'HelloWorld');
      });

      test('should trim whitespace', () {
        final withWhitespace = '  Hello World  ';
        final sanitized = InputValidators.sanitize(withWhitespace);
        expect(sanitized, 'Hello World');
      });
    });

    group('Compose Validators', () {
      test('should pass all validators', () {
        final validator = InputValidators.compose([
          InputValidators.required,
          InputValidators.minLength(3),
          InputValidators.maxLength(10),
        ]);

        expect(validator('test'), isNull);
        expect(validator('hello'), isNull);
      });

      test('should fail on first validator error', () {
        final validator = InputValidators.compose([
          InputValidators.required,
          InputValidators.minLength(3),
        ]);

        expect(validator(''), isNotNull); // Fails required
        expect(validator('ab'), isNotNull); // Fails minLength
      });
    });
  });
}
