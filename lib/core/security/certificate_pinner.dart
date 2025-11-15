import 'dart:io';
import '../../services/logger_adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';

/// Certificate Pinner
/// Implements certificate pinning to prevent MITM attacks
///
/// SECURITY: Certificate pinning validates that the server's SSL certificate
/// matches known good certificates, preventing man-in-the-middle attacks.
class CertificatePinner {
  final LoggerAdapter _logger = LoggerAdapter();

  /// Known certificate SHA-256 fingerprints
  ///
  /// PRODUCTION: Add your Paperless server's certificate fingerprints here
  ///
  /// To get fingerprint:
  /// ```bash
  /// openssl s_client -connect your-server.com:443 < /dev/null 2>/dev/null | \
  ///   openssl x509 -fingerprint -sha256 -noout -in /dev/stdin
  /// ```
  static const List<String> pinnedCertificates = [
    // Example: 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99'
    // Add your production certificates here
  ];

  /// Enable certificate pinning on Dio client
  ///
  /// WARNING: Only enable in production with valid certificates
  /// Development/testing should use standard SSL validation
  void enablePinning(Dio dio, {bool allowBadCertificates = false}) {
    if (pinnedCertificates.isEmpty) {
      _logger.w('⚠️ Certificate pinning enabled but no certificates configured');
      if (!allowBadCertificates) {
        throw StateError(
          'Certificate pinning requires configured certificates. '
          'Add fingerprints to CertificatePinner.pinnedCertificates',
        );
      }
    }

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      // Security context configuration
      client.badCertificateCallback = (cert, host, port) {
        _logger.d('🔐 Validating certificate for $host:$port');

        // DEVELOPMENT: Allow self-signed certificates
        if (allowBadCertificates) {
          _logger.w('⚠️ Allowing bad certificates (DEVELOPMENT ONLY)');
          return true;
        }

        // PRODUCTION: Validate certificate pinning
        return _validateCertificate(cert, host);
      };

      return client;
    };

    _logger.i('🔐 Certificate pinning enabled');
  }

  /// Validate certificate against pinned fingerprints
  bool _validateCertificate(X509Certificate cert, String host) {
    try {
      // Get certificate SHA-256 fingerprint
      final certFingerprint = _getCertificateFingerprint(cert);

      _logger.d('Certificate fingerprint: $certFingerprint');

      // Check if certificate matches any pinned certificate
      final isValid = pinnedCertificates.contains(certFingerprint);

      if (!isValid) {
        _logger.e('❌ Certificate validation FAILED for $host');
        _logger.e('Expected one of: $pinnedCertificates');
        _logger.e('Got: $certFingerprint');
      } else {
        _logger.i('✅ Certificate validated for $host');
      }

      return isValid;
    } catch (e, stackTrace) {
      _logger.e('❌ Certificate validation error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Extract SHA-256 fingerprint from certificate
  String _getCertificateFingerprint(X509Certificate cert) {
    // Get DER-encoded certificate
    final der = cert.der;

    // Calculate SHA-256 hash
    final digest = _sha256Digest(der);

    // Format as colon-separated hex string
    return digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Calculate SHA-256 digest
  List<int> _sha256Digest(List<int> data) {
    return sha256.convert(data).bytes;
  }

  /// Disable certificate pinning (testing only)
  void disablePinning(Dio dio) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // Use default certificate validation
      client.badCertificateCallback = null;
      return client;
    };

    _logger.i('🔓 Certificate pinning disabled');
  }

  /// Validate that certificate pinning is configured correctly
  static bool isConfigured() {
    return pinnedCertificates.isNotEmpty;
  }

  /// Get list of pinned certificate fingerprints (for debugging)
  static List<String> getPinnedCertificates() {
    return List.unmodifiable(pinnedCertificates);
  }
}

/// Certificate Pinning Configuration
class CertificatePinningConfig {
  /// Enable certificate pinning
  static const bool enabled = bool.fromEnvironment(
    'ENABLE_CERTIFICATE_PINNING',
    defaultValue: false, // Disabled by default (requires configuration)
  );

  /// Allow bad certificates (DEVELOPMENT ONLY)
  ///
  /// WARNING: Never enable in production
  static const bool allowBadCertificates = bool.fromEnvironment(
    'ALLOW_BAD_CERTIFICATES',
    defaultValue: false,
  );

  /// Check if should enable pinning based on environment
  static bool shouldEnablePinning() {
    // Production: Enable if configured
    if (const bool.fromEnvironment('dart.vm.product')) {
      return enabled && CertificatePinner.isConfigured();
    }

    // Development: Optional
    return enabled;
  }
}
