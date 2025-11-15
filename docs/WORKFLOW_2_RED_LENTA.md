# 🧪 WORKFLOW 2: Testing en Red Lenta (3G)

**Fecha**: 27 de octubre de 2025
**Versión**: Lumara v4.5.2 - FASE 1+2+3 Optimizado
**Duración Estimada**: 45-60 minutos
**Prerrequisito**: Workflow 1 completado exitosamente

---

## 📋 Objetivo

Validar que las **optimizaciones de resiliencia de FASE 3** funcionan correctamente en condiciones de red lenta (3G), incluyendo:

- ✅ **Retry con Jitter**: Reintentos con backoff exponencial y randomización ±25%
- ✅ **Circuit Breaker**: Prevención de fallos en cascada
- ✅ **Compresión HTTP**: Reducción de payload en 60-80%
- ✅ **Optimización de Imágenes**: Reducción antes de transferencia
- ✅ **Cache de Metadatos**: Evita llamadas API innecesarias

**Condiciones de Red Simuladas**:
- Velocidad: 500 KB/s
- Latencia: 100-200ms
- Packet Loss: 3-5%

---

## 🎯 Criterios de Éxito

### Criterios BLOQUEANTES (deben pasar todos)

| ID | Criterio | Métrica Objetivo | Cómo Medir |
|----|----------|------------------|------------|
| **B1** | Upload exitoso en red 3G | ≥95% success rate | Logs: `✅ Document uploaded successfully` |
| **B2** | Retry funciona correctamente | ≥2 reintentos antes de fallar | Logs: `🔄 Retry attempt X/3` |
| **B3** | Jitter activo | ±25% variación en delays | Logs: `delay with jitter: XXXms` |
| **B4** | Circuit breaker se abre tras fallos | Abre después de 5 fallos | Logs: `⛔ Circuit breaker OPEN` |
| **B5** | Sin crashes durante red lenta | 0 crashes en 30 min | App se mantiene estable |

### Criterios DESEABLES (recomendados)

| ID | Criterio | Métrica Objetivo | Cómo Medir |
|----|----------|------------------|------------|
| **D1** | Upload completo en <60s | <60s en red 3G | Tiempo total de upload |
| **D2** | Compresión HTTP activa | >60% reducción payload | Logs: `Compressed: XMB → YMB` |
| **D3** | Optimización de imágenes activa | >60% reducción size | Logs: `🖼️ Image optimized: X→Y` |
| **D4** | Circuit breaker se recupera | Cierra después de éxito | Logs: `Circuit breaker CLOSED` |
| **D5** | UX aceptable | Usuario no percibe lentitud extrema | Observación manual |

---

## 🔧 Preparación del Entorno

### 1. Verificar APK Instalado

```bash
# Verificar versión instalada
adb shell dumpsys package com.lumara.app | grep versionName

# Debe ser: versionName=4.5.2
```

### 2. Verificar Dispositivo Conectado

```bash
# Listar dispositivos
adb devices

# Debe mostrar al menos un dispositivo
```

### 3. Preparar Scripts de Testing

```bash
# Ubicarse en directorio del proyecto
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Verificar scripts disponibles
ls -lh scripts/*.sh

# Dar permisos de ejecución si es necesario
chmod +x scripts/*.sh
```

---

## 📝 Procedimiento de Ejecución

### FASE A: Instalación y Configuración

#### A1. Instalar APK con Optimizaciones

```bash
adb install -r Lumara_v4.5.2_FASE_1_2_3_OPTIMIZADO_20251027.apk
```

**Resultado Esperado**:
```
Success
```

**En caso de error**:
```bash
# Si ya está instalado, usar -r para reinstalar
# Si hay conflicto de firma, desinstalar primero:
adb uninstall com.lumara.app
adb install Lumara_v4.5.2_FASE_1_2_3_OPTIMIZADO_20251027.apk
```

#### A2. Limpiar Datos Previos (Opcional)

```bash
# Solo si quieres empezar desde cero
adb shell pm clear com.lumara.app
```

**⚠️ ADVERTENCIA**: Esto borrará:
- Cache de la app
- Datos de login
- Base de datos local
- Preferencias

#### A3. Iniciar App y Login

1. Abrir app Lumara en el dispositivo
2. Login con credenciales de prueba
3. Esperar a que cargue lista de personas (esto poblará el cache)

**Verificar en logs**:
```bash
# En otra terminal, monitorear logs
./scripts/watch_logs.sh '' cache
```

**Logs esperados**:
```
📋 Fetching tags from API
✅ Tags cached (25 items)
📋 Fetching document types from API
✅ Document types cached (8 items)
```

---

### FASE B: Simular Red 3G

#### B1. Activar Throttling de Red

**⚠️ IMPORTANTE**: Esto afectará TODO el tráfico de red del dispositivo mientras esté activo.

```bash
# Simular red 3G
./scripts/simulate_network.sh '' 3g
```

**Output Esperado**:
```
🌐 Simulating 3G network...
📡 Speed: 500 KB/s
⏱️  Latency: 100-200ms
📉 Packet Loss: 3-5%
✅ Network throttling applied
```

**Verificar throttling**:
```bash
# En el dispositivo, debería verse red lenta
# Puedes probar abriendo un navegador
```

#### B2. Iniciar Monitoreo de Logs

En **3 terminales separadas**, ejecutar:

**Terminal 1 - Logs de Retry/Circuit Breaker**:
```bash
./scripts/watch_logs.sh '' retry
```

**Terminal 2 - Logs de Optimizaciones**:
```bash
./scripts/watch_logs.sh '' optimizations
```

**Terminal 3 - Logs de Errores**:
```bash
./scripts/watch_logs.sh '' errors
```

---

### FASE C: Ejecución de Test Cases

#### TC-2-01: Upload de Documento en Red 3G (Éxito)

**Objetivo**: Verificar que un upload completo funciona en red lenta con retry y jitter.

**Pasos**:
1. En la app, ir a "Upload Document"
2. Seleccionar una persona del censo
3. Seleccionar tipo de documento (ej: "Cédula de Ciudadanía")
4. Tomar foto con cámara (o seleccionar desde galería)
5. Confirmar upload
6. Observar logs en las 3 terminales

**Logs Esperados en Terminal 1 (retry)**:
```
📤 Uploading document for: [Nombre Persona]
🖼️ Optimizing image...
🖼️ Image optimized: 4.2MB → 890KB (78.8% reduction)
🗜️ Compressing HTTP request...
🗜️ Compressed: 890KB → 178KB (80% reduction)
📡 Sending request...
⏱️  Response time: 12.5s
✅ Document uploaded successfully
```

**Si hay timeout temporal (esperado en 3G)**:
```
📡 Sending request...
❌ Request timeout
🔄 Retry attempt 1/3 with jitter (delay: 2.3s)
⏳ Waiting 2.3s before retry...
📡 Sending request...
⏱️  Response time: 15.8s
✅ Document uploaded successfully
```

**Verificar**:
- [ ] Upload exitoso después de retry
- [ ] Jitter aplicado (delays varían: 2.0s → 2.3s → 4.6s)
- [ ] Tiempo total <60s
- [ ] Optimización de imagen funcionó
- [ ] Compresión HTTP funcionó

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-2-02: Retry con Backoff Exponencial

**Objetivo**: Verificar que los reintentos incrementan el delay exponencialmente con jitter.

**Pasos**:
1. Simular fallos de red intermitentes (o dejar que fallen naturalmente)
2. Intentar upload de documento
3. Observar logs de retry en Terminal 1

**Logs Esperados**:
```
📡 Sending request...
❌ Connection timeout
🔄 Retry attempt 1/3 with jitter (delay: 2.1s)
⏳ Waiting 2.1s before retry...

📡 Sending request...
❌ Connection timeout
🔄 Retry attempt 2/3 with jitter (delay: 4.8s)
⏳ Waiting 4.8s before retry...

📡 Sending request...
❌ Connection timeout
🔄 Retry attempt 3/3 with jitter (delay: 7.9s)
⏳ Waiting 7.9s before retry...

📡 Sending request...
✅ Document uploaded successfully
```

**Verificar Backoff Exponencial**:
- Intento 1: ~2s (base 2s, jitter ±0.5s)
- Intento 2: ~4s (base 4s, jitter ±1s)
- Intento 3: ~8s (base 8s, jitter ±2s)

**Verificar Jitter (±25%)**:
- Los delays NO deben ser exactos (2.0s, 4.0s, 8.0s)
- Deben variar ligeramente: (1.8s-2.2s, 3.5s-4.5s, 7.0s-9.0s)

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-2-03: Circuit Breaker se Abre tras 5 Fallos

**Objetivo**: Verificar que el circuit breaker se abre después de 5 fallos consecutivos para prevenir sobrecarga.

**Pasos**:
1. Desconectar temporalmente el servidor backend (o simular offline)
```bash
# En otra terminal
docker-compose stop paperless-webserver
```

2. Intentar upload de documento (esto fallará)
3. Repetir 5 veces (o esperar a que falle automáticamente con retry)
4. Observar logs

**Logs Esperados**:
```
📡 Sending request...
❌ Connection failed (attempt 1)

📡 Sending request...
❌ Connection failed (attempt 2)

📡 Sending request...
❌ Connection failed (attempt 3)

📡 Sending request...
❌ Connection failed (attempt 4)

📡 Sending request...
❌ Connection failed (attempt 5)

⛔ Circuit breaker OPEN for operation: uploadDocument
⏱️  Will retry in 2 minutes (half-open state)

📡 Attempting request...
❌ Circuit breaker is OPEN - request blocked
```

**Verificar**:
- [ ] Circuit breaker abre tras 5 fallos
- [ ] Requests subsiguientes son bloqueados inmediatamente
- [ ] Log indica "Circuit breaker OPEN"

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-2-04: Circuit Breaker se Recupera (Half-Open → Closed)

**Objetivo**: Verificar que el circuit breaker se recupera automáticamente después de 2 minutos.

**Pasos**:
1. Con circuit breaker OPEN (del test anterior)
2. Reconectar servidor backend
```bash
docker-compose start paperless-webserver
```

3. Esperar 2 minutos
4. Intentar upload de documento nuevamente
5. Observar logs

**Logs Esperados después de 2 min**:
```
🔄 Circuit breaker HALF-OPEN - allowing test request
📡 Sending request...
✅ Document uploaded successfully
✅ Circuit breaker CLOSED - operation restored
```

**Verificar**:
- [ ] Circuit breaker pasa a HALF-OPEN después de 2 min
- [ ] Permite un request de prueba
- [ ] Si el request tiene éxito, pasa a CLOSED
- [ ] Operaciones normales se restauran

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-2-05: Compresión HTTP en Red Lenta

**Objetivo**: Confirmar que la compresión HTTP está activa y reduce significativamente el payload.

**Pasos**:
1. Con red 3G activa
2. Intentar upload de documento (imagen mediana/grande)
3. Observar logs en Terminal 2 (optimizations)

**Logs Esperados**:
```
🖼️ Processing image: document_12345.jpg
📏 Original size: 4.2MB
📐 Original dimensions: 4032x3024

🖼️ Optimizing...
  ↳ Resize to: 1920x1440
  ↳ JPEG quality: 85%
  ↳ Time: 234ms

✅ Image optimized: 4.2MB → 890KB (78.8% reduction)

🗜️ Compressing HTTP request...
🗜️ Request body >1KB, applying gzip compression
✅ Compressed: 890KB → 178KB (80.0% reduction)
```

**Verificar**:
- [ ] Optimización de imagen activa (>60% reducción)
- [ ] Compresión HTTP activa (>60% reducción)
- [ ] Total reducción: >90% (4.2MB → 178KB)
- [ ] Tiempo de upload <60s en 3G

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-2-06: Cache de Metadatos Evita Llamadas API

**Objetivo**: Verificar que el cache de metadatos evita llamadas API innecesarias en red lenta.

**Pasos**:
1. Con red 3G activa
2. Ir a "Upload Document"
3. Observar logs en Terminal 2 (optimizations)

**Primera Vez (Cache Miss)**:
```
📋 Fetching tags from API
⏱️  API call time: 3.2s
✅ Tags cached (25 items)

📋 Fetching document types from API
⏱️  API call time: 2.8s
✅ Document types cached (8 items)
```

**Segunda Vez y Subsiguientes (Cache Hit)**:
```
📋 Using cached tags (25 items)
📋 Using cached document types (8 items)
⏱️  Load time: 12ms (from cache)
```

**Verificar**:
- [ ] Primera carga: Fetch desde API (~3s cada uno)
- [ ] Cargas subsiguientes: Desde cache (<50ms)
- [ ] Mejora: >99% más rápido

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-2-07: Uploads Consecutivos en Red 3G

**Objetivo**: Probar estabilidad con múltiples uploads en red lenta.

**Pasos**:
1. Con red 3G activa
2. Hacer 3 uploads consecutivos (diferentes personas/documentos)
3. Medir tiempo total y observar logs

**Logs Esperados**:
```
Upload 1:
  📤 Start: 10:00:00
  ✅ Success: 10:00:45 (45s)

Upload 2:
  📤 Start: 10:00:50
  ✅ Success: 10:01:28 (38s) ← Más rápido por cache

Upload 3:
  📤 Start: 10:01:35
  ✅ Success: 10:02:12 (37s) ← Más rápido por cache
```

**Verificar**:
- [ ] Todos los uploads exitosos
- [ ] Tiempo total <3 minutos para 3 uploads
- [ ] Uploads subsiguientes más rápidos (cache activo)
- [ ] Sin crashes o memory leaks

**Resultado**: ✅ Aprobado / ❌ Fallido

---

### FASE D: Restauración y Limpieza

#### D1. Restaurar Red Normal

```bash
# Desactivar throttling
./scripts/simulate_network.sh '' reset
```

**Output Esperado**:
```
🌐 Resetting network to normal...
✅ Network throttling removed
```

#### D2. Verificar Conectividad Normal

```bash
# Probar conexión al servidor
curl -w "\nTime: %{time_total}s\n" http://172.20.10.3:8001/api/

# Debe responder en <1s
```

#### D3. Detener Monitoreo de Logs

Cerrar las 3 terminales de logs (Ctrl+C en cada una).

---

## 📊 Reporte de Resultados

### Template de Reporte

```markdown
# WORKFLOW 2: Testing en Red Lenta (3G) - Reporte

**Fecha**: [Fecha de ejecución]
**Dispositivo**: [Modelo y Android version]
**Duración Total**: [XX minutos]
**APK Version**: 4.5.2 FASE_1_2_3_OPTIMIZADO

---

## Resultados por Test Case

| TC ID | Nombre | Resultado | Tiempo | Observaciones |
|-------|--------|-----------|--------|---------------|
| TC-2-01 | Upload en 3G (Éxito) | ✅/❌ | XXs | [Notas] |
| TC-2-02 | Retry Backoff Exponencial | ✅/❌ | XXs | [Notas] |
| TC-2-03 | Circuit Breaker Abre | ✅/❌ | XXs | [Notas] |
| TC-2-04 | Circuit Breaker Recupera | ✅/❌ | XXs | [Notas] |
| TC-2-05 | Compresión HTTP | ✅/❌ | XXs | [Notas] |
| TC-2-06 | Cache de Metadatos | ✅/❌ | XXs | [Notas] |
| TC-2-07 | Uploads Consecutivos | ✅/❌ | XXs | [Notas] |

---

## Criterios de Éxito

### Bloqueantes

- [ ] **B1**: Upload exitoso en red 3G (≥95% success rate)
- [ ] **B2**: Retry funciona correctamente (≥2 reintentos)
- [ ] **B3**: Jitter activo (±25% variación)
- [ ] **B4**: Circuit breaker se abre tras 5 fallos
- [ ] **B5**: Sin crashes durante 30 min

**Bloqueantes Cumplidos**: X/5

### Deseables

- [ ] **D1**: Upload completo en <60s
- [ ] **D2**: Compresión HTTP activa (>60%)
- [ ] **D3**: Optimización imágenes (>60%)
- [ ] **D4**: Circuit breaker se recupera
- [ ] **D5**: UX aceptable

**Deseables Cumplidos**: X/5

---

## Métricas de Performance

### Tiempos de Upload (Red 3G)

| Operación | Baseline (sin optimización) | Con Optimizaciones | Mejora |
|-----------|----------------------------|-------------------|--------|
| Upload 1 (cold start) | ~180s | XXs | XX% |
| Upload 2 (cache hit) | ~180s | XXs | XX% |
| Upload 3 (cache hit) | ~180s | XXs | XX% |

### Reducción de Payload

| Etapa | Original | Optimizado | Reducción |
|-------|----------|------------|-----------|
| Imagen | X MB | Y MB | XX% |
| HTTP Compression | Y MB | Z MB | XX% |
| **Total** | X MB | Z MB | **XX%** |

### Retry Behavior

| Intento | Delay Esperado | Delay Real | Jitter |
|---------|----------------|------------|--------|
| 1 | 2s ±0.5s | X.Xs | ±XX% |
| 2 | 4s ±1s | X.Xs | ±XX% |
| 3 | 8s ±2s | X.Xs | ±XX% |

---

## Issues Encontrados

### Críticos (🔴)
[Lista de issues que bloquean producción]

### Menores (🟡)
[Lista de issues que no bloquean pero deberían mejorarse]

### Observaciones (🔵)
[Notas generales, sugerencias de mejora]

---

## Conclusión

[Descripción breve del resultado general]

**Decisión Final**:
- ✅ **Aprobado**: Todos los criterios bloqueantes cumplidos
- ⚠️ **Aprobado con Observaciones**: Criterios cumplidos pero con issues menores
- ❌ **Rechazado**: Requiere fixes antes de continuar

## Próximos Pasos

- [ ] Continuar con Workflow 3 (Testing Offline)
- [ ] Documentar observaciones
- [ ] Crear tickets de mejora
```

---

## 🎯 Criterios de Aprobación

### ✅ Aprobar SIN Reservas

**Condiciones**:
- 100% criterios BLOQUEANTES cumplidos (5/5)
- ≥80% criterios DESEABLES cumplidos (≥4/5)
- 0 crashes en 30 minutos de uso
- Performance en 3G <60s por upload
- Retry + Circuit Breaker funcionan correctamente

**Acción**: Continuar con Workflow 3 (Testing Offline)

---

### ⚠️ Aprobar con Observaciones

**Condiciones**:
- 100% criterios BLOQUEANTES cumplidos (5/5)
- ≥60% criterios DESEABLES cumplidos (≥3/5)
- Issues menores documentados
- Performance aceptable (60-90s por upload)

**Acción**:
1. Documentar observaciones
2. Continuar con Workflow 3
3. Crear tickets de mejora

---

### ❌ Rechazar - Requiere Fixes

**Condiciones**:
- <100% criterios BLOQUEANTES cumplidos
- Crashes frecuentes (≥2 en 30 min)
- Performance inaceptable (>90s por upload)
- Retry o Circuit Breaker no funcionan

**Acción**:
1. Detener testing
2. Documentar issues críticos
3. Fix issues antes de continuar
4. Re-ejecutar Workflow 2

---

## 📞 Troubleshooting

### Issue: Throttling de Red No Funciona

**Síntoma**: Los uploads siguen siendo rápidos después de activar 3G.

**Solución**:
1. Verificar que el script se ejecutó correctamente
```bash
adb shell tc qdisc show
```

2. Si el dispositivo no soporta `tc`, usar alternativas:
   - Emulador Android Studio: Settings → Extended Controls → Network
   - Chrome DevTools: Network tab → Throttling
   - Proxy externo (Charles Proxy, Fiddler)

---

### Issue: Circuit Breaker No Se Abre

**Síntoma**: Después de 5+ fallos, el circuit breaker no se abre.

**Verificar**:
1. Logs muestran conteo de fallos
```bash
./scripts/watch_logs.sh '' errors | grep "failure count"
```

2. Verificar configuración en `connectivity_service.dart`:
```dart
static const int maxFailures = 5; // Debe ser 5
static const Duration openDuration = Duration(minutes: 2); // Debe ser 2min
```

---

### Issue: Compresión HTTP No Activa

**Síntoma**: No hay logs de "Compressing HTTP request".

**Verificar**:
1. Request body >1KB (threshold de compresión)
```bash
./scripts/watch_logs.sh '' optimizations | grep "Compressed"
```

2. Si la imagen es muy pequeña (<1KB), la compresión no se aplica (esperado)

3. Verificar interceptor en `paperless_api_client.dart`:
```dart
static const int compressionThreshold = 1024; // 1KB
```

---

### Issue: Logs No Aparecen

**Solución**:
```bash
# Limpiar buffer de logcat
adb logcat -c

# Reiniciar monitoreo
./scripts/watch_logs.sh '' all

# Verificar que la app está corriendo
adb shell ps | grep lumara
```

---

## 📚 Referencias

- [WORKFLOW_1_PERFORMANCE_BASICO.md](./WORKFLOW_1_PERFORMANCE_BASICO.md) - Workflow anterior
- [PLAN_PRUEBAS_COMPLETO.md](../PLAN_PRUEBAS_COMPLETO.md) - Plan general
- [FASE3_COMPLETADA_REPORTE.md](../FASE3_COMPLETADA_REPORTE.md) - Optimizaciones FASE 3
- [scripts/README.md](../scripts/README.md) - Documentación de scripts

---

**Última actualización**: 27 de octubre de 2025
