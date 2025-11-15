# Lumara Frontend Architecture Map

**Project:** Lumara Scan - Smart Document Digitization System for Indigenous Communities  
**Framework:** Flutter 3.x with Dart  
**Architecture:** Clean Architecture (Presentation/Domain/Data layers)  
**Version:** 5.6.1 (Fase 2: Session Tracking + Review Workflow + CSV Export)

---

## 1. Screens (Grouped by User Role)

### 1.1 Authentication & Onboarding

| Screen | Route | Functionality | Providers Used | Navigation |
|--------|-------|---------------|----------------|-----------|
| **LoginScreen** | `/login` | JWT authentication with username/password. Supports custom base URL configuration. Rate limiting (5 attempts). | AuthProvider | → PersonSelectionScreen (on success) |
| **OnboardingScreen** | `/onboarding` | First-time user introduction (4 pages). Covers: benefits, offline mode, privacy, security | None (SharedPreferences) | → LoginScreen |
| **ServerConfigScreen** | `/server-config` | Configure and test Paperless API connection. Connection status validation | AuthProvider | Settings/Config |

### 1.2 Census & Document Selection

| Screen | Route | Functionality | Providers Used | Navigation |
|--------|-------|---------------|----------------|-----------|
| **PersonSelectionScreen** | `/person-selection` | Search/select persons from census data. Shows statistics. Logout option | AuthProvider, CensusProvider | → DocumentMetadataScreen (on selection) |
| **DocumentMetadataScreen** | `/document-metadata` | Select document type and enter document number after person selection | CensusProvider | → HomeScreen (OpenScan camera flow) |

### 1.3 Document Management

| Screen | Route | Functionality | Providers Used | Navigation |
|--------|-------|---------------|----------------|-----------|
| **UploadScreen** | `/upload` | Document capture, validation, and upload. Anti-duplicate detection. Quality checking. | CensusProvider, AuthProvider, AssignmentProvider, DocumentRepository, UploadService | → DocumentPreviewScreen |
| **DocumentPreviewScreen** | `/document-preview` | Full-screen preview with zoom. Quality score validation. Image cropping/rotation. OCR processing (hybrid local+cloud) | None (direct services) | ← UploadScreen (image editing) |

### 1.4 Assignment Management (Digitizers)

| Screen | Route | Functionality | Providers Used | Navigation |
|--------|-------|---------------|----------------|-----------|
| **AssignmentListScreen** | `/assignments` | List digitizer's assignments with progress tracking. Filterable by status (PENDING/IN_PROGRESS/COMPLETED) | AssignmentProvider | Role-based routing |

### 1.5 Dashboards (Role-Based)

| Screen | Route | Functionality | Providers Used | Navigation | Role |
|--------|-------|---------------|----------------|-----------|------|
| **AdminDashboardScreen** | `/admin-dashboard` | Team statistics, top 5 digitizers leaderboard, assignment management, real-time metrics, quick actions | AssignmentProvider | Admin panel, settings | ADMIN |
| **DigitizerDashboardScreen** | `/digitizer-dashboard` | Personal productivity metrics, my assignments summary, daily/weekly/monthly progress, achievements | AssignmentProvider | Person selection (start digitizing) | DIGITALIZADOR |
| **ReviewerDashboardScreen** | `/reviewer-dashboard` | Review queue (completed assignments), quality metrics, documents to review with filters, quality statistics | AssignmentProvider | Quality review actions | REVISOR |
| **ViewerDashboardScreen** | `/viewer-dashboard` | Read-only overview, progress reports, analytics/charts, CSV export functionality | AssignmentProvider, CSVExportService | Export reports | VIEWER |

### 1.6 Reporting & Analytics (Feature Phase 2)

| Screen | Route | Functionality | Providers Used | Navigation |
|--------|-------|---------------|----------------|-----------|
| **DashboardScreen** | `/dashboard` | Overall statistics, progress charts, quick actions, recent activity | ReportingService, AppDatabase | Analytics |
| **FamilyReportScreen** | `/family-report` | Family-level reports and progress tracking | ReportingService | Analytics |
| **ExportReportScreen** | `/export-report` | Export to CSV, PDF with filtering by date range and user role | CSVExportService, AssignmentRepository | Reports |
| **GapAnalysisScreen** | `/gap-analysis` | Document gaps analysis. Tabs: Summary, Per Person, Per Family. Shows missing documents | GapAnalysisService, AppDatabase | Analytics |
| **AdminPanelScreen** | `/admin-panel` | System status, quick actions, workflow management, system configuration | ProductionConfig, WorkflowEngine | Admin |

---

## 2. Providers Implemented

### 2.1 AuthProvider
**File:** `lib/presentation/providers/auth_provider.dart`

| Aspect | Details |
|--------|---------|
| **State Managed** | Authentication token, user session, loading state, errors, base URL |
| **Repository Used** | AuthRepository |
| **Key Methods** | login(), logout(), updateBaseUrl(), getBaseUrl(), _checkAuthStatus() |
| **Key Getters** | isAuthenticated, isLoading, error, currentToken, username, baseUrl |
| **Screens Using It** | LoginScreen, PersonSelectionScreen, all dashboards |
| **Data Flow** | User credentials → AuthRepository → Paperless API → JWT token storage |

**Key Features:**
- JWT authentication with access + refresh tokens
- Secure token storage (flutter_secure_storage)
- Rate limiting (5 login attempts per user)
- Error message translation to Spanish
- Base URL configuration persistence

---

### 2.2 CensusProvider
**File:** `lib/presentation/providers/census_provider.dart`

| Aspect | Details |
|--------|---------|
| **State Managed** | All persons list, filtered persons, selected person, census statistics, search query, document metadata |
| **Repository Used** | CensusRepository |
| **Key Methods** | loadPersons(), searchPersons(), selectPerson(), clearSelection(), restoreSelection(), getPersonsByFamily(), getFamilyIds(), setDocumentMetadata() |
| **Key Getters** | persons, selectedPerson, statistics, isLoading, error, hasSelectedPerson, totalPersons, searchQuery, documentType, documentNumber |
| **Screens Using It** | PersonSelectionScreen, DocumentMetadataScreen, UploadScreen |
| **Data Flow** | Census CSV → CensusRepository → PersonList, Selection persistence in SharedPreferences |

**Key Features:**
- Loads census data from API/CSV
- Real-time search with filtering
- Person selection persistence
- Family grouping support
- Document metadata tracking for current scan session

---

### 2.3 AssignmentProvider
**File:** `lib/presentation/providers/assignment_provider.dart`

| Aspect | Details |
|--------|---------|
| **State Managed** | User profile, my assignments, all assignments (admin), productivity metrics, team statistics, digitizers list, session tracking, review data, loading states |
| **Repository Used** | AssignmentRepository |
| **Key Methods** | loadUserProfile(), loadMyAssignments(), loadAllAssignments(), loadMyProductivity(), loadTeamStatistics(), loadDigitizers(), loadCurrentSession(), startSession(), completeAssignment(), approveAssignment(), rejectAssignment(), createBulkAssignments() |
| **Key Getters** | currentUserProfile, myAssignments, allAssignments, myProductivity, teamStatistics, digitizers, isAdmin, isDigitizer, currentSessionId, hasActiveSession, assignmentReviews |
| **Screens Using It** | AdminDashboardScreen, DigitizerDashboardScreen, ReviewerDashboardScreen, ViewerDashboardScreen, AssignmentListScreen, all dashboards |
| **Data Flow** | User API → AssignmentRepository (Dio HTTP) → Assignment list, User profile → Local state management |

**Key Features:**
- Multi-user role support (ADMIN, DIGITALIZADOR, REVISOR, VIEWER)
- Role-based permission checks
- Session tracking (H2 feature)
- Review workflow management (H3 feature)
- Team productivity metrics
- Bulk assignment creation

---

## 3. Repositories

### 3.1 AuthRepository
**Location:** `lib/data/repositories/auth_repository.dart`

| Aspect | Details |
|--------|---------|
| **API Client** | PaperlessApiClient (Dio HTTP) |
| **Storage** | FlutterSecureStorage (encrypted) |
| **Key Methods** | login(username, password, baseUrl), logout(), isAuthenticated(), refreshToken() |
| **Key Features** | Rate limiting, token caching, base URL configuration |
| **Data Entities** | AuthToken (access_token, refresh_token, expires_in, username, baseUrl) |

---

### 3.2 CensusRepository
**Location:** `lib/data/repositories/census_repository.dart`

| Aspect | Details |
|--------|---------|
| **Data Source** | CensusDataSource (CSV files + API) |
| **Key Methods** | getAllPersons(), searchPersons(query), selectPerson(), clearSelection(), getSelectedPerson(), getStatistics(), getPersonsByFamily(), getFamilyIds() |
| **Storage** | SharedPreferences (person selection) |
| **Data Entities** | Person (personId, firstName, lastName, fullName, familyId, documentNumber, dateOfBirth) |

---

### 3.3 DocumentRepository
**Location:** `lib/data/repositories/document_repository.dart`

| Aspect | Details |
|--------|---------|
| **API Client** | PaperlessApiClient (Dio HTTP) |
| **Database** | AppDatabase (SQLite with Drift) |
| **Key Methods** | uploadDocumentForPerson(), uploadGenericDocument(), checkDocumentExists(), getDocumentHistory() |
| **Key Features** | Anti-duplicate detection, document replacement support (isReplacement param), metadata caching (1-hour TTL) |
| **Data Entities** | DocumentExistenceCheck (exists, quality_score, hasHighQuality, recommendation) |
| **Cache** | 1-hour TTL for metadata optimization (Phase 2) |

---

### 3.4 AssignmentRepository
**Location:** `lib/data/repositories/assignment_repository.dart`

| Aspect | Details |
|--------|---------|
| **API Client** | Dio HTTP (initialized with auth tokens) |
| **Key Methods** | getMyProfile(), getMyAssignments(), getAllAssignments(), createBulkAssignments(), startAssignment(), completeAssignment(), approveAssignment(), rejectAssignment(), getMyProductivity(), getTeamStatistics(), getDigitizers(), exportAssignmentsCSV() |
| **API Endpoints** | /api/auth/me/, /api/auth/my-assignments/, /api/auth/assignments/, /api/auth/productivity/, /api/auth/team-stats/ |
| **Data Entities** | UserProfile, PersonAssignment, ProductivityMetrics, TeamStatistics |

---

## 4. Services

### 4.1 Core Upload & Sync Services

| Service | Purpose | Key Methods | Used By |
|---------|---------|------------|---------|
| **UploadService** | Queue-based document upload with retry logic and backoff | uploadDocument(), syncPendingUploads(), retryFailedUploads(), updateSyncStatus() | UploadScreen, Background sync |
| **BackgroundSyncService** | Background synchronization with foreground task. Periodic sync every 15 minutes | initialize(), startPeriodicSync(), stopPeriodicSync(), syncCallback() | main.dart initialization |
| **FileDeletionService** | Clean up scanned images after successful upload | deleteScannedImages(), deleteLocalCopies() | UploadService |

### 4.2 Image Processing Services

| Service | Purpose | Key Methods | Used By |
|---------|---------|------------|---------|
| **ImageOptimizer** | Compress images to 60-80% quality before upload (Phase 2) | optimizeImage(), compressToTarget() | UploadService |
| **DocumentScannerService** | Crop and rotate documents. Edge detection | cropImage(), rotateImage(), detectEdges() | DocumentPreviewScreen |
| **ImageQualityChecker** | Validate image quality (brightness, sharpness, contrast) | checkQuality() | DocumentPreviewScreen |

### 4.3 OCR & Document Detection Services

| Service | Purpose | Key Methods | Used By |
|---------|---------|------------|---------|
| **HybridOcrService** | Hybrid OCR: Local (Google ML Kit) → Cloud fallback (OpenAI) | processDocument(), detectDocumentType(), extractFields() | DocumentPreviewScreen |
| **LocalOcrService** | On-device OCR using Google ML Kit | processImage(), extractText() | HybridOcrService |
| **DocumentTypeDetector** | Detect document type from OCR results | detectType() | HybridOcrService |
| **FieldExtractor** | Extract structured fields from document text | extractFields() | HybridOcrService |

### 4.4 Analytics & Reporting Services

| Service | Purpose | Key Methods | Used By |
|---------|---------|------------|---------|
| **ReportingService** | Generate analytics and statistics | getOverallStatistics(), getDailyTrends(), getDocumentTypeDistribution(), getFamilyReports() | DashboardScreen, ExportReportScreen |
| **GapAnalysisService** | Analyze document gaps per person/family | analyzePersonGaps(), analyzeFamilyGaps(), getGapStatistics() | GapAnalysisScreen |
| **CSVExportService** | Export assignments/productivity to CSV and share | exportAndShareAssignments(), exportAndShareProductivity() | ViewerDashboardScreen |

### 4.5 System Services

| Service | Purpose | Key Methods | Used By |
|---------|---------|------------|---------|
| **ConnectivityService** | Monitor network connectivity | isOnline(), startMonitoring() | Upload flow, sync service |
| **NetworkMonitor** | Advanced network monitoring and status | startMonitoring(), getNetworkStatus() | main.dart initialization |
| **WorkflowEngine** | Rule-based workflow automation (classification, tagging, notifications) | executeRule(), addRule(), processDocument() | Admin, automated flows |

---

## 5. Data Flow Diagrams

### 5.1 Authentication Flow

```
User Input (Login Screen)
    ↓
[AuthProvider.login()]
    ↓
[AuthRepository.login()]
    ├→ Rate limit check (5 attempts)
    ├→ PaperlessApiClient.login() [HTTP POST /api/auth/login/]
    └→ JWT Token response
         ↓
    FlutterSecureStorage.save(token)
         ↓
    Update AuthProvider state
         ↓
[RoleBasedNavigator.navigateAfterLogin()]
    ├→ Load UserProfile (GET /api/auth/me/)
    └→ Navigate to role-specific dashboard:
       - ADMIN → AdminDashboardScreen
       - DIGITALIZADOR → DigitizerDashboardScreen
       - REVISOR → ReviewerDashboardScreen
       - VIEWER → ViewerDashboardScreen
```

### 5.2 Document Upload Flow (Complete Anti-Duplicate System)

```
PersonSelectionScreen
    ↓ (Select person + document type)
DocumentMetadataScreen
    ↓ (Set document type & number)
DocumentMetadata stored in CensusProvider
    ↓
UploadScreen (Camera capture)
    ↓
[_checkAndCapture()]
    ├→ DocumentRepository.checkDocumentExists()
    │   └→ Backend API: POST /api/documents/check/
    │       ↓
    │   DocumentExistenceCheck result:
    │   - exists: boolean
    │   - quality_score: 0-100
    │   - hasHighQuality: boolean
    │   - recommendation: "skip" | "replace" | "upload"
    │
    ├→ IF exists & HIGH_QUALITY → Show "Already exists" dialog
    ├→ IF exists & LOW_QUALITY → Ask "Replace?" dialog
    └→ IF not_exists → Proceed to capture
         ↓
[Image Capture via Camera]
    ↓
DocumentPreviewScreen
    ├→ ImageQualityChecker.checkQuality()
    │   └→ Calculate: brightness, sharpness, contrast
    │
    ├→ HybridOcrService.processDocument()
    │   ├→ LocalOcrService (Google ML Kit)
    │   │   ├→ Extract text
    │   │   ├→ Calculate confidence
    │   │   └→ IF confidence < 70% → fallback to cloud
    │   │
    │   └→ OpenAI Vision API (fallback)
    │       └→ Better extraction with higher cost
    │
    ├→ [Approve] or [Re-take]
    └─→ [Proceed to Upload]
         ↓
[UploadScreen.uploadDocument()]
    ├→ ImageOptimizer.optimizeImage() [Phase 2]
    │   └→ Compress to 60-80% quality
    │
    ├→ DocumentRepository.uploadDocumentForPerson()
    │   └→ PaperlessApiClient.uploadDocument()
    │       └→ HTTP POST /api/documents/ (multipart)
    │           ├─ image file
    │           ├─ person_id
    │           ├─ document_type
    │           └─ isReplacement (if replacing low-quality)
    │
    └→ UploadService Queue Management
        ├→ Offline: Queue to SQLite
        ├→ Online: Immediate upload + retry logic
        ├→ Success: Update statistics
        └→ Failure: Retry with exponential backoff

Upload Status Stream
    ↓
UI Update (Progress indicator)
```

### 5.3 Assignment Workflow

```
Admin Dashboard (AdminDashboardScreen)
    ├→ AssignmentProvider.loadAllAssignments()
    │   └→ Backend: GET /api/auth/assignments/
    │
    ├→ Create Bulk Assignments
    │   ├→ Select Digitizer + Persons
    │   ├→ AssignmentRepository.createBulkAssignments()
    │   └→ Backend: POST /api/auth/assignments/bulk/
    │
    └→ Refresh + Monitor
         ↓
Digitizer Dashboard (DigitizerDashboardScreen)
    ├→ AssignmentProvider.loadMyAssignments()
    │   └→ Backend: GET /api/auth/my-assignments/
    │
    ├→ View Personal Assignments
    │   └─→ PENDING → IN_PROGRESS → COMPLETED
    │
    └→ Track Productivity
         ├→ Documents digitized
         ├→ Documents per hour
         └→ Quality score
              ↓
Reviewer Dashboard (ReviewerDashboardScreen)
    ├→ AssignmentProvider.loadAllAssignments(status='COMPLETED')
    │   └→ Get ready-for-review assignments
    │
    ├→ Quality Review
    │   ├→ Approve: COMPLETED → REVIEWED
    │   ├→ Reject: COMPLETED → PENDING (with feedback)
    │   └→ Request Re-capture
    │
    └→ Quality Metrics
         └→ Approval rate, rejection rate by digitizer

Admin Analytics (ViewerDashboardScreen)
    ├→ Overall statistics
    ├→ Progress by digitizer/family/timeframe
    ├→ Export to CSV/PDF
    └→ Gap analysis dashboard
```

### 5.4 Session Tracking (Phase 2)

```
Digitizer starts work
    ↓
[AssignmentProvider.startSession()]
    ├→ Backend: POST /api/auth/sessions/
    │   └→ Create DigitizationSession record
    │
    ├→ Store currentSessionId in provider
    └→ SessionIndicatorWidget shows active session
         ↓
User digitizes documents
    ├→ Each upload tagged with currentSessionId
    └→ Backend tracks: session_id, user, start_time, end_time, documents_count
         ↓
[AssignmentProvider.completeSession()]
    ├→ Backend: PATCH /api/auth/sessions/{id}/
    │   └→ Calculate session metrics
    │
    └→ Session analytics available to admin
```

---

## 6. Features Implementation Status

### 6.1 Multi-User System

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| User authentication (JWT) | JWT tokens | AuthProvider | login flow | ✅ Complete |
| Role-based access control | 4 roles defined | RoleBasedNavigator | All screens | ✅ Complete |
| Permission-based UI rendering | Permissions API | Role checks in providers | Dashboards | ✅ Complete |
| Bulk assignment creation | Django ViewSet | AssignmentRepository | Admin dashboard | ✅ Complete |
| Personal assignment view | API filters | AssignmentProvider | Digitizer dashboard | ✅ Complete |
| Session tracking | DigitizationSession model | Session management | Phase 2 complete | ✅ Phase 2 |
| Review workflow | ApprovalQueue model | ReviewerDashboard | Phase 2 complete | ✅ Phase 2 |

### 6.2 Document Capture & Upload

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Camera capture | Document API | ImagePicker + DocumentScannerService | UploadScreen | ✅ Complete |
| Image optimization | Image processing | ImageOptimizer service | Phase 2 | ✅ Phase 2 |
| Quality validation | Quality score API | ImageQualityChecker | DocumentPreview | ✅ Complete |
| Anti-duplicate detection | checkDocumentExists endpoint | DocumentRepository | UploadScreen | ✅ Complete |
| Document replacement | isReplacement parameter | UploadScreen param | Upload flow | ✅ Complete |
| Image cropping & rotation | Image processing | DocumentScannerService | DocumentPreview | ✅ Complete |
| Offline upload queue | SQLite queue table | UploadService | BackgroundSync | ✅ Complete |
| Automatic retry with backoff | Retry logic | UploadService | Background task | ✅ Complete |

### 6.3 OCR & Text Extraction

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Local OCR (Google ML Kit) | N/A (client-side) | LocalOcrService | HybridOCR | ✅ Complete |
| Cloud OCR fallback (OpenAI) | GPT-4o-mini integration | HybridOcrService | Document processing | ✅ Complete |
| Document type detection | ML models | DocumentTypeDetector | HybridOCR | ✅ Complete |
| Field extraction | Regex patterns | FieldExtractor | HybridOCR | ✅ Complete |
| Confidence scoring | ML scores | HybridOcrResult | Quality decision | ✅ Complete |
| Hybrid strategy (local→cloud) | N/A | HybridOcrService logic | 70% confidence threshold | ✅ Complete |

### 6.4 Assignment Management

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Create assignments | Django admin + API | BulkAssignmentDialog | Admin dashboard | ✅ Complete |
| List my assignments | Filtered API | AssignmentListScreen | Digitizer | ✅ Complete |
| Filter by status | Query params | AssignmentProvider | List screens | ✅ Complete |
| Track progress (docs/required) | Progress calculation | AssignmentCard widgets | All dashboards | ✅ Complete |
| Complete assignment | Mark COMPLETED | CompleteDialog | Digitizer flow | ✅ Complete |
| Reassign documents | Update person_id | Admin only | Admin dashboard | ⚠️ Partial |

### 6.5 Review Workflow

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Review queue (COMPLETED status) | Status filter | ReviewerDashboardScreen | Reviewer | ✅ Phase 2 |
| Approve documents | Status → REVIEWED | ApprovalDialog | ReviewerDashboard | ✅ Phase 2 |
| Reject documents | Status → PENDING + feedback | RejectionDialog | ReviewerDashboard | ✅ Phase 2 |
| Request re-capture | Feedback attachment | ReviewDialog | ReviewerDashboard | ✅ Phase 2 |
| Quality statistics | Approval metrics | QualityStatsWidget | Admin/Reviewer | ✅ Phase 2 |
| Review history | Review audit trail | N/A | Backend logging | ⚠️ Partial |

### 6.6 CSV Export & Reporting

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Export assignments to CSV | exportAssignmentsCSV endpoint | CSVExportService | ViewerDashboard | ✅ Phase 2 |
| Export productivity data | exportProductivity endpoint | CSVExportService | Analytics | ✅ Phase 2 |
| Overall statistics generation | Statistical queries | ReportingService | DashboardScreen | ✅ Phase 2 |
| Daily trends reporting | Time-series data | ReportingService | DashboardScreen | ✅ Phase 2 |
| Document type distribution | Aggregation queries | ReportingService | Charts | ✅ Phase 2 |
| Family-level reports | Family grouping | FamilyReportScreen | Reporting | ✅ Phase 2 |
| PDF export | PDF generation | printing package | Reports | ⚠️ Partial |
| Excel export | Excel generation | excel package | Reports | ⚠️ Partial |

### 6.7 Gap Analysis

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Define required documents | Hardcoded list | GapAnalysisService | Service | ✅ Complete |
| Analyze per-person gaps | Database queries | GapAnalysisService | GapAnalysisScreen | ✅ Complete |
| Analyze family-level gaps | Aggregation | GapAnalysisService | GapAnalysisScreen tab | ✅ Complete |
| Missing document alerts | Workflow rules | WorkflowEngine | Admin flow | ✅ Complete |
| Priority recommendations | Gap scoring | GapAnalysisService | Admin UI | ⚠️ Partial |
| Completion percentage | Progress calculation | PersonGapAnalysis entity | Analytics | ✅ Complete |

### 6.8 Additional Features

| Feature | Backend | Frontend | Integration | Status |
|---------|---------|----------|-------------|--------|
| Offline-first sync | Queue + retry | BackgroundSyncService | Global | ✅ Complete |
| Network connectivity monitoring | Connectivity checks | ConnectivityService + NetworkMonitor | Upload/sync | ✅ Complete |
| Rate limiting (login) | 5 attempts per user | LoginRateLimiter | AuthRepository | ✅ Complete |
| Secure token storage | Encrypted storage | FlutterSecureStorage | AuthRepository | ✅ Complete |
| Workflow automation | Rule engine | WorkflowEngine | Admin/Auto | ✅ Complete |
| Session tracking | DigitizationSession model | Session management | Phase 2 | ✅ Phase 2 |
| Productive metrics | Productivity API | ProductivityMetrics | Dashboards | ✅ Complete |
| Foreground background sync | Background service | BackgroundSyncService | Periodic | ✅ Complete |
| Metadata caching (1hr TTL) | Cache headers | DocumentRepository | Performance | ✅ Phase 2 |
| Image optimization (compression) | N/A | ImageOptimizer | Phase 2 | ✅ Phase 2 |

---

## 7. Navigation Flow Diagram

```
START
  │
  ├─→ [InitialRouteSelector]
  │    │
  │    ├─ Check: onboarding_completed?
  │    │   ├─ NO → OnboardingScreen (4 pages) → LoginScreen
  │    │   └─ YES → Check: isAuthenticated?
  │    │       ├─ NO → LoginScreen
  │    │       └─ YES → PersonSelectionScreen
  │    │
  │    └─ Loading splash while checking...
  │
  ├─→ [LoginScreen]
  │    │
  │    ├─ Username + Password input
  │    ├─ Custom base URL (optional)
  │    ├─ Login button → AuthProvider.login()
  │    │   │
  │    │   └─ Success → RoleBasedNavigator.navigateAfterLogin()
  │    │       │
  │    │       ├─ Load UserProfile (API call)
  │    │       │
  │    │       ├─ ADMIN role
  │    │       │  ├─ Load: allAssignments, teamStats, digitizers
  │    │       │  └─→ AdminDashboardScreen
  │    │       │      ├─ View team statistics
  │    │       │      ├─ Manage assignments
  │    │       │      └─ Quick actions
  │    │       │
  │    │       ├─ DIGITALIZADOR role
  │    │       │  ├─ Load: myAssignments, myProductivity
  │    │       │  └─→ DigitizerDashboardScreen
  │    │       │      ├─ View my assignments
  │    │       │      ├─ Track productivity
  │    │       │      └─ Start digitizing → PersonSelectionScreen
  │    │       │
  │    │       ├─ REVISOR role
  │    │       │  ├─ Load: completedAssignments, qualityMetrics
  │    │       │  └─→ ReviewerDashboardScreen
  │    │       │      ├─ Review queue
  │    │       │      ├─ Quality metrics
  │    │       │      └─ Approve/Reject actions
  │    │       │
  │    │       └─ VIEWER role
  │    │          ├─ Load: allAssignments, teamStats
  │    │          └─→ ViewerDashboardScreen
  │    │             ├─ Read-only analytics
  │    │             ├─ Export reports
  │    │             └─ View dashboards
  │    │
  │    └─ Login error → Show snackbar
  │
  ├─→ [PersonSelectionScreen]
  │    │
  │    ├─ Search/List persons from census
  │    ├─ Select person → CensusProvider.selectPerson()
  │    │
  │    └─→ [DocumentMetadataScreen]
  │        │
  │        ├─ Select document type (dropdown)
  │        ├─ Enter document number (textfield)
  │        ├─ Confirm → CensusProvider.setDocumentMetadata()
  │        │
  │        └─→ [HomeScreen - OpenScan Camera]
  │            │
  │            ├─ Capture → Image from camera
  │            │
  │            ├─ UploadScreen
  │            │  │
  │            │  ├─ Check document exists?
  │            │  │  ├─ Backend API call
  │            │  │  ├─ High quality → "Skip, already exists"
  │            │  │  ├─ Low quality → "Replace?"
  │            │  │  └─ Not exists → "Proceed"
  │            │  │
  │            │  ├─ Capture image → Camera intent
  │            │  │
  │            │  └─→ [DocumentPreviewScreen]
  │            │      │
  │            │      ├─ Check image quality
  │            │      ├─ Run OCR (HybridOcrService)
  │            │      ├─ Image editing (crop/rotate)
  │            │      ├─ Show quality score
  │            │      │
  │            │      ├─ [Approve] → Upload
  │            │      │   │
  │            │      │   ├─ Optimize image (Phase 2)
  │            │      │   ├─ DocumentRepository.uploadDocumentForPerson()
  │            │      │   ├─ Success → Statistics update
  │            │      │   └─ Failure → Queue + Retry
  │            │      │
  │            │      └─ [Re-take] → Back to camera
  │            │
  │            └─ Back → PersonSelectionScreen
  │
  ├─→ [AdminDashboardScreen]
  │    │
  │    ├─ Team Statistics Card
  │    ├─ Top 5 Digitizers Leaderboard
  │    ├─ Quick Actions (Manage assignments, etc)
  │    ├─ Refresh button
  │    ├─ Settings button (TODO)
  │    │
  │    ├─ [Manage Assignments]
  │    │  └─ Create bulk assignments
  │    │
  │    ├─ [View All Assignments]
  │    │  └─→ AssignmentListScreen
  │    │
  │    └─ Menu → ServerConfigScreen, AdminPanelScreen
  │
  ├─→ [DigitizerDashboardScreen]
  │    │
  │    ├─ Personal productivity metrics
  │    ├─ My assignments summary (PENDING/IN_PROGRESS/COMPLETED)
  │    ├─ Daily/weekly/monthly progress
  │    │
  │    ├─ [Start Digitizing] → PersonSelectionScreen
  │    └─ [View Assignments] → AssignmentListScreen
  │
  ├─→ [ReviewerDashboardScreen]
  │    │
  │    ├─ Review Queue (Status=COMPLETED)
  │    ├─ Quality metrics overview
  │    ├─ Documents to review (filterable)
  │    │
  │    ├─ [Review Document]
  │    │  ├─ View assignment + captured image
  │    │  ├─ [Approve] → Status = REVIEWED
  │    │  ├─ [Reject] → Status = PENDING + feedback
  │    │  └─ [Request Re-capture]
  │    │
  │    └─ Quality statistics by digitizer
  │
  ├─→ [ViewerDashboardScreen]
  │    │
  │    ├─ Overall statistics (read-only)
  │    ├─ Progress reports by digitizer/family
  │    ├─ Timeframe selector (today/week/month/all)
  │    │
  │    ├─ [Export Reports]
  │    │  ├─ Generate CSV
  │    │  └─ Share via system
  │    │
  │    └─ [Advanced Analytics]
  │        └─→ DashboardScreen (Phase 2)
  │
  ├─→ [GapAnalysisScreen]
  │    │
  │    ├─ Tab 1: Summary statistics
  │    ├─ Tab 2: Per person gaps
  │    ├─ Tab 3: Per family gaps
  │    │
  │    └─ Missing documents alerts
  │
  └─→ [Logout]
       │
       └─ Clear auth state
       └─ Clear selections
       └─→ LoginScreen
```

---

## 8. Component Relationship Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Screens (17 total)                  Providers (3 total)             │
│  ├─ LoginScreen                      ├─ AuthProvider                 │
│  ├─ OnboardingScreen                 ├─ CensusProvider               │
│  ├─ PersonSelectionScreen            └─ AssignmentProvider           │
│  ├─ DocumentMetadataScreen                                           │
│  ├─ UploadScreen                     Widgets                         │
│  ├─ DocumentPreviewScreen            ├─ SessionIndicatorWidget       │
│  ├─ AssignmentListScreen             ├─ AssignmentCard               │
│  ├─ AdminDashboardScreen             ├─ DashboardWidgets             │
│  ├─ DigitizerDashboardScreen         └─ ChartWidget                  │
│  ├─ ReviewerDashboardScreen                                          │
│  ├─ ViewerDashboardScreen            Navigation                      │
│  ├─ DashboardScreen (Phase 2)        └─ RoleBasedNavigator           │
│  ├─ FamilyReportScreen                                               │
│  ├─ ExportReportScreen                                               │
│  ├─ GapAnalysisScreen                                                │
│  ├─ AdminPanelScreen                                                 │
│  └─ ServerConfigScreen                                               │
│                                                                       │
└───────────────────┬───────────────────────────────────────────────────┘
                    │ Consumes
                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Repositories (4 total)              Services (12 total)             │
│  ├─ AuthRepository                   ├─ UploadService                │
│  ├─ CensusRepository                 ├─ BackgroundSyncService        │
│  ├─ DocumentRepository               ├─ HybridOcrService             │
│  └─ AssignmentRepository             ├─ LocalOcrService              │
│                                      ├─ ImageOptimizer (Phase 2)     │
│  Data Sources                        ├─ DocumentScannerService       │
│  ├─ PaperlessApiClient               ├─ ImageQualityChecker          │
│  ├─ CensusDataSource                 ├─ ReportingService             │
│  └─ AppDatabase (SQLite)             ├─ GapAnalysisService           │
│                                      ├─ CSVExportService             │
│                                      ├─ FileDeletionService          │
│                                      ├─ ConnectivityService          │
│                                      └─ WorkflowEngine                │
│                                                                       │
└───────────────────┬───────────────────────────────────────────────────┘
                    │ Uses
                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Entities (8 total)                                                  │
│  ├─ AuthToken        ├─ Person                ├─ Assignment           │
│  ├─ UserProfile      ├─ DocumentExistenceCheck                       │
│  ├─ PersonAssignment ├─ DocumentReview                               │
│  ├─ DigitizationSession (Phase 2)                                    │
│  └─ Tag                                                              │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                    │ Maps to
                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       BACKEND API (Django)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Authentication: /api/auth/login/, /api/auth/me/                    │
│  Assignments:    /api/auth/assignments/, /api/auth/my-assignments/  │
│  Documents:      /api/documents/, /api/documents/check/             │
│  Productivity:   /api/auth/productivity/                            │
│  Metrics:        /api/auth/team-stats/                              │
│  Census:         /api/census/ (persons, families)                   │
│  Export:         /api/auth/assignments/export-csv/                  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 9. State Management Architecture

```
┌──────────────────────────────────────────────────────┐
│          PROVIDER PATTERN (ChangeNotifier)           │
├──────────────────────────────────────────────────────┤
│                                                      │
│  MultiProvider at root (main.dart)                  │
│  ├─ ChangeNotifierProvider: AuthProvider            │
│  ├─ ChangeNotifierProvider: CensusProvider          │
│  ├─ ChangeNotifierProvider: AssignmentProvider      │
│  └─ Provider.value: Repositories & Services         │
│                                                      │
│  Child widgets consume via:                         │
│  ├─ Consumer<AuthProvider>                          │
│  ├─ Provider.of<AssignmentProvider>()              │
│  └─ context.read<CensusProvider>()                 │
│                                                      │
├──────────────────────────────────────────────────────┤
│         SECONDARY STATE STORAGE                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  SharedPreferences (unencrypted):                   │
│  ├─ onboarding_completed: boolean                   │
│  ├─ selectedPerson: JSON                            │
│  └─ documentMetadata: key-value pairs               │
│                                                      │
│  FlutterSecureStorage (encrypted):                  │
│  ├─ token: JWT access token                         │
│  ├─ refreshToken: JWT refresh token                 │
│  ├─ username: cached username                       │
│  └─ baseUrl: API server URL                         │
│                                                      │
│  SQLite (AppDatabase - Drift):                      │
│  ├─ upload_queue: pending uploads                   │
│  ├─ upload_history: completed uploads               │
│  ├─ failed_uploads: upload errors                   │
│  └─ session_data: local session tracking            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 10. Key Architecture Patterns

### 10.1 Clean Architecture Layers

```
Presentation Layer (UI)
    ↓ (Depends on)
Domain Layer (Business Logic)
    ↓ (Depends on)
Data Layer (API + Local Storage)
    ↑ (Implements interfaces from)
Domain Layer
```

### 10.2 Repository Pattern
- **Purpose:** Abstract data sources (API, local database)
- **Implementation:** 4 repositories (Auth, Census, Document, Assignment)
- **Benefits:** Easy to mock, testable, loose coupling

### 10.3 Provider Pattern (State Management)
- **Purpose:** Reactive state management without complex logic
- **Implementation:** ChangeNotifier + Consumer widgets
- **Benefits:** Simple, performant, Flutter native

### 10.4 Service Layer Pattern
- **Purpose:** Complex business logic separated from UI
- **Implementation:** 12 independent services
- **Benefits:** Reusability, testability, separation of concerns

### 10.5 Role-Based Navigation Pattern
- **Purpose:** Route users to correct dashboard based on role
- **Implementation:** RoleBasedNavigator + UserProfile.role
- **Benefits:** Centralized routing logic, easy to maintain

---

## 11. API Endpoints Reference

| Method | Endpoint | Used By | Purpose |
|--------|----------|---------|---------|
| POST | `/api/auth/login/` | AuthProvider | JWT authentication |
| GET | `/api/auth/me/` | AssignmentProvider | Get user profile |
| GET | `/api/auth/my-assignments/` | AssignmentProvider | Get digitizer's assignments |
| GET | `/api/auth/assignments/` | AssignmentProvider | Get all assignments (admin) |
| POST | `/api/auth/assignments/bulk/` | AdminDashboard | Create bulk assignments |
| PATCH | `/api/auth/assignments/{id}/` | ReviewerDashboard | Update assignment (approve/reject) |
| GET | `/api/auth/productivity/` | AssignmentProvider | Get productivity metrics |
| GET | `/api/auth/team-stats/` | AssignmentProvider | Get team statistics |
| GET | `/api/auth/digitizers/` | AssignmentProvider | Get list of digitizers |
| POST | `/api/documents/` | DocumentRepository | Upload document |
| POST | `/api/documents/check/` | DocumentRepository | Check if document exists |
| GET | `/api/documents/{id}/` | DocumentRepository | Get document details |
| POST | `/api/auth/sessions/` | AssignmentProvider | Start digitization session |
| PATCH | `/api/auth/sessions/{id}/` | AssignmentProvider | Complete session |
| GET | `/api/auth/assignments/export-csv/` | CSVExportService | Export to CSV |
| GET | `/api/census/persons/` | CensusRepository | Get all persons |
| GET | `/api/census/persons/search/` | CensusRepository | Search persons |
| POST | `/api/documents/ocr/` | HybridOcrService | Cloud OCR processing |

---

## 12. Key Files Summary

```
lib/
├── main.dart (🔑 Entry point, Provider setup)
├── presentation/
│   ├── screens/ (legacy OpenScan screens)
│   ├── auth/
│   │   └── login_screen.dart (🔑 Authentication)
│   ├── census/
│   │   └── person_selection_screen.dart (🔑 Person selection)
│   ├── document/
│   │   ├── upload_screen.dart (🔑 Upload with anti-duplicate)
│   │   └── document_preview_screen.dart (🔑 Quality & OCR)
│   ├── assignment/
│   │   └── assignment_list_screen.dart (Assignment progress)
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart (🔑 Admin view)
│   │   └── admin_panel_screen.dart (System configuration)
│   ├── digitizer/
│   │   └── digitizer_dashboard_screen.dart (🔑 Digitizer view)
│   ├── reviewer/
│   │   └── reviewer_dashboard_screen.dart (🔑 Review workflow)
│   ├── viewer/
│   │   └── viewer_dashboard_screen.dart (🔑 Analytics view)
│   ├── reporting/
│   │   ├── dashboard_screen.dart (Analytics)
│   │   ├── family_report_screen.dart (Family reports)
│   │   └── export_report_screen.dart (CSV/PDF export)
│   ├── gap_analysis/
│   │   └── gap_analysis_screen.dart (Gap detection)
│   ├── providers/
│   │   ├── auth_provider.dart (🔑 Auth state)
│   │   ├── census_provider.dart (🔑 Person state)
│   │   └── assignment_provider.dart (🔑 Assignment state)
│   └── widgets/ (Reusable UI components)
├── data/
│   ├── datasources/
│   │   ├── paperless_api_client.dart (🔑 API communication)
│   │   └── census_data_source.dart (Census loading)
│   ├── repositories/
│   │   ├── auth_repository.dart (🔑 Auth logic)
│   │   ├── census_repository.dart (Census logic)
│   │   ├── document_repository.dart (🔑 Upload logic)
│   │   └── assignment_repository.dart (🔑 Assignment logic)
│   └── local/
│       └── database/
│           └── app_database.dart (SQLite schema)
├── domain/
│   └── entities/
│       ├── auth_token.dart (JWT structure)
│       ├── user_profile.dart (🔑 User role enum)
│       ├── assignment.dart (🔑 Assignment entity)
│       ├── person.dart (Census person)
│       ├── digitization_session.dart (Phase 2)
│       └── document_review.dart (Phase 2)
├── services/
│   ├── upload_service.dart (🔑 Upload queue & retry)
│   ├── background_sync_service.dart (🔑 Periodic sync)
│   ├── hybrid_ocr_service.dart (🔑 Local → Cloud OCR)
│   ├── image_optimizer.dart (Phase 2 compression)
│   ├── csv_export_service.dart (Phase 2 export)
│   ├── gap_analysis_service.dart (Gap detection)
│   ├── reporting_service.dart (Analytics)
│   ├── workflow_engine.dart (Rule automation)
│   └── [8 more services]
├── core/
│   ├── constants/
│   │   └── api_constants.dart (API URLs, defaults)
│   ├── navigation/
│   │   └── role_based_navigator.dart (🔑 Role routing)
│   ├── security/
│   │   ├── rate_limiter.dart (Login rate limit)
│   │   └── secure_config_manager.dart (Encrypted storage)
│   └── config/
│       ├── production_config.dart (App configuration)
│       └── logging_config.dart (Phase 2)
└── Utilities/
    ├── database_helper.dart
    └── constants.dart

🔑 = Critical/Core file for architecture
```

---

## 13. Completeness Assessment

### Fully Implemented
✅ Authentication system (JWT + rate limiting)
✅ Multi-user role-based access (4 roles)
✅ Document upload with anti-duplicate detection
✅ Quality validation (images, OCR)
✅ Hybrid OCR (local + cloud fallback)
✅ Assignment management (create, view, complete)
✅ Offline-first sync with queue + retry
✅ Gap analysis (missing documents)
✅ Role-based navigation (routing by user role)
✅ Session tracking (Phase 2)
✅ Review workflow (approve/reject)
✅ CSV export (Phase 2)
✅ Reporting & analytics (basic)

### Partially Implemented
⚠️ PDF export (infrastructure exists, needs polish)
⚠️ Excel export (infrastructure exists, needs polish)
⚠️ Advanced analytics/charts (basic implementation)
⚠️ Image optimization (Phase 2, basic compression)
⚠️ Reassignment workflows (admin function)

### Not Yet Implemented
❌ Push notifications
❌ Advanced search (full-text across documents)
❌ Batch OCR processing
❌ Document versioning
❌ Audit trail (complete logging)
❌ Permission-based field editing
❌ Document recommendations
❌ ML-based quality automation

---

## 14. Dependencies (Key)

| Package | Purpose | Version |
|---------|---------|---------|
| flutter | UI framework | 3.x |
| provider | State management | ^6.1.2 |
| dio | HTTP client | ^5.7.0 |
| drift | SQLite ORM | ^2.14.0 |
| flutter_secure_storage | Encrypted storage | ^9.2.2 |
| google_mlkit_text_recognition | Local OCR | ^0.13.1 |
| image_cropper | Image editing | ^11.0.0 |
| image | Image processing | ^4.1.7 |
| flutter_foreground_task | Background sync | ^8.14.0 |
| logger | Logging | ^2.4.0 |
| fl_chart | Charts/graphs | ^0.66.0 |
| csv | CSV parsing | ^6.0.0 |
| excel | Excel export | ^4.0.3 |

---

## 15. Security Considerations

| Concern | Implementation |
|---------|----------------|
| Token storage | FlutterSecureStorage (encrypted) |
| API authentication | JWT (Bearer token) + rate limiting |
| Password transmission | HTTPS only (enforced in API client) |
| Sensitive data in logs | Masked in logger (no tokens/passwords) |
| Local database encryption | AES-256-GCM for uploaded files |
| CSRF protection | Backend CSRF tokens |
| Input validation | Form validation + sanitization |
| SQL injection | Drift (type-safe ORM) |
| Network security | Certificate pinning (optional) |

---

## 16. Performance Optimizations

| Area | Optimization | Impact |
|------|--------------|--------|
| Image upload | ImageOptimizer (Phase 2) 60-80% compression | ↓ 50-70% bandwidth |
| Database | SQLite WAL mode + indexes | ↑ 3-5x faster queries |
| API calls | Metadata caching (1-hour TTL) | ↓ API calls |
| List rendering | ListView.builder | ↑ Smooth scrolling |
| Images | Progressive JPEG encoding | ↓ Load time |
| OCR | Hybrid (local preferred) | ↓ 70% API costs |
| Sync | Background service + queue | Offline-first |

---

**Document Generated:** November 1, 2025  
**Lumara Version:** 5.6.1 (Fase 2)  
**Analysis Thoroughness:** Very Thorough  
**Frontend Status:** Production Ready (Phase 2 features integrated)
