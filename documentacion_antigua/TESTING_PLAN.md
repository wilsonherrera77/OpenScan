# Sprint 1.5 - Offline Queue Testing Plan

## 🎯 Testing Objective

Validate the complete offline-first document upload queue system with background synchronization.

## 📋 Test Environment Setup

### Prerequisites

1. **Tejido-ngx Backend Running:**
   ```bash
   cd /home/smt/Escritorio/programacion_proyectos/tejido/tejido-ngx
   docker compose up -d
   # Verify: http://localhost:8001
   ```

2. **Flutter Environment:**
   ```bash
   cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
   ./build.sh  # Generates Drift code
   ```

3. **Census Data Present:**
   - Verify `assets/census/censo_indigenas.csv` exists
   - Contains 3,997 person records

4. **Test Devices:**
   - Android Emulator (API 30+)
   - OR Physical Android device with USB debugging

## 🧪 Test Cases

### TC-1: Database Initialization

**Objective:** Verify Drift database creates tables correctly

**Steps:**
1. Launch app: `flutter run`
2. Check logs for database initialization
3. Expected log: `✅ Background sync initialized`

**Expected Results:**
- No database creation errors
- Tables `pending_uploads` and `upload_history` created
- Initial schema version: 1

**Pass Criteria:** App launches without database errors

---

### TC-2: Login and Authentication

**Objective:** Verify authentication stores credentials properly

**Steps:**
1. Enter credentials:
   - Username: `admin`
   - Password: `admin`
   - Base URL: `http://10.0.2.2:8001` (emulator) or device IP
2. Tap "Iniciar Sesión"

**Expected Results:**
- Token saved to FlutterSecureStorage
- Navigation to Person Selection screen
- AuthProvider.isAuthenticated = true

**Pass Criteria:** Successful login and navigation

---

### TC-3: Person Selection

**Objective:** Verify census data loads correctly

**Steps:**
1. On Person Selection screen
2. Observe person list
3. Check statistics card
4. Try search: "María"

**Expected Results:**
- All 3,997 persons displayed
- Statistics show correct counts
- Search filters results
- Can select person

**Pass Criteria:** Can select a person and proceed to upload

---

### TC-4: Online Upload (Immediate Success)

**Objective:** Verify immediate upload when network available

**Steps:**
1. Ensure device has network connectivity
2. Select person from list
3. Tap "Cámara" or "Galería"
4. Select/capture test image
5. Select document type: "Cédula de Ciudadanía"
6. Enter document number (optional): "12345678"
7. Tap "Subir Documento"

**Expected Results:**
1. Document enqueued to database
2. Immediate upload attempted
3. Success message: "✅ Documento agregado a cola de sincronización"
4. Upload completes in background
5. Document appears in Tejido-ngx
6. Local file deleted after successful upload
7. Entry added to upload_history
8. Entry removed from pending_uploads

**Verification:**
```bash
# Check Tejido has document
curl -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  http://localhost:8001/api/documents/ | jq
```

**Pass Criteria:** Document visible in Tejido within 5 seconds

---

### TC-5: Offline Upload (Queue Storage)

**Objective:** Verify documents queue when offline

**Steps:**
1. **Disable network:**
   - Emulator: Turn off WiFi in Android settings
   - Physical: Enable airplane mode
2. Select person
3. Capture/select image
4. Select document type
5. Tap "Subir Documento"

**Expected Results:**
1. Document enqueued successfully
2. Immediate upload fails silently (logged)
3. Success message still shown
4. Document persists in `pending_uploads` table
5. Status: "pending"
6. retryCount: 0

**Database Verification:**
```dart
// Check via Flutter logs or database inspector
final pending = await uploadService.getPendingUploads();
print(pending); // Should show queued document
```

**Pass Criteria:** Document saved to queue, no crash

---

### TC-6: Background Sync Trigger

**Objective:** Verify background sync processes queue

**Steps:**
1. With documents in queue (from TC-5)
2. **Re-enable network**
3. Wait for background sync (15 min periodic)
4. OR trigger manual sync:
   ```dart
   await BackgroundSyncService.scheduleImmediateSync();
   ```
5. Observe logs

**Expected Results:**
1. WorkManager executes sync task
2. Logs show: `🔄 Background task started`
3. Pending documents uploaded
4. Logs show: `✅ Background task completed successfully`
5. Documents removed from pending_uploads
6. Entries added to upload_history
7. Documents visible in Tejido

**Pass Criteria:** All queued documents uploaded within 2 minutes

---

### TC-7: Retry Logic - Network Errors

**Objective:** Verify retryable errors increment retry count

**Steps:**
1. Upload document with network disabled
2. Manually trigger upload processing:
   ```dart
   await uploadService.processUpload(uploadId);
   ```
3. Observe retry behavior

**Expected Results:**
1. First attempt fails
2. Status remains: "pending"
3. retryCount: 1
4. lastError populated
5. lastAttemptAt updated

**Pass Criteria:** Retry count increments, status stays pending

---

### TC-8: Retry Logic - Permanent Failures

**Objective:** Verify non-retryable errors mark as failed

**Steps:**
1. Modify person data to cause 400 error (invalid data)
2. Upload document
3. Observe behavior

**Expected Results:**
1. Upload fails with client error
2. Error classified as non-retryable
3. Status changes to: "failed"
4. Document not deleted from queue
5. User can manually retry later

**Pass Criteria:** Failed upload marked as "failed", not deleted

---

### TC-9: Upload Statistics

**Objective:** Verify statistics calculation

**Steps:**
1. After completing TC-4 through TC-8
2. Call statistics method:
   ```dart
   final stats = await uploadService.getStatistics();
   print(stats);
   ```

**Expected Results:**
```dart
{
  'pending': X,   // Documents waiting
  'success': Y,   // Successful uploads
  'failed': Z,    // Permanently failed
  'total': X+Y+Z
}
```

**Pass Criteria:** Statistics accurately reflect database state

---

### TC-10: History Cleanup

**Objective:** Verify old history cleanup (keeps last 1,000)

**Steps:**
1. Create >1,000 history entries (simulate)
2. Call cleanup:
   ```dart
   await uploadService.cleanOldHistory();
   ```
3. Check remaining entries

**Expected Results:**
- Only 1,000 most recent entries remain
- Oldest entries deleted

**Pass Criteria:** History limited to 1,000 records

---

### TC-11: Retry Failed Upload

**Objective:** Verify manual retry of failed upload

**Steps:**
1. Get failed upload from TC-8
2. Fix issue (e.g., restore network)
3. Retry:
   ```dart
   await uploadService.retryUpload(uploadId);
   ```

**Expected Results:**
1. Retry count reset to 0
2. Status changed to "pending"
3. Upload attempted again
4. If successful: removed from queue

**Pass Criteria:** Failed upload can be successfully retried

---

### TC-12: File Cleanup After Success

**Objective:** Verify local files deleted after upload

**Steps:**
1. Note file path before upload
2. Upload document successfully
3. Check if file exists after upload

**Expected Results:**
- Local image file deleted
- Disk space freed
- Logs show: `🗑️ Deleted local file: <path>`

**Pass Criteria:** File no longer exists after successful upload

---

### TC-13: Concurrent Uploads

**Objective:** Verify multiple uploads don't interfere

**Steps:**
1. Queue 5 documents offline
2. Enable network
3. Trigger background sync

**Expected Results:**
- All 5 documents processed sequentially
- No database locking issues
- Success/fail count accurate

**Pass Criteria:** All documents processed without errors

---

### TC-14: App Restart Persistence

**Objective:** Verify queue persists across app restarts

**Steps:**
1. Queue documents offline
2. Close app (force stop)
3. Restart app
4. Check pending uploads

**Expected Results:**
- Queued documents still present
- No data loss
- Background sync resumes

**Pass Criteria:** Queue intact after restart

---

### TC-15: WorkManager Periodic Sync

**Objective:** Verify 15-minute periodic sync works

**Steps:**
1. Queue documents
2. Wait 15 minutes (or simulate time advance)
3. Observe logs

**Expected Results:**
- WorkManager triggers sync every 15 minutes
- Constraint: Network connected
- Logs show periodic execution

**Pass Criteria:** Sync executes periodically

---

## 🔍 Performance Tests

### PT-1: Large Queue Performance

**Objective:** Test with 100 queued documents

**Steps:**
1. Queue 100 documents offline
2. Enable network
3. Trigger background sync
4. Measure time to complete

**Expected Results:**
- All 100 documents uploaded
- No memory issues
- No ANR (Application Not Responding)

**Pass Criteria:** Complete within 5 minutes

---

### PT-2: Database Query Performance

**Objective:** Verify queries fast with 1,000+ history records

**Steps:**
1. Populate 1,000 history records
2. Query statistics
3. Query by person
4. Measure query time

**Expected Results:**
- All queries < 100ms
- UI remains responsive

**Pass Criteria:** No noticeable lag

---

## 🐛 Error Scenarios

### ES-1: Corrupted Image File

**Objective:** Handle missing/corrupted files gracefully

**Steps:**
1. Queue upload with valid file
2. Delete/corrupt file before sync
3. Trigger sync

**Expected Results:**
- Error caught: "File not found"
- Status marked: "failed"
- No crash

**Pass Criteria:** Graceful error handling

---

### ES-2: Invalid API Token

**Objective:** Handle authentication errors

**Steps:**
1. Change to invalid token
2. Attempt upload

**Expected Results:**
- 401/403 error
- Classified as non-retryable
- Status: "failed"
- User informed to re-login

**Pass Criteria:** Error categorized correctly

---

### ES-3: Server Unavailable

**Objective:** Handle 500-level errors

**Steps:**
1. Stop Tejido backend
2. Attempt upload

**Expected Results:**
- Connection/500 error
- Classified as retryable
- Status: "pending"
- Will retry

**Pass Criteria:** Retry scheduled for later

---

## 📊 Test Results Template

```
Date: __________
Tester: __________
Device: __________
Flutter Version: __________
Tejido Version: __________

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC-1      | ⬜ Pass ⬜ Fail | |
| TC-2      | ⬜ Pass ⬜ Fail | |
| TC-3      | ⬜ Pass ⬜ Fail | |
| TC-4      | ⬜ Pass ⬜ Fail | |
| TC-5      | ⬜ Pass ⬜ Fail | |
| TC-6      | ⬜ Pass ⬜ Fail | |
| TC-7      | ⬜ Pass ⬜ Fail | |
| TC-8      | ⬜ Pass ⬜ Fail | |
| TC-9      | ⬜ Pass ⬜ Fail | |
| TC-10     | ⬜ Pass ⬜ Fail | |
| TC-11     | ⬜ Pass ⬜ Fail | |
| TC-12     | ⬜ Pass ⬜ Fail | |
| TC-13     | ⬜ Pass ⬜ Fail | |
| TC-14     | ⬜ Pass ⬜ Fail | |
| TC-15     | ⬜ Pass ⬜ Fail | |

Performance Tests:
| PT-1      | ⬜ Pass ⬜ Fail | Completion time: _____ |
| PT-2      | ⬜ Pass ⬜ Fail | Query time: _____ |

Error Scenarios:
| ES-1      | ⬜ Pass ⬜ Fail | |
| ES-2      | ⬜ Pass ⬜ Fail | |
| ES-3      | ⬜ Pass ⬜ Fail | |

Overall Result: ⬜ PASS ⬜ FAIL

Critical Issues Found:
1.
2.
3.

Recommendations:
1.
2.
3.
```

## 🚀 Post-Testing Actions

If all tests pass:
- ✅ Mark Sprint 1.5 as complete
- ✅ Create release tag: `v1.5.0-offline-queue`
- ✅ Update documentation
- ✅ Prepare for Sprint 2

If tests fail:
- ❌ Document failures
- ❌ Create bug tickets
- ❌ Fix and re-test
- ❌ Do not proceed to Sprint 2
