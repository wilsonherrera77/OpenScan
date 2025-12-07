#!/bin/bash

################################################################################
# Test Certificate Generator for Staging/Development
# Purpose: Generate self-signed certificates for testing certificate pinning
# Usage: ./generate_test_cert.sh [domain]
################################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="${1:-tejido-staging.local}"
OUTPUT_DIR="./certs"
DAYS_VALID=365

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create output directory
mkdir -p "${OUTPUT_DIR}"

print_info "Generating test certificate for: ${DOMAIN}"
print_warning "⚠️  This is for TESTING ONLY - Do NOT use in production!"

# Generate private key
print_info "Generating private key..."
openssl genrsa -out "${OUTPUT_DIR}/${DOMAIN}.key" 2048

# Generate certificate signing request
print_info "Generating CSR..."
openssl req -new -key "${OUTPUT_DIR}/${DOMAIN}.key" \
    -out "${OUTPUT_DIR}/${DOMAIN}.csr" \
    -subj "/C=CO/ST=Test/L=Test/O=Lumara Test/CN=${DOMAIN}"

# Generate self-signed certificate
print_info "Generating self-signed certificate..."
openssl x509 -req -days ${DAYS_VALID} \
    -in "${OUTPUT_DIR}/${DOMAIN}.csr" \
    -signkey "${OUTPUT_DIR}/${DOMAIN}.key" \
    -out "${OUTPUT_DIR}/${DOMAIN}.crt"

# Extract public key fingerprint
print_info "Extracting fingerprint..."
FINGERPRINT=$(openssl x509 -in "${OUTPUT_DIR}/${DOMAIN}.crt" -pubkey -noout | \
    openssl pkey -pubin -outform der | \
    openssl dgst -sha256 -binary | \
    openssl enc -base64)

echo ""
echo "========================================"
echo -e "${GREEN}✅ Test Certificate Generated${NC}"
echo "========================================"
echo ""
echo "Domain: ${DOMAIN}"
echo "Valid for: ${DAYS_VALID} days"
echo ""
echo "Files generated in ${OUTPUT_DIR}/:"
echo "  - ${DOMAIN}.key (private key)"
echo "  - ${DOMAIN}.csr (certificate signing request)"
echo "  - ${DOMAIN}.crt (certificate)"
echo ""
echo "SHA-256 Fingerprint:"
echo "sha256/${FINGERPRINT}"
echo ""
echo "Add to production_config.dart for testing:"
echo "static const List<String> certificateFingerprints = ["
echo "  'sha256/${FINGERPRINT}', // ${DOMAIN} (TEST)"
echo "];"
echo ""
echo "========================================"
echo -e "${YELLOW}Testing Instructions${NC}"
echo "========================================"
echo ""
echo "1. Configure your test server with these files:"
echo "   - Certificate: ${OUTPUT_DIR}/${DOMAIN}.crt"
echo "   - Private Key: ${OUTPUT_DIR}/${DOMAIN}.key"
echo ""
echo "2. Update /etc/hosts to point ${DOMAIN} to your server"
echo ""
echo "3. Update production_config.dart with fingerprint above"
echo ""
echo "4. Test with: flutter run --dart-define=STAGING=true"
echo ""

exit 0
