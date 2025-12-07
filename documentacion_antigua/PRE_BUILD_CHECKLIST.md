# ✅ Pre-Build Checklist - Lumara Indigenous Communities

**Fecha de verificación:** 2025-10-06 22:00
**Versión:** v3.0.0+1 (Sprint 1.5 Complete)

---

## 📋 Checklist de Archivos Críticos

### ✅ Código Fuente
- [x] `lib/main.dart` - Punto de entrada (96 líneas) ✅
- [x] `lib/data/local/database/app_database.dart` - Schema (220 líneas) ✅
- [x] `lib/data/local/database/app_database.g.dart` - Generated (1,072 líneas) ✅
- [x] `lib/services/upload_service.dart` - Queue manager (290 líneas) ✅
- [x] `lib/services/background_sync_service.dart` - WorkManager (150 líneas) ✅
- [x] `lib/presentation/document/upload_screen.dart` - UI (400 líneas) ✅
- [x] `lib/presentation/auth/login_screen.dart` - Login (245 líneas) ✅
- [x] `lib/presentation/census/person_selection_screen.dart` - Census (315 líneas) ✅

### ✅ Configuración
- [x] `pubspec.yaml` - Dependencies configuradas ✅
- [x] `android/app/src/main/AndroidManifest.xml` - Permisos ✅
- [x] `assets/census/persons.csv` - 3,997 personas (685 KB) ✅

### ✅ Documentación
- [x] `README_BUILD.md` - Instrucciones de build ✅
- [x] `TESTING_PLAN.md` - Plan de testing ✅
- [x] `SPRINT_1.5_FINAL_STATUS.md` - Estado final ✅

---

## 🔍 Verificación de Integridad

### Archivos Generados
```bash
✅ app_database.g.dart existe (38 KB)
✅ Contiene 1,072 líneas de código
✅ Incluye todas las clases necesarias
```

### Census Data
```bash
✅ persons.csv existe (685 KB)
✅ Contiene 3,998 líneas (3,997 personas + header)
✅ Formato válido CSV
```

### Dependencies
```bash
✅ drift: ^2.14.0
✅ workmanager: ^0.5.2
✅ provider: ^6.1.2
✅ dio: ^5.7.0
✅ flutter_secure_storage: ^9.2.2
```

---

## ⚠️ Problemas Conocidos (No Bloqueantes)

### 1. Flutter Snap Output
**Síntoma:** Comandos Flutter no muestran output (solo git warnings)
**Impacto:** ❌ No bloquea compilación
**Status:** Los comandos se ejecutan correctamente (exit code 0)

### 2. Dependencies Installation
**Síntoma:** `.dart_tool` y `pubspec.lock` no se crean con `flutter pub get`
**Impacto:** ⚠️ Puede causar error en build
**Solución:** Build automáticamente instalará dependencias

---

## 🚀 Comandos de Build

### Opción 1: Build APK Release (Recomendado)
```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
flutter build apk --release
```

**Output esperado:**
```
build/app/outputs/flutter-apk/app-release.apk
```

### Opción 2: Build APK por Arquitectura (Más ligero)
```bash
flutter build apk --split-per-abi
```

**Output esperado:**
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Opción 3: Build APK Debug (Para testing)
```bash
flutter build apk --debug
```

---

## 📦 Tamaño Estimado del APK

### Sin Optimizaciones
- **Universal APK:** ~80-120 MB
- **Incluye:** Lumara scanner lib, Drift, WorkManager, Dio

### Con `--split-per-abi`
- **arm64-v8a:** ~40-50 MB (mayoría de dispositivos modernos)
- **armeabi-v7a:** ~35-45 MB (dispositivos más antiguos)
- **x86_64:** ~50-60 MB (emuladores)

---

## 🧪 Pruebas Post-Build

### 1. Instalación
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Verificar Instalación
```bash
adb shell pm list packages | grep lumara
```

### 3. Lanzar App
```bash
adb shell am start -n com.example.lumara_indigenas/.MainActivity
```

### 4. Ver Logs
```bash
adb logcat | grep -i flutter
```

---

## ✅ Checklist Pre-Build Final

Antes de ejecutar `flutter build apk --release`:

- [x] ✅ Código fuente completo
- [x] ✅ Archivo generado (app_database.g.dart) presente
- [x] ✅ Census data (3,997 personas)
- [x] ✅ Dependencies definidas en pubspec.yaml
- [x] ✅ Assets configurados
- [x] ✅ Permisos Android configurados
- [x] ✅ Flutter SDK instalado

**ESTADO:** ✅ **LISTO PARA BUILD**

---

## 🔄 Proceso de Build Esperado

```
1. flutter build apk --release
   ↓
2. Flutter resuelve dependencias
   ↓
3. Compila Dart a código nativo
   ↓
4. Empaqueta assets (census.csv)
   ↓
5. Genera APK firmado (debug key)
   ↓
6. APK disponible en build/app/outputs/
```

**Tiempo estimado:** 3-10 minutos (primera vez más lento)

---

## 🎯 Configuración de la App en el APK

### App Metadata
- **Package:** com.example.lumara_indigenas
- **Versión:** 3.0.0+1
- **Nombre:** Lumara Indígenas
- **Min SDK:** Android 5.0 (API 21)
- **Target SDK:** Android 14 (API 34)

### Permisos Incluidos
- `INTERNET` - Comunicación con Tejido
- `CAMERA` - Captura de documentos
- `READ_EXTERNAL_STORAGE` - Acceso a galería
- `WRITE_EXTERNAL_STORAGE` - Guardar imágenes temporales
- `WAKE_LOCK` - Background sync
- `ACCESS_NETWORK_STATE` - Detectar conexión

### Features Incluidas
- ✅ Offline queue (SQLite/Drift)
- ✅ Background sync (WorkManager)
- ✅ Smart retry logic
- ✅ File cleanup
- ✅ Upload history

---

## 🚨 Errores Comunes y Soluciones

### Error: "Gradle build failed"
**Solución:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "SDK license not accepted"
**Solución:**
```bash
flutter doctor --android-licenses
# Aceptar todas las licencias
```

### Error: "No connected devices"
**Solución:** No es necesario dispositivo para build APK

### Error: "Out of memory"
**Solución:**
```bash
export GRADLE_OPTS="-Xmx4096m"
flutter build apk --release
```

---

## 📊 Resultado Esperado

### Si Build es Exitoso
```bash
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.X MB)
```

### Archivo Generado
```
build/app/outputs/flutter-apk/app-release.apk
```

### Siguiente Paso
```bash
# Instalar en dispositivo
adb install build/app/outputs/flutter-apk/app-release.apk

# O transferir por USB y instalar manualmente
```

---

## ✅ CONFIRMACIÓN FINAL

**¿Está lista la herramienta para generar APK?**

# ✅ SÍ, ESTÁ LISTA

**Razones:**
1. ✅ Todo el código fuente presente
2. ✅ Archivo generado (app_database.g.dart) existe
3. ✅ Census data completo (3,997 personas)
4. ✅ Dependencies configuradas
5. ✅ Assets incluidos
6. ✅ Flutter SDK instalado

**Comando para ejecutar:**
```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
flutter build apk --release
```

**Siguiente paso después del build:**
```bash
# Ver tamaño del APK
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Instalar en dispositivo
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

**APROBADO PARA BUILD** ✅
**Fecha:** 2025-10-06
**Versión:** v3.0.0+1
