# 📋 SPRINT 0.1 - FINALIZAR BUILD APK v1.0

**Fecha:** 2025-10-07
**Estado:** EN PROGRESO - Día 1 - Resolviendo errores de código

---

## ✅ COMPLETADO

### 1. Java JDK 17 Instalado ✅
```bash
✓ OpenJDK 17.0.13 descargado (187MB)
✓ Extraído en ~/jdk/jdk-17
✓ Configurado JAVA_HOME
✓ Agregado a PATH
✓ Persistido en ~/.bashrc

Verificación:
$ java -version
openjdk version "17.0.13" 2024-10-15
```

### 2. Android SDK Configurado ✅
```bash
✓ Command line tools en ~/Android/Sdk
✓ Licencias aceptadas (7 de 7)
✓ ANDROID_HOME configurado
✓ Agregado a PATH
✓ Persistido en ~/.bashrc

Verificación:
$ sdkmanager --version
9.0
```

### 3. Componentes SDK Instalados ✅
```bash
✓ platform-tools
✓ platforms;android-34
✓ platforms;android-35
✓ platforms;android-36
✓ platforms;android-28
✓ platforms;android-29
✓ platforms;android-33
✓ build-tools;34.0.0
✓ NDK 27.0.12077973
```

### 4. Flutter Doctor ✅
```bash
[✓] Flutter (Channel stable, 3.35.5)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Chrome - develop for the web
[✓] VS Code (version 1.104.2)
[✓] Connected device (2 available)
[✓] Network resources
```

### 5. Gradle Actualizado ✅
```bash
✓ Gradle 8.7
✓ Android Gradle Plugin 8.6.0
✓ Kotlin 2.1.0
```

### 6. Plugins Android Actualizados ✅
```bash
✓ flutter_scanner_cropper - namespace añadido
✓ scanlibrary - namespace añadido
✓ share_extend - namespace añadido
```

---

## 🔄 EN PROGRESO

### 7. Resolver Errores de Compilación

**Errores identificados:**

1. ❌ **Missing Package** `package:openscan/Utilities/Classes.dart`
   - Archivo no existe en el proyecto

2. ❌ **Drift toJson** signatures incorrectas
   - `PendingUpload.toJson()` needs `{ValueSerializer? serializer}`
   - `UploadHistoryData.toJson()` needs `{ValueSerializer? serializer}`

3. ❌ **DirectoryOS** no definido
   - Método `DirectoryOS()` no existe en clase OpenScan

4. ❌ **Type mismatch** en custom fields
   - `person.personId` es `int` pero se espera `String`
   - `person.familyId` es `int` pero se espera `String`
   - Similar para otros campos

5. ❌ **DriftWebStorage** no encontrado
   - Necesita importación correcta

6. ❌ **PopupMenuEntry** type error
   - Lista de widgets incorrectos

---

## ⏳ PENDIENTE

### 8. Fixing Código (En curso)
- [ ] Crear/importar `Utilities/Classes.dart`
- [ ] Corregir firmas `toJson()` en Drift
- [ ] Implementar/importar `DirectoryOS()`
- [ ] Convertir IDs a String con `.toString()`
- [ ] Importar DriftWebStorage correctamente
- [ ] Corregir PopupMenu types

### 9. Generar APK Final
```bash
$ flutter build apk --release --android-skip-build-dependency-validation
```

### 10. Verificar APK
```bash
$ ls -lh build/app/outputs/flutter-apk/app-release.apk
Esperado: ~45MB
```

---

## 📊 PROGRESO GENERAL

```
Día 1 - Setup + Troubleshooting
████████████████░░░░  80% completado

Tareas completadas: 6 de 10
Tiempo invertido: ~4 horas
Tiempo restante: ~1 hora
```

---

## 🎯 SIGUIENTE PASO

Resolver errores de código identificados:
1. Arreglar tipos de datos (int → String)
2. Corregir firmas de métodos Drift
3. Resolver imports faltantes
4. Rebuild APK

---

## 📝 NOTAS TÉCNICAS

### Configuración Persistida en ~/.bashrc:
```bash
# Java JDK 17
export JAVA_HOME="$HOME/jdk/jdk-17"
export PATH="$JAVA_HOME/bin:$PATH"

# Flutter SDK
export PATH="$PATH:$HOME/flutter/bin"

# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
```

### SDKs Descargados:
- OpenJDK 17: ~/jdk/jdk-17 (187MB)
- Android platforms: 28, 29, 33, 34, 35, 36
- NDK 27.0.12077973
- Build tools 34.0.0

### Espacio en Disco Utilizado:
- Total usado: ~2.5GB
- Espacio requerido adicional: ~200MB
- Total estimado: ~2.7GB

---

**Próxima actualización:** Cuando se resuelvan errores de código
