# 🛠️ Scripts de Testing - Lumara Scan

Scripts para facilitar la ejecución de pruebas de las optimizaciones implementadas en FASE 1, 2 y 3.

---

## 📋 Scripts Disponibles

### 1. `simulate_network.sh` - Simulación de Condiciones de Red

Simula diferentes tipos de conexiones de red para testing de resiliencia.

**Uso**:
```bash
./scripts/simulate_network.sh [device-id] [network-type]
```

**Tipos de Red**:
- `wifi` - Red WiFi normal (sin throttling)
- `4g-good` - 4G bueno (10 MB/s, 30ms latency)
- `4g-bad` - 4G malo (2 MB/s, 100ms latency, 2% loss)
- `3g` - 3G típico (500 KB/s, 150ms latency, 5% loss)
- `edge` - Edge/2G (100 KB/s, 300ms latency, 10% loss)
- `intermittent` - Red intermitente (se desconecta cada 10s)
- `offline` - Modo offline completo
- `reset` - Restaurar red normal

**Ejemplos**:
```bash
# Simular red 3G
./scripts/simulate_network.sh emulator-5554 3g

# Simular red intermitente
./scripts/simulate_network.sh 192.168.1.100 intermittent

# Restaurar red normal
./scripts/simulate_network.sh emulator-5554 reset

# Usar dispositivo por defecto (primer device conectado)
./scripts/simulate_network.sh '' 3g
```

**Notas**:
- Requiere permisos root en el dispositivo para `tc` command
- Si el dispositivo no tiene `tc`, usar throttling de red del emulador o Chrome DevTools

---

### 2. `watch_logs.sh` - Monitoreo de Logs en Tiempo Real

Filtra y muestra logs relevantes de Lumara en tiempo real.

**Uso**:
```bash
./scripts/watch_logs.sh [device-id] [filter]
```

**Filtros Disponibles**:
- `performance` - Logs de performance (⏱️, 🚀, ⚡, 📊)
- `network` - Logs de red (🌐, 📡, 🔌, 📶, 🔄)
- `errors` - Logs de errores (❌, ⚠️, ERROR, Exception)
- `optimizations` - Logs de optimizaciones (🖼️, 🗜️, 💾, ✅)
- `cache` - Logs de cache
- `retry` - Logs de retry y circuit breaker
- `all` - Todos los logs de Lumara

**Ejemplos**:
```bash
# Ver logs de optimizaciones
./scripts/watch_logs.sh emulator-5554 optimizations

# Ver logs de errores
./scripts/watch_logs.sh 192.168.1.100 errors

# Ver todos los logs
./scripts/watch_logs.sh '' all
```

**Uso Típico**:
```bash
# En una terminal, simular red 3G
./scripts/simulate_network.sh emulator-5554 3g

# En otra terminal, monitorear logs de performance
./scripts/watch_logs.sh emulator-5554 performance

# Ejecutar operaciones en la app y observar logs
```

---

### 3. `validate_indexes.sh` - Validación de Índices SQLite

Verifica que los índices SQLite existen y se usan correctamente en queries.

**Uso**:
```bash
./scripts/validate_indexes.sh [device-id]
```

**Output Esperado**:
```
🔍 Validando índices SQLite...

📋 Índices existentes:
     1  idx_pending_uploads_status_created
     2  idx_pending_uploads_last_attempt
     3  idx_pending_uploads_person
     4  idx_upload_history_person_uploaded
     5  idx_upload_history_status_uploaded
     6  idx_upload_history_offline
     7  idx_persons_name
     8  idx_persons_community
     9  idx_tags_cached_at
    10  idx_document_types_cached_at
    11  idx_custom_fields_cached_at

🔍 Verificando uso de índices en queries comunes:

1. Query: pending uploads by status
SEARCH pending_uploads USING INDEX idx_pending_uploads_status_created (status=?)

2. Query: upload history by person
SEARCH upload_history USING INDEX idx_upload_history_person_uploaded (person_id=?)

...
```

**Criterios de Éxito**:
- ✅ 11+ índices listados
- ✅ Cada query usa "SEARCH ... USING INDEX" (no "SCAN TABLE")
- ❌ Si ve "SCAN TABLE", el índice no se está usando

**Ejemplos**:
```bash
# Validar índices en dispositivo
./scripts/validate_indexes.sh emulator-5554

# Usar dispositivo por defecto
./scripts/validate_indexes.sh
```

---

## 🧪 Workflows de Testing Comunes

### Testing de Performance Básico

```bash
# 1. Instalar APK
adb install -r app-release.apk

# 2. Limpiar datos previos
adb shell pm clear com.lumara.app

# 3. Monitorear logs de performance
./scripts/watch_logs.sh '' performance &

# 4. Ejecutar operaciones en la app
# - Login
# - Cargar personas
# - Buscar persona
# - Upload documento

# 5. Observar tiempos en logs
```

### Testing de Resiliencia en Red Lenta

```bash
# 1. Simular red 3G
./scripts/simulate_network.sh '' 3g

# 2. Monitorear logs de retry
./scripts/watch_logs.sh '' retry &

# 3. Intentar upload de documento
# 4. Observar retry con backoff exponencial

# 5. Restaurar red
./scripts/simulate_network.sh '' reset
```

### Testing de Optimizaciones de Imágenes

```bash
# 1. Monitorear logs de optimizaciones
./scripts/watch_logs.sh '' optimizations &

# 2. Tomar foto con cámara (máxima resolución)
# 3. Procesar upload

# 4. Observar en logs:
# - Tamaño original
# - Tamaño optimizado
# - % de compresión
# - Tiempo de optimización
```

### Testing de Cache Offline

```bash
# 1. Online: Login y cargar personas (cache poblado)
./scripts/watch_logs.sh '' cache &

# 2. Ir offline
./scripts/simulate_network.sh '' offline

# 3. Navegar a pantalla de upload
# 4. Observar: "✅ Using cached tags"

# 5. Restaurar red
./scripts/simulate_network.sh '' reset
```

### Validación Completa Post-Deploy

```bash
# 1. Validar índices SQLite
./scripts/validate_indexes.sh

# 2. Testing funcional en red normal
./scripts/simulate_network.sh '' wifi
# Ejecutar flujo E2E completo

# 3. Testing en red 3G
./scripts/simulate_network.sh '' 3g
# Ejecutar flujo E2E completo

# 4. Testing offline
./scripts/simulate_network.sh '' offline
# Intentar operaciones sin conexión

# 5. Testing de recuperación
./scripts/simulate_network.sh '' reset
# Verificar sincronización automática

# 6. Revisar logs de errores
./scripts/watch_logs.sh '' errors
```

---

## 📊 Captura de Métricas

### Benchmark de Performance

```bash
# Capturar logs durante 5 minutos de uso
timeout 300 ./scripts/watch_logs.sh '' performance > benchmark_logs.txt

# Analizar métricas
grep "⏱️" benchmark_logs.txt | awk '{print $NF}' | sort -n | uniq -c

# Extraer tiempos de upload
grep "Upload completed" benchmark_logs.txt
```

### Análisis de Errores

```bash
# Capturar errores durante 1 hora
timeout 3600 ./scripts/watch_logs.sh '' errors > error_logs.txt

# Contar tipos de errores
grep "❌" error_logs.txt | cut -d':' -f2 | sort | uniq -c

# Identificar errores frecuentes
grep "Exception" error_logs.txt | sed 's/.*Exception: //' | sort | uniq -c | sort -rn
```

---

## 🚨 Troubleshooting

### Error: "tc: command not found"

**Problema**: El dispositivo no tiene el comando `tc` para throttling de red.

**Solución**:
1. Usar emulador de Android Studio con throttling incorporado
2. Usar Chrome DevTools Network Throttling si la app es hybrid
3. Usar proxy con throttling (ej: Charles Proxy)

### Error: "run-as: Package 'com.lumara.app' is not debuggable"

**Problema**: No se puede acceder a la base de datos en build de release.

**Solución**:
1. Usar build de debug para inspección de DB: `flutter build apk --debug`
2. O agregar `android:debuggable="true"` temporalmente en AndroidManifest.xml

### Los logs no aparecen

**Problema**: Los filtros de grep no capturan los logs.

**Solución**:
```bash
# Ver logs sin filtro
adb logcat | grep -i lumara

# Verificar que la app está corriendo
adb shell ps | grep lumara

# Limpiar buffer de logcat y reintentar
adb logcat -c
./scripts/watch_logs.sh '' all
```

### Red simulada no se aplica

**Problema**: El throttling con `tc` no funciona.

**Solución**:
```bash
# Verificar interfaz de red correcta
adb shell ip addr show

# Algunas devices usan wlan0, otras wlan1
# Modificar script si es necesario

# Verificar que tc está disponible
adb shell which tc
```

---

## 📚 Comandos ADB Adicionales Útiles

```bash
# Limpiar caché y datos de la app
adb shell pm clear com.lumara.app

# Forzar detención de la app
adb shell am force-stop com.lumara.app

# Abrir app
adb shell am start -n com.lumara.app/.MainActivity

# Ver uso de memoria
adb shell dumpsys meminfo com.lumara.app | grep TOTAL

# Ver uso de batería
adb shell dumpsys batterystats com.lumara.app | grep "Uid"

# Capturar screenshot
adb shell screencap -p /sdcard/screenshot.png && adb pull /sdcard/screenshot.png

# Grabar video de pantalla (10 segundos)
adb shell screenrecord /sdcard/test_video.mp4 --time-limit 10 && adb pull /sdcard/test_video.mp4

# Ver APK instalado
adb shell pm list packages | grep lumara

# Ver versión del APK
adb shell dumpsys package com.lumara.app | grep versionName
```

---

## 🎯 Checklist Rápido de Testing

**Pre-Deploy**:
- [ ] Índices SQLite validados: `./scripts/validate_indexes.sh`
- [ ] Flujo E2E en WiFi: OK (<30s)
- [ ] Flujo E2E en 3G: OK (<60s)
- [ ] Flujo offline: Funciona con cache
- [ ] Sincronización post-offline: OK
- [ ] Sin crashes en 10 minutos de uso
- [ ] Sin memory leaks

**Durante Beta**:
- [ ] Monitorear logs de errores: `./scripts/watch_logs.sh '' errors`
- [ ] Capturar métricas de performance
- [ ] Recolectar feedback de usuarios
- [ ] Documentar issues encontrados

---

## 📞 Soporte

Para issues con los scripts o el plan de pruebas, consultar:
- [PLAN_PRUEBAS_COMPLETO.md](../PLAN_PRUEBAS_COMPLETO.md) - Plan de pruebas detallado
- [FASE3_COMPLETADA_REPORTE.md](../FASE3_COMPLETADA_REPORTE.md) - Documentación de optimizaciones

---

**Última actualización**: 27 de octubre de 2025
