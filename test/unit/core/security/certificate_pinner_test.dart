import 'package:flutter_test/flutter_test.dart';
import 'package:lumara_indigenas/core/security/certificate_pinner.dart';

void main() {
  group('CertificatePinner', () {
    test('should report not configured when no certificates pinned', () {
      expect(CertificatePinner.isConfigured(), false);
    });

    test('should return pinned certificates list', () {
      final certs = CertificatePinner.getPinnedCertificates();
      expect(certs, isA<List<String>>());
    });
  });

  group('CertificatePinningConfig', () {
    test('should have default values', () {
      expect(CertificatePinningConfig.enabled, isA<bool>());
      expect(CertificatePinningConfig.allowBadCertificates, isA<bool>());
    });

    test('shouldEnablePinning should return false in dev without config', () {
      final result = CertificatePinningConfig.shouldEnablePinning();
      expect(result, false); // Not configured by default
    });
  });
}
