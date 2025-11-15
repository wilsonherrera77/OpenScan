/// Input Sanitizer
/// Security utility to prevent injection attacks
class InputSanitizer {
  /// Sanitize string input by removing dangerous characters
  static String sanitize(String input) {
    return input
        // Remove HTML/script tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Remove dangerous characters
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .replaceAll('`', '')
        .replaceAll(';', '')
        // Remove newlines
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        // Trim whitespace
        .trim();
  }

  /// Sanitize optional string (null-safe)
  static String? sanitizeOptional(String? input) {
    if (input == null || input.isEmpty) return null;
    return sanitize(input);
  }

  /// Sanitize and validate document number
  static String? sanitizeDocumentNumber(String? input) {
    if (input == null || input.isEmpty) return null;

    final sanitized = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (sanitized.isEmpty) return null;
    if (sanitized.length < 6 || sanitized.length > 15) return null;

    return sanitized;
  }

  /// Validate and sanitize person ID
  static bool isValidPersonId(String personId) {
    if (personId.isEmpty) return false;

    // Allow alphanumeric and underscore
    final pattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    return pattern.hasMatch(personId);
  }

  /// Sanitize filename
  static String sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'\.\.'), '.')
        .trim();
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Sanitize for logging (remove sensitive data)
  static String sanitizeForLogging(String message) {
    return message
        .replaceAll(RegExp(r'(token|password|api_key)[:=]\s*[^\s,]+', caseSensitive: false), r'$1: [REDACTED]')
        .replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[EMAIL_REDACTED]');
  }
}
