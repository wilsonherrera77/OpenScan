#!/bin/bash

################################################################################
# Production Validation Script
# Purpose: Validate that all production requirements are met before deployment
# Usage: ./validate_production.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Print functions
print_header() {
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "────────────────────────────────────────────────────────────────"
}

print_check() {
    echo -n "  [ ] $1... "
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC}"
    echo -e "      ${RED}$1${NC}"
    ((FAILED++))
}

print_warn() {
    echo -e "${YELLOW}⚠ WARNING${NC}"
    echo -e "      ${YELLOW}$1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "      ${BLUE}ℹ $1${NC}"
}

# Validation functions

validate_flutter_env() {
    print_section "1. Flutter Environment"

    # Check Flutter installed
    print_check "Flutter SDK installed"
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -1 | awk '{print $2}')
        print_pass
        print_info "Version: $FLUTTER_VERSION"
    else
        print_fail "Flutter SDK not found. Install from https://flutter.dev"
    fi

    # Check Dart version
    print_check "Dart SDK installed"
    if command -v dart &> /dev/null; then
        DART_VERSION=$(dart --version 2>&1 | awk '{print $4}')
        print_pass
        print_info "Version: $DART_VERSION"
    else
        print_fail "Dart SDK not found"
    fi

    # Check Flutter doctor
    print_check "Flutter doctor status"
    if flutter doctor | grep -q "No issues found"; then
        print_pass
    else
        print_warn "Some Flutter doctor checks failed. Run 'flutter doctor' for details"
    fi
}

validate_dependencies() {
    print_section "2. Dependencies"

    # Check pubspec.yaml exists
    print_check "pubspec.yaml exists"
    if [ -f "pubspec.yaml" ]; then
        print_pass
    else
        print_fail "pubspec.yaml not found. Are you in the project root?"
        return
    fi

    # Check dependencies installed
    print_check "Dependencies installed"
    if [ -d ".dart_tool" ] && [ -f "pubspec.lock" ]; then
        print_pass
    else
        print_fail "Dependencies not installed. Run 'flutter pub get'"
    fi

    # Check for outdated dependencies
    print_check "Checking for outdated packages"
    OUTDATED=$(flutter pub outdated --json 2>/dev/null | grep -c "upgradable" || echo "0")
    if [ "$OUTDATED" -eq 0 ]; then
        print_pass
    else
        print_warn "$OUTDATED packages can be upgraded. Run 'flutter pub outdated'"
    fi
}

validate_configuration() {
    print_section "3. Production Configuration"

    CONFIG_FILE="lib/core/config/production_config.dart"

    # Check config file exists
    print_check "Production config file exists"
    if [ -f "$CONFIG_FILE" ]; then
        print_pass
    else
        print_fail "Config file not found: $CONFIG_FILE"
        return
    fi

    # Check production URL
    print_check "Production URL configured"
    if grep -q "paperless.example.com" "$CONFIG_FILE"; then
        print_fail "Production URL still uses placeholder (paperless.example.com)"
    else
        PROD_URL=$(grep "paperlessProductionUrl" "$CONFIG_FILE" | sed "s/.*= '//" | sed "s/'.*//")
        print_pass
        print_info "URL: $PROD_URL"
    fi

    # Check certificate fingerprints
    print_check "Certificate fingerprints configured"
    if grep -A 3 "certificateFingerprints = \[" "$CONFIG_FILE" | grep -q "TODO\|//"; then
        print_fail "Certificate fingerprints not configured (still has TODO/comments)"
    else
        CERT_COUNT=$(grep -A 10 "certificateFingerprints = \[" "$CONFIG_FILE" | grep -c "sha256/" || echo "0")
        if [ "$CERT_COUNT" -ge 2 ]; then
            print_pass
            print_info "Configured: $CERT_COUNT fingerprint(s)"
        elif [ "$CERT_COUNT" -eq 1 ]; then
            print_warn "Only 1 certificate pinned. Recommend at least 2 for redundancy"
        else
            print_fail "No certificate fingerprints configured"
        fi
    fi

    # Check support email
    print_check "Support email configured"
    if grep -q "support@openscan-indigenas.org" "$CONFIG_FILE"; then
        print_fail "Support email still uses placeholder"
    else
        SUPPORT_EMAIL=$(grep "supportEmail" "$CONFIG_FILE" | sed "s/.*= '//" | sed "s/'.*//")
        print_pass
        print_info "Email: $SUPPORT_EMAIL"
    fi

    # Check privacy policy URL
    print_check "Privacy policy URL configured"
    PRIVACY_URL=$(grep "privacyPolicyUrl" "$CONFIG_FILE" | sed "s/.*= '//" | sed "s/'.*//")
    if [[ "$PRIVACY_URL" == *"openscan-indigenas.org"* ]]; then
        print_warn "Privacy policy URL may be placeholder"
        print_info "URL: $PRIVACY_URL"
    else
        print_pass
        print_info "URL: $PRIVACY_URL"
    fi

    # Check terms of service URL
    print_check "Terms of service URL configured"
    TERMS_URL=$(grep "termsOfServiceUrl" "$CONFIG_FILE" | sed "s/.*= '//" | sed "s/'.*//")
    if [[ "$TERMS_URL" == *"openscan-indigenas.org"* ]]; then
        print_warn "Terms of service URL may be placeholder"
        print_info "URL: $TERMS_URL"
    else
        print_pass
        print_info "URL: $TERMS_URL"
    fi
}

validate_security() {
    print_section "4. Security Checks"

    # Check for hardcoded secrets
    print_check "No hardcoded secrets"
    SECRETS_FOUND=$(grep -r -i "password\|api_key\|secret" lib/ --include="*.dart" | grep -v "// " | grep -v "/\*" | grep -v "passwordController\|passwordField" | wc -l || echo "0")
    if [ "$SECRETS_FOUND" -eq 0 ]; then
        print_pass
    else
        print_warn "Found $SECRETS_FOUND potential hardcoded secrets. Review manually"
    fi

    # Check for debug flags
    print_check "No debug flags in production code"
    if grep -r "kDebugMode = true\|debugShowCheckedModeBanner = true" lib/ --include="*.dart" | grep -v "//"; then
        print_fail "Found debug flags enabled in production code"
    else
        print_pass
    fi

    # Check for console logs in production
    print_check "No print statements in production code"
    PRINT_COUNT=$(grep -r "print(" lib/ --include="*.dart" | grep -v "// " | grep -v "/\*" | wc -l || echo "0")
    if [ "$PRINT_COUNT" -eq 0 ]; then
        print_pass
    else
        print_warn "Found $PRINT_COUNT print() statements. Use logger instead"
    fi

    # Check secure storage usage
    print_check "Using secure storage for sensitive data"
    if grep -r "flutter_secure_storage" pubspec.yaml > /dev/null; then
        print_pass
    else
        print_fail "Secure storage package not found"
    fi
}

validate_tests() {
    print_section "5. Testing"

    # Check test directory exists
    print_check "Test directory exists"
    if [ -d "test" ]; then
        TEST_COUNT=$(find test -name "*_test.dart" | wc -l)
        print_pass
        print_info "Found $TEST_COUNT test files"
    else
        print_fail "No test directory found"
        return
    fi

    # Run tests
    print_check "Running tests"
    if flutter test --no-pub 2>&1 | tee /tmp/flutter_test_output.txt | grep -q "All tests passed"; then
        print_pass
    else
        if grep -q "No tests found" /tmp/flutter_test_output.txt; then
            print_warn "No tests found to run"
        else
            print_fail "Some tests failed. Check output above"
        fi
    fi

    # Check coverage
    print_check "Test coverage"
    if [ -f "coverage/lcov.info" ]; then
        # Simple coverage calculation (lines covered / total lines)
        TOTAL_LINES=$(grep -c "^DA:" coverage/lcov.info || echo "1")
        COVERED_LINES=$(grep "^DA:" coverage/lcov.info | grep -v ",0$" | wc -l || echo "0")
        COVERAGE=$((COVERED_LINES * 100 / TOTAL_LINES))

        if [ "$COVERAGE" -ge 85 ]; then
            print_pass
            print_info "Coverage: ${COVERAGE}%"
        elif [ "$COVERAGE" -ge 70 ]; then
            print_warn "Coverage: ${COVERAGE}% (target: 85%)"
        else
            print_fail "Coverage: ${COVERAGE}% (minimum: 70%)"
        fi
    else
        print_warn "No coverage data found. Run 'flutter test --coverage'"
    fi
}

validate_documentation() {
    print_section "6. Documentation"

    REQUIRED_DOCS=(
        "README.md"
        "DEPLOYMENT.md"
        "SECURITY.md"
        "PRODUCTION_BLOCKERS_RESOLUTION.md"
        "PRODUCTION_DEPLOYMENT_CHECKLIST.md"
        "PRODUCTION_READINESS_STATUS.md"
        "docs/USER_MANUAL_ES.md"
        "docs/FIELD_GUIDE_ES.md"
    )

    for doc in "${REQUIRED_DOCS[@]}"; do
        print_check "$(basename $doc) exists"
        if [ -f "$doc" ]; then
            print_pass
        else
            print_fail "Missing: $doc"
        fi
    done
}

validate_build() {
    print_section "7. Build Validation"

    # Check if build is possible
    print_check "Can build APK (dry run)"
    if flutter build apk --debug --no-pub 2>&1 | tee /tmp/flutter_build_output.txt | grep -q "Built build/app/outputs/flutter-apk"; then
        APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-debug.apk 2>/dev/null | awk '{print $5}')
        print_pass
        print_info "APK size: $APK_SIZE"
    else
        print_fail "Build failed. Check output above"
    fi

    # Check for build warnings
    print_check "No critical build warnings"
    if grep -i "error\|fatal" /tmp/flutter_build_output.txt | grep -v "No issues found"; then
        print_fail "Found critical build errors"
    else
        print_pass
    fi
}

validate_infrastructure() {
    print_section "8. Infrastructure Connectivity"

    # Extract production URL from config
    PROD_URL=$(grep "paperlessProductionUrl" lib/core/config/production_config.dart | sed "s/.*= '//" | sed "s/'.*//")

    # Check if URL is configured
    if [[ "$PROD_URL" == *"example.com"* ]]; then
        print_check "Production server connectivity"
        print_warn "Production URL not configured (still using example.com)"
        return
    fi

    # Check production server accessibility
    print_check "Production server accessibility"
    if curl -Is --connect-timeout 5 "$PROD_URL" > /dev/null 2>&1; then
        HTTP_CODE=$(curl -Is --connect-timeout 5 "$PROD_URL" | head -1 | awk '{print $2}')
        print_pass
        print_info "Server responds with HTTP $HTTP_CODE"
    else
        print_fail "Cannot reach production server: $PROD_URL"
    fi

    # Check SSL certificate
    print_check "SSL certificate valid"
    if curl -Is --connect-timeout 5 "$PROD_URL" > /dev/null 2>&1; then
        CERT_EXPIRY=$(echo | openssl s_client -servername "$(echo $PROD_URL | sed 's|https://||' | sed 's|/.*||')" -connect "$(echo $PROD_URL | sed 's|https://||' | sed 's|/.*||'):443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$CERT_EXPIRY" ]; then
            print_pass
            print_info "Expires: $CERT_EXPIRY"
        else
            print_warn "Could not verify SSL certificate"
        fi
    else
        print_warn "Server not accessible for SSL check"
    fi
}

# Main execution
main() {
    print_header "OpenScan Indígenas - Production Validation"

    echo "This script validates that all production requirements are met."
    echo "Running validation checks..."

    # Run all validations
    validate_flutter_env
    validate_dependencies
    validate_configuration
    validate_security
    validate_tests
    validate_documentation
    validate_build
    validate_infrastructure

    # Print summary
    print_header "Validation Summary"

    echo -e "${GREEN}✓ Passed:  ${PASSED}${NC}"
    echo -e "${YELLOW}⚠ Warnings: ${WARNINGS}${NC}"
    echo -e "${RED}✗ Failed:  ${FAILED}${NC}"

    echo ""

    # Final verdict
    if [ $FAILED -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}${BOLD}  ✓ ALL CHECKS PASSED - READY FOR PRODUCTION${NC}"
            echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
            exit 0
        else
            echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}${BOLD}  ⚠ PASSED WITH WARNINGS - REVIEW BEFORE PRODUCTION${NC}"
            echo -e "${YELLOW}${BOLD}════════════════════════════════════════════════════════════════${NC}"
            exit 0
        fi
    else
        echo -e "${RED}${BOLD}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}${BOLD}  ✗ VALIDATION FAILED - NOT READY FOR PRODUCTION${NC}"
        echo -e "${RED}${BOLD}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Next Steps:${NC}"
        echo "  1. Review failures above"
        echo "  2. Fix all critical issues"
        echo "  3. Re-run this validation script"
        echo "  4. See PRODUCTION_BLOCKERS_RESOLUTION.md for guidance"
        echo ""
        exit 1
    fi
}

# Check if running from project root
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: Must be run from project root directory${NC}"
    echo "Usage: cd /path/to/openscan && ./scripts/validate_production.sh"
    exit 1
fi

# Run main
main
