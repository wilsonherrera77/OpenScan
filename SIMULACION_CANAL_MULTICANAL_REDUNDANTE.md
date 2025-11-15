# 🔄 SIMULACIÓN: Canal Multicanal/Redundante Lumara → Tejido

**Fecha:** 2025-11-10
**Equipo:** Arquitecto, Backend, Frontend, DevOps, Creativo Disruptivo
**Objetivo:** Evaluar estrategia de canal redundante para upload de documentos

---

## 📊 ARQUITECTURA ACTUAL (v6.2.0) - Single Channel

```
┌─────────────────────────────────────────────────────────────────┐
│                         LUMARA (Mobile)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Usuario captura documento                                  │
│  2. Optimización de imagen (1280px, 80% JPEG)                  │
│  3. Almacenamiento local (SQLite + Drift)                      │
│  4. Upload Service intenta enviar                              │
│     │                                                           │
│     ├─ Validación de red (ConnectivityService)                │
│     ├─ Validación de servidor (ping /api/)                    │
│     └─ POST /api/documents/upload_with_person/                │
│                                                                 │
│         ┌──────────── Si FALLA ────────────┐                   │
│         │                                  │                   │
│         │  - Marca como "pending"          │                   │
│         │  - Espera 1 minuto (auto-sync)  │                   │
│         │  - Reintenta                     │                   │
│         │  - Si falla 3 veces → alerta    │                   │
│         │                                  │                   │
│         └──────────────────────────────────┘                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ HTTP POST
                                │ (Single Channel)
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        TEJIDO (Backend)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Recibe HTTP POST                                            │
│  2. Valida autenticación (Token)                                │
│  3. Valida persona existe en censo                              │
│  4. Guarda archivo en disco                                     │
│  5. Procesa OCR (15-45 segundos)                                │
│  6. Crea documento en Paperless                                 │
│  7. Crea DocumentPersonRelation                                 │
│  8. Retorna HTTP 201 + metadata                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### ❌ PROBLEMAS DEL CANAL SIMPLE:

1. **Single Point of Failure:**
   - Si servidor cae → TODOS los uploads fallan
   - Si red WiFi falla → Queue local crece sin límite
   - Si timeout ocurre → Usuario no sabe si subió o no

2. **No hay confirmación redundante:**
   - Upload dice "success" pero ¿realmente llegó?
   - No hay verificación de integridad del archivo
   - No hay validación post-upload

3. **Visibilidad limitada:**
   - Usuario solo ve "Subiendo..." o "Error"
   - No sabe cuántos documentos quedan en queue
   - No sabe si servidor está procesando

---

## 🚀 PROPUESTA 1: Canal Dual HTTP (Primary + Fallback)

### Arquitecto de Software opina:

```
┌─────────────────────────────────────────────────────────────────┐
│                         LUMARA (Mobile)                         │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ├────────────────┬────────────────┐
                    │                │                │
                    ▼                ▼                ▼
            PRIMARY CHANNEL   FALLBACK CHANNEL  VERIFICATION
                    │                │                │
     POST /upload_with_person/  POST /post_document/ GET /check_exists/
                    │                │                │
                    ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  TEJIDO (Backend - Same Server)                 │
└─────────────────────────────────────────────────────────────────┘

FLUJO:
1. Intenta PRIMARY channel (con metadata completa)
   └─ Si SUCCESS → Valida con VERIFICATION
   └─ Si FALLA → Intenta FALLBACK channel (sin metadata)
      └─ Si SUCCESS → Asocia metadata después con PATCH
      └─ Si FALLA → Queue local para retry

VENTAJA:
✅ Redundancia en endpoints
✅ Metadata completa si primario funciona
✅ Fallback garantiza upload aunque sea sin metadata

DESVENTAJA:
❌ Mismo servidor (si servidor cae, todo falla igual)
❌ Complejidad adicional en app
❌ Más requests = más latencia
```

**Código simulado:**

```dart
Future<Map<String, dynamic>> uploadWithRedundancy(File file, Metadata meta) async {
  _logger.i('🔄 REDUNDANT UPLOAD: Trying PRIMARY channel');

  try {
    // CANAL PRIMARIO: Endpoint custom con metadata
    final response = await _dio.post(
      '/api/documents/upload_with_person/',
      data: FormData.fromMap({
        'document': await MultipartFile.fromFile(file.path),
        'person_id': meta.personId,
        'document_type': meta.documentType,
        'nuip': meta.nuip,
      }),
    );

    if (response.statusCode == 201) {
      _logger.i('✅ PRIMARY channel SUCCESS');

      // VERIFICACIÓN: Confirma que documento existe en servidor
      final verification = await _dio.get(
        '/api/documents/${response.data['document_id']}/',
      );

      if (verification.statusCode == 200) {
        _logger.i('✅ VERIFICATION SUCCESS - Document confirmed on server');
        return {'success': true, 'channel': 'primary', ...response.data};
      }
    }
  } catch (e) {
    _logger.w('⚠️  PRIMARY channel FAILED: $e');
    _logger.i('🔄 Trying FALLBACK channel...');

    try {
      // CANAL FALLBACK: Endpoint estándar sin metadata
      final fallbackResponse = await _dio.post(
        '/api/documents/post_document/',
        data: FormData.fromMap({
          'document': await MultipartFile.fromFile(file.path),
        }),
      );

      if (fallbackResponse.statusCode == 200) {
        _logger.i('✅ FALLBACK channel SUCCESS');

        // Asociar metadata después con PATCH
        final docId = fallbackResponse.data; // task_id o doc_id
        await _associateMetadataLater(docId, meta);

        return {'success': true, 'channel': 'fallback', 'task_id': docId};
      }
    } catch (e2) {
      _logger.e('❌ FALLBACK channel FAILED: $e2');
      _logger.e('💾 Saving to local queue for later retry');

      await _saveToLocalQueue(file, meta);
      return {'success': false, 'channel': 'none', 'queued': true};
    }
  }

  return {'success': false};
}
```

---

## 🌐 PROPUESTA 2: Canal Multiservidor (Primary + Secondary Server)

### DevOps Engineer opina:

```
┌─────────────────────────────────────────────────────────────────┐
│                         LUMARA (Mobile)                         │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ├────────────────┬────────────────┐
                    │                │                │
                    ▼                ▼                ▼
         PRIMARY SERVER      SECONDARY SERVER    LOCAL QUEUE
       192.168.40.17:8001    192.168.40.17:8002   SQLite DB
              (Prod)              (Backup)          (Offline)
                    │                │                │
                    ▼                ▼                ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────┐
│  TEJIDO Primary     │  │  TEJIDO Secondary   │  │  Local  │
│  - Procesamiento    │  │  - Solo recepción   │  │  Retry  │
│  - OCR inmediato    │  │  - OCR diferido     │  │  Queue  │
└─────────────────────┘  └─────────────────────┘  └─────────┘

FLUJO:
1. Intenta PRIMARY server
   └─ Si SUCCESS → Done
   └─ Si TIMEOUT → Intenta SECONDARY server en paralelo
      └─ Si SUCCESS → Primary procesará después
      └─ Si FALLA → LOCAL QUEUE

VENTAJA:
✅ Alta disponibilidad (99.9%)
✅ Servidor secundario recibe aunque primario caiga
✅ Sincronización entre servidores después

DESVENTAJA:
❌ Requiere 2 servidores Paperless
❌ Sincronización compleja
❌ Conflictos si ambos procesan mismo documento
```

**Configuración requerida:**

```yaml
# docker-compose.yml - Servidor secundario
services:
  webserver_secondary:
    image: paperless-ngx-custom:latest
    ports:
      - "8002:8000"  # Puerto diferente
    environment:
      - PAPERLESS_URL=http://192.168.40.17:8002
      - PAPERLESS_OCR_MODE=skip_noarchive  # OCR diferido
    volumes:
      - backup_data:/usr/src/paperless/data
      - backup_media:/usr/src/paperless/media
```

---

## ⚡ PROPUESTA 3: Upload Paralelo + Race Condition (MÁS RÁPIDO GANA)

### Creativo Disruptivo propone:

```
┌─────────────────────────────────────────────────────────────────┐
│                         LUMARA (Mobile)                         │
│                                                                 │
│  Future.race([                                                  │
│    uploadToPrimary(),      // Endpoint custom                  │
│    uploadToFallback(),     // Endpoint estándar                │
│    uploadToLocalQueue(),   // SQLite (siempre exitoso)         │
│  ])                                                             │
│                                                                 │
│  → El primero en completarse gana                              │
│  → Cancela otros requests                                      │
│  → Usuario ve upload instantáneo                               │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ├────────────────┬────────────────┬──────────────┐
                    │ (Paralelo)     │ (Paralelo)     │ (Paralelo)   │
                    ▼                ▼                ▼              ▼
            ENDPOINT 1        ENDPOINT 2        LOCAL QUEUE    WEBSOCKET
         /upload_with_person  /post_document    SQLite         (Real-time)

FLUJO:
1. Lanza 3 uploads en paralelo
2. El primero en responder (HTTP 201 o local save) gana
3. Cancela requests restantes
4. WebSocket notifica a servidor: "Upload X completado por channel Y"
5. Servidor deduplica si recibe mismo documento por 2 canales

VENTAJA:
✅ Latencia mínima (usa el canal más rápido)
✅ Redundancia total (3 canales)
✅ Usuario ve resultado instantáneo

DESVENTAJA:
❌ Puede subir 2-3 veces el mismo documento
❌ Requiere deduplicación en servidor
❌ Mayor uso de ancho de banda
```

**Código simulado:**

```dart
Future<Map<String, dynamic>> uploadParallel(File file, Metadata meta) async {
  _logger.i('⚡ PARALLEL UPLOAD: Racing 3 channels');

  final futures = <Future<Map<String, dynamic>>>[
    // CANAL 1: Endpoint custom (con metadata)
    _uploadToCustomEndpoint(file, meta).then((result) {
      return {...result, 'channel': 'custom', 'priority': 1};
    }),

    // CANAL 2: Endpoint estándar (sin metadata)
    _uploadToStandardEndpoint(file).then((result) {
      return {...result, 'channel': 'standard', 'priority': 2};
    }),

    // CANAL 3: Queue local (siempre exitoso, procesará después)
    _saveToLocalQueue(file, meta).then((_) {
      return {'success': true, 'channel': 'local_queue', 'priority': 3};
    }),
  ];

  // Race: El primero en completarse gana
  final winner = await Future.any(futures);

  _logger.i('🏆 WINNER: ${winner['channel']} (priority: ${winner['priority']})');

  // Cancelar requests restantes (si es posible con Dio)
  // await _cancelOtherRequests();

  return winner;
}
```

---

## 📡 PROPUESTA 4: WebSocket Bidireccional + HTTP Fallback (RECOMENDADO)

### Backend Engineer + Frontend Engineer recomiendan:

```
┌─────────────────────────────────────────────────────────────────┐
│                         LUMARA (Mobile)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CANAL PRIMARIO: WebSocket (Bidireccional)                     │
│  ├─ Conexión persistente                                       │
│  ├─ Upload en chunks (streaming)                               │
│  ├─ Confirmación en tiempo real                                │
│  └─ Notificación de progreso OCR                               │
│                                                                 │
│  CANAL FALLBACK: HTTP POST (Tradicional)                       │
│  └─ Si WebSocket desconectado → HTTP POST                     │
│                                                                 │
│  CANAL TERCIARIO: Local Queue                                  │
│  └─ Si ambos fallan → SQLite                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ├─────────────── WebSocket ──────────────────┐
                    │                                            │
                    │                                            ▼
                    │                              ┌──────────────────────┐
                    │                              │  WebSocket Server    │
                    │                              │  (Django Channels)   │
                    │                              └──────────────────────┘
                    │                                            │
                    │                                            │
                    ▼                                            ▼
            HTTP POST (Fallback)                    Real-time Processing
                    │                                            │
                    └──────────────── ambos ─────────────────────┤
                                                                 │
                                                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                        TEJIDO (Backend)                         │
│                                                                 │
│  1. Recibe por WebSocket o HTTP                                │
│  2. Valida + Guarda                                             │
│  3. Procesa OCR                                                 │
│  4. Notifica progreso vía WebSocket:                           │
│     - "OCR started..."     (5%)                                │
│     - "Processing page 1"  (50%)                               │
│     - "OCR completed"      (100%)                              │
│  5. Envía confirmación final                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### FLUJO DETALLADO:

```dart
class RedundantUploadService {
  late WebSocketChannel _wsChannel;
  bool _wsConnected = false;

  Future<void> initialize() async {
    // Conectar WebSocket al iniciar app
    try {
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.40.17:8001/ws/uploads/'),
      );

      _wsChannel.stream.listen((message) {
        _handleWebSocketMessage(message);
      });

      _wsConnected = true;
      _logger.i('✅ WebSocket connected');
    } catch (e) {
      _logger.w('⚠️  WebSocket connection failed, will use HTTP fallback');
      _wsConnected = false;
    }
  }

  Future<Map<String, dynamic>> uploadDocument(File file, Metadata meta) async {
    // ESTRATEGIA 1: Intentar WebSocket primero
    if (_wsConnected) {
      try {
        return await _uploadViaWebSocket(file, meta);
      } catch (e) {
        _logger.w('⚠️  WebSocket upload failed: $e');
        _logger.i('🔄 Falling back to HTTP...');
      }
    }

    // ESTRATEGIA 2: Fallback a HTTP POST
    try {
      return await _uploadViaHTTP(file, meta);
    } catch (e) {
      _logger.e('❌ HTTP upload failed: $e');
      _logger.i('💾 Saving to local queue...');
    }

    // ESTRATEGIA 3: Local queue (siempre exitoso)
    await _saveToLocalQueue(file, meta);
    return {'success': true, 'channel': 'local_queue', 'queued': true};
  }

  Future<Map<String, dynamic>> _uploadViaWebSocket(File file, Metadata meta) async {
    _logger.i('📡 WEBSOCKET UPLOAD: Streaming document...');

    // 1. Enviar metadata primero
    _wsChannel.sink.add(jsonEncode({
      'type': 'upload_start',
      'person_id': meta.personId,
      'document_type': meta.documentType,
      'nuip': meta.nuip,
      'file_size': file.lengthSync(),
    }));

    // 2. Enviar archivo en chunks (streaming)
    final bytes = await file.readAsBytes();
    const chunkSize = 64 * 1024; // 64 KB chunks

    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      final chunk = bytes.sublist(i, end);

      _wsChannel.sink.add(chunk);

      // Progreso
      final progress = (end / bytes.length * 100).toStringAsFixed(0);
      _logger.i('   Upload progress: $progress%');
    }

    // 3. Señal de fin de upload
    _wsChannel.sink.add(jsonEncode({'type': 'upload_complete'}));

    // 4. Esperar confirmación del servidor
    final confirmation = await _wsChannel.stream
        .firstWhere((msg) => jsonDecode(msg)['type'] == 'upload_confirmed');

    final data = jsonDecode(confirmation);
    _logger.i('✅ WEBSOCKET UPLOAD SUCCESS: document_id=${data['document_id']}');

    return {
      'success': true,
      'channel': 'websocket',
      'document_id': data['document_id'],
      'relation_id': data['relation_id'],
    };
  }

  Future<Map<String, dynamic>> _uploadViaHTTP(File file, Metadata meta) async {
    _logger.i('📡 HTTP UPLOAD: Standard POST request...');

    final response = await _dio.post(
      '/api/documents/upload_with_person/',
      data: FormData.fromMap({
        'document': await MultipartFile.fromFile(file.path),
        'person_id': meta.personId,
        'document_type': meta.documentType,
        'nuip': meta.nuip,
      }),
    );

    if (response.statusCode == 201) {
      _logger.i('✅ HTTP UPLOAD SUCCESS');
      return {'success': true, 'channel': 'http', ...response.data};
    }

    throw Exception('HTTP upload failed: ${response.statusCode}');
  }

  void _handleWebSocketMessage(String message) {
    final data = jsonDecode(message);

    switch (data['type']) {
      case 'ocr_progress':
        _logger.i('📊 OCR Progress: ${data['progress']}% - ${data['status']}');
        // Actualizar UI con progreso
        break;

      case 'ocr_completed':
        _logger.i('✅ OCR Completed for document ${data['document_id']}');
        break;

      case 'error':
        _logger.e('❌ Server error: ${data['message']}');
        break;
    }
  }
}
```

---

## 📊 COMPARACIÓN DE ESTRATEGIAS

| Estrategia | Confiabilidad | Latencia | Complejidad | Costo Infraestructura | RECOMENDACIÓN |
|------------|---------------|----------|-------------|----------------------|---------------|
| **Actual (Single HTTP)** | ⭐⭐ 80% | ⭐⭐⭐⭐ Buena | ⭐ Baja | ⭐ Bajo | ❌ Mejorable |
| **Dual HTTP** | ⭐⭐⭐ 90% | ⭐⭐⭐ Media | ⭐⭐ Media | ⭐ Bajo | ⚠️ Parcial |
| **Multiservidor** | ⭐⭐⭐⭐ 99% | ⭐⭐⭐ Media | ⭐⭐⭐⭐ Alta | ⭐⭐⭐ Alto | ⚠️ Overkill |
| **Upload Paralelo** | ⭐⭐⭐ 95% | ⭐⭐⭐⭐⭐ Excelente | ⭐⭐⭐ Alta | ⭐⭐ Medio | ⚠️ Desperdicio |
| **WebSocket + HTTP Fallback** | ⭐⭐⭐⭐ 98% | ⭐⭐⭐⭐⭐ Excelente | ⭐⭐⭐ Alta | ⭐⭐ Medio | ✅ **MEJOR** |

---

## 🏆 RECOMENDACIÓN DEL EQUIPO: WebSocket + HTTP Fallback

### ¿Por qué WebSocket + HTTP?

**Arquitecto de Software:**
> "WebSocket ofrece conexión persistente bidireccional, ideal para notificaciones en tiempo real del progreso de OCR. HTTP como fallback garantiza compatibilidad total."

**Backend Engineer:**
> "Django Channels soporta WebSocket nativamente. Podemos usar el mismo autenticación (Token) y enviar progreso de OCR al cliente sin polling."

**Frontend Engineer:**
> "Flutter tiene excelente soporte para WebSocket con `web_socket_channel` package. Podemos mostrar progreso en tiempo real al usuario."

**DevOps:**
> "WebSocket usa misma infraestructura. Solo necesitamos agregar Django Channels y Redis (que ya tenemos). Sin costo adicional."

**Creativo Disruptivo:**
> "Con WebSocket podemos innovar: notificaciones push, chat de soporte, sincronización en tiempo real entre dispositivos. Es invertir en futuro."

---

## 🎯 PLAN DE IMPLEMENTACIÓN (FASE 1: Mínima)

### OPCIÓN RECOMENDADA: **Dual HTTP (Conservador)**

Si el equipo NO quiere complejidad de WebSocket, implementar **Dual HTTP**:

```dart
Future<Map<String, dynamic>> uploadWithFallback(File file, Metadata meta) async {
  // CANAL 1: Endpoint custom (primario)
  try {
    final response = await _dio.post(
      '/api/documents/upload_with_person/',
      data: _buildFormData(file, meta),
    );

    if (response.statusCode == 201) {
      _logger.i('✅ PRIMARY channel SUCCESS');
      return {'success': true, 'channel': 'primary', ...response.data};
    }
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      _logger.w('⚠️  PRIMARY timeout, trying FALLBACK...');

      // CANAL 2: Endpoint estándar (fallback)
      try {
        final fallbackResponse = await _dio.post(
          '/api/documents/post_document/',
          data: FormData.fromMap({
            'document': await MultipartFile.fromFile(file.path),
          }),
        );

        if (fallbackResponse.statusCode == 200) {
          _logger.i('✅ FALLBACK channel SUCCESS');

          // Asociar metadata después (PATCH)
          await _patchMetadata(fallbackResponse.data, meta);

          return {'success': true, 'channel': 'fallback'};
        }
      } catch (e2) {
        _logger.e('❌ FALLBACK failed: $e2');
      }
    }
  }

  // CANAL 3: Local queue
  await _saveToLocalQueue(file, meta);
  return {'success': true, 'channel': 'local_queue', 'queued': true};
}
```

**Ventajas:**
- ✅ Fácil de implementar (1-2 horas)
- ✅ No requiere cambios en backend
- ✅ Redundancia inmediata
- ✅ Compatible con v6.2.0

**Tiempo estimado:** 2-3 horas
**Riesgo:** Bajo
**Impacto:** Alto (mejora confiabilidad 80% → 95%)

---

## 📋 SIMULACIÓN DE ESCENARIOS

### Escenario 1: Red Inestable (WiFi débil)

**Sin Redundancia (Actual):**
```
Usuario captura → Intenta upload → Timeout (90s) → FALLA
                                                    └─ Queue local
                                                    └─ Reintenta en 1 min
                                                    └─ Usuario frustrado ❌
```

**Con Dual HTTP:**
```
Usuario captura → PRIMARY (timeout 30s) → FALLBACK (timeout 30s) → Queue local
                  └─ Falla                └─ SUCCESS ✅
                                                    └─ Metadata agregada después
                                                    └─ Usuario ve éxito inmediato
```

### Escenario 2: Servidor Sobrecargado (10 usuarios simultáneos)

**Sin Redundancia:**
```
10 usuarios → PRIMARY endpoint → Queue de Celery crece → Algunos timeouts ❌
```

**Con WebSocket:**
```
10 usuarios → WebSocket streaming → Chunks procesados progresivamente → 0 timeouts ✅
           └─ Notificación en tiempo real: "Procesando... 50%"
```

### Escenario 3: Servidor Caído (Mantenimiento)

**Sin Redundancia:**
```
Usuario captura → PRIMARY (error connection) → Queue local → Espera 1 min ❌
```

**Con Multiservidor:**
```
Usuario captura → PRIMARY (error) → SECONDARY (success) ✅ → Sincroniza después
```

---

## 💡 CONCLUSIÓN DEL EQUIPO

### ESTRATEGIA RECOMENDADA (Iterativa):

**FASE 1 (Corto plazo - 1 semana):**
✅ Implementar **Dual HTTP** (Primary + Fallback)
- Endpoint custom primario
- Endpoint estándar fallback
- Local queue terciario
- **Esfuerzo:** 3 horas
- **Riesgo:** Bajo
- **Mejora:** 80% → 95% confiabilidad

**FASE 2 (Mediano plazo - 1 mes):**
✅ Agregar **WebSocket + HTTP Fallback**
- Django Channels en backend
- WebSocket client en Flutter
- Notificaciones en tiempo real
- **Esfuerzo:** 2 días
- **Riesgo:** Medio
- **Mejora:** UX significativa + progreso OCR visible

**FASE 3 (Largo plazo - 3 meses):**
✅ Considerar **Multiservidor** si:
- Usuarios crecen >50 concurrentes
- Alta disponibilidad crítica (99.9%)
- Presupuesto permite infraestructura adicional

---

## 🎯 RESPUESTA DIRECTA A TU PREGUNTA

**¿Serviría una estrategia multicanal/redundante?**

**SÍ, ABSOLUTAMENTE.** El equipo recomienda:

1. **Implementar YA:** Dual HTTP (mínimo)
2. **Planificar:** WebSocket para UX mejorada
3. **Evaluar después:** Multiservidor si escala lo requiere

**La redundancia es ESENCIAL para un sistema de digitalización masiva donde perder documentos es inaceptable.**

---

**Preparado por:** Equipo completo Lumara
**Consenso:** Unánime a favor de canal redundante
**Prioridad:** Alta
**Estado:** Listo para implementación
