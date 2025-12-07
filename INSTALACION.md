# 📱 Instalación de Lumara Scan v4.0.0

## 🚀 INSTALACIÓN AUTOMÁTICA (Recomendado)

### Método 1: Script de instalación

```bash
./install_apk.sh
```

El script automáticamente:
- ✅ Verifica integridad del APK (MD5)
- ✅ Detecta dispositivo Android conectado
- ✅ Desinstala versiones anteriores
- ✅ Instala Lumara Scan v4.0.0
- ✅ Opción de iniciar app automáticamente

---

## 📦 INSTALACIÓN MANUAL

### Método 2: ADB manual

```bash
# Verificar dispositivo conectado
adb devices

# Desinstalar versión anterior (opcional)
adb uninstall com.ethereal.lumara

# Instalar APK
adb install -r LumaraScan_v4.0.0_debug.apk
```

### Método 3: Instalación directa en dispositivo

1. Copiar `LumaraScan_v4.0.0_debug.apk` al dispositivo
2. Habilitar "Instalar apps desconocidas" en Configuración
3. Tocar el archivo APK y seguir instrucciones

---

## 📍 UBICACIÓN DEL APK

```
/home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara/LumaraScan_v4.0.0_debug.apk
```

### Verificación de integridad:
```bash
md5sum LumaraScan_v4.0.0_debug.apk
```

**MD5 esperado:** `29dad07803ba14da4782194f82a3b7bb`
**Tamaño:** 159 MB

---

## ⚙️ CONFIGURACIÓN POST-INSTALACIÓN

### 1. Primer inicio
- Abrir Lumara Scan
- Completar onboarding (si es primera vez)
- Iniciar sesión con credenciales Tejido

### 2. Configurar servidor Tejido
- **URL del servidor:** `http://192.168.40.17:8001`
- **Usuario:** admin
- **Contraseña:** [tu contraseña]

### 3. Activar sincronización automática
- En **HomeScreen**, tocar icono **sync** (esquina superior derecha)
- Se activará sincronización cada 15 minutos
- Aparecerá notificación persistente durante sync

### 4. Permisos requeridos
La app solicitará los siguientes permisos:

- ✅ **Almacenamiento** (leer/escribir documentos)
- ✅ **Cámara** (escanear documentos)
- ✅ **Internet** (conectar a Tejido)
- ✅ **Notificaciones** (estado de sincronización)
- ✅ **Foreground service** (sync en background)

**IMPORTANTE:** Conceder todos los permisos para funcionamiento completo.

---

## 🔧 REQUISITOS DEL SISTEMA

### Mínimos:
- Android 7.0+ (API 24+)
- 200 MB de almacenamiento libre
- Conexión a Internet (WiFi o datos móviles)

### Recomendados:
- **Android 14+ (API 36)** ⭐ Recomendado
- 500 MB de almacenamiento libre
- Conexión WiFi estable para sincronización
- Batería > 20% o enchufado

---

## 🛠️ SOLUCIÓN DE PROBLEMAS

### Error: "App no instalada"
**Causa:** Versión anterior corrupta
**Solución:**
```bash
adb uninstall com.ethereal.lumara
adb install -r LumaraScan_v4.0.0_debug.apk
```

### Error: "Parse error"
**Causa:** APK corrupto
**Solución:** Descargar APK nuevamente y verificar MD5

### Error: "Dispositivo no autorizado"
**Causa:** USB Debugging no autorizado
**Solución:**
1. Habilitar "Depuración USB" en Configuración → Opciones de desarrollador
2. Tocar "Permitir" en popup de autorización del dispositivo

### App se cierra inmediatamente
**Causa:** Permisos no concedidos
**Solución:**
1. Configuración → Apps → Lumara Scan → Permisos
2. Conceder todos los permisos solicitados

### Sincronización no funciona
**Causa:** Servidor Tejido no accesible
**Solución:**
1. Verificar IP del servidor: `ping 192.168.40.17`
2. Verificar Tejido activo: `http://192.168.40.17:8001` en navegador
3. En app, ir a Configuración y actualizar URL si es necesario

### Notificación "Esperando conexión a Internet"
**Causa:** Sin conectividad o servidor no accesible
**Solución:**
1. Verificar WiFi/datos móviles activos
2. Verificar conectividad al servidor Tejido
3. La app reintentar automáticamente al recuperar conexión

---

## 📊 VERIFICACIÓN DE INSTALACIÓN

### Comprobar versión instalada:
```bash
adb shell dumpsys package com.ethereal.lumara | grep versionName
```

**Output esperado:** `versionName=4.0.0`

### Comprobar permisos concedidos:
```bash
adb shell dumpsys package com.ethereal.lumara | grep "granted=true"
```

### Ver logs en tiempo real:
```bash
adb logcat -s flutter:V
```

---

## 🔄 ACTUALIZACIÓN DESDE v3.x.x

### Pasos para actualizar:

1. **Desinstalar versión anterior:**
   ```bash
   adb uninstall com.ethereal.lumara
   ```

2. **Instalar v4.0.0:**
   ```bash
   ./install_apk.sh
   ```

3. **Verificar migración de datos:**
   - Las credenciales se preservan (FlutterSecureStorage)
   - La base de datos local se mantiene
   - Los documentos pendientes se conservan

**NOTA:** Primera sincronización después de actualizar puede tardar más tiempo.

---

## 📞 SOPORTE

### Logs de la app:
```bash
# Ver todos los logs
adb logcat > lumara_logs.txt

# Ver solo errores
adb logcat *:E > lumara_errors.txt
```

### Información del sistema:
```bash
adb shell getprop ro.build.version.sdk    # SDK version
adb shell getprop ro.build.version.release # Android version
adb shell getprop ro.product.model         # Modelo dispositivo
```

### Reportar issues:
Incluir la siguiente información:
- Versión Android
- Modelo dispositivo
- Logs de error
- Pasos para reproducir el problema

---

## 🎯 FUNCIONALIDADES v4.0.0

### ✅ Nuevas funcionalidades:
- Sincronización automática en background (cada 15 min)
- Retry automático con exponential backoff
- Validación de servidor con latency check
- Persistencia mejorada de app (80-90%)
- Toggle de auto-sync en HomeScreen
- Notificaciones persistentes con estado

### ✅ Funcionalidades existentes:
- Búsqueda por número de documento
- Recorte interactivo de imágenes
- Compresión automática de imágenes
- Compartir PDF/imágenes
- Base de datos: 3,997 personas
- Integración Tejido-ngx completa

---

**Versión:** 4.0.0+4
**Fecha:** 8 Octubre 2025
**Compatibilidad:** Android 7.0+ (SDK 24+)
**Optimizado para:** Android 14+ (SDK 36)
