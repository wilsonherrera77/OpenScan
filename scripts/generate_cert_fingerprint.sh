#!/bin/bash

################################################################################
# SSL Certificate Fingerprint Generator
# Purpose: Extract SHA-256 public key fingerprint for certificate pinning
# Usage: ./generate_cert_fingerprint.sh <hostname> [port]
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PORT="${2:-443}"
HOSTNAME="$1"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate input
if [ -z "$HOSTNAME" ]; then
    print_error "Usage: $0 <hostname> [port]"
    echo "Example: $0 paperless.example.com 443"
    exit 1
fi

print_info "Extracting certificate from ${HOSTNAME}:${PORT}..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
CERT_FILE="${TEMP_DIR}/cert.pem"
PUBKEY_FILE="${TEMP_DIR}/pubkey.pem"

# Cleanup function
cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Step 1: Download certificate
print_info "Step 1: Downloading certificate..."
echo | openssl s_client -servername "${HOSTNAME}" -connect "${HOSTNAME}:${PORT}" 2>/dev/null | \
    openssl x509 -outform PEM > "${CERT_FILE}"

if [ ! -s "${CERT_FILE}" ]; then
    print_error "Failed to download certificate from ${HOSTNAME}:${PORT}"
    print_warning "Make sure the server is accessible and using SSL/TLS"
    exit 1
fi

print_info "Certificate downloaded successfully"

# Step 2: Extract certificate details
print_info "\nStep 2: Certificate Details"
echo "----------------------------------------"
openssl x509 -in "${CERT_FILE}" -noout -subject -issuer -dates

# Step 3: Extract public key
print_info "\nStep 3: Extracting public key..."
openssl x509 -in "${CERT_FILE}" -pubkey -noout > "${PUBKEY_FILE}"

# Step 4: Generate SHA-256 fingerprint
print_info "Step 4: Generating SHA-256 fingerprint..."
FINGERPRINT=$(openssl pkey -pubin -in "${PUBKEY_FILE}" -outform der | \
    openssl dgst -sha256 -binary | \
    openssl enc -base64)

# Output results
echo ""
echo "========================================"
echo -e "${GREEN}✅ Certificate Pinning Configuration${NC}"
echo "========================================"
echo ""
echo "Hostname: ${HOSTNAME}"
echo "Port: ${PORT}"
echo ""
echo -e "${YELLOW}SHA-256 Fingerprint:${NC}"
echo "sha256/${FINGERPRINT}"
echo ""
echo "========================================"
echo -e "${GREEN}Flutter Configuration${NC}"
echo "========================================"
echo ""
echo "Add this to lib/core/config/production_config.dart:"
echo ""
echo "static const List<String> certificateFingerprints = ["
echo "  'sha256/${FINGERPRINT}', // ${HOSTNAME}"
echo "];"
echo ""

# Generate additional fingerprints for certificate chain
print_info "Checking for certificate chain..."
CHAIN_COUNT=$(echo | openssl s_client -servername "${HOSTNAME}" -connect "${HOSTNAME}:${PORT}" -showcerts 2>/dev/null | grep -c "BEGIN CERTIFICATE")

if [ "$CHAIN_COUNT" -gt 1 ]; then
    print_warning "Certificate chain detected (${CHAIN_COUNT} certificates)"
    print_info "Consider pinning multiple certificates for redundancy:"
    echo ""

    # Extract all certificates from chain
    echo | openssl s_client -servername "${HOSTNAME}" -connect "${HOSTNAME}:${PORT}" -showcerts 2>/dev/null | \
        awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print}' | \
        awk 'BEGIN {cert=""} /BEGIN CERTIFICATE/ {cert=""} {cert=cert"\n"$0} /END CERTIFICATE/ {print cert > "'"${TEMP_DIR}"'/cert" ++count ".pem"}' 2>/dev/null || true

    # Generate fingerprints for each cert in chain
    for cert in "${TEMP_DIR}"/cert*.pem; do
        if [ -f "$cert" ]; then
            SUBJECT=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
            FP=$(openssl x509 -in "$cert" -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)
            echo "  'sha256/${FP}', // ${SUBJECT}"
        fi
    done
    echo ""
fi

# Validation instructions
echo "========================================"
echo -e "${GREEN}Validation Steps${NC}"
echo "========================================"
echo ""
echo "1. Update production_config.dart with the fingerprint above"
echo "2. Build the app in release mode:"
echo "   flutter build apk --release"
echo ""
echo "3. Test certificate pinning:"
echo "   - Deploy to staging environment"
echo "   - Verify app connects successfully"
echo "   - Test with invalid certificate (should fail)"
echo ""
echo "4. Monitor for certificate expiry:"
echo "   Current cert expires: $(openssl x509 -in "${CERT_FILE}" -noout -enddate | cut -d= -f2)"
echo ""

# Security recommendations
echo "========================================"
echo -e "${YELLOW}⚠️  Security Recommendations${NC}"
echo "========================================"
echo ""
echo "1. Pin multiple certificates (backup/intermediate CA)"
echo "2. Setup certificate renewal monitoring"
echo "3. Test certificate rotation procedure"
echo "4. Document certificate update process"
echo "5. Keep backup fingerprints for certificate rollover"
echo ""

# Export to file
OUTPUT_FILE="cert_pinning_${HOSTNAME}.txt"
cat > "${OUTPUT_FILE}" <<EOF
Certificate Pinning Configuration
Generated: $(date)
Hostname: ${HOSTNAME}:${PORT}

SHA-256 Fingerprint:
sha256/${FINGERPRINT}

Flutter Configuration:
static const List<String> certificateFingerprints = [
  'sha256/${FINGERPRINT}', // ${HOSTNAME}
];

Certificate Details:
$(openssl x509 -in "${CERT_FILE}" -noout -subject -issuer -dates)

Expiry Date: $(openssl x509 -in "${CERT_FILE}" -noout -enddate | cut -d= -f2)
EOF

print_info "Configuration saved to: ${OUTPUT_FILE}"
echo ""

exit 0
