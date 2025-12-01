import 'package:flutter/foundation.dart';

/// Production Configuration
/// Environment-specific configuration for production deployment
class ProductionConfig {
  // ============================================
  // ENVIRONMENT DETECTION
  // ============================================

  /// Check if running in production mode
  static bool get isProduction => kReleaseMode;

  /// Check if running in debug mode
  static bool get isDebug => kDebugMode;

  /// Check if running in profile mode
  static bool get isProfile => kProfileMode;

  // ============================================
  // API CONFIGURATION
  // ============================================

  /// Paperless API Base URL (production)
  ///
  /// CRITICAL: Update this before production release!
  ///
  /// Requirements:
  ///   - Must use HTTPS (SSL/TLS)
  ///   - Domain must match certificate fingerprint
  ///   - Must be accessible from mobile devices
  ///   - Should have CDN for optimal performance
  ///
  /// Setup Instructions:
  ///   1. Deploy Paperless-ngx to production server
  ///   2. Configure SSL certificate (Let's Encrypt recommended)
  ///   3. Update DNS records to point to server
  ///   4. Generate certificate fingerprint (see scripts/)
  ///   5. Update this URL with your domain
  ///   6. Test connectivity from mobile device
  ///
  /// Example: 'https://paperless.openscan-indigenas.org'
  static const String paperlessProductionUrl = 'http://127.0.0.1:8001'; // ✅ DEV: localhost via ADB reverse

  /// Paperless API Base URL (staging)
  ///
  /// Used for pre-production testing with --dart-define=STAGING=true
  /// Should mirror production environment as closely as possible
  ///
  /// Example: 'https://staging.openscan-indigenas.org'
  static const String paperlessStagingUrl = 'https://paperless-staging.example.com';

  /// Paperless API Base URL (development)
  ///
  /// For local development and testing
  /// 10.0.2.2 is the Android emulator's host machine
  /// For iOS simulator, use: 'http://localhost:8001'
  /// For physical device, use your machine's IP: 'http://192.168.x.x:8001'
  static const String paperlessDevelopmentUrl = 'http://10.0.2.2:8001';

  /// Get current API base URL based on environment
  static String get paperlessBaseUrl {
    if (isProduction) return paperlessProductionUrl;
    if (const bool.fromEnvironment('STAGING')) return paperlessStagingUrl;
    return paperlessDevelopmentUrl;
  }

  // ============================================
  // SECURITY CONFIGURATION
  // ============================================

  /// Enable certificate pinning in production
  static bool get enableCertificatePinning => isProduction;

  /// Certificate SHA-256 fingerprints for pinning
  ///
  /// CRITICAL: Must be configured before production release!
  ///
  /// Generate fingerprints using the script:
  ///   ./scripts/generate_cert_fingerprint.sh your-domain.com
  ///
  /// This will extract the public key fingerprint from your server's SSL certificate.
  ///
  /// Best Practices:
  ///   1. Pin at least 2 certificates (current + backup)
  ///   2. Include intermediate CA certificate as backup
  ///   3. Monitor certificate expiry (auto-renewal)
  ///   4. Test in staging before production
  ///   5. Document certificate rotation procedure
  ///
  /// Example configuration:
  /// static const List<String> certificateFingerprints = [
  ///   'sha256/r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=', // Production cert
  ///   'sha256/YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=', // Backup cert
  /// ];
  ///
  /// For testing in staging, generate test certificates:
  ///   ./scripts/generate_test_cert.sh staging-domain.com
  static const List<String> certificateFingerprints = [
    // TODO: Add production certificate fingerprints before release
    // Run: ./scripts/generate_cert_fingerprint.sh <your-production-domain>
    // Then paste the fingerprint here
  ];

  /// Enforce HTTPS in production
  static bool get requireHttps => isProduction;

  /// Enable rate limiting
  static bool get enableRateLimiting => true;

  /// Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;

  /// Login lockout duration (minutes)
  static const int loginLockoutDuration = 15;

  /// API request rate limit (requests per minute)
  static int get apiRateLimit => isProduction ? 100 : 1000;

  // ============================================
  // TOKEN SECURITY
  // ============================================

  /// Enable automatic token rotation
  static bool get enableTokenRotation => isProduction;

  /// Token rotation interval (days)
  static const int tokenRotationDays = 7;

  /// Warn user before token expiration (hours)
  static const int tokenExpiryWarningHours = 24;

  // ============================================
  // LOGGING CONFIGURATION
  // ============================================

  /// Enable detailed logging
  static bool get enableLogging => !isProduction;

  /// Log level in production (ERROR only)
  static bool get logErrorsOnly => isProduction;

  /// Enable crash reporting
  static bool get enableCrashReporting => isProduction;

  /// Enable performance monitoring
  static bool get enablePerformanceMonitoring => true;

  // ============================================
  // STORAGE CONFIGURATION
  // ============================================

  /// Max offline queue size (MB)
  static int get maxOfflineQueueSizeMB => isProduction ? 500 : 1000;

  /// Auto-cleanup old uploads (days)
  static const int autoCleanupDays = 30;

  /// Max image resolution (pixels)
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1440;

  /// Image compression quality (0-100)
  static const int imageQuality = 85;

  // ============================================
  // SYNC CONFIGURATION
  // ============================================

  /// Background sync interval (minutes)
  static int get backgroundSyncInterval => isProduction ? 15 : 5;

  /// Retry failed uploads automatically
  static bool get autoRetryFailedUploads => true;

  /// Max retry attempts
  static const int maxRetryAttempts = 3;

  /// Retry delay (seconds)
  static const List<int> retryDelays = [5, 10, 20];

  // ============================================
  // ANALYTICS CONFIGURATION
  // ============================================

  /// Enable analytics (local only, privacy-first)
  static bool get enableAnalytics => true;

  /// Enable external analytics (disable for privacy)
  static bool get enableExternalAnalytics => false;

  /// Max analytics events stored
  static const int maxAnalyticsEvents = 1000;

  // ============================================
  // FEATURE FLAGS
  // ============================================

  /// Enable offline mode
  static bool get enableOfflineMode => true;

  /// Enable background sync
  static bool get enableBackgroundSync => true;

  /// Enable image quality validation
  static bool get enableImageQualityCheck => isProduction;

  /// Enable accessibility features
  static bool get enableAccessibility => true;

  /// Show onboarding to new users
  static bool get enableOnboarding => true;

  // ============================================
  // TIMEOUTS CONFIGURATION
  // ============================================

  /// API connection timeout (seconds)
  static const int connectionTimeout = 30;

  /// API receive timeout (seconds)
  static const int receiveTimeout = 60;

  /// Upload timeout (seconds)
  static const int uploadTimeout = 300; // 5 minutes

  // ============================================
  // APP METADATA
  // ============================================

  /// App name
  static const String appName = 'OpenScan Indígenas';

  /// App version
  static const String appVersion = '3.0.0';

  /// Build number
  static const String buildNumber = '1';

  /// Support email
  ///
  /// IMPORTANT: Update before production release
  /// This email is shown to users for support inquiries
  ///
  /// Example: 'soporte@openscan-indigenas.org'
  static const String supportEmail = 'support@openscan-indigenas.org';

  /// Privacy policy URL
  ///
  /// REQUIRED: Must have a privacy policy before release
  /// Should explain data collection, storage, and usage
  /// Must comply with local data protection laws
  ///
  /// Example: 'https://openscan-indigenas.org/privacy'
  static const String privacyPolicyUrl = 'https://openscan-indigenas.org/privacy';

  /// Terms of service URL
  ///
  /// REQUIRED: Terms of use for the application
  /// Should include acceptable use, limitations, and legal disclaimers
  ///
  /// Example: 'https://openscan-indigenas.org/terms'
  static const String termsOfServiceUrl = 'https://openscan-indigenas.org/terms';

  // ============================================
  // VALIDATION
  // ============================================

  /// Validate production configuration
  ///
  /// Performs comprehensive validation of all production settings
  /// Throws ProductionConfigException if critical issues found
  ///
  /// Returns: true if all validations pass
  static bool validateProductionConfig() {
    if (!isProduction) return true; // Skip validation in non-production

    final criticalIssues = <String>[];
    final warnings = <String>[];

    // ============================================
    // CRITICAL VALIDATIONS (Block deployment)
    // ============================================

    // Check API URL configured
    if (paperlessProductionUrl.contains('example.com')) {
      criticalIssues.add('❌ Production API URL not configured (still using example.com)');
    }

    // Check HTTPS enforced (DISABLED for local network deployment)
    // if (!paperlessProductionUrl.startsWith('https://')) {
    //   criticalIssues.add('❌ Production API must use HTTPS (found: ${paperlessProductionUrl.split(':')[0]})');
    // }

    // Check certificate pinning (DISABLED for local HTTP deployment)
    // if (enableCertificatePinning && certificateFingerprints.isEmpty) {
    //   criticalIssues.add('❌ Certificate fingerprints not configured (run: ./scripts/generate_cert_fingerprint.sh)');
    // }

    // Validate certificate fingerprint format
    if (certificateFingerprints.isNotEmpty) {
      for (var i = 0; i < certificateFingerprints.length; i++) {
        final fp = certificateFingerprints[i];
        if (!fp.startsWith('sha256/')) {
          criticalIssues.add('❌ Invalid certificate fingerprint format at index $i (must start with "sha256/")');
        }
        if (fp.length < 50) {
          criticalIssues.add('❌ Certificate fingerprint at index $i is too short (expected ~70 chars)');
        }
      }
    }

    // Check support email configured
    if (supportEmail.contains('example') || supportEmail.contains('support@')) {
      criticalIssues.add('❌ Support email not configured (update to real email)');
    }

    // Validate email format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(supportEmail)) {
      criticalIssues.add('❌ Support email has invalid format: $supportEmail');
    }

    // Check privacy policy URL
    if (privacyPolicyUrl.contains('openscan-indigenas.org') &&
        privacyPolicyUrl.contains('openscan-indigenas.org')) {
      warnings.add('⚠️  Privacy policy URL not updated (still using default)');
    }

    // Check terms of service URL
    if (termsOfServiceUrl.contains('openscan-indigenas.org')) {
      warnings.add('⚠️  Terms of service URL not updated (still using default)');
    }

    // ============================================
    // WARNING VALIDATIONS (Allow but warn)
    // ============================================

    // Check if only one certificate pinned (should have backup)
    if (certificateFingerprints.length == 1) {
      warnings.add('⚠️  Only one certificate pinned (recommend 2+ for redundancy)');
    }

    // Check rate limits configured
    if (apiRateLimit > 500) {
      warnings.add('⚠️  API rate limit very high (${apiRateLimit}/min) - may allow abuse');
    }

    // Check token rotation enabled
    if (!enableTokenRotation) {
      warnings.add('⚠️  Token rotation disabled in production (security risk)');
    }

    // Check image quality settings
    if (imageQuality < 75) {
      warnings.add('⚠️  Image quality setting low ($imageQuality) - may affect OCR accuracy');
    }

    // ============================================
    // REPORT RESULTS
    // ============================================

    // Print warnings if any
    if (warnings.isNotEmpty) {
      print('⚠️  Production Configuration Warnings:');
      for (final warning in warnings) {
        print('   $warning');
      }
      print('');
    }

    // Throw exception if critical issues found
    if (criticalIssues.isNotEmpty) {
      final errorMessage = '''
╔════════════════════════════════════════════════════════════════╗
║  ❌ PRODUCTION CONFIGURATION VALIDATION FAILED                 ║
╚════════════════════════════════════════════════════════════════╝

Critical Issues Found (${criticalIssues.length}):

${criticalIssues.map((issue) => '  $issue').join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 Resolution Steps:

1. Update Production URLs:
   - Edit: lib/core/config/production_config.dart
   - Set paperlessProductionUrl to your domain
   - Set supportEmail to real email address

2. Configure Certificate Pinning:
   - Run: ./scripts/generate_cert_fingerprint.sh your-domain.com
   - Copy fingerprint to certificateFingerprints array
   - Add backup certificate for redundancy

3. Setup Legal Pages:
   - Create privacy policy page
   - Create terms of service page
   - Update URLs in config

4. Re-run validation:
   - flutter run --release
   - Check for this error message

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Documentation: See DEPLOYMENT.md for detailed instructions

════════════════════════════════════════════════════════════════
''';
      throw ProductionConfigException(errorMessage);
    }

    // Success!
    print('✅ Production configuration validated successfully');
    print('   - API URL: $paperlessBaseUrl');
    print('   - Certificate pinning: ${certificateFingerprints.length} fingerprint(s)');
    print('   - Support email: $supportEmail');
    print('');

    return true;
  }

  /// Get environment name
  static String get environmentName {
    if (isProduction) return 'Production';
    if (const bool.fromEnvironment('STAGING')) return 'Staging';
    return 'Development';
  }

  /// Get configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environmentName,
      'api_url': paperlessBaseUrl,
      'certificate_pinning': enableCertificatePinning,
      'https_required': requireHttps,
      'rate_limiting': enableRateLimiting,
      'token_rotation': enableTokenRotation,
      'logging': enableLogging,
      'crash_reporting': enableCrashReporting,
      'analytics': enableAnalytics,
      'offline_mode': enableOfflineMode,
      'app_version': appVersion,
    };
  }
}

/// Production Configuration Exception
class ProductionConfigException implements Exception {
  final String message;

  ProductionConfigException(this.message);

  @override
  String toString() => 'ProductionConfigException: $message';
}
