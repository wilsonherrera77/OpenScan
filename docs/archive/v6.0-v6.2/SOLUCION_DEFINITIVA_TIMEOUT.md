# SOLUCIÓN DEFINITIVA AL CÍRCULO VICIOSO DEL TIMEOUT

**Fecha:** 2025-11-10
**Versión Actual:** v6.0.8
**Problema:** Timeout en sincronización aunque "todo funciona"
**Causa Raíz:** Arquitectura cliente-servidor desalineada

---

## 🔴 DIAGNÓSTICO CONFIRMADO

### Evidencia del Backend (Logs 19:00-21:05):
```
✅ Celery worker: ACTIVO y procesando tareas
✅ Redis broker: FUNCIONANDO correctamente
✅ No hay errores en logs
❌ CERO actividad de uploads de documentos
❌ CERO tareas de OCR en cola
```

### Conclusión:
**LOS UPLOADS NUNCA LLEGAN AL SERVIDOR**

El timeout ocurre en el **CLIENTE** antes de que la petición HTTP llegue al backend.

---

## 🎯 CAUSA RAÍZ: ARQUITECTURA DESALINEADA

### Backend (Django + Celery):
```python
# Backend ACTUAL - YA ES ASÍNCRONO
def upload_document(request):
    # 1. Recibe archivo
    # 2. Crea tarea Celery (devuelve task_id en <1 segundo)
    # 3. Responde inmediatamente con task_id
    # 4. OCR se procesa en background (15-45 segundos)
```

### Cliente (Flutter):
```dart
// Cliente ACTUAL - ES SÍNCRONO
final response = await _apiClient.uploadDocument(...);
// ❌ PROBLEMA: Espera respuesta completa (60 segundos timeout)
// ❌ Backend devuelve task_id en <1s pero OCR toma 15-45s
// ❌ Cliente no sabe esperar task_id
```

### El Círculo Vicioso:
```
📱 Cliente intenta upload con timeout 60s
    ↓
🔄 Backend recibe y devuelve task_id en <1s
    ↓
⏱️  Cliente espera resultado completo (OCR procesado)
    ↓
❌ Timeout a los 60s (OCR todavía procesando en background)
    ↓
🔁 Usuario reinstala APK → MISMO PROBLEMA
```

---

## 💡 SOLUCIÓN EN 3 NIVELES

---

## ✅ NIVEL 1: FIX INMEDIATO (Workaround - 1 hora)

**Objetivo:** Romper el círculo vicioso AHORA

### Cambios:

#### 1. Aumentar timeout a 180 segundos

**Archivo:** `lib/core/constants/api_constants.dart`

```dart
// ANTES (v6.0.8):
static const Duration receiveTimeout = Duration(seconds: 60);

// DESPUÉS (v6.0.9):
static const Duration receiveTimeout = Duration(seconds: 180); // ✅ Permite OCR completo
```

**Justificación:**
- OCR Tesseract: 15-45 segundos por página
- Documentos multi-página: hasta 90 segundos
- 180s = margen de seguridad 2x

#### 2. Mejorar manejo de timeouts

**Archivo:** `lib/services/upload_service.dart`

```dart
// Agregar retry automático con backoff exponencial
Future<void> processUpload(int uploadId) async {
  int attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      // ... código de upload ...
      return; // Éxito
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        attempts++;
        if (attempts < maxAttempts) {
          final waitTime = Duration(seconds: 5 * attempts); // 5s, 10s, 15s
          _logger.w('⏱️  Timeout, retry $attempts/$maxAttempts en ${waitTime.inSeconds}s');
          await Future.delayed(waitTime);
          continue;
        }
      }
      rethrow;
    }
  }
}
```

### Resultado Esperado:
- ✅ Uploads completan exitosamente
- ✅ Círculo vicioso roto temporalmente
- ⚠️  Sincronización sigue siendo lenta (180s por documento)

**Tiempo de implementación:** 30 minutos
**Compilación + testing:** 30 minutos
**TOTAL:** 1 hora

---

## 🟢 NIVEL 2: FIX CORTO PLAZO (Fire-and-Forget - 4 horas)

**Objetivo:** Upload rápido sin esperar OCR

### Arquitectura Fire-and-Forget:

```
📱 Cliente
    ↓ (Upload file)
🌐 Backend recibe archivo
    ↓ (<1 segundo)
✅ Backend responde: {"task_id": "abc123", "status": "processing"}
    ↓
📱 Cliente MARCA COMO EXITOSO inmediatamente
    ↓
🔄 Backend procesa OCR en background (15-45s)
    ↓
✅ Documento disponible cuando OCR complete
```

### Cambios:

#### 1. Modificar cliente para aceptar task_id

**Archivo:** `lib/data/repositories/document_repository.dart`

```dart
Future<Map<String, dynamic>> uploadDocumentForPerson({
  required String filePath,
  required String fileName,
  required entities.Person person,
  required String documentType,
  String? documentNumber,
  String? digitizedBy,
  bool isReplacement = false,
}) async {
  try {
    _logger.i('📤 Uploading document (fire-and-forget mode)');

    final docTypeLabel = _getDocumentTypeLabel(documentType);

    // Upload to backend
    final response = await _apiClient.uploadDocumentWithPerson(
      personId: person.personId,
      documentType: docTypeLabel,
      filePath: filePath,
      fileName: fileName,
      isReplacement: isReplacement,
      documentNumber: documentNumber ?? person.documentNumber,
      digitizedBy: digitizedBy,
    );

    // ✅ NEW: Check if response has task_id (async processing)
    if (response.containsKey('task_id')) {
      _logger.i('✅ Upload accepted, processing in background');
      _logger.i('   Task ID: ${response['task_id']}');

      // Store task_id for later status checking (FASE 3)
      // For now, just consider it successful
      return {
        'success': true,
        'task_id': response['task_id'],
        'status': 'processing',
        'message': 'Documento enviado, procesando en segundo plano',
      };
    }

    // Traditional sync response (backwards compatible)
    _logger.i('✅ Document uploaded (sync mode)');
    return response;

  } catch (e, stackTrace) {
    _logger.e('❌ Upload failed: $e');
    rethrow;
  }
}
```

#### 2. Actualizar UI para mostrar estado "Procesando"

**Archivo:** `lib/presentation/digitizer/digitizer_dashboard_screen.dart`

```dart
// Mostrar badge "Procesando OCR" para uploads recientes
ListTile(
  title: Text(assignment.personName),
  subtitle: Text(
    assignment.isProcessing
      ? '🔄 Procesando OCR en segundo plano...'
      : 'Documentos: ${assignment.digitizedCount}',
  ),
  trailing: assignment.isProcessing
    ? CircularProgressIndicator()
    : Text('${assignment.digitizedCount}'),
)
```

### Ventajas:
- ✅ Upload completa en <5 segundos
- ✅ Usuario puede continuar digitalizando sin esperar
- ✅ UX mucho mejor (no bloquea la app)
- ✅ Compatible con backend actual

### Desventajas:
- ⚠️  Usuario no ve resultado OCR inmediatamente
- ⚠️  Necesita refrescar para ver documento completado

**Tiempo de implementación:** 3 horas
**Testing:** 1 hora
**TOTAL:** 4 horas

---

## 🔵 NIVEL 3: SOLUCIÓN DEFINITIVA (Async + Polling - 2 días)

**Objetivo:** Arquitectura completamente asíncrona con feedback en tiempo real

### Arquitectura Completa:

```
📱 Cliente upload (2 segundos)
    ↓
🌐 Backend: task_id devuelto
    ↓
📱 Cliente: Guarda task_id en DB local
    ↓
🔄 Background Service: Polling cada 10s
    ↓
📊 GET /api/task_status/{task_id}
    ↓
✅ {"status": "completed", "document_id": 123, "ocr_confidence": 0.95}
    ↓
📱 Cliente: Actualiza UI automáticamente
    ↓
🎉 Usuario ve documento procesado sin refrescar
```

### Componentes Nuevos:

#### 1. Backend: Endpoint de status

**Crear:** `tejido-ngx/src/documents/views.py`

```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from celery.result import AsyncResult

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def task_status(request, task_id):
    """
    Check status of Celery task

    Returns:
        {
            "status": "pending" | "processing" | "completed" | "failed",
            "progress": 0-100,
            "document_id": int (if completed),
            "ocr_confidence": float (if completed),
            "error": str (if failed)
        }
    """
    result = AsyncResult(task_id)

    if result.ready():
        if result.successful():
            return Response({
                "status": "completed",
                "document_id": result.result.get('document_id'),
                "ocr_confidence": result.result.get('ocr_confidence'),
                "progress": 100
            })
        else:
            return Response({
                "status": "failed",
                "error": str(result.info),
                "progress": 0
            })
    else:
        # Task still processing
        meta = result.info or {}
        return Response({
            "status": "processing",
            "progress": meta.get('progress', 50),
            "current_step": meta.get('current_step', 'OCR processing')
        })
```

#### 2. Cliente: Background Polling Service

**Crear:** `lib/services/task_polling_service.dart`

```dart
import 'dart:async';
import 'package:logger/logger.dart';
import '../data/datasources/tejido_api_client.dart';
import '../data/local/database/app_database.dart';

/// Background service que monitorea tasks de Celery
class TaskPollingService {
  final TejidoApiClient _apiClient;
  final AppDatabase _database;
  final Logger _logger = Logger();

  Timer? _pollingTimer;
  bool _isPolling = false;

  TaskPollingService(this._apiClient, this._database);

  /// Iniciar polling cada 10 segundos
  void startPolling() {
    if (_isPolling) return;

    _logger.i('🔄 Starting task polling service');
    _isPolling = true;

    _pollingTimer = Timer.periodic(
      Duration(seconds: 10),
      (_) => _pollPendingTasks(),
    );
  }

  /// Detener polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
    _logger.i('🛑 Stopped task polling service');
  }

  /// Verificar status de todas las tareas pendientes
  Future<void> _pollPendingTasks() async {
    try {
      // Obtener todas las tareas con task_id pero sin document_id
      final pendingTasks = await _database.getPendingTaskUploads();

      if (pendingTasks.isEmpty) return;

      _logger.d('🔍 Polling ${pendingTasks.length} pending tasks');

      for (final upload in pendingTasks) {
        await _checkTaskStatus(upload);
      }
    } catch (e) {
      _logger.e('❌ Polling error: $e');
    }
  }

  /// Verificar status de una tarea específica
  Future<void> _checkTaskStatus(PendingUpload upload) async {
    try {
      final response = await _apiClient.getTaskStatus(upload.taskId!);
      final status = response['status'] as String;

      switch (status) {
        case 'completed':
          _logger.i('✅ Task ${upload.taskId} completed');
          await _database.markUploadCompleted(
            upload.id,
            documentId: response['document_id'],
            ocrConfidence: response['ocr_confidence'],
          );
          break;

        case 'failed':
          _logger.e('❌ Task ${upload.taskId} failed: ${response['error']}');
          await _database.markUploadFailed(
            upload.id,
            error: response['error'],
          );
          break;

        case 'processing':
          _logger.d('🔄 Task ${upload.taskId} still processing (${response['progress']}%)');
          await _database.updateUploadProgress(
            upload.id,
            progress: response['progress'],
          );
          break;
      }
    } catch (e) {
      _logger.w('⚠️  Failed to check task ${upload.taskId}: $e');
    }
  }
}
```

#### 3. Integrar Polling en App Lifecycle

**Archivo:** `lib/main.dart`

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late TaskPollingService _taskPollingService;

  @override
  void initState() {
    super.initState();

    // Inicializar polling service
    _taskPollingService = TaskPollingService(
      TejidoApiClient(),
      AppDatabase(),
    );

    // Iniciar polling
    _taskPollingService.startPolling();

    // Observer de lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _taskPollingService.stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausar polling cuando app en background
    if (state == AppLifecycleState.paused) {
      _taskPollingService.stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      _taskPollingService.startPolling();
    }
  }
}
```

### Ventajas:
- ✅ Upload instantáneo (<3 segundos)
- ✅ Feedback en tiempo real del progreso OCR
- ✅ Usuario puede cerrar app y OCR continúa
- ✅ Notificaciones cuando OCR completa
- ✅ Arquitectura escalable (múltiples documentos simultáneos)
- ✅ Robusto ante fallos de red

### Desventajas:
- ⚠️  Requiere cambios en backend
- ⚠️  Más complejo de implementar y mantener
- ⚠️  Consume batería por polling (mitigable con WorkManager)

**Tiempo de implementación:**
- Backend: 4 horas
- Cliente: 8 horas
- Testing: 4 horas
- **TOTAL:** 2 días (16 horas)

---

## 📊 COMPARACIÓN DE SOLUCIONES

| Aspecto | NIVEL 1 (Workaround) | NIVEL 2 (Fire-and-Forget) | NIVEL 3 (Async) |
|---------|---------------------|----------------------------|-----------------|
| **Tiempo de implementación** | 1 hora | 4 horas | 2 días |
| **Tiempo de upload** | 90-180s | <5s | <3s |
| **UX Rating** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Robustez** | ⚠️  Baja | ✅ Media | ✅ Alta |
| **Escalabilidad** | ❌ No | ⚠️  Media | ✅ Alta |
| **Cambios backend** | ❌ No | ❌ No | ✅ Sí |
| **Feedback en tiempo real** | ❌ No | ❌ No | ✅ Sí |
| **Rompe círculo vicioso** | ⚠️  Temporalmente | ✅ Sí | ✅ Definitivamente |

---

## 🎯 RECOMENDACIÓN DEL EQUIPO

### Estrategia Incremental:

#### **HOY (1 hora):**
- ✅ Implementar NIVEL 1 (workaround)
- ✅ Compilar v6.0.9 con timeout 180s
- ✅ Probar en dispositivo real
- ✅ Romper círculo vicioso AHORA

#### **Esta Semana (4 horas):**
- ✅ Implementar NIVEL 2 (fire-and-forget)
- ✅ Compilar v6.1.0 con upload rápido
- ✅ UX mejorada dramáticamente

#### **Próxima Semana (2 días):**
- ✅ Implementar NIVEL 3 (arquitectura definitiva)
- ✅ Versión v7.0.0 - Arquitectura async completa
- ✅ Solución escalable y robusta

---

## 📝 CHECKLIST DE IMPLEMENTACIÓN

### NIVEL 1 (HOY - Urgente):
- [ ] Modificar `api_constants.dart`: timeout → 180s
- [ ] Agregar retry con backoff en `upload_service.dart`
- [ ] Compilar APK v6.0.9
- [ ] Testing en dispositivo real (3 documentos)
- [ ] Verificar logs backend (uploads deben llegar)
- [ ] Distribuir APK si funciona

### NIVEL 2 (Esta Semana):
- [ ] Modificar `document_repository.dart`: detectar task_id
- [ ] Modificar UI: mostrar estado "Procesando"
- [ ] Agregar badge visual para uploads en progreso
- [ ] Testing: upload 10 documentos consecutivos
- [ ] Verificar UX: usuario puede continuar digitalizando

### NIVEL 3 (Próxima Semana):
- [ ] Backend: crear endpoint `/api/task_status/{task_id}/`
- [ ] Backend: agregar progress updates en Celery tasks
- [ ] Cliente: crear `TaskPollingService`
- [ ] Cliente: integrar polling en app lifecycle
- [ ] Cliente: agregar notificaciones locales
- [ ] Testing E2E: upload → polling → completion
- [ ] Benchmarking: 100 documentos paralelos

---

## 🚨 RIESGOS Y MITIGACIONES

### Riesgo 1: NIVEL 1 no resuelve problema
**Probabilidad:** Baja (10%)
**Mitigación:** Si timeout 180s no funciona, el problema es de red/conectividad, no de arquitectura

### Riesgo 2: Polling consume demasiada batería
**Probabilidad:** Media (30%)
**Mitigación:** Usar WorkManager para polling adaptativo (más frecuente cuando app activa, menos en background)

### Riesgo 3: Usuario no entiende "Procesando en background"
**Probabilidad:** Alta (60%)
**Mitigación:**
- Tutorial al primer uso
- Notificaciones cuando OCR complete
- Badge visual claro en UI

---

## ✅ CRITERIOS DE ÉXITO

### NIVEL 1 (Workaround):
- ✅ Upload de 1 documento completa sin timeout
- ✅ Backend logs muestran uploads recibidos
- ✅ Usuario puede digitalizar 10 documentos consecutivos

### NIVEL 2 (Fire-and-Forget):
- ✅ Upload completa en <5 segundos
- ✅ Usuario puede upload 10 documentos en 1 minuto
- ✅ UI muestra estado "Procesando" claramente

### NIVEL 3 (Async):
- ✅ Upload completa en <3 segundos
- ✅ Progreso OCR visible en tiempo real
- ✅ Notificación cuando documento procesado
- ✅ Robusto ante pérdida temporal de conexión

---

## 📞 CONTACTO DEL EQUIPO

**Desarrolladores Responsables:**
- Arquitecto Backend: Django + Celery
- Ingeniero Frontend: Flutter + Dart
- DevOps: Infraestructura y Monitoreo

**Próxima Revisión:** 2025-11-11 (después de NIVEL 1)

---

**Versión del Documento:** 1.0
**Última Actualización:** 2025-11-10 21:15
**Estado:** ✅ LISTO PARA IMPLEMENTACIÓN NIVEL 1
