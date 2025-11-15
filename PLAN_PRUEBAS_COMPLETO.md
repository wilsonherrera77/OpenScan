# 🧪 PLAN DE PRUEBAS COMPLETO - Lumara Scan

**Fecha de Creación**: 27 de octubre de 2025
**Alcance**: Validación de FASE 1, FASE 2, y FASE 3
**Objetivo**: Asegurar que las optimizaciones funcionan correctamente en condiciones reales
**Responsable**: Equipo de Ingeniería Senior

---

## 📋 Índice

1. [Objetivos del Plan](#objetivos-del-plan)
2. [Matriz de Pruebas](#matriz-de-pruebas)
3. [Entornos de Prueba](#entornos-de-prueba)
4. [Categorías de Pruebas](#categorías-de-pruebas)
5. [Test Cases Detallados](#test-cases-detallados)
6. [Herramientas y Scripts](#herramientas-y-scripts)
7. [Criterios de Aceptación](#criterios-de-aceptación)
8. [Procedimiento de Ejecución](#procedimiento-de-ejecución)
9. [Reporte de Resultados](#reporte-de-resultados)
10. [Checklist de Validación](#checklist-de-validación)

---

## 🎯 Objetivos del Plan

### Objetivos Primarios

1. **Validar Funcionalidad**: Todas las features funcionan después de optimizaciones
2. **Confirmar Performance**: Las mejoras medidas son reales (no solo teóricas)
3. **Probar Resiliencia**: Sistema robusto ante fallos de red y servidor
4. **Verificar Compatibilidad**: Funciona en diferentes dispositivos y condiciones
5. **Asegurar UX**: Experiencia de usuario mejorada perceptiblemente

### Objetivos Secundarios

- Identificar regresiones potenciales
- Documentar edge cases no considerados
- Generar métricas para dashboard de monitoreo
- Validar backward compatibility con datos existentes
- Preparar para deploy a producción

---

## 📊 Matriz de Pruebas

| Fase | Optimización | Pruebas Críticas | Pruebas Opcionales | Prioridad |
|------|-------------|------------------|-------------------|-----------|
| **FASE 1** | Conectividad corregida | ✅ Conexión al servidor<br>✅ Upload básico | 🔵 Config dinámica<br>🔵 Múltiples servidores | 🔴 Alta |
| **FASE 1** | Timeouts optimizados | ✅ Timeout efectivo<br>✅ Respuesta rápida | 🔵 Timeout con retry | 🟡 Media |
| **FASE 2** | WAL Mode SQLite | ✅ Escrituras concurrentes<br>✅ Sin bloqueos | 🔵 Checkpoint automático | 🟡 Media |
| **FASE 2** | Cache de metadatos | ✅ Cache hit/miss<br>✅ TTL expiration<br>✅ Offline fallback | 🔵 Cache invalidation manual | 🔴 Alta |
| **FASE 2** | Optimización imágenes | ✅ Compresión 60-80%<br>✅ Calidad visual | 🔵 Batch optimization | 🔴 Alta |
| **FASE 2** | Logging por entorno | ✅ Debug vs Release<br>✅ No PII leaks | 🔵 Performance impact | 🟢 Baja |
| **FASE 3** | Retry con jitter | ✅ Backoff exponencial<br>✅ Jitter distribution | 🔵 Stress test 100 clients | 🟡 Media |
| **FASE 3** | Circuit breaker | ✅ Open tras 5 fallos<br>✅ Half-open recovery | 🔵 Metrics accuracy | 🟡 Media |
| **FASE 3** | Índices SQLite | ✅ Query performance<br>✅ Mejora 10-100x | 🔵 Index overhead | 🔴 Alta |
| **FASE 3** | Compresión gzip | ✅ Compression >1KB<br>✅ Decompression auto | 🔵 Compression errors | 🟡 Media |

**Leyenda**:
- 🔴 Alta: Crítico para producción
- 🟡 Media: Importante pero no bloqueante
- 🟢 Baja: Nice to have
- ✅ Pruebas críticas
- 🔵 Pruebas opcionales

---

## 🌍 Entornos de Prueba

### 1. Dispositivos

| Categoría | Dispositivo | Android | RAM | Storage | Prioridad |
|-----------|------------|---------|-----|---------|-----------|
| **Gama Alta** | Samsung Galaxy S23 | 13 | 8GB | 256GB | 🟢 Baja |
| **Gama Media** | Xiaomi Redmi Note 12 | 12 | 4GB | 128GB | 🔴 Alta |
| **Gama Baja** | Samsung Galaxy A04 | 11 | 3GB | 64GB | 🔴 Alta |
| **Tablet** | Samsung Tab A8 | 12 | 4GB | 64GB | 🟡 Media |

**Justificación**:
- Gama media/baja son dispositivos típicos en zonas rurales
- RAM limitada prueba eficiencia de cache y optimizaciones
- Storage limitado valida compresión de imágenes

### 2. Condiciones de Red

| Tipo | Velocidad | Latencia | Packet Loss | Simulación |
|------|-----------|----------|-------------|------------|
| **WiFi** | 10-50 MB/s | 10-30ms | 0% | Red local |
| **4G Bueno** | 5-20 MB/s | 30-50ms | 0-1% | Throttling ADB |
| **4G Malo** | 1-5 MB/s | 50-150ms | 1-3% | Throttling ADB |
| **3G** | 500 KB/s | 100-200ms | 3-5% | Throttling ADB |
| **Edge/2G** | 50-100 KB/s | 300-500ms | 5-10% | Throttling ADB |
| **Offline** | 0 | ∞ | 100% | Modo avión |
| **Intermitente** | Variable | Variable | 10-30% | Script toggle WiFi |

### 3. Condiciones de Servidor

| Escenario | Estado | Simulación |
|-----------|--------|------------|
| **Normal** | Responde 200 en <100ms | Servidor real |
| **Lento** | Responde 200 en 1-5s | Delay en nginx |
| **Sobrecargado** | Responde 503 | Script sobrecarga |
| **Caído** | No responde | Detener container |
| **Intermitente** | 50% success, 50% timeout | Script aleatorio |
| **Rate Limited** | Responde 429 tras 10 requests | Config en Paperless |

### 4. Volúmenes de Datos

| Dataset | Descripción | Tamaño | Uso |
|---------|-------------|--------|-----|
| **Pequeño** | 50 personas, 10 documentos | 5MB | Pruebas rápidas |
| **Medio** | 500 personas, 100 documentos | 50MB | Producción típica |
| **Grande** | 5000 personas, 1000 documentos | 500MB | Stress test |
| **Masivo** | 50000 personas, 10000 documentos | 5GB | Límite extremo |

---

## 🧩 Categorías de Pruebas

### 1. Pruebas Funcionales (¿Funciona?)

**Objetivo**: Validar que todas las features funcionan correctamente.

**Cobertura**:
- ✅ Login y autenticación
- ✅ Carga de censo de personas
- ✅ Búsqueda y selección de persona
- ✅ Captura de foto con cámara
- ✅ Carga de metadatos (tags, tipos, campos)
- ✅ Upload de documento
- ✅ Visualización de documentos pendientes
- ✅ Sincronización en background
- ✅ Manejo de errores

### 2. Pruebas de Performance (¿Qué tan rápido?)

**Objetivo**: Medir mejoras cuantificables en velocidad.

**Métricas Clave**:
- ⏱️ Tiempo de carga de metadatos
- ⏱️ Tiempo de búsqueda de persona
- ⏱️ Tiempo de compresión de imagen
- ⏱️ Tiempo de upload completo
- ⏱️ Tiempo de queries SQL frecuentes
- 📊 Throughput de uploads (docs/min)

### 3. Pruebas de Resiliencia (¿Qué tan robusto?)

**Objetivo**: Validar comportamiento en condiciones adversas.

**Escenarios**:
- 🔌 Red intermitente (conecta/desconecta)
- 📶 Red lenta (3G, Edge)
- 🚫 Sin conexión (modo avión)
- ⚠️ Servidor caído
- 🐌 Servidor lento (latencia alta)
- 🚨 Errores de API (4xx, 5xx)
- 🔄 Interrupciones durante upload

### 4. Pruebas de Regresión (¿Rompió algo?)

**Objetivo**: Asegurar que optimizaciones no rompieron funcionalidad existente.

**Áreas Críticas**:
- 🔍 Búsqueda de personas con caracteres especiales
- 📸 Captura de foto con diferentes resoluciones
- 📤 Upload de diferentes tipos de archivos (JPG, PNG, PDF)
- 💾 Persistencia de datos offline
- 🔄 Sincronización tras reconexión
- 🗑️ Eliminación de pendientes

### 5. Pruebas de Compatibilidad (¿Funciona en todos lados?)

**Objetivo**: Validar en diferentes dispositivos y versiones Android.

**Cobertura**:
- 📱 Android 11, 12, 13, 14
- 💾 Dispositivos con poco storage (<1GB libre)
- 🧠 Dispositivos con poca RAM (<2GB)
- 🔋 Dispositivos con batería baja (<20%)
- 🌐 Diferentes idiomas/locales

### 6. Pruebas de Carga (¿Escala?)

**Objetivo**: Validar comportamiento con datasets grandes.

**Escenarios**:
- 👥 5000+ personas en censo
- 📄 1000+ documentos pendientes
- 🗂️ 100+ tags y tipos de documento
- 📊 10000+ registros en upload history
- 💾 DB de 500MB+

---

## 🔬 Test Cases Detallados

### FASE 1: Conectividad

#### TC-F1-01: Conexión al Servidor Correcto
**Prioridad**: 🔴 Alta
**Objetivo**: Validar que la app se conecta al servidor correcto (172.20.10.3)

**Precondiciones**:
- App instalada en dispositivo
- Servidor Paperless corriendo en 172.20.10.3:8001
- Dispositivo en misma red

**Pasos**:
1. Lanzar app
2. Navegar a pantalla de login
3. Observar logs con: `adb logcat | grep "🌐"`

**Resultado Esperado**:
```
🌐 POST http://172.20.10.3:8001/api/token/
✅ 200 http://172.20.10.3:8001/api/token/
```

**Criterio de Éxito**: ✅ Conexión a 172.20.10.3 exitosa en <100ms

---

#### TC-F1-02: Timeout Efectivo (10s connect, 15s receive)
**Prioridad**: 🟡 Media
**Objetivo**: Validar que los timeouts se respetan

**Precondiciones**:
- Servidor configurado con delay de 12 segundos en /api/persons/

**Pasos**:
1. Login exitoso
2. Navegar a pantalla de selección de personas
3. Medir tiempo hasta timeout

**Resultado Esperado**:
```
⏱️  Request timeout after 15000ms
❌ Error: ReceiveTimeout
```

**Criterio de Éxito**: ✅ Timeout ocurre en ~15 segundos (no 30+)

---

#### TC-F1-03: Configuración Dinámica de Servidor
**Prioridad**: 🔵 Opcional
**Objetivo**: Validar que se puede cambiar URL del servidor sin recompilar

**Pasos**:
1. Login con servidor A (172.20.10.3)
2. Ir a Settings → Server Configuration
3. Cambiar a servidor B (192.168.1.100)
4. Test Connection
5. Intentar operación (fetch persons)

**Criterio de Éxito**: ✅ Operación usa nuevo servidor sin reiniciar app

---

### FASE 2: Performance

#### TC-F2-01: Cache Hit de Metadatos
**Prioridad**: 🔴 Alta
**Objetivo**: Validar que metadatos se cargan desde cache en <50ms

**Precondiciones**:
- Cache poblado (al menos 1 load previo)
- Cache no expirado (<1 hora desde última carga)

**Pasos**:
1. Navegar a pantalla de upload
2. Medir tiempo de carga de tags
3. Verificar en logs: `adb logcat | grep "✅ Using cached"`

**Resultado Esperado**:
```
✅ Using cached tags (7 items)
⏱️  Load time: 8ms
```

**Criterio de Éxito**: ✅ Carga en <50ms desde cache local

---

#### TC-F2-02: Cache Miss - Fetch de API
**Prioridad**: 🔴 Alta
**Objetivo**: Validar que cache se actualiza cuando expira

**Precondiciones**:
- Cache expirado (>1 hora) o vacío

**Pasos**:
1. Navegar a pantalla de upload
2. Observar logs: `adb logcat | grep "🔄 Fetching fresh"`
3. Medir tiempo de carga

**Resultado Esperado**:
```
🔄 Fetching fresh tags from API...
💾 Cached 7 tags
⏱️  Load time: 342ms
```

**Criterio de Éxito**: ✅ Cache se actualiza y persiste para próxima carga

---

#### TC-F2-03: Cache Stale Fallback (Offline)
**Prioridad**: 🔴 Alta
**Objetivo**: Validar que se usan datos stale cuando API falla

**Precondiciones**:
- Cache poblado pero expirado
- Sin conexión a internet

**Pasos**:
1. Activar modo avión
2. Navegar a pantalla de upload
3. Verificar que carga datos (aunque expirados)

**Resultado Esperado**:
```
⚠️ API call failed, using stale cache: SocketException
✅ Returning 7 cached tags (stale)
```

**Criterio de Éxito**: ✅ App funciona offline con datos stale

---

#### TC-F2-04: Optimización de Imagen (Grande)
**Prioridad**: 🔴 Alta
**Objetivo**: Validar compresión 60-80% en imágenes grandes

**Precondiciones**:
- Imagen de prueba: 4032×3024, 4.2MB

**Pasos**:
1. Tomar foto con cámara (máxima resolución)
2. Procesar upload
3. Verificar logs de optimización

**Resultado Esperado**:
```
🖼️  Optimizing image: IMG_20251027_143522.jpg
   Original size: 4.2 MB
   Original dimensions: 4032x3024
   ✂️  Image too large, resizing...
   New dimensions: 1920x1440
✅ Image optimized successfully
   Original: 4.2 MB
   Optimized: 890.3 KB
   Savings: 78.8%
   Time: 234ms
```

**Criterio de Éxito**:
- ✅ Compresión 60-80%
- ✅ Tiempo <500ms
- ✅ Calidad visual aceptable (inspección manual)

---

#### TC-F2-05: No Optimización de Imagen Pequeña
**Prioridad**: 🟡 Media
**Objetivo**: Validar que imágenes pequeñas no se procesan innecesariamente

**Precondiciones**:
- Imagen de prueba: 800×600, 500KB

**Pasos**:
1. Upload de imagen pequeña
2. Verificar logs

**Resultado Esperado**:
```
ℹ️  Image already optimized or small enough
```

**Criterio de Éxito**: ✅ No se procesa, upload directo

---

#### TC-F2-06: WAL Mode - Escrituras Concurrentes
**Prioridad**: 🟡 Media
**Objetivo**: Validar que múltiples escrituras no se bloquean

**Pasos**:
1. Ejecutar script de escrituras concurrentes:
```bash
# Script: concurrent_writes_test.sh
for i in {1..100}; do
  adb shell "am broadcast -a com.lumara.TEST_WRITE --ei doc_id $i" &
done
wait
```

2. Medir tasa de escrituras (inserts/segundo)
3. Verificar errores de "database is locked"

**Resultado Esperado**:
```
✅ 100 writes completed in 2.3 seconds
📊 Throughput: 43 inserts/second
❌ Errors: 0
```

**Criterio de Éxito**:
- ✅ >30 inserts/segundo
- ✅ 0 errores de bloqueo

---

#### TC-F2-07: Logging - Debug vs Release
**Prioridad**: 🟢 Baja
**Objetivo**: Validar que logging se reduce en release

**Pasos**:
1. Build debug: `flutter build apk --debug`
2. Contar logs en 1 minuto de uso: `adb logcat | wc -l`
3. Build release: `flutter build apk --release`
4. Contar logs en 1 minuto de uso

**Resultado Esperado**:
- Debug: ~500-1000 logs/minuto
- Release: ~10-50 logs/minuto (solo warnings/errors)

**Criterio de Éxito**: ✅ Reducción >90% en logs de release

---

### FASE 3: Resiliencia

#### TC-F3-01: Retry con Backoff Exponencial
**Prioridad**: 🟡 Media
**Objetivo**: Validar delays: 2s, 4s, 8s, 16s, 32s

**Precondiciones**:
- Servidor configurado para fallar 5 veces seguidas

**Pasos**:
1. Intentar upload de documento
2. Observar logs de retry con timestamps

**Resultado Esperado**:
```
🔄 Attempt 1/5 for: Upload document
⚠️ Attempt 1 failed (Network error), retrying in 2s
🔄 Attempt 2/5 for: Upload document
⚠️ Attempt 2 failed (Network error), retrying in 4s
🔄 Attempt 3/5 for: Upload document
⚠️ Attempt 3 failed (Network error), retrying in 8s
...
```

**Criterio de Éxito**: ✅ Delays siguen secuencia exponencial 2^n

---

#### TC-F3-02: Jitter Distribution (Anti Thundering Herd)
**Prioridad**: 🟡 Media
**Objetivo**: Validar que jitter distribuye retries en ±25%

**Pasos**:
1. Simular 20 clientes fallando simultáneamente
2. Registrar tiempo de cada retry
3. Analizar distribución estadística

**Script**:
```bash
# Script: test_jitter.sh
for i in {1..20}; do
  (adb shell "am broadcast -a com.lumara.TEST_RETRY" 2>&1 | grep "retrying in" | awk '{print $NF}') &
done | tee jitter_results.txt

# Análisis
awk '{sum+=$1; count++} END {print "Mean:", sum/count, "Stddev:", ...}' jitter_results.txt
```

**Criterio de Éxito**:
- ✅ Media ~2000ms
- ✅ Desviación estándar ~250ms (±12.5%)
- ✅ No más de 2 requests en mismo milisegundo

---

#### TC-F3-03: Circuit Breaker - Open tras 5 Fallos
**Prioridad**: 🟡 Media
**Objetivo**: Validar que circuit breaker se abre tras 5 fallos

**Pasos**:
1. Detener servidor Paperless
2. Intentar 5 uploads consecutivos
3. Intentar 6to upload
4. Verificar exception: `CircuitBreakerOpenException`

**Resultado Esperado**:
```
❌ Attempt 1 failed
❌ Attempt 2 failed
❌ Attempt 3 failed
❌ Attempt 4 failed
❌ Attempt 5 failed
⚠️ Circuit breaker OPEN for Upload document (5 consecutive failures)
🚫 6th attempt blocked: CircuitBreakerOpenException
```

**Criterio de Éxito**: ✅ Sexto intento bloqueado inmediatamente

---

#### TC-F3-04: Circuit Breaker - Half-Open Recovery
**Prioridad**: 🔵 Opcional
**Objetivo**: Validar que circuit breaker prueba recovery tras timeout

**Pasos**:
1. Abrir circuit breaker (5 fallos)
2. Esperar 2 minutos (timeout)
3. Reiniciar servidor
4. Intentar operación
5. Verificar que intenta y tiene éxito

**Resultado Esperado**:
```
⚠️ Circuit breaker OPEN for Upload document
⏱️  Waiting 2 minutes...
🔄 Circuit breaker HALF-OPEN for Upload document (testing service)
✅ Upload document succeeded on attempt 1
✅ Circuit breaker CLOSED for Upload document (service recovered)
```

**Criterio de Éxito**: ✅ Circuit breaker se cierra tras success

---

#### TC-F3-05: Clasificación de Errores - 404 No Retry
**Prioridad**: 🟡 Media
**Objetivo**: Validar que errores 4xx no se reintentan

**Pasos**:
1. Configurar endpoint para retornar 404
2. Intentar operación
3. Medir tiempo hasta abort

**Resultado Esperado**:
```
🔄 Attempt 1/5 for: Fetch person details
❌ Error 404: Person not found
⚠️ Non-retryable error (Client error (4xx)), aborting
⏱️  Total time: 87ms
```

**Criterio de Éxito**: ✅ Aborta en <100ms sin reintentos

---

#### TC-F3-06: Índices SQLite - Query Performance
**Prioridad**: 🔴 Alta
**Objetivo**: Validar mejora 10-100x en queries frecuentes

**Precondiciones**:
- Base de datos con 1000+ registros

**Pasos**:
1. Ejecutar query: `SELECT * FROM pending_uploads WHERE status='pending' ORDER BY created_at`
2. Medir tiempo con EXPLAIN QUERY PLAN
3. Verificar uso de índice

**Script**:
```bash
adb shell "run-as com.lumara.app sqlite3 /data/data/com.lumara.app/databases/openscan_indigenas.db 'EXPLAIN QUERY PLAN SELECT * FROM pending_uploads WHERE status=\"pending\" ORDER BY created_at;'"
```

**Resultado Esperado**:
```
SEARCH pending_uploads USING INDEX idx_pending_uploads_status_created (status=?)
⏱️  Query time: 3ms (vs ~180ms without index)
```

**Criterio de Éxito**:
- ✅ Usa índice (no SCAN TABLE)
- ✅ Query time <10ms

---

#### TC-F3-07: Compresión HTTP - Request >1KB
**Prioridad**: 🟡 Media
**Objetivo**: Validar que requests grandes se comprimen automáticamente

**Precondiciones**:
- Payload de prueba >1KB (ej: documento con 50 custom fields)

**Pasos**:
1. Upload documento con metadata pesada
2. Interceptar request con proxy o logs
3. Verificar header `Content-Encoding: gzip`

**Resultado Esperado**:
```
🗜️  Compressed request: 3.2 KB → 850 B (73.4% reduction)
📤 POST /api/documents/
   Headers: Content-Encoding: gzip
   Size: 850 bytes
```

**Criterio de Éxito**:
- ✅ Compresión >50%
- ✅ Header Content-Encoding presente

---

#### TC-F3-08: Compresión HTTP - Request <1KB (No Compress)
**Prioridad**: 🔵 Opcional
**Objetivo**: Validar que requests pequeños no se comprimen

**Precondiciones**:
- Payload de prueba <1KB

**Pasos**:
1. Upload documento simple (solo título y tipo)
2. Verificar logs

**Resultado Esperado**:
```
📤 POST /api/documents/
   Size: 423 bytes
   (No compression - below threshold)
```

**Criterio de Éxito**: ✅ Sin mensaje de compresión

---

### Pruebas de Integración End-to-End

#### TC-E2E-01: Flujo Completo de Upload (Red Buena)
**Prioridad**: 🔴 Alta
**Objetivo**: Validar flujo completo desde login hasta upload exitoso

**Pasos**:
1. Login con credenciales válidas
2. Cargar lista de personas (500+)
3. Buscar persona por nombre
4. Seleccionar persona
5. Tomar foto con cámara
6. Seleccionar tipo de documento
7. Agregar custom fields
8. Upload documento
9. Verificar éxito

**Criterio de Éxito**:
- ✅ Flujo completo en <30 segundos
- ✅ Sin errores
- ✅ Documento visible en Paperless

---

#### TC-E2E-02: Flujo Completo de Upload (Red Lenta - 3G)
**Prioridad**: 🔴 Alta
**Objetivo**: Validar flujo en condiciones de red rural

**Precondiciones**:
- Simular red 3G: `adb shell tc qdisc add dev wlan0 root netem delay 100ms rate 500kbit`

**Pasos**: (mismos que TC-E2E-01)

**Criterio de Éxito**:
- ✅ Flujo completo en <60 segundos
- ✅ Sin errores
- ✅ Optimizaciones visibles en logs

---

#### TC-E2E-03: Flujo Offline → Online (Sincronización)
**Prioridad**: 🔴 Alta
**Objetivo**: Validar sincronización tras reconexión

**Pasos**:
1. Login (online)
2. Cargar personas (cache poblado)
3. Activar modo avión
4. Seleccionar persona (desde cache)
5. Tomar 3 fotos
6. Completar formularios y "upload" (guardan en queue local)
7. Desactivar modo avión
8. Esperar sincronización automática

**Criterio de Éxito**:
- ✅ 3 documentos se suben automáticamente
- ✅ Notificación de sincronización exitosa
- ✅ Queue local vacío

---

#### TC-E2E-04: Flujo con Interrupciones (Resiliencia)
**Prioridad**: 🟡 Media
**Objetivo**: Validar recuperación tras interrupciones

**Pasos**:
1. Iniciar upload de 5 documentos
2. Durante uploads, simular interrupciones:
   - Toggle WiFi on/off cada 10s
   - Detener/reiniciar servidor
   - Poner app en background
3. Verificar que todos se suben eventualmente

**Criterio de Éxito**:
- ✅ 5/5 documentos subidos exitosamente
- ✅ Retry automático funciona
- ✅ Sin pérdida de datos

---

### Pruebas de Carga y Estrés

#### TC-LOAD-01: 5000 Personas en Censo
**Prioridad**: 🟡 Media
**Objetivo**: Validar performance con dataset grande

**Precondiciones**:
- Servidor con 5000 personas en censo

**Pasos**:
1. Login
2. Cargar lista de personas
3. Medir tiempo de carga
4. Buscar persona específica
5. Medir memoria usada

**Criterio de Éxito**:
- ✅ Carga inicial <5 segundos
- ✅ Búsqueda <100ms
- ✅ Memoria <200MB

---

#### TC-LOAD-02: 1000 Documentos Pendientes
**Prioridad**: 🟡 Media
**Objetivo**: Validar performance de queue local grande

**Precondiciones**:
- 1000 documentos en pending_uploads (modo offline prolongado)

**Pasos**:
1. Abrir app
2. Navegar a pantalla de pendientes
3. Medir tiempo de carga de lista
4. Scroll en lista (verificar lag)

**Criterio de Éxito**:
- ✅ Carga lista <3 segundos
- ✅ Scroll fluido (>30 FPS)

---

#### TC-LOAD-03: Sincronización Masiva (100 docs)
**Prioridad**: 🔵 Opcional
**Objetivo**: Validar sincronización de muchos documentos

**Pasos**:
1. Acumular 100 documentos en queue offline
2. Reconectar a internet
3. Observar sincronización automática
4. Medir throughput (docs/min)

**Criterio de Éxito**:
- ✅ >10 documentos/minuto
- ✅ Sin crashes
- ✅ Sin memory leaks

---

## 🛠️ Herramientas y Scripts

### 1. Script de Simulación de Red

**Archivo**: `scripts/simulate_network.sh`

```bash
#!/bin/bash
# Simula diferentes condiciones de red con ADB

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
NETWORK_TYPE=${2:-3g}

echo "🌐 Simulando red $NETWORK_TYPE en dispositivo $DEVICE"

case $NETWORK_TYPE in
  "wifi")
    adb -s $DEVICE shell "tc qdisc del dev wlan0 root 2>/dev/null"
    echo "✅ Red WiFi (sin throttling)"
    ;;

  "4g-good")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 30ms rate 10mbit"
    echo "✅ Red 4G buena (10 MB/s, 30ms latency)"
    ;;

  "4g-bad")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 100ms rate 2mbit loss 2%"
    echo "✅ Red 4G mala (2 MB/s, 100ms latency, 2% loss)"
    ;;

  "3g")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 150ms rate 500kbit loss 5%"
    echo "✅ Red 3G (500 KB/s, 150ms latency, 5% loss)"
    ;;

  "edge")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 300ms rate 100kbit loss 10%"
    echo "✅ Red Edge/2G (100 KB/s, 300ms latency, 10% loss)"
    ;;

  "intermittent")
    echo "✅ Red intermitente (toggle cada 10s)"
    for i in {1..5}; do
      adb -s $DEVICE shell "svc wifi disable"
      echo "  📴 WiFi OFF"
      sleep 10
      adb -s $DEVICE shell "svc wifi enable"
      echo "  📶 WiFi ON"
      sleep 10
    done
    ;;

  "offline")
    adb -s $DEVICE shell "svc wifi disable && svc data disable"
    echo "✅ Modo offline (WiFi y datos desactivados)"
    ;;

  "reset")
    adb -s $DEVICE shell "tc qdisc del dev wlan0 root 2>/dev/null"
    adb -s $DEVICE shell "svc wifi enable && svc data enable"
    echo "✅ Red restaurada"
    ;;

  *)
    echo "❌ Tipo de red desconocido: $NETWORK_TYPE"
    echo "Tipos válidos: wifi, 4g-good, 4g-bad, 3g, edge, intermittent, offline, reset"
    exit 1
    ;;
esac
```

**Uso**:
```bash
# Simular 3G
./scripts/simulate_network.sh <device-id> 3g

# Simular red intermitente
./scripts/simulate_network.sh <device-id> intermittent

# Restaurar red normal
./scripts/simulate_network.sh <device-id> reset
```

---

### 2. Script de Benchmark de Performance

**Archivo**: `scripts/benchmark_performance.sh`

```bash
#!/bin/bash
# Ejecuta suite de benchmarks de performance

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
OUTPUT_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).txt"

echo "📊 Ejecutando benchmarks de performance..." | tee $OUTPUT_FILE
echo "Dispositivo: $DEVICE" | tee -a $OUTPUT_FILE
echo "Fecha: $(date)" | tee -a $OUTPUT_FILE
echo "" | tee -a $OUTPUT_FILE

# Función para medir tiempo
measure_operation() {
  local operation=$1
  local command=$2

  echo "⏱️  Midiendo: $operation" | tee -a $OUTPUT_FILE

  local start=$(date +%s%3N)
  eval $command
  local end=$(date +%s%3N)

  local duration=$((end - start))
  echo "   Tiempo: ${duration}ms" | tee -a $OUTPUT_FILE
  echo "" | tee -a $OUTPUT_FILE
}

# Benchmark 1: Carga de metadatos (cache hit)
measure_operation "Carga de metadatos (cache hit)" \
  "adb -s $DEVICE shell 'am broadcast -a com.lumara.BENCHMARK_LOAD_METADATA 2>&1 | grep \"Load time\"'"

# Benchmark 2: Búsqueda de persona
measure_operation "Búsqueda de persona" \
  "adb -s $DEVICE shell 'am broadcast -a com.lumara.BENCHMARK_SEARCH_PERSON --es query \"Maria\" 2>&1 | grep \"Search time\"'"

# Benchmark 3: Query SQL (pending uploads)
measure_operation "Query SQL (pending uploads)" \
  "adb -s $DEVICE shell 'am broadcast -a com.lumara.BENCHMARK_SQL_QUERY 2>&1 | grep \"Query time\"'"

# Benchmark 4: Optimización de imagen
measure_operation "Optimización de imagen (4MB)" \
  "adb -s $DEVICE shell 'am broadcast -a com.lumara.BENCHMARK_IMAGE_OPTIMIZATION 2>&1 | grep \"Optimization time\"'"

# Benchmark 5: Upload completo
measure_operation "Upload completo (con optimizaciones)" \
  "adb -s $DEVICE shell 'am broadcast -a com.lumara.BENCHMARK_FULL_UPLOAD 2>&1 | grep \"Upload time\"'"

echo "✅ Benchmarks completados. Resultados guardados en: $OUTPUT_FILE"
```

---

### 3. Script de Validación de Índices SQLite

**Archivo**: `scripts/validate_indexes.sh`

```bash
#!/bin/bash
# Valida que los índices SQLite existen y se usan

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
DB_PATH="/data/data/com.lumara.app/databases/openscan_indigenas.db"

echo "🔍 Validando índices SQLite..."
echo ""

# Función para ejecutar query SQLite
sqlite_query() {
  local query=$1
  adb -s $DEVICE shell "run-as com.lumara.app sqlite3 $DB_PATH \"$query\""
}

# Verificar existencia de índices
echo "📋 Índices existentes:"
sqlite_query "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%';" | nl

echo ""

# Verificar uso de índices en queries comunes
echo "🔍 Verificando uso de índices en queries comunes:"
echo ""

echo "1. Query: pending uploads by status"
sqlite_query "EXPLAIN QUERY PLAN SELECT * FROM pending_uploads WHERE status='pending' ORDER BY created_at;"
echo ""

echo "2. Query: upload history by person"
sqlite_query "EXPLAIN QUERY PLAN SELECT * FROM upload_history WHERE person_id='P001' ORDER BY uploaded_at DESC;"
echo ""

echo "3. Query: person search by name"
sqlite_query "EXPLAIN QUERY PLAN SELECT * FROM persons WHERE name LIKE '%Maria%';"
echo ""

echo "4. Query: cache expiration check"
sqlite_query "EXPLAIN QUERY PLAN SELECT MIN(cached_at) FROM tags;"
echo ""

echo "✅ Validación completa"
echo "⚠️  Verificar que cada query usa 'SEARCH ... USING INDEX' (no 'SCAN TABLE')"
```

---

### 4. Script de Logs en Tiempo Real

**Archivo**: `scripts/watch_logs.sh`

```bash
#!/bin/bash
# Filtra y muestra logs relevantes en tiempo real

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
FILTER=${2:-all}

echo "📱 Monitoreando logs de Lumara en dispositivo $DEVICE"
echo "Filtro: $FILTER"
echo ""

case $FILTER in
  "performance")
    adb -s $DEVICE logcat | grep -E "⏱️|🚀|⚡|📊"
    ;;

  "network")
    adb -s $DEVICE logcat | grep -E "🌐|📡|🔌|📶|🔄"
    ;;

  "errors")
    adb -s $DEVICE logcat | grep -E "❌|⚠️|ERROR|Exception"
    ;;

  "optimizations")
    adb -s $DEVICE logcat | grep -E "🖼️|🗜️|💾|✅|⚡ FASE"
    ;;

  "cache")
    adb -s $DEVICE logcat | grep -E "cache|Cache|CACHE|💾"
    ;;

  "retry")
    adb -s $DEVICE logcat | grep -E "retry|Retry|🔄|Circuit|circuit"
    ;;

  "all")
    adb -s $DEVICE logcat | grep -E "Lumara|lumara|openscan"
    ;;

  *)
    echo "❌ Filtro desconocido: $FILTER"
    echo "Filtros válidos: performance, network, errors, optimizations, cache, retry, all"
    exit 1
    ;;
esac
```

**Uso**:
```bash
# Ver logs de performance
./scripts/watch_logs.sh <device-id> performance

# Ver logs de red
./scripts/watch_logs.sh <device-id> network

# Ver todos los logs
./scripts/watch_logs.sh <device-id> all
```

---

### 5. Script de Test de Carga (SQLite)

**Archivo**: `scripts/load_test_sqlite.sh`

```bash
#!/bin/bash
# Inserta 10K registros de prueba para load testing

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
COUNT=${2:-10000}
DB_PATH="/data/data/com.lumara.app/databases/openscan_indigenas.db"

echo "📊 Insertando $COUNT registros de prueba en SQLite..."

# Generar SQL de inserción
SQL_FILE="/tmp/load_test_inserts.sql"
echo "BEGIN TRANSACTION;" > $SQL_FILE

for i in $(seq 1 $COUNT); do
  echo "INSERT INTO persons (id, name, census_id, community, synced_at) VALUES ('TEST_$i', 'Persona Test $i', 'CENSUS_$i', 'Community $((i % 10))', datetime('now'));" >> $SQL_FILE
done

echo "COMMIT;" >> $SQL_FILE

# Push SQL file al dispositivo
adb -s $DEVICE push $SQL_FILE /data/local/tmp/load_test.sql

# Ejecutar inserciones
echo "Ejecutando inserciones..."
adb -s $DEVICE shell "run-as com.lumara.app sqlite3 $DB_PATH < /data/local/tmp/load_test.sql"

# Verificar count
FINAL_COUNT=$(adb -s $DEVICE shell "run-as com.lumara.app sqlite3 $DB_PATH 'SELECT COUNT(*) FROM persons;'")
echo "✅ Insertados $FINAL_COUNT registros"

# Limpiar
rm $SQL_FILE
adb -s $DEVICE shell "rm /data/local/tmp/load_test.sql"

echo ""
echo "🔍 Ahora ejecuta benchmarks de búsqueda para medir performance"
```

---

## ✅ Criterios de Aceptación

### Criterios Generales

| Categoría | Métrica | Objetivo | Crítico |
|-----------|---------|----------|---------|
| **Funcionalidad** | Pruebas funcionales pasadas | 100% | ✅ Sí |
| **Performance** | Mejora vs baseline | >3x | ✅ Sí |
| **Resiliencia** | Success rate en red inestable | >90% | ✅ Sí |
| **Regresión** | Features rotas | 0 | ✅ Sí |
| **Compatibilidad** | Dispositivos soportados | >95% | 🟡 No |
| **Carga** | Performance con 5K personas | <5s load | 🟡 No |

### Criterios por Fase

#### FASE 1: Conectividad
- ✅ **Conexión exitosa**: <100ms @ 172.20.10.3
- ✅ **Timeout efectivo**: 10s connect, 15s receive
- 🟡 **Config dinámica**: Cambio sin reinicio

#### FASE 2: Performance
- ✅ **Cache hit**: <50ms carga de metadatos
- ✅ **Cache offline**: Funciona con datos stale
- ✅ **Optimización imagen**: 60-80% reducción, <500ms
- ✅ **WAL mode**: >30 inserts/segundo, 0 bloqueos
- 🟡 **Logging**: >90% reducción en release

#### FASE 3: Resiliencia & Eficiencia
- ✅ **Retry con jitter**: Distribución ±25%
- ✅ **Circuit breaker**: Abre tras 5 fallos
- 🟡 **Clasificación errores**: 4xx aborta inmediato
- ✅ **Índices SQL**: 10-100x mejora, usa índices
- ✅ **Compresión HTTP**: >50% reducción en >1KB

---

## 📝 Procedimiento de Ejecución

### Fase 1: Preparación (1 hora)

**Checklist**:
- [ ] Servidor Paperless corriendo en 172.20.10.3:8001
- [ ] Base de datos poblada con 500 personas de prueba
- [ ] Dispositivos de prueba cargados y conectados
- [ ] Scripts de test instalados y validados
- [ ] APK de prueba compilado: `flutter build apk --release`
- [ ] APK instalado en dispositivos: `adb install app-release.apk`

### Fase 2: Pruebas Funcionales (2 horas)

**Orden de Ejecución**:
1. Login y autenticación (TC-F1-01)
2. Carga de personas (TC-F2-01, TC-F2-02)
3. Búsqueda y selección (TC-F2-06)
4. Captura y optimización de imagen (TC-F2-04, TC-F2-05)
5. Upload completo (TC-E2E-01)

**Registro**:
- Capturar pantallas de cada paso
- Guardar logs: `adb logcat > logs_functional.txt`
- Documentar cualquier issue

### Fase 3: Pruebas de Performance (3 horas)

**Orden de Ejecución**:
1. Ejecutar benchmarks: `./scripts/benchmark_performance.sh`
2. Validar índices: `./scripts/validate_indexes.sh`
3. Test de carga: `./scripts/load_test_sqlite.sh 5000`
4. Medir throughput de uploads

**Métricas a Capturar**:
- Tiempos de carga (ms)
- Throughput (docs/min)
- Uso de memoria (MB)
- Uso de CPU (%)
- Tamaño de datos transmitidos (MB)

### Fase 4: Pruebas de Resiliencia (4 horas)

**Orden de Ejecución**:
1. Test con red 3G: `./scripts/simulate_network.sh <device> 3g`
2. Test offline → online (TC-E2E-03)
3. Test con interrupciones (TC-E2E-04)
4. Test circuit breaker (TC-F3-03, TC-F3-04)
5. Test retry con jitter (TC-F3-01, TC-F3-02)

**Condiciones a Probar**:
- Red 3G (500 KB/s)
- Red Edge (100 KB/s)
- Red intermitente
- Servidor caído
- Servidor lento

### Fase 5: Pruebas de Regresión (2 horas)

**Checklist de Features Existentes**:
- [ ] Búsqueda con tildes y ñ funciona
- [ ] Captura de foto con diferentes resoluciones
- [ ] Upload de PDF funciona
- [ ] Eliminación de pendientes funciona
- [ ] Background sync funciona
- [ ] Notificaciones funcionan

### Fase 6: Consolidación y Reporte (2 horas)

**Tareas**:
1. Compilar resultados de todas las pruebas
2. Generar gráficos de performance
3. Identificar issues encontrados
4. Priorizar fixes necesarios
5. Documentar en reporte final

---

## 📊 Reporte de Resultados

### Template de Reporte

**Archivo**: `TEST_RESULTS_YYYYMMDD.md`

```markdown
# Reporte de Pruebas - Lumara Scan
**Fecha**: [Fecha de ejecución]
**Versión**: [Versión de la app]
**Ejecutado por**: [Nombre del tester]

## Resumen Ejecutivo

**Estado General**: ✅ Aprobado / ⚠️ Con observaciones / ❌ Rechazado

**Cobertura de Pruebas**:
- Funcionales: X/Y pasadas (Z%)
- Performance: X/Y pasadas (Z%)
- Resiliencia: X/Y pasadas (Z%)
- Regresión: X/Y pasadas (Z%)

**Issues Críticos Encontrados**: N

## Resultados por Categoría

### 1. Pruebas Funcionales

| Test Case | Resultado | Tiempo | Observaciones |
|-----------|-----------|--------|---------------|
| TC-F1-01 | ✅ Pass | 87ms | - |
| TC-F1-02 | ✅ Pass | 15.2s | Timeout correcto |
| ... | | | |

### 2. Pruebas de Performance

**Benchmarks**:
| Operación | Tiempo | Objetivo | Estado |
|-----------|--------|----------|--------|
| Carga metadatos (cache) | 8ms | <50ms | ✅ |
| Búsqueda persona | 5ms | <10ms | ✅ |
| Optimización imagen | 234ms | <500ms | ✅ |
| Upload completo | 2.3s | <5s | ✅ |

**Gráfico de Mejoras**:
[Insertar gráfico de barras comparando antes/después]

### 3. Pruebas de Resiliencia

**Escenarios Probados**:
- ✅ Red 3G: 95% success rate
- ✅ Red intermitente: Recovery automático
- ✅ Servidor caído: Circuit breaker funcionó
- ✅ Offline → Online: Sincronización exitosa

### 4. Issues Encontrados

#### Issue #1: [Título]
**Severidad**: 🔴 Alta / 🟡 Media / 🟢 Baja
**Descripción**: [Descripción del problema]
**Steps to Reproduce**:
1. Paso 1
2. Paso 2

**Expected**: [Comportamiento esperado]
**Actual**: [Comportamiento observado]
**Logs**: [Extracto de logs relevantes]

#### Issue #2: ...

## Métricas Acumuladas

**Performance Global**:
- Tiempo promedio de upload: X segundos
- Throughput: Y documentos/minuto
- Success rate: Z%
- Mejora vs baseline: Nx más rápido

**Recursos**:
- Uso de memoria: X MB
- Uso de CPU: Y%
- Datos transmitidos: Z MB (W% reducción vs sin optimizaciones)

## Conclusiones

### Fortalezas
- [Lista de aspectos positivos]

### Áreas de Mejora
- [Lista de áreas que necesitan trabajo]

### Recomendaciones
- [Lista de recomendaciones para próximos pasos]

## Aprobación

**¿Listo para Producción?**: ✅ Sí / ❌ No

**Justificación**: [Explicación de la decisión]

**Firma**: [Nombre del responsable]
**Fecha**: [Fecha de aprobación]
```

---

## ✅ Checklist de Validación Final

### Pre-Deploy a Producción

**Funcionalidad** (BLOQUEANTE):
- [ ] Login funciona
- [ ] Carga de personas funciona
- [ ] Búsqueda funciona
- [ ] Captura de foto funciona
- [ ] Upload funciona
- [ ] Sincronización funciona
- [ ] Background sync funciona

**Performance** (BLOQUEANTE):
- [ ] Carga de metadatos <50ms (cache hit)
- [ ] Upload completo <30s (WiFi)
- [ ] Upload completo <60s (3G)
- [ ] Búsqueda <100ms
- [ ] Queries SQL <10ms

**Resiliencia** (BLOQUEANTE):
- [ ] Funciona offline (con datos cached)
- [ ] Recovery automático tras reconexión
- [ ] Retry funciona en red inestable
- [ ] Circuit breaker funciona
- [ ] No crashes en 1 hora de uso

**Regresión** (BLOQUEANTE):
- [ ] 0 features rotas
- [ ] Datos existentes migran correctamente
- [ ] Backward compatible

**Optimizaciones** (NO BLOQUEANTE):
- [ ] Optimización de imágenes funciona (60-80%)
- [ ] Compresión HTTP funciona (>50%)
- [ ] Índices SQLite activos
- [ ] Logging reducido en release
- [ ] WAL mode activo

**Seguridad** (BLOQUEANTE):
- [ ] API keys rotadas
- [ ] No PII en logs
- [ ] Tokens almacenados de forma segura

**Documentación** (NO BLOQUEANTE):
- [ ] Reporte de pruebas completo
- [ ] Issues documentados
- [ ] Métricas capturadas

---

## 📚 Apéndices

### A. Comandos Útiles ADB

```bash
# Limpiar caché y datos de la app
adb shell pm clear com.lumara.app

# Ver logs en tiempo real
adb logcat | grep Lumara

# Simular conexión lenta
adb shell tc qdisc add dev wlan0 root netem delay 100ms rate 500kbit

# Restaurar conexión normal
adb shell tc qdisc del dev wlan0 root

# Instalar APK
adb install -r app-release.apk

# Capturar screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Ver uso de memoria
adb shell dumpsys meminfo com.lumara.app

# Ver uso de batería
adb shell dumpsys batterystats com.lumara.app

# Forzar sincronización en background
adb shell am broadcast -a com.lumara.FORCE_SYNC
```

### B. Queries SQLite Útiles

```sql
-- Ver todos los índices
SELECT name, sql FROM sqlite_master WHERE type='index';

-- Ver tamaño de la base de datos
SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size();

-- Ver estadísticas de tablas
SELECT name, (SELECT COUNT(*) FROM pragma_table_info(name)) as columns
FROM sqlite_master WHERE type='table';

-- Ver pending uploads
SELECT COUNT(*), status FROM pending_uploads GROUP BY status;

-- Ver uso de índices (query plan)
EXPLAIN QUERY PLAN SELECT * FROM pending_uploads WHERE status='pending';

-- Optimizar base de datos
PRAGMA optimize;
VACUUM;
```

### C. Checklist de Dispositivos de Prueba

| Dispositivo | Android | RAM | Resultado | Observaciones |
|------------|---------|-----|-----------|---------------|
| Samsung Galaxy A04 | 11 | 3GB | ⬜ | |
| Xiaomi Redmi Note 12 | 12 | 4GB | ⬜ | |
| Samsung Galaxy S23 | 13 | 8GB | ⬜ | |
| Samsung Tab A8 | 12 | 4GB | ⬜ | |

### D. Matriz de Compatibilidad

| Android Version | Estado | Notas |
|----------------|--------|-------|
| 11 (API 30) | ⬜ Probado | |
| 12 (API 31) | ⬜ Probado | |
| 13 (API 33) | ⬜ Probado | |
| 14 (API 34) | ⬜ Probado | |

---

## 🎯 Resumen del Plan

**Duración Estimada**: 14 horas de ejecución + 2 horas reporte = **16 horas totales**

**Distribución**:
- Preparación: 1 hora (6%)
- Funcionales: 2 horas (13%)
- Performance: 3 horas (19%)
- Resiliencia: 4 horas (25%)
- Regresión: 2 horas (13%)
- Consolidación: 2 horas (13%)

**Recursos Necesarios**:
- 4 dispositivos de prueba (gama baja/media prioritario)
- Servidor Paperless configurado
- Conexión a internet estable
- Herramientas ADB y scripts
- 1-2 testers experimentados

**Criterio de Éxito Global**:
- ✅ >95% pruebas críticas pasadas
- ✅ 0 issues bloqueantes
- ✅ Mejoras de performance confirmadas (>3x)
- ✅ Resiliencia >90% en red inestable

**Próximos Pasos tras Aprobación**:
1. Deploy a grupo beta de usuarios (50-100 usuarios)
2. Monitoreo activo por 1-2 semanas
3. Recolección de feedback
4. Iteración y fixes menores
5. Deploy a producción completa

---

**FIN DEL PLAN DE PRUEBAS** ✅
