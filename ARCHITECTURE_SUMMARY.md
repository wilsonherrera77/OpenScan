# Lumara Frontend - Quick Reference Guide

## Project Overview
- **Name:** Lumara Scan (Lumara)
- **Version:** 5.6.1 (Phase 2: Session Tracking + Review Workflow + CSV Export)
- **Framework:** Flutter 3.x with Dart
- **Architecture:** Clean Architecture (Presentation/Domain/Data)
- **Target:** Indigenous communities document digitization system
- **Status:** Production ready with Phase 2 features integrated

---

## Quick Stats

| Metric | Value |
|--------|-------|
| **Total Screens** | 17 |
| **Providers** | 3 (Auth, Census, Assignment) |
| **Repositories** | 4 (Auth, Census, Document, Assignment) |
| **Services** | 12+ (Upload, OCR, Analytics, etc.) |
| **Domain Entities** | 8 |
| **Routes/Screens** | 20+ named routes |
| **User Roles** | 4 (Admin, Digitalizador, Revisor, Viewer) |
| **API Endpoints** | 15+ |
| **Key Dependencies** | provider, dio, drift, flutter_secure_storage, google_mlkit, image_cropper |

---

## Architecture Layers

### 1. Presentation Layer (`lib/presentation/`)
- **17 screens** organized by feature (auth, census, document, admin, etc.)
- **3 providers** for state management (AuthProvider, CensusProvider, AssignmentProvider)
- **RoleBasedNavigator** for conditional routing based on user role

### 2. Domain Layer (`lib/domain/`)
- **8 entities** (AuthToken, UserProfile, PersonAssignment, Person, etc.)
- **Enums** for UserRole, AssignmentStatus, etc.
- Business logic entities

### 3. Data Layer (`lib/data/`)
- **4 repositories** (AuthRepository, CensusRepository, DocumentRepository, AssignmentRepository)
- **2 data sources** (TejidoApiClient, CensusDataSource)
- **SQLite database** (AppDatabase with Drift ORM)

### 4. Services Layer (`lib/services/`)
- **Upload & Sync:** UploadService, BackgroundSyncService, FileDeletionService
- **Image Processing:** ImageOptimizer, DocumentScannerService, ImageQualityChecker
- **OCR & Detection:** HybridOcrService, LocalOcrService, DocumentTypeDetector, FieldExtractor
- **Analytics:** ReportingService, GapAnalysisService, CSVExportService
- **System:** ConnectivityService, NetworkMonitor, WorkflowEngine

---

## Key Features by Category

### User Management
- JWT authentication with rate limiting
- 4-role RBAC (Admin, Digitalizador, Revisor, Viewer)
- Session tracking (Phase 2)
- Role-based navigation

### Document Management
- Camera capture with anti-duplicate detection
- Quality validation (brightness, sharpness, contrast)
- Image optimization (Phase 2: 60-80% compression)
- Image editing (crop, rotate)
- OCR processing (Hybrid: Local ML Kit → Cloud fallback)
- Offline upload queue with retry logic

### Assignment Workflow
- Bulk assignment creation
- Status tracking (PENDING → IN_PROGRESS → COMPLETED → REVIEWED)
- Personal assignment view for digitizers
- Review workflow for reviewers (approve/reject)
- Productivity metrics tracking

### Analytics & Reporting
- Overall statistics generation
- Daily trends and charts
- Document type distribution
- Family-level reports
- CSV export with sharing
- Gap analysis (missing documents per person/family)

### Offline Support
- Queue-based upload system
- Background sync every 15 minutes
- Foreground service for Android SDK 36+
- Network connectivity monitoring
- Automatic retry with exponential backoff

---

## Screen Map by User Role

### ADMIN Dashboard
Route: `/admin-dashboard`
- Team statistics overview
- Top 5 digitizers leaderboard
- Assignment management
- Real-time metrics
- Quick actions

### DIGITALIZADOR Dashboard
Route: `/digitizer-dashboard`
- Personal productivity metrics
- My assignments (with progress)
- Daily/weekly/monthly progress
- Achievements & motivational elements
- Quick action: Start digitizing

### REVISOR Dashboard
Route: `/reviewer-dashboard`
- Review queue (completed assignments)
- Quality metrics
- Documents to review with filters
- Quality statistics by digitizer
- Approve/Reject actions

### VIEWER Dashboard
Route: `/viewer-dashboard`
- Read-only analytics
- Progress reports (by digitizer/family/timeframe)
- Charts and visualizations
- CSV/PDF export
- Gap analysis dashboard

---

## Data Flow Summary

```
1. AUTHENTICATION
   LoginScreen → AuthProvider.login() → AuthRepository → API → JWT Token → Dashboards

2. DOCUMENT UPLOAD
   PersonSelection → DocumentMetadata → UploadScreen → Quality Check → OCR → Upload → Queue/Sync

3. ASSIGNMENT WORKFLOW
   Admin Creates → Digitizer Receives → Completes → Reviewer Reviews → Analytics Dashboard

4. BACKGROUND SYNC
   Pending Upload Queue → BackgroundSyncService → Periodic Sync (15 min) → Retry Logic → Success
```

---

## Critical Files

| File | Purpose |
|------|---------|
| `main.dart` | Entry point, Provider initialization |
| `auth_provider.dart` | JWT auth state management |
| `assignment_provider.dart` | Multi-user assignment state |
| `auth_repository.dart` | Auth API + secure storage |
| `document_repository.dart` | Upload + anti-duplicate logic |
| `upload_service.dart` | Queue-based upload with retry |
| `hybrid_ocr_service.dart` | Local → Cloud OCR fallback |
| `background_sync_service.dart` | Periodic sync, foreground service |
| `role_based_navigator.dart` | Route users by role |

---

## API Integration

**Base URL:** Configurable in LoginScreen (default: ApiConstants.defaultBaseUrl)

**Authentication:** JWT Bearer tokens in Authorization header

**Key Endpoints:**
- `POST /api/auth/login/` - JWT authentication
- `GET /api/auth/me/` - User profile
- `GET /api/auth/my-assignments/` - Digitizer's assignments
- `GET /api/auth/assignments/` - All assignments (admin)
- `POST /api/documents/` - Upload document
- `POST /api/documents/check/` - Check if exists (anti-duplicate)
- `GET /api/auth/productivity/` - Productivity metrics
- `GET /api/auth/team-stats/` - Team statistics

---

## State Management Strategy

### Provider Pattern (ChangeNotifier)
```dart
// Global providers initialized in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>,
    ChangeNotifierProvider<CensusProvider>,
    ChangeNotifierProvider<AssignmentProvider>,
    Provider.value<Repositories>,
  ],
)
```

### Secondary Storage
- **SharedPreferences:** onboarding_completed, person selection
- **FlutterSecureStorage:** JWT tokens, credentials
- **SQLite (Drift):** Upload queue, history, local caching

---

## Performance Optimizations

| Optimization | Impact |
|--------------|--------|
| Image compression (Phase 2) | 50-70% bandwidth reduction |
| SQLite WAL mode | 3-5x faster queries |
| Metadata caching (1hr TTL) | Reduced API calls |
| ListView.builder | Smooth list scrolling |
| Local OCR (ML Kit) | 70% cost reduction vs cloud |
| Background sync | Offline-first capability |

---

## Security Features

| Feature | Implementation |
|---------|----------------|
| Token storage | FlutterSecureStorage (AES encrypted) |
| API auth | JWT Bearer tokens + rate limiting |
| Login attempts | Max 5 attempts per user |
| Data encryption | AES-256-GCM for files |
| Input validation | Form validation + sanitization |
| SQL injection | Drift ORM (type-safe) |
| Network security | HTTPS enforced, certificate pinning ready |

---

## Testing Checklist

- [ ] Authentication (login, logout, token refresh)
- [ ] Census loading and person search
- [ ] Document upload flow (online + offline)
- [ ] Quality validation (image & OCR)
- [ ] Assignment creation and management
- [ ] Review workflow (approve/reject)
- [ ] Background sync (periodic + retry)
- [ ] Role-based navigation (all 4 roles)
- [ ] CSV export functionality
- [ ] Gap analysis calculation
- [ ] Offline mode (no internet)
- [ ] Network recovery (internet restored)

---

## Common Tasks

### Add a New Screen
1. Create `lib/presentation/feature/screen_name.dart`
2. Add route to `main.dart`
3. Add provider if needed (consumer of existing)
4. Implement navigation from parent screen

### Add a New Provider
1. Create `lib/presentation/providers/feature_provider.dart`
2. Extend `ChangeNotifier` with state + methods
3. Add to MultiProvider in `main.dart`
4. Use `Consumer<FeatureProvider>` in screens

### Add a New API Endpoint
1. Add method to appropriate Repository
2. Use TejidoApiClient (Dio HTTP)
3. Map to Domain entity with `.fromJson()`
4. Expose through Provider/Service
5. Consume in Screen

### Debug Network Issues
1. Check `core/constants/api_constants.dart` for URL
2. Test connection: `ServerConfigScreen` → Test Connection
3. Check `TejidoApiClient` for auth token
4. Review logs: Check `Logger` output in console

---

## Documentation Files

- `ARCHITECTURE_MAP.md` - Comprehensive architecture documentation
- `ARCHITECTURE_SUMMARY.md` - This quick reference guide
- `pubspec.yaml` - Dependencies and version info
- `CLAUDE.md` - AI configuration for AI Assistant

---

## Next Steps / Phase 3 Ideas

- Push notifications (assignment updates)
- Advanced search (full-text document search)
- Batch OCR processing (queue optimization)
- Document versioning (track changes)
- Audit trail (complete logging)
- ML-based quality automation (auto-approve high quality)
- Performance dashboards (real-time metrics)
- Mobile offline-first improvements

---

**Last Updated:** November 1, 2025  
**Lumara Version:** 5.6.1 (Phase 2)  
**Architecture Status:** Mature & Stable
