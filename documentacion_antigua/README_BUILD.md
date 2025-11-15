# OpenScan Indigenous Communities - Build Instructions

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK** (3.5.3 or higher)
   - Install: https://docs.flutter.dev/get-started/install
   - Or use snap: `sudo snap install flutter --classic`

2. **Android Studio** (for Android development)
   - Install: https://developer.android.com/studio

3. **Xcode** (for iOS development, macOS only)
   - Install from Mac App Store

### Build Steps

#### 1. Generate Drift Database Code

The app uses Drift for offline database functionality. You must generate the database code before building:

```bash
# Run the build script (recommended)
./build.sh

# Or manually:
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `lib/data/local/database/app_database.g.dart` which is required for the app to compile.

#### 2. Run on Device/Emulator

```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Run in release mode
flutter run --release
```

#### 3. Build APK (Android)

```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Build split APKs (smaller size)
flutter build apk --split-per-abi
```

#### 4. Build iOS (macOS only)

```bash
# Build iOS
flutter build ios --release

# Or build IPA
flutter build ipa
```

## 📋 Configuration

### Census Data

The app expects census data in CSV format at:
```
assets/census/censo_indigenas.csv
```

Ensure this file is included in your assets.

### Paperless API Configuration

Default configuration in `lib/core/config/env_config.dart`:

```dart
class EnvConfig {
  static const String paperlessBaseUrl = 'http://10.0.2.2:8001';
  static const String paperlessApiToken = 'YOUR_TOKEN_HERE';
  static const bool enableOfflineMode = true;
  static const int maxRetryAttempts = 3;
}
```

**Note:** `10.0.2.2` is Android emulator's address for localhost. Change for physical devices.

## 🔄 Offline Queue System

### How It Works

1. **Document Capture:** User captures/selects image and metadata
2. **Queue Storage:** Document saved to local Drift database
3. **Immediate Upload:** App tries immediate upload if network available
4. **Background Sync:** WorkManager syncs queue every 15 minutes
5. **Smart Retry:** Failed uploads retry with exponential backoff

### Database Tables

**PendingUploads:**
- Stores documents waiting for upload
- Tracks retry count, status, and errors
- Auto-cleanup after successful upload

**UploadHistory:**
- Records successful uploads
- Links to Paperless document IDs
- Keeps last 1,000 records

### Testing Offline Mode

```bash
# Run app
flutter run

# Disable network on device/emulator
# Try uploading documents - they will queue

# Re-enable network
# Background sync will upload queued documents
```

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                           # App entry point
├── core/
│   ├── config/env_config.dart         # Configuration
│   └── utils/input_sanitizer.dart     # Security utilities
├── data/
│   ├── datasources/
│   │   ├── paperless_api_client.dart  # Paperless API
│   │   └── census_data_source.dart    # Census CSV loader
│   ├── repositories/
│   │   ├── auth_repository.dart       # Authentication
│   │   ├── census_repository.dart     # Census data
│   │   └── document_repository.dart   # Document uploads
│   └── local/database/
│       └── app_database.dart          # Drift database
├── domain/entities/
│   ├── person.dart                    # Person model
│   └── auth_token.dart                # Auth token model
├── presentation/
│   ├── auth/login_screen.dart         # Login UI
│   ├── census/person_selection_screen.dart
│   ├── document/upload_screen.dart    # Document upload UI
│   └── providers/
│       ├── auth_provider.dart         # Auth state
│       └── census_provider.dart       # Census state
└── services/
    ├── upload_service.dart            # Upload queue manager
    └── background_sync_service.dart   # WorkManager integration
```

### Key Dependencies

```yaml
# State management
provider: ^6.1.2

# HTTP client
dio: ^5.7.0
http: ^1.2.2

# Offline database
drift: ^2.14.0
drift_flutter: ^0.1.0
sqlite3_flutter_libs: ^0.5.0

# Background tasks
workmanager: ^0.5.2

# Secure storage
flutter_secure_storage: ^9.2.2

# Logging
logger: ^2.4.0

# CSV parsing
csv: ^6.0.0
```

### Regenerating Code

If you modify `app_database.dart`:

```bash
# Clean previous build
flutter pub run build_runner clean

# Regenerate
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch mode (auto-regenerate on changes)
flutter pub run build_runner watch
```

## 🧪 Testing

### Manual Testing Checklist

- [ ] Login with valid credentials
- [ ] Load census data (3,997 persons)
- [ ] Search persons by name
- [ ] Select person and navigate to upload
- [ ] Capture image from camera
- [ ] Select image from gallery
- [ ] Select document type
- [ ] Upload with network (immediate)
- [ ] Upload without network (queue)
- [ ] Verify background sync
- [ ] Check upload history
- [ ] Retry failed uploads
- [ ] Logout and re-login

### Unit Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Platform-Specific Notes

### Android

**Minimum SDK:** 21 (Android 5.0)
**Target SDK:** 34 (Android 14)

**Permissions required:**
- `INTERNET` - API communication
- `CAMERA` - Document capture
- `READ_EXTERNAL_STORAGE` - Gallery access
- `WRITE_EXTERNAL_STORAGE` - Image storage

### iOS

**Minimum iOS:** 12.0

**Info.plist entries required:**
```xml
<key>NSCameraUsageDescription</key>
<string>Needed to capture documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Needed to select images from gallery</string>
```

## 🐛 Troubleshooting

### Error: `app_database.g.dart` not found

**Solution:** Run build script
```bash
./build.sh
```

### Error: Flutter command not found

**Solution:** Install Flutter or add to PATH
```bash
export PATH="$PATH:$HOME/flutter/bin"
```

### Error: Drift/build_runner fails

**Solution:** Clean and rebuild
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Network Error: Failed to connect to 10.0.2.2:8001

**Solution:**
- For Android Emulator: `10.0.2.2` should work
- For Physical Device: Use actual IP address (e.g., `192.168.1.10:8001`)
- Update `EnvConfig.paperlessBaseUrl`

### WorkManager not running background tasks

**Solution:**
- Ensure battery optimization disabled for app
- Check Android Doze mode settings
- Verify network connectivity constraint
- Check logs: `flutter logs`

## 📚 Additional Resources

- **Flutter Docs:** https://docs.flutter.dev
- **Drift Documentation:** https://drift.simonbinder.eu
- **WorkManager:** https://pub.dev/packages/workmanager
- **Paperless-ngx API:** https://docs.paperless-ngx.com/api/

## 🤝 Contributing

1. Create feature branch
2. Run `./build.sh` to verify build
3. Test thoroughly
4. Submit pull request

## 📄 License

This project is a fork of OpenScan for Indigenous Communities document digitization.
