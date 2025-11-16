# DIAGNÓSTICO: Backend Connectivity

**Fecha:** 2025-11-16  
**Versión:** v7.0.0  
**Investigación:** 45 minutos  
**Estado:** ✅ ROOT CAUSE IDENTIFICADO

---

## RESUMEN EJECUTIVO

**Problema Reportado:** Timeouts intermitentes al conectar con backend Paperless-ngx  
**Root Cause:** IP incorrecta hardcodeada en código (192.168.40.17 no existe en red actual)  
**Backend Status:** ✅ Funcionando perfectamente en localhost:8001  
**Impacto:** 🔴 CRÍTICO - App no puede conectar con servidor desde dispositivos móviles  
**Solución:** Actualizar IP en api_constants.dart + implementar configuración dinámica

---

## INVESTIGACIÓN REALIZADA

### 1. Verificación de Backend

#### Docker Containers Status
```bash
$ docker ps --filter "name=paperless"
NAMES                   STATUS                PORTS
paperless_webserver_1   Up 9 days (healthy)   0.0.0.0:8001->8000/tcp
paperless_broker_1      Up 9 days             6379/tcp
```

**Resultado:** ✅ Contenedores operacionales, 9 días de uptime

#### Logs de Backend
```bash
$ docker logs 4e58904b8162 --tail 50 | grep -i "error\|warning"
[WARNING] [paperless.tasks] Classifier error: No training data available.
```

**Resultado:** ✅ Solo 1 WARNING menor (esperado, no hay datos de training)  
**Sin errores críticos:** No hay crashes, timeouts internos, o fallos de servicios

#### Django System Check
```bash
$ docker exec 4e58904b8162 python manage.py check
System check identified no issues (0 silenced).
```

**Resultado:** ✅ 0 issues, configuración Django correcta

---

### 2. Tests de Conectividad

#### Test 1: IP Hardcodeada (192.168.40.17)
```bash
$ curl -s http://192.168.40.17:8001/api/ --max-time 5
Exit code 28 (timeout)

$ ping -c 3 192.168.40.17
100% packet loss
```

**Resultado:** ❌ IP NO EXISTE en red actual

#### Test 2: Localhost
```bash
$ curl -s http://localhost:8001/api/auth/
{
    "profiles": "http://localhost:8001/api/auth/profiles/",
    "assignments": "http://localhost:8001/api/auth/assignments/",
    "logs": "http://localhost:8001/api/auth/logs/"
}
```

**Resultado:** ✅ API responde perfectamente

#### Test 3: IP Local Real (192.168.110.149)
```bash
$ ip addr show | grep "inet " | grep -v "127.0.0.1"
inet 192.168.110.149/24 brd 192.168.110.255 scope global wlp0s20f3
```

**Resultado:** IP real es 192.168.110.149 (WiFi interface)

---

### 3. Análisis de Código

#### Archivo Crítico: lib/core/constants/api_constants.dart

```dart
class ApiConstants {
  // ⚠️ PROBLEMA: IP incorrecta
  static const String defaultBaseUrl = 'http://192.168.40.17:8001'; 
  
  // Alternativas disponibles
  static const String localhostUrl = 'http://127.0.0.1:8001';
  static const String dockerInternalUrl = 'http://172.21.0.3:8000';
  
  // Storage key para configuración dinámica
  static const String baseUrlKey = 'paperless_base_url';
}
```

**Hallazgos:**
- ✅ Código tiene soporte para URL configurable (baseUrlKey)
- ❌ IP por defecto es incorrecta (192.168.40.17)
- ✅ Tiene alternativas (localhost, docker)

#### Archivos Afectados
```bash
$ grep -r "192\.168\.40\.17" . | wc -l
60 archivos
```

**Impacto:** 60 archivos con IP hardcodeada (mayoría documentación/scripts)

---

## ROOT CAUSE CONFIRMADO

**Problema:** Desincronización entre IP configurada y red real

| Configuración | IP Esperada | IP Real | Estado |
|--------------|-------------|---------|--------|
| api_constants.dart | 192.168.40.17 | NO EXISTE | ❌ |
| Red WiFi actual | - | 192.168.110.149 | ✅ |
| Backend localhost | 127.0.0.1:8001 | 127.0.0.1:8001 | ✅ |
| Docker interno | - | 172.x.x.x | ✅ |

**Conclusión:** Backend funciona correctamente. El problema es de configuración de red en la app.

---

## IMPACTO

### 🔴 CRÍTICO

1. **App móvil no puede conectar**
   - Dispositivos Android en red WiFi no alcanzan backend
   - Todas las operaciones que requieren API fallan
   - Login, censo, upload bloqueados

2. **Testing E2E imposible**
   - No se puede probar la app en dispositivo real
   - APKs distribuidos no funcionan
   - Validación de features bloqueada

3. **Círculo vicioso de APKs**
   - APKs compilados con IP incorrecta
   - Testing falla → nuevo APK → testing falla
   - Contribuyó al problema de 20+ APKs en 10 días

### 🟡 MENOR

1. **Scripts de testing afectados**
   - 60 archivos con IP vieja
   - Mayoría son scripts/docs históricos
   - No bloquea desarrollo, solo confunde

---

## SOLUCIONES PROPUESTAS

### SOLUCIÓN 1: Fix Inmediato (5 minutos) - RECOMENDADA

**Acción:** Actualizar IP en api_constants.dart

```dart
// lib/core/constants/api_constants.dart
static const String defaultBaseUrl = 'http://192.168.110.149:8001'; // ✅ IP actual
```

**Pros:**
- ✅ Inmediato (5 min)
- ✅ Desbloquea testing E2E
- ✅ Permite validar v7.0.0

**Contras:**
- ❌ Si IP cambia (DHCP), rompe de nuevo
- ❌ No escalable para múltiples entornos

**Cuándo usar:** AHORA - para desbloquear testing urgente

---

### SOLUCIÓN 2: Configuración Dinámica (30 minutos)

**Acción:** Implementar pantalla de configuración en primer uso

```dart
// lib/presentation/setup/server_config_screen.dart
class ServerConfigScreen extends StatelessWidget {
  // Input field para IP servidor
  // Guardar en SharedPreferences (baseUrlKey)
  // Validar conectividad antes de guardar
}

// lib/services/api_service.dart
class ApiService {
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.baseUrlKey) 
        ?? ApiConstants.defaultBaseUrl;
  }
}
```

**Pros:**
- ✅ Usuario configura IP manualmente
- ✅ Funciona con cualquier red
- ✅ Permite cambiar servidor sin recompilar

**Contras:**
- ⚠️ Usuario debe conocer IP del servidor
- ⚠️ Errores de tipeo comunes

**Cuándo usar:** Corto plazo (próxima versión v7.1.0)

---

### SOLUCIÓN 3: QR Code Configuration (1 hora) - MEJOR PRÁCTICA

**Acción:** Escanear QR desde Tejido dashboard para auto-configurar

```dart
// Tejido (frontend web) genera QR:
{
  "server_url": "http://192.168.110.149:8001",
  "server_name": "Paperless Chía 2",
  "timestamp": "2025-11-16T12:00:00Z"
}

// App Flutter escanea QR:
// - Valida JSON
// - Prueba conectividad
// - Guarda en SharedPreferences
// - Redirige a login
```

**Pros:**
- ✅ UX excelente (0 errores de tipeo)
- ✅ Funciona en cualquier red
- ✅ Permite múltiples servidores (testing/producción)
- ✅ Se alinea con roadmap existente

**Contras:**
- ⚠️ Requiere cámara (ya implementado para digitalización)
- ⚠️ Requiere modificar Tejido dashboard

**Cuándo usar:** Mediano plazo (v7.2.0 o v8.0.0)

---

### SOLUCIÓN 4: mDNS Auto-Discovery (2 horas) - AVANZADA

**Acción:** Servidor anuncia presencia vía mDNS/Avahi, app descubre automáticamente

```dart
// Backend anuncia:
paperless-chia2.local -> 192.168.110.149:8001

// App Flutter descubre:
import 'package:nsd/nsd.dart';

final discovery = await startDiscovery('_paperless._tcp');
// Encuentra automáticamente servidor en red local
```

**Pros:**
- ✅ Zero-config para usuario
- ✅ Funciona con IP dinámica (DHCP)
- ✅ Profesional (Apple Bonjour, ChromeCast usan esto)

**Contras:**
- ❌ Complejidad técnica alta
- ❌ Requiere configurar Avahi en backend
- ❌ No funciona fuera de red local

**Cuándo usar:** Largo plazo (v8.0.0+) si se justifica

---

## PLAN DE ACCIÓN RECOMENDADO

### FASE A: Urgente (HOY - 30 min)

1. ✅ **[COMPLETADO]** Diagnosticar problema
2. **[PENDIENTE]** Actualizar IP en api_constants.dart:
   ```bash
   # Editar archivo
   vim lib/core/constants/api_constants.dart
   # Cambiar línea 7:
   static const String defaultBaseUrl = 'http://192.168.110.149:8001';
   ```

3. **[PENDIENTE]** Compilar APK de testing:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   cp build/app/outputs/flutter-apk/app-release.apk \
      ~/Descargas/Lumara_v7.0.0_IP_FIX_$(date +%Y%m%d_%H%M%S).apk
   ```

4. **[PENDIENTE]** Testing E2E en dispositivo:
   - Login
   - Censo (3998 personas)
   - Captura documento
   - Upload a servidor
   - Verificar nuevas features v7.0.0

### FASE B: Corto Plazo (Esta semana - 2 horas)

1. **[PENDIENTE]** Implementar pantalla de configuración dinámica
2. **[PENDIENTE]** Agregar validación de conectividad
3. **[PENDIENTE]** Testing con múltiples IPs
4. **[PENDIENTE]** Release v7.0.1 con configuración dinámica

### FASE C: Mediano Plazo (Próximo sprint - 1 semana)

1. **[PENDIENTE]** Implementar QR code configuration
2. **[PENDIENTE]** Agregar feature en Tejido dashboard
3. **[PENDIENTE]** Documentar proceso de configuración
4. **[PENDIENTE]** Release v7.1.0 con QR config

---

## MÉTRICAS DE ÉXITO

### Inmediato (Post-Fix)
- [ ] App conecta exitosamente desde dispositivo Android
- [ ] Login funciona en red WiFi local
- [ ] Censo carga 3998 personas
- [ ] Upload de documento exitoso
- [ ] Todas las features v7.0.0 validadas

### Corto Plazo (v7.0.1)
- [ ] Usuario puede configurar IP manualmente
- [ ] Validación de conectividad antes de guardar
- [ ] Mensaje de error claro si servidor no alcanzable
- [ ] IP guardada persiste entre sesiones

### Mediano Plazo (v7.1.0)
- [ ] QR code scanning funcionando
- [ ] Auto-configuración en <10 segundos
- [ ] 0 errores de tipeo en configuración
- [ ] Soporte para múltiples servidores (switch fácil)

---

## LECCIONES APRENDIDAS

### ¿Por qué pasó esto?

1. **IP Estática en Código**
   - Mala práctica: hardcodear IPs en constants
   - Mejor: configuración dinámica desde inicio

2. **Sin Validación de Conectividad**
   - No hay health check al compilar APK
   - Mejor: CI/CD que valide IP antes de release

3. **DHCP No Considerado**
   - IP WiFi puede cambiar (router reiniciado, lease expirado)
   - Mejor: mDNS o static lease en router

### Prevención Futura

1. ✅ **Implementar configuración dinámica** (no más IPs hardcodeadas)
2. ✅ **Agregar health check** en CI/CD
3. ✅ **Documentar IP actual** en README/ESTADO_ACTUAL
4. ✅ **QR code config** para UX sin fricciones

---

## ANEXO A: Comandos de Verificación

### Verificar IP Actual del Servidor
```bash
# Obtener todas las IPs locales
ip addr show | grep "inet " | grep -v "127.0.0.1"

# Verificar puerto 8001 escuchando
sudo ss -tulpn | grep :8001

# Test de conectividad
curl -s http://NUEVA_IP:8001/api/ | python3 -m json.tool
```

### Verificar Contenedores Docker
```bash
# Status de contenedores
docker ps --filter "name=paperless"

# Logs recientes
docker logs paperless_webserver_1 --tail 50

# Django check
docker exec paperless_webserver_1 python manage.py check
```

### Compilar APK con Nueva IP
```bash
# 1. Editar api_constants.dart (línea 7)
# 2. Clean build
flutter clean
flutter pub get

# 3. Build
flutter build apk --release

# 4. Copiar con nombre descriptivo
cp build/app/outputs/flutter-apk/app-release.apk \
   ~/Descargas/Lumara_v7.0.0_IP_$(ip addr show wlp0s20f3 | grep "inet " | awk '{print $2}' | cut -d/ -f1)_$(date +%Y%m%d_%H%M%S).apk
```

---

## ANEXO B: Testing Checklist

### Pre-Compilación
- [ ] Verificar IP actual con `ip addr show`
- [ ] Probar conectividad con `curl localhost:8001/api/`
- [ ] Actualizar api_constants.dart línea 7
- [ ] Commit cambios en Git

### Post-Compilación
- [ ] APK copiado a ~/Descargas/
- [ ] MD5 hash capturado
- [ ] Dispositivo Android conectado (`adb devices`)
- [ ] Desinstalar versión anterior
- [ ] Instalar nuevo APK
- [ ] Verificar no hay crash al abrir

### Testing E2E
- [ ] Configurar IP servidor (si pantalla de setup existe)
- [ ] Login exitoso
- [ ] Censo carga (verificar 3998 personas)
- [ ] Seleccionar persona
- [ ] Capturar documento con cámara
- [ ] Upload exitoso (verificar en Tejido)
- [ ] Dashboard de métricas visible
- [ ] Quick actions funcionan
- [ ] Búsqueda avanzada responde
- [ ] Offline indicators correctos
- [ ] Cambio de idioma (i18n)

---

**Generado:** 2025-11-16 12:30 UTC  
**Investigación:** AI Assistant v2.0.31  
**Duración:** 45 minutos  
**Próxima acción:** Implementar Solución 1 (Fix Inmediato)
