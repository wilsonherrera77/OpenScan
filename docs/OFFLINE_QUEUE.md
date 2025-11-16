# 📦 Offline Queue Implementation

**Status**: ✅ Complete
**Version**: 1.0.0
**Sprint**: Phase 1 - Core Functionality

---

## 📋 Overview

Sistema de cola offline que permite a la aplicación OpenScan continuar digitalizando documentos sin conexión a internet. Los documentos se almacenan localmente y se sincronizan automáticamente con Paperless-ngx cuando se restaura la conectividad.

### Características Principales

- ✅ **Persistencia Local**: Base de datos SQLite con Drift ORM
- ✅ **Retry Logic**: Reintentos automáticos con backoff exponencial
- ✅ **Background Sync**: Sincronización periódica cada 15 minutos
- ✅ **Network Monitor**: Detección automática de reconexión
- ✅ **Performance Tracking**: Métricas de tamaño, duración y estado offline
- ✅ **UI Indicators**: Widget visual del estado de la cola

---

## 🏗️ Arquitectura

### Componentes

```
┌─────────────────────────────────────────────────────────┐
│                     OpenScan App                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ UploadScreen │  │  Upload      │  │  Network     │  │
│  │              │→ │  Service     │← │  Monitor     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                 ↓                   ↓          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Queue        │  │  App         │  │  Background  │  │
│  │ Indicator    │  │  Database    │  │  Sync Svc    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                           ↓                   ↓          │
│                    ┌──────────────────────────┐         │
│                    │   Drift SQLite DB        │         │
│                    │ openscan_indigenas.db    │         │
│                    └──────────────────────────┘         │
│                                                          │
└─────────────────────────────────────────────────────────┘
                           ↓
                 Network Available?
                           ↓
          ┌────────────────┴────────────────┐
          ↓                                 ↓
    ┌──────────┐                      ┌──────────┐
    │ Paperless│                      │  Local   │
    │   API    │                      │  Queue   │
    └──────────┘                      └──────────┘
```

---

## 💾 Database Schema

### Tables

#### PendingUploads
Documentos esperando ser subidos a Paperless.

| Column          | Type      | Description                    |
|-----------------|-----------|--------------------------------|
| id              | INTEGER   | Primary key                    |
| personId        | TEXT      | ID de la persona del censo     |
| personName      | TEXT      | Nombre completo                |
| familyId        | TEXT      | ID de la familia               |
| filePath        | TEXT      | Ruta local del archivo         |
| fileName        | TEXT      | Nombre del archivo             |
| documentType    | TEXT      | Tipo de documento (legacy)     |
| documentNumber  | TEXT?     | Número del documento           |
| digitizedBy     | TEXT?     | Usuario que digitalizó         |
| **metadata**    | TEXT      | **JSON con metadata adicional**|
| **tags**        | TEXT      | **IDs de tags separados por ,**|
| **documentTypeId**| INTEGER?| **ID del tipo en Paperless**   |
| createdAt       | DATETIME  | Timestamp de creación          |
| retryCount      | INTEGER   | Número de reintentos           |
| status          | TEXT      | pending/uploading/failed       |
| lastError       | TEXT?     | Último error registrado        |
| lastAttemptAt   | DATETIME? | Timestamp del último intento   |

#### UploadHistory
Historial de documentos subidos exitosamente.

| Column              | Type      | Description                    |
|---------------------|-----------|--------------------------------|
| id                  | INTEGER   | Primary key                    |
| personId            | TEXT      | ID de la persona               |
| personName          | TEXT      | Nombre completo                |
| documentType        | TEXT      | Tipo de documento              |
| paperlessDocumentId | INTEGER?  | ID en Paperless-ngx            |
| uploadedAt          | DATETIME  | Timestamp de subida            |
| status              | TEXT      | success/failed                 |
| **fileSize**        | INTEGER   | **Tamaño del archivo (bytes)** |
| **uploadDurationMs**| INTEGER   | **Duración de subida (ms)**    |
| **wasOffline**      | BOOLEAN   | **¿Se subió offline?**         |

#### Persons
Cache local del censo de personas.

| Column      | Type     | Description                    |
|-------------|----------|--------------------------------|
| id          | TEXT     | Primary key - ID persona       |
| censusId    | TEXT?    | ID del censo                   |
| name        | TEXT     | Nombre completo                |
| birthDate   | TEXT?    | Fecha de nacimiento            |
| lifeStage   | TEXT?    | Etapa de vida                  |
| familyRole  | TEXT?    | Rol en la familia              |
| community   | TEXT?    | Comunidad                      |
| syncedAt    | DATETIME | Última sincronización          |

#### DocumentTypes
Cache de tipos de documento de Paperless.

| Column    | Type     | Description                    |
|-----------|----------|--------------------------------|
| id        | INTEGER  | Primary key - ID Paperless     |
| name      | TEXT     | Nombre del tipo                |
| cachedAt  | DATETIME | Timestamp del cache            |

#### Tags
Cache de tags de Paperless.

| Column    | Type     | Description                    |
|-----------|----------|--------------------------------|
| id        | INTEGER  | Primary key - ID Paperless     |
| name      | TEXT     | Nombre del tag                 |
| color     | TEXT?    | Color hex del tag              |
| cachedAt  | DATETIME | Timestamp del cache            |

---

## 🔄 Upload Flow

### 1. User Captures Document

```dart
// lib/presentation/document/upload_screen.dart
Future<void> _upload() async {
  final uploadId = await uploadService.enqueueUploadEnhanced(
    person: person,
    imageFile: _imageFile!,
    documentType: _selectedDocType!,
    documentNumber: _docNumberController.text,
    digitizedBy: authProvider.username,
    documentTypeId: 1,
    tagIds: [1, 2, 3],
    metadata: {'location': 'Comunidad A'},
  );

  // Upload queued → will sync automatically
}
```

### 2. Immediate Upload Attempt

```dart
// lib/services/upload_service.dart
Future<int> enqueueUploadEnhanced(...) async {
  final id = await _database.enqueueUpload(...);

  // Try immediate upload (non-blocking)
  _attemptImmediateUpload(id);

  return id;
}
```

### 3. Background Sync (if immediate fails)

```dart
// lib/services/background_sync_service.dart
// Executes every 15 minutes via WorkManager
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final uploadService = UploadService(database, repository);
    await uploadService.processAllPending();
    return Future.value(true);
  });
}
```

### 4. Network Restore Trigger

```dart
// lib/services/network_monitor.dart
void _onConnectivityChanged(List<ConnectivityResult> results) {
  if (_wasOffline && !isCurrentlyOffline) {
    // Offline → Online transition detected
    BackgroundSyncService.scheduleImmediateSync();
  }
}
```

---

## ⚙️ Retry Logic

### Exponential Backoff

```dart
Duration _calculateBackoffDelay(int attempt) {
  // Attempt 1: 5s
  // Attempt 2: 10s
  // Attempt 3: 20s
  // Max: 300s (5 minutes)

  final seconds = retryDelayBase.inSeconds * (1 << (attempt - 1));
  return Duration(seconds: seconds.clamp(5, 300));
}
```

### Retryable Errors

| Error Type          | Retryable? | Reason                        |
|---------------------|------------|-------------------------------|
| Network errors      | ✅ Yes     | Temporary connectivity issue  |
| Timeout             | ✅ Yes     | May succeed on retry          |
| Server errors (5xx) | ✅ Yes     | Server may recover            |
| Auth errors (401)   | ❌ No      | Requires user intervention    |
| Client errors (4xx) | ❌ No      | Bad request, won't change     |
| File not found      | ❌ No      | File deleted from device      |

### Max Retry Attempts

```dart
static const int maxRetryAttempts = 3;
```

Después de 3 intentos, el upload se marca como `failed` y requiere intervención manual.

---

## 📊 Performance Metrics

### Tracked Metrics

1. **File Size** (`fileSize`)
   - Tamaño del archivo en bytes
   - Usado para calcular velocidad de subida

2. **Upload Duration** (`uploadDurationMs`)
   - Tiempo desde inicio hasta fin de subida
   - Incluye tiempo de red + procesamiento Paperless

3. **Offline Flag** (`wasOffline`)
   - `true` si el upload tuvo `retryCount > 0`
   - Indica que el documento fue queued mientras estaba offline

### Statistics Query

```dart
final stats = await uploadService.getEnhancedStatistics();

// Returns:
{
  'pending': 5,
  'failed': 2,
  'success': 150,
  'total': 157,
  'avg_duration_ms': 2500,
  'offline_uploads': 30,
}
```

---

## 🖥️ UI Components

### UploadQueueIndicator

Widget badge que muestra el estado de la cola en tiempo real.

**Location**: `lib/presentation/widgets/upload_queue_indicator.dart`

**Usage**:
```dart
AppBar(
  actions: [
    UploadQueueIndicator(
      onTap: () => showQueueDetails(),
    ),
  ],
)
```

**Features**:
- Auto-hide cuando no hay uploads pendientes/fallidos
- Badge azul para pendientes, rojo para fallidos
- Tap para abrir detalles en bottom sheet
- Refresh automático al abrir

---

## 🧪 Testing

### Unit Tests

```bash
flutter test test/data/local/app_database_test.dart
flutter test test/services/upload_service_test.dart
```

**Coverage**:
- ✅ Database CRUD operations
- ✅ Upload enqueue with metadata
- ✅ Retry logic validation
- ✅ Statistics tracking
- ✅ Performance metrics
- ✅ Cache operations (Persons, DocumentTypes, Tags)

**Note**: Tests require `libsqlite3` installed on host machine.

### Integration Test Scenarios

1. **Offline Upload Flow**
   - User captures document offline
   - Document queued locally
   - Network restored
   - Auto-sync triggered
   - Document uploaded successfully

2. **Retry with Backoff**
   - Upload fails with network error
   - Retry after 5 seconds (attempt 1)
   - Retry after 10 seconds (attempt 2)
   - Retry after 20 seconds (attempt 3)
   - Mark as failed after max retries

3. **Multiple Pending Uploads**
   - Queue 10 documents offline
   - Network restored
   - All documents processed sequentially
   - Statistics updated correctly

---

## 📖 API Reference

### UploadService

#### Methods

##### `enqueueUpload()`
Legacy method for backward compatibility.

```dart
Future<int> enqueueUpload({
  required Person person,
  required File imageFile,
  required String documentType,
  String? documentNumber,
  String? digitizedBy,
}) async
```

##### `enqueueUploadEnhanced()`
Enhanced method with full metadata support.

```dart
Future<int> enqueueUploadEnhanced({
  required Person person,
  required File imageFile,
  required String documentType,
  String? documentNumber,
  String? digitizedBy,
  int? documentTypeId,
  List<int>? tagIds,
  Map<String, dynamic>? metadata,
}) async
```

##### `processUpload(uploadId)`
Process a single upload with retry logic.

```dart
Future<void> processUpload(int uploadId) async
```

##### `processAllPending()`
Process all pending uploads.

```dart
Future<void> processAllPending() async
```

##### `getStatistics()`
Get basic upload statistics.

```dart
Future<Map<String, int>> getStatistics() async
// Returns: {pending, failed, success, total}
```

##### `getEnhancedStatistics()`
Get statistics with performance metrics.

```dart
Future<Map<String, dynamic>> getEnhancedStatistics() async
// Returns: {pending, failed, success, total, avg_duration_ms, offline_uploads}
```

##### `retryUpload(uploadId)`
Retry a specific failed upload.

```dart
Future<void> retryUpload(int uploadId) async
```

##### `retryAllFailed()`
Retry all failed uploads.

```dart
Future<void> retryAllFailed() async
```

##### `clearFailedUploads()`
Remove all failed uploads from queue.

```dart
Future<void> clearFailedUploads() async
```

---

### NetworkMonitor

#### Methods

##### `startMonitoring()`
Start listening to network connectivity changes.

```dart
Future<void> startMonitoring() async
```

##### `stopMonitoring()`
Stop network monitoring.

```dart
Future<void> stopMonitoring() async
```

##### `isConnected()`
Check if device has network connectivity.

```dart
Future<bool> isConnected() async
```

##### `getConnectivityStatus()`
Get detailed connectivity status.

```dart
Future<String> getConnectivityStatus() async
// Returns: 'wifi' | 'mobile' | 'ethernet' | 'offline' | 'unknown'
```

##### `isGoodForUploads()`
Check if network is suitable for uploads.

```dart
Future<bool> isGoodForUploads() async
// WiFi/Ethernet = true, Mobile = true (configurable), Offline = false
```

---

### BackgroundSyncService

#### Methods

##### `initialize()`
Initialize WorkManager and schedule periodic sync.

```dart
static Future<void> initialize() async
```

##### `scheduleImmediateSync()`
Trigger immediate one-time sync.

```dart
static Future<void> scheduleImmediateSync() async
```

##### `cancelAll()`
Cancel all background tasks.

```dart
static Future<void> cancelAll() async
```

##### `rescheduleSync({frequency})`
Change periodic sync frequency.

```dart
static Future<void> rescheduleSync({
  required Duration frequency,
}) async
```

---

## 🚀 Usage Examples

### Basic Upload

```dart
final uploadId = await uploadService.enqueueUpload(
  person: selectedPerson,
  imageFile: File('/path/to/image.jpg'),
  documentType: 'CEDULA_CIUDADANIA',
  documentNumber: '1234567890',
  digitizedBy: 'admin',
);

print('Upload queued with ID: $uploadId');
```

### Upload with Tags and Metadata

```dart
final uploadId = await uploadService.enqueueUploadEnhanced(
  person: selectedPerson,
  imageFile: File('/path/to/image.jpg'),
  documentType: 'CEDULA_CIUDADANIA',
  documentNumber: '1234567890',
  digitizedBy: 'admin',
  documentTypeId: 1,
  tagIds: [10, 20, 30], // Paperless tag IDs
  metadata: {
    'location': 'Comunidad A',
    'notes': 'Documento escaneado en campo',
    'quality': 'high',
  },
);
```

### Check Queue Status

```dart
final stats = await uploadService.getEnhancedStatistics();

print('Pending: ${stats['pending']}');
print('Failed: ${stats['failed']}');
print('Success: ${stats['success']}');
print('Avg Duration: ${stats['avg_duration_ms']}ms');
print('Offline Uploads: ${stats['offline_uploads']}');
```

### Manual Retry

```dart
// Retry specific upload
await uploadService.retryUpload(uploadId);

// Retry all failed
await uploadService.retryAllFailed();

// Clear all failed
await uploadService.clearFailedUploads();
```

### Network Monitoring

```dart
final monitor = NetworkMonitor();

// Start monitoring
await monitor.startMonitoring();

// Check status
final isConnected = await monitor.isConnected();
final status = await monitor.getConnectivityStatus();
final goodForUpload = await monitor.isGoodForUploads();

print('Connected: $isConnected');
print('Status: $status'); // wifi/mobile/ethernet/offline
print('Good for upload: $goodForUpload');
```

---

## 🔧 Configuration

### WorkManager Frequency

Default: Every 15 minutes

```dart
// lib/services/background_sync_service.dart
await Workmanager().registerPeriodicTask(
  uniqueName,
  syncTaskName,
  frequency: const Duration(minutes: 15), // Change here
);
```

### Retry Settings

```dart
// lib/services/upload_service.dart
static const int maxRetryAttempts = 3; // Max retry count
static const Duration retryDelayBase = Duration(seconds: 5); // Base delay
```

### Database Name

```dart
// lib/data/local/database/app_database.dart
return driftDatabase(
  name: 'openscan_indigenas.db', // Change here
);
```

---

## 📝 Migration Guide

### Schema Version 1 → 2

**What changed**:
- Added `metadata`, `tags`, `documentTypeId` columns to `PendingUploads`
- Added `fileSize`, `uploadDurationMs`, `wasOffline` columns to `UploadHistory`
- Added new tables: `Persons`, `DocumentTypes`, `Tags`

**Migration is automatic** on app upgrade. Existing data is preserved.

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      // Add columns
      await m.addColumn(pendingUploads, pendingUploads.metadata);
      await m.addColumn(pendingUploads, pendingUploads.tags);
      // ... etc

      // Create tables
      await m.createTable(persons);
      await m.createTable(documentTypes);
      await m.createTable(tags);
    }
  },
);
```

---

## 🐛 Troubleshooting

### Issue: Uploads stuck in "uploading" state

**Cause**: App crashed during upload
**Solution**: Status will be reset to "pending" after app restart and backoff delay

### Issue: Failed uploads not retrying

**Cause**: Error is non-retryable (e.g., 401, 404)
**Solution**: Check `lastError` field, fix root cause, then manual retry

### Issue: Background sync not working

**Cause**: Battery optimization blocking WorkManager
**Solution**: Disable battery optimization for OpenScan in device settings

### Issue: Network monitor not triggering sync

**Cause**: Connectivity changes not detected
**Solution**: Check app has `ACCESS_NETWORK_STATE` permission

---

## 🎯 Future Enhancements

1. **Compression**: Compress images before queuing to save space
2. **Priority Queue**: Allow marking urgent uploads for priority processing
3. **Batch Upload**: Upload multiple documents in parallel
4. **Conflict Resolution**: Handle duplicate uploads gracefully
5. **Storage Limits**: Auto-clean old queue items when storage low
6. **Upload Scheduling**: User-configured sync times (e.g., only on WiFi)
7. **Progress Notifications**: Show upload progress in notification bar
8. **Selective Sync**: Allow user to pause/resume specific uploads

---

## 📜 License

Part of OpenScan Indigenas project
See [LICENSE](../LICENSE) for details

---

## 👥 Contributors

- AI Assistant (Implementation)
- SMT (Requirements & Testing)

---

**Last Updated**: 2025-10-07
**Document Version**: 1.0.0
