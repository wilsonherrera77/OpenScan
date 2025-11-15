#!/bin/bash
# OpenScan Indigenous Communities Build Script
# Generates Drift database code and prepares app for build

set -e

echo "🔨 OpenScan Build Script"
echo "========================"
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter is not installed or not in PATH"
    echo ""
    echo "Please install Flutter:"
    echo "1. Visit: https://docs.flutter.dev/get-started/install"
    echo "2. Or use snap: sudo snap install flutter --classic"
    echo ""
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n1)"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Generate Drift code
echo "🔄 Generating Drift database code..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

# Check for generated files
if [ -f "lib/data/local/database/app_database.g.dart" ]; then
    echo "✅ app_database.g.dart generated successfully"
else
    echo "❌ WARNING: app_database.g.dart not found"
fi

echo ""
echo "🎉 Build preparation complete!"
echo ""
echo "Next steps:"
echo "  - Test on device: flutter run"
echo "  - Build APK: flutter build apk"
echo "  - Build iOS: flutter build ios"
echo ""
