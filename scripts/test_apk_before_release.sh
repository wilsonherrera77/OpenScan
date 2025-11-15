#!/bin/bash

# ═══════════════════════════════════════════════════════════
# TEST APK BEFORE RELEASE - Lumara Quality Assurance
# ═══════════════════════════════════════════════════════════
# Purpose: Automated testing checklist for APK before distribution
# Usage: ./scripts/test_apk_before_release.sh <path-to-apk>
# Version: 1.0.0
# Date: 2025-11-09
# ═══════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════
# Validation
# ═══════════════════════════════════════════════════════════

if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: APK path required${NC}"
    echo "Usage: $0 <path-to-apk>"
    echo "Example: $0 build/app/outputs/flutter-apk/app-release.apk"
    exit 1
fi

APK_PATH="$1"

if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ Error: APK not found: $APK_PATH${NC}"
    exit 1
fi

# ═══════════════════════════════════════════════════════════
# Device Check
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   LUMARA APK TESTING PROTOCOL${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📱 Checking Android device...${NC}"
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No Android device connected${NC}"
    echo ""
    echo "Please connect device via USB and enable USB debugging:"
    echo "  1. Settings → About Phone → Tap 'Build Number' 7 times"
    echo "  2. Settings → Developer Options → Enable USB Debugging"
    echo "  3. Connect USB cable"
    echo "  4. Accept USB debugging prompt on device"
    echo ""
    exit 1
fi

DEVICE_ID=$(adb devices | grep -v "List" | grep "device$" | head -1 | awk '{print $1}')
DEVICE_MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model | tr -d '\r')
ANDROID_VERSION=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.release | tr -d '\r')

echo -e "${GREEN}✅ Device connected: $DEVICE_MODEL (Android $ANDROID_VERSION)${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# APK Info
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}📦 APK Information:${NC}"
APK_SIZE=$(du -h "$APK_PATH" | awk '{print $1}')
APK_MD5=$(md5sum "$APK_PATH" | awk '{print $1}')
APK_NAME=$(basename "$APK_PATH")

echo "  Path: $APK_PATH"
echo "  Size: $APK_SIZE"
echo "  MD5:  $APK_MD5"
echo ""

# ═══════════════════════════════════════════════════════════
# Install APK
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}🔧 Installing APK...${NC}"

# Uninstall old version first (ignore errors if not installed)
adb -s "$DEVICE_ID" uninstall com.ethereal.openscan 2>/dev/null || true

# Install new APK
if adb -s "$DEVICE_ID" install -r "$APK_PATH" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ APK installed successfully${NC}"
else
    echo -e "${RED}❌ APK installation failed${NC}"
    exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════
# Start Log Capture
# ═══════════════════════════════════════════════════════════

LOG_DIR="/tmp/lumara_test_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_$(date +%Y%m%d_%H%M%S).log"

echo -e "${YELLOW}📝 Starting log capture...${NC}"
adb -s "$DEVICE_ID" logcat -c  # Clear logs
adb -s "$DEVICE_ID" logcat | grep -iE "lumara|openscan|flutter|error|exception" > "$LOG_FILE" &
LOGCAT_PID=$!

echo -e "${GREEN}✅ Logs capturing to: $LOG_FILE${NC}"
echo -e "   (PID: $LOGCAT_PID - will auto-stop at end of tests)"
echo ""

# Cleanup on exit
trap "kill $LOGCAT_PID 2>/dev/null || true" EXIT

# ═══════════════════════════════════════════════════════════
# Manual Testing Checklist
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   MANUAL TESTING CHECKLIST (5 Critical Tests)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo "Please perform the following tests on the device:"
echo ""

echo -e "${YELLOW}TEST 1: LOGIN (All Roles)${NC}"
echo "  [ ] Open Lumara app"
echo "  [ ] Login as 'admin' (or configured credentials)"
echo "  [ ] Verify redirect to Admin Dashboard"
echo "  [ ] Logout"
echo "  [ ] Login as 'digitizer'"
echo "  [ ] Verify redirect to Digitizer Dashboard"
echo ""
read -p "Press ENTER when Test 1 complete (or 'skip' to skip)... " TEST1
echo ""

echo -e "${YELLOW}TEST 2: CENSUS LOADING${NC}"
echo "  [ ] From dashboard → Access census view"
echo "  [ ] Wait for loading (should be < 10 seconds)"
echo "  [ ] Verify person count shown (should be 3,998 or close)"
echo "  [ ] Try search: Enter 'García' in search box"
echo "  [ ] Verify multiple results appear"
echo ""
read -p "Press ENTER when Test 2 complete (or 'skip' to skip)... " TEST2
echo ""

echo -e "${YELLOW}TEST 3: PERSON SELECTION${NC}"
echo "  [ ] From Digitizer Dashboard → 'Capturar Documento'"
echo "  [ ] Search for a person by name or ID"
echo "  [ ] Select person from list"
echo "  [ ] Verify person details displayed correctly"
echo ""
read -p "Press ENTER when Test 3 complete (or 'skip' to skip)... " TEST3
echo ""

echo -e "${YELLOW}TEST 4: DOCUMENT CAPTURE${NC}"
echo "  [ ] After selecting person → Click 'Capturar'"
echo "  [ ] Camera opens successfully"
echo "  [ ] Take photo of test document"
echo "  [ ] Verify preview appears"
echo "  [ ] Crop/adjust if needed"
echo "  [ ] Confirm capture"
echo ""
read -p "Press ENTER when Test 4 complete (or 'skip' to skip)... " TEST4
echo ""

echo -e "${YELLOW}TEST 5: UPLOAD SYNC${NC}"
echo "  [ ] Select document type (e.g., 'Cédula de Ciudadanía')"
echo "  [ ] Confirm upload"
echo "  [ ] Wait for sync indicator"
echo "  [ ] Verify success message"
echo "  [ ] (Optional) Check Tejido backend for uploaded document"
echo "      URL: http://192.168.40.17:8001/admin/documents/document/"
echo ""
read -p "Press ENTER when Test 5 complete (or 'skip' to skip)... " TEST5
echo ""

# ═══════════════════════════════════════════════════════════
# Test Results
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   TEST RESULTS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

echo "Please indicate test results:"
echo ""

for i in 1 2 3 4 5; do
    TEST_NAME=""
    case $i in
        1) TEST_NAME="LOGIN (All Roles)" ;;
        2) TEST_NAME="CENSUS LOADING (3998 persons)" ;;
        3) TEST_NAME="PERSON SELECTION" ;;
        4) TEST_NAME="DOCUMENT CAPTURE" ;;
        5) TEST_NAME="UPLOAD SYNC" ;;
    esac

    echo -e "${YELLOW}TEST $i: $TEST_NAME${NC}"
    read -p "  Result? (pass/fail/skip): " RESULT

    case "$RESULT" in
        pass|p|PASS|P)
            echo -e "  ${GREEN}✅ PASS${NC}"
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        fail|f|FAIL|F)
            echo -e "  ${RED}❌ FAIL${NC}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            read -p "  Error description: " ERROR_DESC
            echo "  Error: $ERROR_DESC" >> "$LOG_FILE"
            ;;
        skip|s|SKIP|S)
            echo -e "  ${YELLOW}⏭  SKIPPED${NC}"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            ;;
        *)
            echo -e "  ${YELLOW}⏭  SKIPPED (invalid input)${NC}"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            ;;
    esac
    echo ""
done

# ═══════════════════════════════════════════════════════════
# Regression Check
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   REGRESSION CHECK${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Did any previously working feature break?${NC}"
read -p "Any regressions? (yes/no): " REGRESSION

if [[ "$REGRESSION" == "yes" || "$REGRESSION" == "y" ]]; then
    echo -e "${RED}⚠️  REGRESSION DETECTED${NC}"
    read -p "Describe regression: " REGRESSION_DESC
    echo "REGRESSION: $REGRESSION_DESC" >> "$LOG_FILE"
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "${GREEN}✅ No regressions detected${NC}"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# Stop Log Capture
# ═══════════════════════════════════════════════════════════

echo -e "${YELLOW}📝 Stopping log capture...${NC}"
kill $LOGCAT_PID 2>/dev/null || true
echo -e "${GREEN}✅ Logs saved to: $LOG_FILE${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# Final Verdict
# ═══════════════════════════════════════════════════════════

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   FINAL VERDICT${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_TESTS=5
echo "Test Summary:"
echo "  PASS:    $PASS_COUNT / $TOTAL_TESTS"
echo "  FAIL:    $FAIL_COUNT / $TOTAL_TESTS"
echo "  SKIPPED: $SKIP_COUNT / $TOTAL_TESTS"
echo ""

# Verdict logic
if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ APK APPROVED FOR DISTRIBUTION${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "All critical tests passed. This APK is safe to distribute."
    echo ""
    echo "Next steps:"
    echo "  1. Copy APK to distribution folder:"
    echo "     cp $APK_PATH ~/Descargas/Lumara_vX.X.X_TESTED_\$(date +%Y%m%d_%H%M%S).apk"
    echo ""
    echo "  2. Create Git tag:"
    echo "     git tag vX.X.X-tested-verified"
    echo ""
    echo "  3. Update documentation:"
    echo "     - CHANGELOG.md"
    echo "     - BASELINE_vX.X.X_VERIFICATION.md"
    echo ""
    exit 0

elif [ $PASS_COUNT -ge 4 ] && [ $FAIL_COUNT -le 1 ]; then
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}   ⚠️  APK NEEDS MINOR FIXES${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Most tests passed, but some issues detected."
    echo ""
    echo "Options:"
    echo "  A) Fix issues and re-test"
    echo "  B) Distribute with known issues (document in release notes)"
    echo "  C) Rollback to previous version"
    echo ""
    echo "Review logs: $LOG_FILE"
    exit 1

else
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}   ❌ APK REJECTED - DO NOT DISTRIBUTE${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Critical failures detected. This APK should NOT be distributed."
    echo ""
    echo "Action required:"
    echo "  1. Review logs: $LOG_FILE"
    echo "  2. Fix critical issues"
    echo "  3. Rebuild APK (flutter clean + flutter build apk)"
    echo "  4. Re-run this test script"
    echo ""
    echo "If issues persist, consider:"
    echo "  - Rollback to baseline (v5.5.0)"
    echo "  - git checkout v5.5.0-baseline-verified"
    echo ""
    exit 1
fi
