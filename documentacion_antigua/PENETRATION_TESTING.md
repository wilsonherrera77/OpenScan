# 🛡️ Penetration Testing Requirements

**Project:** Lumara Indígenas
**Version:** 3.0.0
**Engagement Type:** Black Box / Grey Box Testing
**Last Updated:** 2025-10-07

---

## 📋 Executive Summary

This document outlines the requirements, scope, and methodology for penetration testing of the Lumara Indígenas mobile application and backend infrastructure. The goal is to identify security vulnerabilities before production deployment and ensure compliance with OWASP Mobile Security standards.

---

## 🎯 Objectives

### Primary Objectives

1. **Identify Security Vulnerabilities**
   - Authentication/authorization flaws
   - Data leakage
   - Insecure communication
   - Cryptographic weaknesses

2. **Validate Security Controls**
   - Certificate pinning effectiveness
   - Input validation
   - Session management
   - Rate limiting

3. **Assess OWASP Mobile Top 10 Compliance**
   - Comprehensive coverage of all 10 categories
   - Document findings with severity ratings
   - Provide remediation recommendations

### Secondary Objectives

- Identify logic flaws in business processes
- Assess denial-of-service resistance
- Evaluate data protection controls
- Review third-party dependencies

---

## 📦 Scope

### In Scope

#### Mobile Application

**Platform:** Android (iOS future consideration)
**Package Name:** `com.lumara.indigenas`
**Version:** 3.0.0

**Features to Test:**
- User authentication flow
- Document upload functionality
- Offline queue management
- Background synchronization
- Person selection and search
- Error reporting
- Analytics collection

#### Backend API

**Endpoint:** `https://tejido.your-domain.com/api/`
**Technology:** Tejido-ngx REST API
**Authentication:** Token-based (Bearer)

**Endpoints to Test:**
- `/api/token/` - Authentication
- `/api/documents/` - Document management
- `/api/documents/post_document/` - Upload
- `/api/custom_fields/` - Metadata
- `/api/tags/` - Tagging system

#### Infrastructure

**Server:** Production environment only
**IP Range:** [Provided separately]
**Network:** Public-facing HTTPS

### Out of Scope

- **Physical security** testing
- **Social engineering** attacks on staff
- **Denial of Service** attacks (without approval)
- **Third-party services** (Tejido-ngx core, Google Play Services)
- **Source code review** (provided separately if needed)

---

## 🗓️ Testing Schedule

### Timeline

**Total Duration:** 10 business days

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Planning & Reconnaissance | 1 day | Test plan |
| Scanning & Enumeration | 2 days | Asset inventory |
| Vulnerability Assessment | 3 days | Findings list |
| Exploitation | 2 days | Proof of concepts |
| Reporting | 2 days | Final report |

### Milestones

- **Day 3:** Initial findings briefing
- **Day 7:** Critical findings disclosed
- **Day 10:** Final report delivery
- **Day 12:** Remediation retest (if needed)

---

## 🔬 Testing Methodology

### Framework: OWASP Mobile Security Testing Guide (MSTG)

#### Phase 1: Information Gathering

**Objectives:**
- Understand application architecture
- Identify attack surface
- Map data flows

**Activities:**
- Decompile APK (if permitted)
- Analyze AndroidManifest.xml
- Review permissions
- Identify third-party libraries
- Map API endpoints

**Tools:**
- JADX, APKTool
- MobSF (Mobile Security Framework)
- Dex2Jar, JD-GUI

---

#### Phase 2: Static Analysis

**Objectives:**
- Identify hardcoded secrets
- Review insecure code patterns
- Analyze cryptographic implementations

**Activities:**
- Source code review (if available)
- Detect insecure data storage
- Check for sensitive information in logs
- Review network security configuration
- Analyze ProGuard configuration

**Tools:**
- MobSF
- QARK (Quick Android Review Kit)
- AndroBugs Framework
- Semgrep

**Focus Areas:**
```java
// Check for hardcoded credentials
grep -r "password\|token\|api_key" .

// Check for insecure storage
grep -r "SharedPreferences\|MODE_WORLD" .

// Check for logging sensitive data
grep -r "Log\.[devi]" . | grep -i "password\|token"
```

---

#### Phase 3: Dynamic Analysis

**Objectives:**
- Test runtime behavior
- Intercept network traffic
- Manipulate API requests
- Test authentication flows

**Activities:**

1. **Network Traffic Analysis**
   - Intercept HTTPS traffic
   - Test certificate pinning
   - Analyze API requests/responses
   - Check for sensitive data in transit

2. **Authentication Testing**
   - Brute force protection
   - Session management
   - Token security
   - Logout functionality

3. **Authorization Testing**
   - Vertical privilege escalation
   - Horizontal privilege escalation
   - Direct object references
   - Missing function-level access control

4. **Input Validation**
   - XSS injection
   - SQL injection
   - Path traversal
   - Command injection

5. **Business Logic Testing**
   - File upload restrictions
   - Rate limiting bypasses
   - Workflow manipulation
   - Data integrity

**Tools:**
- Burp Suite Mobile Assistant
- OWASP ZAP
- Frida (runtime instrumentation)
- objection (Frida toolkit)
- mitmproxy

**Setup:**
```bash
# Install mitmproxy certificate
adb push mitmproxy-ca-cert.cer /sdcard/
adb shell "settings put global http_proxy <ip>:8080"

# Launch Frida server
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server"
adb shell "/data/local/tmp/frida-server &"

# Hook certificate pinning
frida -U -f com.lumara.indigenas -l disable-pinning.js
```

---

#### Phase 4: Exploitation

**Objectives:**
- Demonstrate exploitability
- Assess real-world impact
- Develop proof-of-concepts

**Activities:**
- Exploit identified vulnerabilities
- Chain multiple vulnerabilities
- Document exploitation steps
- Create proof-of-concept scripts

**Rules of Engagement:**
- No data destruction
- No permanent changes
- Stop if production impact detected
- Document all actions

---

## 🎯 OWASP Mobile Top 10 Testing

### M1: Improper Platform Usage

**Test Cases:**
- [ ] Insecure platform permissions
- [ ] Misuse of TouchID/FaceID
- [ ] Insecure keychain access
- [ ] App does not validate certificates properly

**Expected Findings:**
- Certificate pinning validation
- Secure storage usage verification
- Platform API misuse

---

### M2: Insecure Data Storage

**Test Cases:**
- [ ] Unencrypted data in SharedPreferences
- [ ] Sensitive data in logs
- [ ] Data in external storage
- [ ] Keyboard cache leakage
- [ ] Backup files contain sensitive data

**Commands:**
```bash
# Check app data directory
adb shell "run-as com.lumara.indigenas ls -laR /data/data/com.lumara.indigenas/"

# Pull database
adb shell "run-as com.lumara.indigenas cp /data/data/.../databases/app.db /sdcard/"
adb pull /sdcard/app.db

# Check for sensitive data
strings app.db | grep -i "password\|token\|secret"

# Check SharedPreferences
adb shell "run-as com.lumara.indigenas cat /data/data/.../shared_prefs/*.xml"
```

---

### M3: Insecure Communication

**Test Cases:**
- [ ] Cleartext traffic
- [ ] Weak SSL/TLS configuration
- [ ] Certificate pinning bypass
- [ ] Man-in-the-middle attacks

**Commands:**
```bash
# Intercept traffic
mitmproxy --mode transparent --showhost

# Test certificate pinning
objection -g com.lumara.indigenas explore
android sslpinning disable

# Check for cleartext
adb logcat | grep "Cleartext"
```

---

### M4: Insecure Authentication

**Test Cases:**
- [ ] Weak password policy
- [ ] Biometric authentication bypass
- [ ] Session management flaws
- [ ] Brute force attacks

**API Tests:**
```bash
# Test brute force protection
for i in {1..20}; do
  curl -X POST https://api/token/ \
    -d '{"username":"admin","password":"wrong'$i'"}' \
    -w "Attempt $i: %{http_code}\n"
done

# Test session timeout
TOKEN=$(login_and_get_token)
sleep 3600  # Wait 1 hour
curl -H "Authorization: Bearer $TOKEN" https://api/documents/
# Expected: 401 Unauthorized
```

---

### M5: Insufficient Cryptography

**Test Cases:**
- [ ] Weak encryption algorithms
- [ ] Hardcoded encryption keys
- [ ] Insecure random number generation
- [ ] Insufficient key length

**Analysis:**
```bash
# Check for weak crypto
jadx -d output app.apk
grep -r "DES\|MD5\|SHA1" output/

# Check for hardcoded keys
grep -r "AES\|RSA" output/ | grep -i "key"
```

---

### M6: Insecure Authorization

**Test Cases:**
- [ ] Privilege escalation
- [ ] Insecure direct object references
- [ ] Missing authorization checks

**API Tests:**
```bash
# Test IDOR
USER1_TOKEN="..."
USER2_DOC_ID="..."

curl -H "Authorization: Bearer $USER1_TOKEN" \
  https://api/documents/$USER2_DOC_ID/
# Expected: 403 Forbidden

# Test privilege escalation
curl -H "Authorization: Bearer $REGULAR_USER_TOKEN" \
  https://api/admin/users/
# Expected: 403 Forbidden
```

---

### M7: Client Code Quality

**Test Cases:**
- [ ] Buffer overflows
- [ ] Null pointer dereferences
- [ ] Race conditions
- [ ] Memory leaks

**Tools:**
- Android Studio Profiler
- LeakCanary
- Valgrind

---

### M8: Code Tampering

**Test Cases:**
- [ ] App runs on rooted devices
- [ ] No integrity checks
- [ ] Debuggable in production
- [ ] No obfuscation

**Commands:**
```bash
# Check if debuggable
adb shell "dumpsys package com.lumara.indigenas | grep debuggable"
# Expected: debuggable=false

# Check obfuscation
jadx app.apk
# Check if code is readable or obfuscated

# Test on rooted device
adb shell su -c "id"
# Launch app and check for root detection
```

---

### M9: Reverse Engineering

**Test Cases:**
- [ ] Extract business logic
- [ ] Recover API keys
- [ ] Understand security controls
- [ ] Identify vulnerabilities in code

**Tools:**
- JADX
- Ghidra
- IDA Pro
- Frida

---

### M10: Extraneous Functionality

**Test Cases:**
- [ ] Debug endpoints exposed
- [ ] Test credentials active
- [ ] Hidden functionality
- [ ] Backdoors

**Check for:**
```dart
// Debug flags
const bool isDebugMode = true;  // Should be false

// Test credentials
final testUsername = "admin";
final testPassword = "password";  // Should not exist

// Hidden endpoints
GET /api/debug/
GET /api/test/
```

---

## 📊 Deliverables

### 1. Executive Summary (2-3 pages)

- Overview of findings
- Risk assessment
- Business impact
- Recommendations

### 2. Technical Report (20-40 pages)

**Contents:**
- Methodology
- Detailed findings
- Proof-of-concepts
- Screenshots/videos
- Remediation steps

**Finding Template:**
```markdown
## Finding #1: [Title]

**Severity:** Critical / High / Medium / Low
**CVSS Score:** X.X (vector string)
**CWE:** CWE-XXX
**OWASP Mobile:** M#

**Description:**
[Detailed description of the vulnerability]

**Impact:**
[What an attacker could achieve]

**Proof of Concept:**
```bash
[Steps to reproduce]
```

**Affected Components:**
- Mobile app version X.X.X
- API endpoint /api/xxx

**Remediation:**
[Specific steps to fix]

**References:**
- [Link to relevant documentation]
```

### 3. Appendices

- Full scan outputs
- Network traffic captures
- Decompiled code snippets (if permitted)
- Tool versions used

---

## 🚨 Severity Classification

### Critical (9.0-10.0 CVSS)

- Authentication bypass
- Remote code execution
- SQL injection
- Sensitive data exposure (credentials)

### High (7.0-8.9 CVSS)

- Privilege escalation
- Insecure data storage
- Certificate pinning bypass
- Authorization bypass

### Medium (4.0-6.9 CVSS)

- XSS vulnerabilities
- Information disclosure
- Weak cryptography
- Missing security headers

### Low (0.1-3.9 CVSS)

- Verbose error messages
- Security misconfiguration
- Missing best practices
- Informational findings

---

## 🔧 Testing Environment

### Provided by Client

- [ ] **Test Account Credentials**
  - Username: ______________
  - Password: ______________
  - Access level: Admin / User

- [ ] **API Documentation**
  - Swagger/OpenAPI spec
  - Authentication guide
  - Rate limit information

- [ ] **APK File**
  - Production build
  - Version: ______________
  - SHA-256: ______________

- [ ] **Network Access**
  - VPN credentials (if required)
  - IP whitelist (if needed)
  - Firewall exceptions

- [ ] **Test Data**
  - Sample person records
  - Sample documents
  - Test community data

### Provided by Tester

- [ ] Android test device (non-rooted)
- [ ] Rooted Android device
- [ ] Intercepting proxy setup
- [ ] Required tools installed
- [ ] Lab environment

---

## 📞 Communication Protocol

### Points of Contact

**Client Side:**
- Technical Contact: _______________
- Security Lead: _______________
- Emergency Contact: _______________

**Tester Side:**
- Lead Pentester: _______________
- QA Contact: _______________

### Reporting Protocol

1. **Critical Findings**
   - Report immediately (within 4 hours)
   - Phone call + encrypted email
   - Do not continue testing until discussed

2. **High Findings**
   - Report within 24 hours
   - Secure email notification
   - Daily status update

3. **Medium/Low Findings**
   - Include in daily report
   - Full documentation in final report

### Daily Stand-up

- **Time:** 9:00 AM (client timezone)
- **Duration:** 15 minutes
- **Format:** Video call or Slack

---

## ⚖️ Rules of Engagement

### Allowed Activities

✅ Port scanning
✅ Vulnerability scanning
✅ Authentication testing
✅ Authorization testing
✅ Input validation testing
✅ Intercepting network traffic
✅ Reverse engineering APK
✅ Runtime manipulation (Frida)

### Prohibited Activities

❌ Social engineering attacks
❌ Physical security testing
❌ DoS/DDoS attacks (without approval)
❌ Data destruction
❌ Accessing other customers' data
❌ Testing outside defined scope
❌ Testing outside agreed schedule

### Emergency Stop

If any of the following occur, **STOP IMMEDIATELY** and contact client:

- Production system becomes unstable
- Data corruption detected
- Unintended access to sensitive data
- Legal notice received
- Third-party systems affected

---

## 📄 Legal & Compliance

### Required Documents

- [ ] **Non-Disclosure Agreement (NDA)** - Signed
- [ ] **Testing Authorization Letter** - Signed
- [ ] **Rules of Engagement** - Agreed
- [ ] **Liability Waiver** - Signed

### Data Handling

- All testing data encrypted at rest
- Data retention: 90 days post-engagement
- Secure deletion after retention period
- No sharing with third parties

### Compliance Requirements

- [ ] GDPR compliance (if applicable)
- [ ] Data protection laws
- [ ] Intellectual property rights
- [ ] Export control regulations

---

## 🎓 Appendix A: Tools & Versions

### Mobile Testing

| Tool | Version | Purpose |
|------|---------|---------|
| MobSF | 3.7+ | Static/Dynamic analysis |
| Frida | 16.0+ | Runtime instrumentation |
| objection | 1.11+ | Frida toolkit |
| JADX | 1.4+ | APK decompiler |
| APKTool | 2.7+ | APK reverse engineering |
| Drozer | 2.4+ | Android security assessment |

### Network Testing

| Tool | Version | Purpose |
|------|---------|---------|
| Burp Suite Pro | 2023+ | Intercepting proxy |
| mitmproxy | 9.0+ | HTTP(S) proxy |
| Wireshark | 4.0+ | Packet analysis |
| Nmap | 7.90+ | Port scanning |

### General

| Tool | Version | Purpose |
|------|---------|---------|
| Metasploit | 6.3+ | Exploitation framework |
| Nuclei | 2.9+ | Vulnerability scanner |
| SQLMap | 1.7+ | SQL injection |

---

## 📚 Appendix B: References

### Standards & Guidelines

- OWASP Mobile Security Testing Guide: https://owasp.org/www-project-mobile-security-testing-guide/
- OWASP Mobile Top 10: https://owasp.org/www-project-mobile-top-10/
- NIST SP 800-163: Vetting the Security of Mobile Applications
- PCI Mobile Payment Acceptance Security Guidelines

### Related Documents

- [Security Audit Report](./SECURITY_AUDIT.md)
- [Security Testing Checklist](./SECURITY_TESTING_CHECKLIST.md)
- [Deployment Guide](./DEPLOYMENT.md)

---

## ✅ Sign-Off

### Client Approval

**Name:** _____________________
**Title:** _____________________
**Signature:** _________________
**Date:** ______________________

### Pentester Acceptance

**Company:** _____________________
**Lead Tester:** _____________________
**Signature:** _________________
**Date:** ______________________

---

**Document Version:** 1.0
**Classification:** Confidential
**Review Date:** 2025-11-07
