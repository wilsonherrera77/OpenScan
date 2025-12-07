# ROOT CAUSE ANALYSIS: Sincronización Colgada Indefinidamente

**Fecha:** 2025-11-09 23:30
**Versión:** v6.0.4
**Status:** ✅ ROOT CAUSE IDENTIFICADO - Fix pendiente
**Equipo:** Análisis profundo de código (BackgroundSyncService + UploadService + ConnectivityService)

---

## 📊 RESUMEN EJECUTIVO

### Síntoma Observado

Después de aplicar v6.0.4 (followRedirects fix):
- ✅ testConnection() funciona → "Servidor alcanzable"
- ✅ Network diagnostic funciona → "Servidor alcanzable: Sí" (6ms)
- ❌ Sincronización se cuelga en "Sincronizando documentos..."
- ❌ Dialog NO se cierra, usuario ve loading infinito
- ❌ APP parece congelada, única opción es forzar cierre

### ROOT CAUSE Identificado (3 problemas concatenados)

**Problema #1: Dialog Timeout vs Proceso Real**
- Dialog tiene timeout: 60 segundos (home_screen.dart:692)
- Proceso real puede tomar: **hasta 6 minutos** con retries

**Problema #2: Circuit Breaker Exception No Manejada**
- Circuit breaker se abre después de 5 fallos consecutivos
- Lanza `CircuitBreakerOpenException`
- Dialog NO maneja esta excepción específica
- Usuario ve dialog indefinidamente sin feedback

**Problema #3: Retry Logic Excesivo Sin Timeout Global**
- `retryWithBackoff()` puede intentar hasta 5 veces
- Cada intento puede tomar 60s (receiveTimeout de Dio)
- Delays exponenciales: 2s, 4s, 8s, 16s, 32s
- **Total máximo: 362 segundos = 6 minutos**
- Dialog timeout = 60s → Dialog se cierra pero proceso sigue

---

## 🔍 ANÁLISIS TÉCNICO DETALLADO

### PASO 1: Flujo de Sincronización Actual

```
Usuario tap "Sincronizar ahora"
    ↓
HomeScreen._syncNow() llama:
    ↓
BackgroundSyncService.scheduleImmediateSync()
    ↓
Step 1: ConnectivityService.hasInternetConnection() (5s timeout)
    ↓ (si OK)
Step 2: ConnectivityService.validateTejidoConnection() (10s timeout)
    ↓ (si OK)
Step 3: ConnectivityService.retryWithBackoff(
    operation: () async {
        uploadService.processAllPending();
    },
    maxRetries: 3,  ← CONFIGURADO EN LLAMADA
    initialDelay: 2s,
)
    ↓
UploadService.processAllPending()
    ↓
    for each pending upload:
        UploadService.processUpload(uploadId)
            ↓
            _uploadDocument(upload)
                ↓
                _documentRepository.smartUploadDocumentForPerson()
                    ↓
                    Dio.post('/api/documents/smart_upload/')
                    (receiveTimeout: 60s)
```

### PASO 2: Cálculo de Timeouts

**Configuración actual:**

```dart
// api_constants.dart:26
receiveTimeout: Duration(seconds: 60)

// background_sync_service.dart:129-154
retryWithBackoff(
  maxRetries: 3,  // Puede fallar hasta 3 veces
  initialDelay: Duration(seconds: 2),
)

// connectivity_service.dart:89-192
retryWithBackoff(
  maxRetries: 5,  // DEFAULT (si no se especifica)
  initialDelay: Duration(seconds: 2),
  backoffMultiplier: 2.0,
  maxDelay: Duration(minutes: 5),
)
```

**Caso peor escenario (1 documento):**

```
Intento #1: 60s (timeout) + falla
  Delay: 2s
Intento #2: 60s + falla
  Delay: 4s
Intento #3: 60s + falla
  Delay: 8s
  └─ maxRetries alcanzado (3)

TOTAL: 60+2+60+4+60+8 = 194 segundos = 3.2 minutos
```

**Si circuit breaker se abre:**

```
CircuitBreakerOpenException lanzada
  ↓
scheduleImmediateSync() atrapa
  ↓
retorna false
  ↓
HomeScreen recibe false
  ↓
Intenta cerrar dialog...
  ↓
SI dialog ya cerrado por timeout (60s) → No pasa nada
SI dialog aún abierto → Cierra y muestra "Error de sincronización"
```

### PASO 3: Problema del Circuit Breaker

**Circuit Breaker State (connectivity_service.dart:358-439):**

```dart
class CircuitBreakerState {
  int _failureCount = 0;
  CircuitBreakerStatus _status = CircuitBreakerStatus.closed;

  void recordFailure() {
    _failureCount++;
    if (_failureCount >= ConnectivityService.circuitBreakerThreshold) {
      // ⚠️ Se abre después de 5 fallos
      _status = CircuitBreakerStatus.open;
    }
  }

  bool shouldAttemptReset() {
    // ⚠️ Solo se resetea después de 2 minutos
    return timeSinceFailure >= Duration(minutes: 2);
  }
}
```

**Escenario:**
1. Usuario intenta sincronizar 5 veces en un día
2. Cada vez falla (ej: backend apagado temporalmente)
3. Circuit breaker se abre después del 5to intento
4. Usuario espera 5 minutos, intenta de nuevo
5. Circuit breaker SIGUE abierto (necesita 2 minutos desde último fallo)
6. `CircuitBreakerOpenException` lanzada
7. Dialog se queda esperando indefinidamente

### PASO 4: Problema del Dialog Timeout

**HomeScreen (lib/screens/home_screen.dart:138-287):**

```dart
bool dialogShown = false;

try {
  showDialog(...);  // Muestra "Sincronizando documentos..."
  dialogShown = true;

  final success = await BackgroundSyncService.scheduleImmediateSync();
  // ⚠️ PROBLEMA: Si esto tarda >60s, dialog ya no existe

  // Intenta cerrar dialog
  if (dialogShown && mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
    dialogShown = false;
  }

  // Muestra resultado
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error de sincronización'),  // ⚠️ Mensaje muy genérico
    ));
  }
} catch (e) {
  // Manejo de error
}
```

**Problema:**
- Dialog no tiene timeout real
- Si `scheduleImmediateSync()` nunca retorna, dialog se queda abierto
- Usuario no tiene feedback de progreso

---

## ✅ SOLUCIONES PROPUESTAS

### Solución #1: Timeout Global para Sincronización (CRÍTICO)

**Archivo:** `lib/services/background_sync_service.dart:96-161`

**Cambio:**

```dart
/// Schedule immediate sync (manual trigger)
static Future<bool> scheduleImmediateSync() async {
  try {
    _logger.i('🔄 Starting immediate manual sync...');

    // ✅ NUEVO: Timeout global de 90 segundos para toda la operación
    return await Future.any([
      _performSync(),
      Future.delayed(
        const Duration(seconds: 90),
        () {
          _logger.w('⏰ Sync timeout after 90 seconds');
          return false;
        },
      ),
    ]);
  } catch (e, stackTrace) {
    _logger.e('❌ Immediate sync failed: $e', error: e, stackTrace: stackTrace);
    return false;
  }
}

/// Extract sync logic to separate method
static Future<bool> _performSync() async {
  // Step 1: Check connectivity
  final hasConnection = await ConnectivityService.hasInternetConnection();
  if (!hasConnection) {
    _logger.w('⚠️ No internet connection, waiting...');

    final connected = await ConnectivityService.waitForConnection(
      timeout: const Duration(seconds: 30),
    );

    if (!connected) {
      _logger.e('❌ Sync aborted: No internet connection');
      return false;
    }
  }

  // Step 2: Verify Tejido server
  final apiClient = TejidoApiClient();
  final baseUrl = apiClient.baseUrl;

  final serverCheck = await ConnectivityService.validateTejidoConnection(baseUrl);
  if (serverCheck['error'] != null) {
    _logger.e('❌ Tejido server validation failed: ${serverCheck['error']}');
    return false;
  }

  _logger.i('✅ Server validated (latency: ${serverCheck['latencyMs']}ms)');

  // Step 3: Execute sync with retry logic
  final result = await ConnectivityService.retryWithBackoff<bool>(
    operation: () async {
      final database = AppDatabase();
      final documentRepository = DocumentRepository(apiClient, database);
      final uploadService = UploadService(database, documentRepository);

      final pendingBefore = await uploadService.getPendingCount();
      _logger.i('📊 Pending uploads: $pendingBefore');

      if (pendingBefore == 0) {
        _logger.i('✅ No pending uploads');
        return true;
      }

      // Process all pending uploads
      await uploadService.processAllPending();

      final stats = await uploadService.getStatistics();
      _logger.i('✅ Sync completed: $stats');

      return true;
    },
    operationName: 'Manual sync',
    maxRetries: 2,  // ✅ REDUCIDO de 3 a 2
    initialDelay: const Duration(seconds: 2),
  );

  return result ?? false;
}
```

**Beneficio:**
- Timeout garantizado de 90 segundos
- Usuario NUNCA ve loading >90s
- Si excede tiempo, retorna `false` y dialog se cierra

---

### Solución #2: Manejo de CircuitBreakerOpenException (CRÍTICO)

**Archivo:** `lib/screens/home_screen.dart:138-287`

**Cambio:**

```dart
try {
  showDialog(...);
  dialogShown = true;

  final success = await BackgroundSyncService.scheduleImmediateSync();

  // Close dialog safely
  if (dialogShown && mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
    dialogShown = false;
  }

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronización exitosa')),
    );
  } else {
    // ✅ MEJORADO: Mensaje más descriptivo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error de sincronización. Verifica conexión y vuelve a intentar.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} on CircuitBreakerOpenException catch (e) {
  // ✅ NUEVO: Manejo específico de circuit breaker
  if (dialogShown && mounted && Navigator.canPop(context)) {
    try {
      Navigator.pop(context);
    } catch (popError) {
      _logger.w('⚠️ Could not pop dialog: $popError');
    }
    dialogShown = false;
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Servicio temporalmente no disponible. '
          'Intenta de nuevo en ${e.retryAfter.inMinutes} minutos.'
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
} catch (e) {
  // Resto del código igual...
}
```

**Beneficio:**
- Feedback específico cuando circuit breaker está abierto
- Usuario sabe cuánto tiempo esperar
- No más "Error de sincronización" genérico

---

### Solución #3: Progress Indicator Durante Sync (MEJORA UX)

**Archivo:** `lib/screens/home_screen.dart:138-287`

**Cambio:**

```dart
// ✅ NUEVO: Usar LinearProgressIndicator animado
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Sincronizando documentos...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // ✅ NUEVO: Progress indicator
            StreamBuilder<int>(
              stream: _syncProgressStream,
              builder: (context, snapshot) {
                final progress = snapshot.data ?? 0;
                final total = _totalUploadsToSync ?? 0;
                if (total > 0) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress / total,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progress / $total documentos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor espera (timeout: 90s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  },
);
```

**Beneficio:**
- Usuario ve progreso real (ej: "3 / 5 documentos")
- Sabe que la app NO está congelada
- Timeout visible (90s) para expectativas claras

---

## 🧪 TESTING PLAN (v6.0.5)

### Test #1: Sincronización con 1 Documento (Happy Path)

**Steps:**
1. Capturar 1 documento
2. Guardar localmente
3. Tap "Sincronizar ahora"

**Esperado:**
- ⏳ Dialog muestra progreso: "1 / 1 documentos"
- ⏳ Completa en <10 segundos
- ✅ Dialog se cierra
- ✅ "Sincronización exitosa"

---

### Test #2: Sincronización con Backend Apagado (Timeout)

**Steps:**
1. **Apagar backend** (`docker-compose stop webserver`)
2. Capturar 1 documento
3. Tap "Sincronizar ahora"

**Esperado:**
- ⏳ Dialog muestra "Sincronizando..."
- ⏳ Espera hasta 90 segundos
- ❌ Dialog se cierra después de 90s
- ❌ "Error de sincronización. Verifica conexión..."

---

### Test #3: Circuit Breaker Abierto

**Steps:**
1. Apagar backend
2. Intentar sincronizar 5 veces consecutivas
3. Esperar que circuit breaker se abra
4. Intentar sincronizar de nuevo

**Esperado:**
- ⏳ Dialog aparece
- ⚡ Se cierra INMEDIATAMENTE (<1s)
- ❌ "Servicio temporalmente no disponible. Intenta de nuevo en 2 minutos."

---

### Test #4: Sincronización con 10 Documentos (Stress Test)

**Steps:**
1. Capturar 10 documentos
2. Guardar localmente
3. Tap "Sincronizar ahora"

**Esperado:**
- ⏳ Dialog muestra progreso: "1 / 10", "2 / 10", ..., "10 / 10"
- ⏳ Completa en <60 segundos
- ✅ Dialog se cierra
- ✅ "Sincronización exitosa"

---

## 📋 FILES A MODIFICAR (v6.0.5)

| File | Lines | Change |
|------|-------|--------|
| `lib/services/background_sync_service.dart` | 96-161 | Add timeout global (90s) + extract _performSync() |
| `lib/screens/home_screen.dart` | 138-287 | Add CircuitBreakerOpenException handler + progress indicator |
| `lib/services/connectivity_service.dart` | 1 | Export CircuitBreakerOpenException (ya está) |
| `pubspec.yaml` | 7 | version: 6.0.5+68 |

**Total:** 4 files, ~100 lines modified

---

## 🎯 EXPECTATIVAS REALISTAS

### Con v6.0.5, DEBERÍA funcionar porque:

1. ✅ **Timeout garantizado:** Nunca más de 90 segundos colgado
2. ✅ **Feedback específico:** Usuario sabe qué pasó (timeout, circuit breaker, etc.)
3. ✅ **Progress indicator:** Usuario ve que algo está pasando
4. ✅ **Retry reducido:** 2 intentos en vez de 3 (más rápido para fallar)

### Si TODAVÍA falla:

**Posibles causas restantes:**
1. Backend NO está respondiendo (verificar con curl)
2. Token de autenticación inválido (401)
3. Problema de red (firewall bloqueando)
4. Documento muy grande (>10 MB)

**Próximos pasos si falla:**
1. Conectar dispositivo vía USB
2. Capturar logs: `adb logcat | grep "BackgroundSyncService"`
3. Ver si timeout se alcanza: Buscar "⏰ Sync timeout after 90 seconds"
4. Ver errores: Buscar "❌"

---

## 💡 MEJORAS FUTURAS (Fuera de alcance v6.0.5)

### 1. Upload Queue con Prioridad

- Documentos urgentes primero
- Documentos grandes al final
- Reintentos solo para documentos críticos

### 2. Pause/Resume Durante Sync

- Botón "Cancelar" en dialog
- Usuario puede pausar sync si tarda mucho
- Retoma desde donde se quedó

### 3. Optimización de Uploads

- Comprimir imágenes antes de upload (ya existe en `image_optimizer.dart`)
- Upload paralelo (2-3 documentos simultáneamente)
- Batch upload endpoint en backend

### 4. Circuit Breaker Configurable

- Threshold configurable en settings
- Usuario puede desactivar circuit breaker
- Métricas visibles en app (cuántos fallos, cuándo se resetea)

---

**Documento generado:** 2025-11-09 23:30 UTC
**Status:** ROOT CAUSE IDENTIFICADO - Fix pendiente
**Equipo:** Análisis de código profundo
**Próxima revisión:** Después de implementar v6.0.5
