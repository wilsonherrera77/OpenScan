/// Input Validators
///
/// Provides security-focused input validation for forms
///
/// Security Features:
/// - SQL injection prevention
/// - XSS prevention (script tag detection)
/// - Email validation (RFC 5322)
/// - URL validation with scheme enforcement
/// - Password strength validation
/// - Custom regex validators
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: InputValidators.username,
/// );
///
/// TextFormField(
///   validator: InputValidators.password,
/// );
/// ```
class InputValidators {
  // ═══════════════════════════════════════════════════════════
  // AUTHENTICATION VALIDATORS
  // ═══════════════════════════════════════════════════════════

  /// Username validator
  ///
  /// Requirements:
  /// - 3-30 characters
  /// - Alphanumeric, underscore, hyphen only
  /// - No SQL injection patterns
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre de usuario es requerido';
    }

    if (value.length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }

    if (value.length > 30) {
      return 'El nombre de usuario no puede exceder 30 caracteres';
    }

    // Only alphanumeric, underscore, hyphen
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números, guiones y guiones bajos';
    }

    // Check for SQL injection patterns
    if (_containsSqlInjection(value)) {
      return 'Caracteres no permitidos detectados';
    }

    return null;
  }

  /// Password validator
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  /// - At least one special character
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Check for uppercase
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra mayúscula';
    }

    // Check for lowercase
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una letra minúscula';
    }

    // Check for digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }

    // Check for special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Debe contener al menos un carácter especial';
    }

    return null;
  }

  /// Simple password validator (less strict)
  ///
  /// Requirements:
  /// - Minimum 6 characters
  static String? passwordSimple(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  /// Confirm password validator
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirme su contraseña';
      }

      if (value != password) {
        return 'Las contraseñas no coinciden';
      }

      return null;
    };
  }

  // ═══════════════════════════════════════════════════════════
  // URL VALIDATORS
  // ═══════════════════════════════════════════════════════════

  /// URL validator
  ///
  /// Requirements:
  /// - Valid URL format
  /// - Must have scheme (http/https)
  /// - No XSS patterns
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'La URL es requerida';
    }

    // Check for XSS patterns
    if (_containsXss(value)) {
      return 'URL no válida';
    }

    // Validate URL format
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Formato de URL no válido. Ejemplo: http://192.168.1.100:8000';
    }

    // Only allow http and https
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Solo se permiten URLs con http:// o https://';
    }

    return null;
  }

  /// HTTPS-only URL validator
  static String? httpsUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'La URL es requerida';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Formato de URL no válido';
    }

    if (uri.scheme != 'https') {
      return 'Solo se permiten URLs con https://';
    }

    return null;
  }

  /// IP address validator
  static String? ipAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'La dirección IP es requerida';
    }

    // IPv4 validation
    final ipv4Pattern = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipv4Pattern.hasMatch(value)) {
      return 'Dirección IP no válida. Ejemplo: 192.168.1.100';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // PERSONAL DATA VALIDATORS
  // ═══════════════════════════════════════════════════════════

  /// Email validator (RFC 5322 compliant)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    if (value.length > 254) {
      return 'El email es demasiado largo';
    }

    // Check for XSS patterns
    if (_containsXss(value)) {
      return 'Email no válido';
    }

    // RFC 5322 email validation
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailPattern.hasMatch(value)) {
      return 'Email no válido';
    }

    return null;
  }

  /// Name validator (person name)
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (value.length > 100) {
      return 'El nombre es demasiado largo';
    }

    // Allow letters, spaces, hyphens, apostrophes, accented characters
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s'-]+$").hasMatch(value)) {
      return 'El nombre solo puede contener letras, espacios y guiones';
    }

    // Check for XSS patterns
    if (_containsXss(value)) {
      return 'Nombre no válido';
    }

    return null;
  }

  /// Phone number validator (Colombian format)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de teléfono es requerido';
    }

    // Remove spaces and hyphens
    final cleanedNumber = value.replaceAll(RegExp(r'[\s-]'), '');

    // Colombian mobile: 10 digits starting with 3
    // Colombian landline: 7 or 10 digits
    if (!RegExp(r'^3[0-9]{9}$|^[0-9]{7,10}$').hasMatch(cleanedNumber)) {
      return 'Número de teléfono no válido';
    }

    return null;
  }

  /// Document number validator (Colombian ID)
  static String? documentNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de documento es requerido';
    }

    // Remove spaces
    final cleanedNumber = value.replaceAll(' ', '');

    // Colombian ID: 6-10 digits
    if (!RegExp(r'^[0-9]{6,10}$').hasMatch(cleanedNumber)) {
      return 'Número de documento no válido (6-10 dígitos)';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // GENERIC VALIDATORS
  // ═══════════════════════════════════════════════════════════

  /// Required field validator
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    return null;
  }

  /// Minimum length validator
  static String? Function(String?) minLength(int length) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Este campo es requerido';
      }

      if (value.length < length) {
        return 'Debe tener al menos $length caracteres';
      }

      return null;
    };
  }

  /// Maximum length validator
  static String? Function(String?) maxLength(int length) {
    return (String? value) {
      if (value != null && value.length > length) {
        return 'No puede exceder $length caracteres';
      }

      return null;
    };
  }

  /// Number validator
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    if (int.tryParse(value) == null) {
      return 'Debe ser un número válido';
    }

    return null;
  }

  /// Positive number validator
  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Debe ser un número válido';
    }

    if (number <= 0) {
      return 'Debe ser un número positivo';
    }

    return null;
  }

  /// Range validator
  static String? Function(String?) range(int min, int max) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Este campo es requerido';
      }

      final number = int.tryParse(value);
      if (number == null) {
        return 'Debe ser un número válido';
      }

      if (number < min || number > max) {
        return 'Debe estar entre $min y $max';
      }

      return null;
    };
  }

  /// Custom regex validator
  static String? Function(String?) regex(RegExp pattern, String errorMessage) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Este campo es requerido';
      }

      if (!pattern.hasMatch(value)) {
        return errorMessage;
      }

      return null;
    };
  }

  /// Compose multiple validators
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  // ═══════════════════════════════════════════════════════════
  // SECURITY HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Check for SQL injection patterns
  static bool _containsSqlInjection(String value) {
    final sqlPatterns = [
      RegExp(r"'.*--", caseSensitive: false),
      RegExp(r"';.*--", caseSensitive: false),
      RegExp(r"' OR '1'='1", caseSensitive: false),
      RegExp(r"' OR 1=1", caseSensitive: false),
      RegExp(r" DROP TABLE ", caseSensitive: false),
      RegExp(r" DELETE FROM ", caseSensitive: false),
      RegExp(r" INSERT INTO ", caseSensitive: false),
      RegExp(r" UPDATE .* SET ", caseSensitive: false),
      RegExp(r"UNION.*SELECT", caseSensitive: false),
      RegExp(r"EXEC\s*\(", caseSensitive: false),
    ];

    return sqlPatterns.any((pattern) => pattern.hasMatch(value));
  }

  /// Check for XSS patterns
  static bool _containsXss(String value) {
    final xssPatterns = [
      RegExp(r"<script", caseSensitive: false),
      RegExp(r"</script", caseSensitive: false),
      RegExp(r"javascript:", caseSensitive: false),
      RegExp(r"onerror\s*=", caseSensitive: false),
      RegExp(r"onload\s*=", caseSensitive: false),
      RegExp(r"onclick\s*=", caseSensitive: false),
      RegExp(r"<iframe", caseSensitive: false),
      RegExp(r"<embed", caseSensitive: false),
      RegExp(r"<object", caseSensitive: false),
    ];

    return xssPatterns.any((pattern) => pattern.hasMatch(value));
  }

  /// Sanitize input (remove dangerous characters)
  static String sanitize(String value) {
    // Remove control characters
    String sanitized = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Remove common XSS patterns
    sanitized = sanitized.replaceAll(RegExp(r'<script.*?>.*?</script>', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'<.*?on\w+\s*=.*?>', caseSensitive: false), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    return sanitized;
  }
}
