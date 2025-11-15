# 🔒 Security Testing Checklist

**Project:** OpenScan Indígenas
**Version:** 3.0.0
**Last Updated:** 2025-10-07

---

## 📋 Overview

This checklist covers all security testing that must be performed before production deployment. Each item should be tested, documented, and signed off by the security team.

**Testing Levels:**
- 🔴 **Critical** - Must pass before production
- 🟠 **High** - Should pass, document if not
- 🟡 **Medium** - Nice to have, acceptable risks
- 🟢 **Low** - Optional, informational

---

## 1. AUTHENTICATION & SESSION MANAGEMENT

### 1.1 Login Security

- [ ] 🔴 **Password Requirements**
  - Minimum 8 characters enforced
  - Complexity requirements (if applicable)
  - No common passwords accepted

- [ ] 🔴 **Brute Force Protection**
  - Rate limiting active (5 attempts / 15 min)
  - Account lockout working
  - Error messages don't reveal user existence

- [ ] 🔴 **Session Management**
  - Token securely stored (flutter_secure_storage)
  - Token not exposed in logs
  - Session timeout working
  - Logout clears all session data

**Test Commands:**
```bash
# Test rate limiting
for i in {1..10}; do
  curl -X POST https://api/login \
    -d '{"username":"test","password":"wrong"}' \
    -w "Attempt $i: %{http_code}\n"
done

# Expected: First 5 return 401, then 429 (Too Many Requests)
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
Tested by: _____________
Date: __________________
```

---

### 1.2 Token Security

- [ ] 🔴 **Token Storage**
  - Tokens stored in secure storage (not SharedPreferences)
  - Tokens not accessible by other apps
  - Tokens encrypted at rest

- [ ] 🔴 **Token Rotation**
  - Automatic rotation every 7 days
  - Rotation timestamp recorded
  - Old tokens invalidated

- [ ] 🟠 **Token Expiry**
  - Tokens expire after inactivity
  - Refresh mechanism working
  - Expired tokens rejected

**Manual Test:**
```dart
// Check token storage
final token = await SecureConfigManager().getApiToken();
print('Token length: ${token?.length}'); // Should be >20 chars
print('Storage: flutter_secure_storage'); // Verify

// Check rotation
final needsRotation = await SecureConfigManager().needsTokenRotation();
print('Needs rotation: $needsRotation');
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 2. DATA PROTECTION

### 2.1 Encryption at Rest

- [ ] 🔴 **File Encryption**
  - Documents encrypted before storage
  - AES-256-GCM algorithm used
  - Unique IV for each file
  - Encryption keys securely stored

- [ ] 🔴 **Database Encryption**
  - Sensitive fields encrypted (person IDs, etc.)
  - SQLite database uses SQLCipher (if enabled)
  - Encryption keys in secure storage

- [ ] 🟠 **Analytics Data**
  - PII removed from analytics
  - Local storage only (no external transmission)
  - Can be cleared by user

**Test Script:**
```bash
# Check if files are encrypted
adb shell "run-as com.openscan.indigenas ls -la /data/data/com.openscan.indigenas/files/"
# Files should have .encrypted extension

# Verify encryption
adb pull /data/data/.../file.jpg.encrypted
file file.jpg.encrypted
# Should NOT show "JPEG" or readable format
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

### 2.2 Encryption in Transit

- [ ] 🔴 **HTTPS Enforcement**
  - All API calls use HTTPS
  - HTTP requests blocked in production
  - No mixed content

- [ ] 🔴 **Certificate Pinning**
  - Certificate fingerprints configured
  - Pinning validation working
  - Invalid certificates rejected

- [ ] 🔴 **TLS Version**
  - TLS 1.2+ required
  - Weak ciphers disabled
  - Perfect Forward Secrecy enabled

**Test Commands:**
```bash
# Test HTTPS enforcement
curl -v http://paperless.your-domain.com/api/
# Should redirect to HTTPS or reject

# Test certificate pinning (with invalid cert)
# Expected: Connection rejected

# Check TLS version
nmap --script ssl-enum-ciphers -p 443 paperless.your-domain.com
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 3. INPUT VALIDATION

### 3.1 Sanitization

- [ ] 🔴 **XSS Prevention**
  - HTML tags stripped from user input
  - Script tags blocked
  - Event handlers removed

- [ ] 🔴 **SQL Injection Prevention**
  - Parameterized queries used
  - ORM (Drift) prevents injection
  - No raw SQL with user input

- [ ] 🔴 **Path Traversal Prevention**
  - File paths sanitized
  - Directory traversal blocked (../)
  - Only allowed directories accessible

**Test Cases:**
```dart
// XSS Tests
final xssPayloads = [
  '<script>alert(1)</script>',
  '<img src=x onerror=alert(1)>',
  'javascript:alert(1)',
];

for (var payload in xssPayloads) {
  final sanitized = InputSanitizer.sanitize(payload);
  assert(!sanitized.contains('<script>'));
  assert(!sanitized.contains('javascript:'));
}

// Path Traversal Tests
final pathPayloads = [
  '../../../etc/passwd',
  '..\\..\\windows\\system32',
  '/etc/shadow',
];

for (var payload in pathPayloads) {
  final sanitized = InputSanitizer.sanitizeFilename(payload);
  assert(!sanitized.contains('..'));
  assert(!sanitized.contains('/etc'));
}
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

### 3.2 File Upload Security

- [ ] 🔴 **File Type Validation**
  - Only allowed file types accepted (jpg, png, pdf)
  - MIME type validation
  - File extension validation

- [ ] 🔴 **File Size Limits**
  - Maximum file size enforced (100MB)
  - Memory limits respected
  - Large files handled gracefully

- [ ] 🟠 **Malware Scanning**
  - Files scanned for viruses (if enabled)
  - Suspicious files quarantined
  - Users notified of threats

**Test Cases:**
```bash
# Test file type restriction
curl -X POST https://api/upload \
  -F "file=@malicious.exe" \
  -H "Authorization: Bearer TOKEN"
# Expected: 400 Bad Request

# Test file size limit
dd if=/dev/zero of=huge.jpg bs=1M count=200
curl -X POST https://api/upload -F "file=@huge.jpg"
# Expected: 413 Payload Too Large
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 4. AUTHORIZATION & ACCESS CONTROL

### 4.1 API Authorization

- [ ] 🔴 **Token Verification**
  - All API endpoints require valid token
  - Expired tokens rejected
  - Invalid tokens return 401

- [ ] 🔴 **User-Level Access**
  - Users can only access own data
  - Cross-user access blocked
  - Admin privileges required for admin endpoints

- [ ] 🟠 **Rate Limiting**
  - API rate limits enforced
  - Per-user rate limits
  - Rate limit headers present

**Test Script:**
```bash
# Test without token
curl https://api/documents
# Expected: 401 Unauthorized

# Test with expired token
curl https://api/documents -H "Authorization: Bearer EXPIRED_TOKEN"
# Expected: 401 Unauthorized

# Test cross-user access
curl https://api/documents/user2_document_id -H "Authorization: Bearer USER1_TOKEN"
# Expected: 403 Forbidden
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

### 4.2 Device Security

- [ ] 🟠 **Root/Jailbreak Detection**
  - Rooted devices detected (warning shown)
  - Option to block on rooted devices
  - Security warning displayed

- [ ] 🟠 **Screen Capture Prevention**
  - Sensitive screens not capturable
  - FLAG_SECURE set on sensitive views
  - Screenshots blocked on key screens

- [ ] 🟡 **Biometric Authentication**
  - Touch ID / Face ID supported (optional)
  - Fallback to password
  - Biometric data stays on device

**Manual Test:**
```
1. Install on rooted device
2. Attempt to take screenshot of login screen
3. Enable biometric auth (if available)
4. Test login with fingerprint
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 5. LOGGING & MONITORING

### 5.1 Secure Logging

- [ ] 🔴 **PII Redaction**
  - Passwords never logged
  - Tokens sanitized in logs
  - Personal data redacted

- [ ] 🔴 **Error Messages**
  - No stack traces in production
  - Generic error messages to users
  - Detailed logs stored securely

- [ ] 🟠 **Audit Trail**
  - Login attempts logged
  - Document operations logged
  - Failed access logged

**Test Cases:**
```dart
// Check log sanitization
final logs = await ErrorReporter().getRecentErrors();
for (var log in logs) {
  assert(!log.contains('password'));
  assert(!log.contains('token'));
  assert(!log.contains(RegExp(r'\d{10}'))); // No phone numbers
}
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

### 5.2 Monitoring & Alerting

- [ ] 🟠 **Error Reporting**
  - Crashes captured and reported
  - Errors include context (no PII)
  - Error rate monitored

- [ ] 🟡 **Performance Monitoring**
  - Slow operations tracked
  - Memory leaks detected
  - Battery drain monitored

- [ ] 🟡 **Security Alerts**
  - Failed login alerts
  - Certificate expiry alerts
  - Unusual activity alerts

**Verification:**
```
1. Trigger crash (test mode)
2. Check error reporter dashboard
3. Verify alert received
4. Confirm no PII in report
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 6. NETWORK SECURITY

### 6.1 API Security

- [ ] 🔴 **Certificate Validation**
  - SSL certificates validated
  - Self-signed certs rejected
  - Certificate chain verified

- [ ] 🔴 **Certificate Pinning**
  - Public key pinned
  - Connection fails with wrong cert
  - Backup pins configured

- [ ] 🟠 **Network Security Config**
  - Cleartext traffic disabled (production)
  - Debug certificates disabled (production)
  - Security config enforced

**Android Network Security Config:**
```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">paperless.your-domain.com</domain>
        <pin-set expiration="2026-01-01">
            <pin digest="SHA-256">YOUR_PIN_HERE</pin>
            <pin digest="SHA-256">BACKUP_PIN_HERE</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

**Test Commands:**
```bash
# Test with wrong certificate
# Install proxy cert (mitmproxy, Burp Suite)
# App should reject connection

# Test cleartext
adb shell am start -n com.openscan.indigenas/.MainActivity
adb logcat | grep "Cleartext"
# Should see: "Cleartext traffic not permitted"
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 7. THIRD-PARTY DEPENDENCIES

### 7.1 Dependency Security

- [ ] 🔴 **Vulnerability Scanning**
  - All dependencies scanned
  - No critical vulnerabilities
  - High vulnerabilities documented

- [ ] 🟠 **License Compliance**
  - All licenses reviewed
  - No GPL violations (if applicable)
  - Licenses documented

- [ ] 🟡 **Outdated Packages**
  - Regular update schedule
  - Breaking changes tested
  - Update log maintained

**Scan Commands:**
```bash
# Flutter dependency check
flutter pub outdated

# Trivy vulnerability scan
trivy fs . --severity HIGH,CRITICAL

# OWASP Dependency Check
dependency-check --scan . --format HTML
```

**Results:**
```
Critical: ___
High: ___
Medium: ___
Low: ___
```

---

## 8. COMPLIANCE & PRIVACY

### 8.1 Data Privacy

- [ ] 🔴 **GDPR Compliance** (if applicable)
  - Privacy policy published
  - Data collection disclosed
  - User consent obtained
  - Right to deletion implemented

- [ ] 🔴 **Data Minimization**
  - Only necessary data collected
  - Data retention policy
  - Old data purged

- [ ] 🟠 **User Rights**
  - Export user data
  - Delete user account
  - Opt-out of analytics

**Verification:**
```
1. Read privacy policy
2. Test data export function
3. Test account deletion
4. Verify data actually deleted
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 9. MOBILE-SPECIFIC SECURITY

### 9.1 Android Security

- [ ] 🔴 **ProGuard/R8 Enabled**
  - Code obfuscation active
  - Mapping file saved
  - Shrinking enabled

- [ ] 🔴 **Debug Flags Disabled**
  - `debuggable=false` in release
  - No test code in release
  - Logs disabled in release

- [ ] 🟠 **App Signing**
  - Properly signed with release key
  - Key stored securely
  - No hardcoded secrets

**Check build.gradle:**
```gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
            debuggable false
        }
    }
}
```

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

### 9.2 iOS Security (if applicable)

- [ ] 🔴 **App Transport Security**
  - ATS enforced
  - No insecure domains
  - Exceptions documented

- [ ] 🔴 **Code Signing**
  - Valid provisioning profile
  - Certificates not expired
  - Entitlements correct

- [ ] 🟠 **Keychain Access**
  - Keychain groups configured
  - Access control appropriate
  - Data protected

**Results:**
```
✅ PASS / ❌ FAIL
Notes: _________________
```

---

## 10. PENETRATION TESTING

### 10.1 Manual Penetration Testing

- [ ] 🔴 **OWASP Mobile Top 10**
  - M1: Improper Platform Usage - Tested
  - M2: Insecure Data Storage - Tested
  - M3: Insecure Communication - Tested
  - M4: Insecure Authentication - Tested
  - M5: Insufficient Cryptography - Tested
  - M6: Insecure Authorization - Tested
  - M7: Client Code Quality - Tested
  - M8: Code Tampering - Tested
  - M9: Reverse Engineering - Tested
  - M10: Extraneous Functionality - Tested

- [ ] 🟠 **Tools Used**
  - [ ] MobSF (Mobile Security Framework)
  - [ ] Drozer
  - [ ] Frida
  - [ ] Burp Suite Mobile
  - [ ] OWASP ZAP

**Penetration Test Report:**
```
Tester: _________________
Date: ___________________
Tools: __________________
Findings: _______________
Severity: _______________
Remediation: ____________
```

---

## 📊 TESTING SUMMARY

### Overall Security Score

```
Critical Issues: ___
High Issues: ___
Medium Issues: ___
Low Issues: ___

Overall Score: ___ / 100

✅ APPROVED FOR PRODUCTION
❌ NOT APPROVED - REQUIRES REMEDIATION
```

### Sign-Off

**Security Team Lead:**
- Name: _____________________
- Signature: _________________
- Date: ______________________

**DevOps Lead:**
- Name: _____________________
- Signature: _________________
- Date: ______________________

**Project Manager:**
- Name: _____________________
- Signature: _________________
- Date: ______________________

---

## 📎 Appendix

### A. Testing Tools

- **MobSF**: https://github.com/MobSF/Mobile-Security-Framework-MobSF
- **Drozer**: https://labs.withsecure.com/tools/drozer
- **Frida**: https://frida.re/
- **Burp Suite**: https://portswigger.net/burp/mobile
- **OWASP ZAP**: https://www.zaproxy.org/

### B. Security Standards

- OWASP Mobile Top 10: https://owasp.org/www-project-mobile-top-10/
- NIST Mobile Security: https://csrc.nist.gov/publications/
- CWE Top 25: https://cwe.mitre.org/top25/

### C. Related Documents

- [Security Audit Report](./SECURITY_AUDIT.md)
- [Deployment Guide](./DEPLOYMENT.md)
- [Penetration Testing Requirements](./PENETRATION_TESTING.md)

---

**Document Version:** 1.0
**Next Review:** 2026-01-07
