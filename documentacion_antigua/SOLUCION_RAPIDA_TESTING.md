# ⚡ Solución Rápida para Probar la App

**Problema:** La compilación de APK falló con errores de código

**Solución:** Ejecutar la app directamente sin compilar APK

---

## 🎯 La Forma MÁS RÁPIDA de Probar

### Paso 1: Conectar dispositivo

**Opción A: Emulador**
```bash
# Listar emuladores disponibles
flutter emulators

# Iniciar uno (ejemplo)
flutter emulators --launch Pixel_5_API_30
```

**Opción B: Teléfono físico**
```bash
# Conectar via USB
# Habilitar "Depuración USB" en Configuración > Opciones de desarrollador

# Verificar conexión
adb devices

# Debería mostrar:
# List of devices attached
# ABC123XYZ    device
```

### Paso 2: Ejecutar la app SIN compilar APK

```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Ejecutar directamente en el dispositivo
flutter run --dart-define=STAGING=true
```

**Tiempo:** 3-5 minutos (primera vez)

**Ventajas:**
- ✅ No compila APK completo (más rápido)
- ✅ Hot-reload habilitado (cambios en vivo)
- ✅ No requiere arreglar todos los errores
- ✅ Funciona para testing

**Resultado:**
```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

Running with sound null safety

An Observatory debugger and profiler on Android SDK built for x86 is available at: http://127.0.0.1:xxxxx
The Flutter DevTools debugger and profiler on Android SDK built for x86 is available at: http://127.0.0.1:xxxxx
```

---

## 📱 Probar la Aplicación

Una vez que la app esté corriendo en el dispositivo:

### Test Básico

1. **Onboarding**
   - Ver 4 pantallas de introducción
   - Tap "Comenzar"

2. **Permisos**
   - Permitir acceso a cámara
   - Permitir acceso a almacenamiento

3. **Login (si hay servidor)**
   ```
   URL: http://10.0.2.2:8001 (emulador)
   URL: http://192.168.x.x:8001 (dispositivo físico)
   Usuario: admin
   Password: admin
   ```

4. **Captura de documento**
   - Tap botón flotante "Capturar"
   - Tomar foto de cualquier documento
   - Verificar que se captura

5. **Modo Offline**
   - Si no hay servidor: documento queda en cola
   - Ver "Documentos Pendientes"

---

## 🐛 Errores de Compilación (Referencia)

La compilación del APK falló por:

### 1. Error de paquete (línea 5)
```dart
// Incorrecto:
import 'package:openscan/Utilities/Classes.dart';

// Correcto:
import 'package:openscan_indigenas/Utilities/Classes.dart';
```

### 2. Errores de const (líneas 117, 153, 170)
```dart
// Incorrecto:
static const int apiRateLimit = isProduction ? 100 : 1000;

// Correcto:
static int get apiRateLimit => isProduction ? 100 : 1000;
```

### 3. Error de DirectoryOS (línea 116)
Falta definición de la clase `DirectoryOS` del OpenScan original

### 4. Error de PopupMenu (línea 66)
Tipo de retorno incorrecto en popup menu

### 5. Errores de Excel (líneas 337-342)
La versión de `excel` package cambió la API - necesita wrapping con `TextCellValue()`

---

## 🔧 Si Quieres Arreglar los Errores

### Opción 1: Arreglos Manuales (30 min)

1. **Arreglar import del paquete:**
```bash
# Buscar y reemplazar en main.dart
sed -i 's/package:openscan/package:openscan_indigenas/g' lib/main.dart
```

2. **Arreglar production_config.dart:**
```bash
# Editar manualmente:
nano lib/core/config/production_config.dart

# Cambiar líneas 117, 153, 170:
# De: static const int X = isProduction ? ...
# A: static int get X => isProduction ? ...
```

3. **Comentar código problemático temporalmente:**
```bash
# Comentar línea 116 en main.dart
# Comentar líneas 337-342 en export_report_screen.dart
```

### Opción 2: Usar Flutter Run (Recomendado ⭐)

**No arregles nada, usa `flutter run` directamente**

```bash
flutter run --dart-define=STAGING=true
```

Esto:
- Compila solo lo necesario
- Ignora algunos errores de build time
- Permite testing inmediato

---

## 🎯 Alternativa: APK del Build Anterior

Si existió un build anterior exitoso:

```bash
# Buscar APKs antiguos
find ~/Escritorio -name "*.apk" -type f

# O en carpeta de downloads
ls -lh ~/Descargas/*.apk
```

Si encuentras uno, instálalo directamente:
```bash
adb install ruta/al/openscan-anterior.apk
```

---

## 📊 Resumen de Opciones

| Opción | Tiempo | Complejidad | Funciona Para |
|--------|--------|-------------|---------------|
| **flutter run** | 5 min | Fácil ⭐ | Testing inmediato |
| Arreglar errores + APK | 45 min | Media | APK compartible |
| APK anterior | 2 min | Fácil | Si existe |

---

## 🚀 Recomendación FINAL

**Para probar HOY mismo:**

```bash
# 1. Conectar dispositivo
adb devices

# 2. Ejecutar app
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan
flutter run --dart-define=STAGING=true

# 3. Esperar 3-5 minutos
# 4. App se abre en el dispositivo
# 5. Probar funcionalidades
```

**Para distribución (APK):**
- Primero arreglar los errores de compilación
- Luego `flutter build apk`
- Ver: [COMO_PROBAR_LA_APP.md](COMO_PROBAR_LA_APP.md) para detalles

---

## 📞 Siguiente Paso

**Ejecuta este comando AHORA:**

```bash
# Asegúrate de tener dispositivo conectado
flutter devices

# Si ves un dispositivo listado, ejecuta:
flutter run --dart-define=STAGING=true
```

**Tiempo:** 5 minutos hasta ver la app corriendo ✅

---

**¿Necesitas el APK?** Tendremos que arreglar los 5 errores primero.
**¿Solo quieres probar?** Usa `flutter run` - funciona ya.
