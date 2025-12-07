# 🔍 DIAGNÓSTICO COMPLETO - Build Flutter Bloqueado

**Fecha:** 2025-10-06 22:10
**Problema:** Flutter build APK falla sin output después de warnings de git

---

## 🚨 PROBLEMA IDENTIFICADO

### Síntomas Observados

```bash
$ flutter build apk --release
fatal: no es un repositorio git (ni ninguno de los directorios superiores): .git
fatal: no es un repositorio git (ni ninguno de los directorios superiores): .git
[cursor se queda colgado, sin más output]
```

### Causa Raíz

**Flutter Snap está ROTO y no puede ejecutar comandos correctamente:**

1. ✅ Flutter instalado: `/snap/bin/flutter` existe
2. ❌ **Flutter --version se cuelga** (no muestra output)
3. ❌ **flutter pub get NO instala dependencias**
4. ❌ **Falta .dart_tool/** (dependencias no resueltas)
5. ❌ **Falta pubspec.lock** (lock file no creado)
6. ❌ **flutter build se cuelga** después de git warnings

### Archivos Faltantes Críticos

```
❌ .dart_tool/                    ← Configuración de Dart/Flutter
❌ .dart_tool/package_config.json ← Resolución de paquetes
❌ pubspec.lock                    ← Lock file de dependencias
❌ .flutter-plugins                ← Plugins Flutter
❌ .flutter-plugins-dependencies   ← Deps de plugins
```

**Sin estos archivos, Flutter NO PUEDE compilar.**

---

## 🔬 ANÁLISIS TÉCNICO

### Por qué Flutter Snap está roto

1. **Git Repository Detection:**
   - Flutter intenta obtener información de git al iniciar
   - Ejecuta `git` commands que fallan
   - Se queda esperando respuesta indefinidamente

2. **Snap Isolation:**
   - Snap contenedoriza Flutter
   - Puede tener problemas de permisos
   - No puede acceder correctamente al filesystem

3. **Inicialización Incompleta:**
   - Flutter descargó 1.3GB pero no completó setup
   - Falta inicialización del SDK
   - Comandos no están listos para usar

---

## ✅ SOLUCIONES PROPUESTAS

### Solución 1: Desinstalar y Reinstalar Flutter (MÁS CONFIABLE)

```bash
# 1. Desinstalar Snap
sudo snap remove flutter

# 2. Instalar Flutter manualmente desde Git
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 3. Agregar a PATH
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

# 4. Verificar
flutter doctor

# 5. Aceptar licencias Android
flutter doctor --android-licenses

# 6. Ir al proyecto y build
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
flutter pub get
flutter build apk --release
```

**Tiempo estimado:** 15-20 minutos

---

### Solución 2: Usar Android Studio para Build (ALTERNATIVA)

Si tienes Android Studio instalado:

```bash
# 1. Abrir Android Studio
android-studio

# 2. File → Open → Seleccionar carpeta Lumara

# 3. Android Studio instalará dependencias automáticamente

# 4. Build → Flutter → Build APK
```

---

### Solución 3: Build en Otro Sistema (ÚLTIMA OPCIÓN)

Si ninguna solución funciona en esta máquina:

1. Comprimir proyecto:
```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara
tar -czf Lumara.tar.gz Lumara/
```

2. Transferir a máquina con Flutter funcional

3. Build allí y traer APK de vuelta

---

### Solución 4: Docker Build (EXPERIMENTAL)

Usar Docker para aislar Flutter:

```bash
# Crear Dockerfile
cat > Dockerfile <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    openjdk-11-jdk wget

RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
ENV PATH="/flutter/bin:$PATH"

RUN flutter doctor
RUN flutter config --no-analytics

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build apk --release

CMD ["cat", "build/app/outputs/flutter-apk/app-release.apk"]
EOF

# Build
docker build -t lumara-builder .

# Extract APK
docker run --rm lumara-builder cat build/app/outputs/flutter-apk/app-release.apk > app-release.apk
```

---

## 🎯 RECOMENDACIÓN INMEDIATA

### OPCIÓN A: Reinstalar Flutter (20 minutos)

```bash
# Ejecutar en terminal
sudo snap remove flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter doctor -v
flutter doctor --android-licenses
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
flutter clean
flutter pub get
flutter build apk --release
```

**Ventajas:**
- ✅ Solución permanente
- ✅ Flutter completamente funcional
- ✅ Actualizaciones fáciles

**Desventajas:**
- ⏱️ Toma 20 minutos
- 💾 Ocupa ~3GB

---

### OPCIÓN B: Usar tu terminal directamente (SI FUNCIONA ALLÍ)

El error que mostraste puede ser un problema de cómo estoy ejecutando los comandos remotamente.

**Intenta TÚ MISMO en tu terminal:**

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# 1. Limpiar
flutter clean

# 2. Pub get (espera 2-3 minutos)
flutter pub get

# 3. Verificar que se creó .dart_tool
ls -la .dart_tool/

# 4. Build (espera 5-10 minutos)
flutter build apk --release

# 5. Verificar APK
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

**Si ves output en tu terminal, significa que funciona para ti pero no para mí remotamente.**

---

## 📱 CONFIGURACIÓN LUMARA ↔ TEJIDO

### Archivos de Configuración

#### 1. URL de Tejido

**Archivo:** `lib/core/constants/api_constants.dart`

```dart
static const String defaultBaseUrl = 'http://10.0.2.2:8001';
```

**Cambiar según dispositivo:**

| Dispositivo | URL |
|-------------|-----|
| Emulador Android | `http://10.0.2.2:8001` |
| Dispositivo en misma WiFi | `http://192.168.X.X:8001` |
| Servidor remoto | `https://tejido.ejemplo.com` |

#### 2. Token de Autenticación

**Opción A: Login dinámico (IMPLEMENTADO)**
- Usuario introduce credenciales en LoginScreen
- App obtiene token automáticamente

**Opción B: Token hardcoded (para testing)**

Editar `lib/core/config/env_config.dart`:
```dart
static const String tejidoApiToken = 'TU_TOKEN_AQUI';
```

### Obtener IP del servidor Tejido

```bash
# En el servidor donde corre Tejido
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Exponer Tejido en la red

Editar `docker-compose.yml` de Tejido:

```yaml
services:
  webserver:
    ports:
      - "0.0.0.0:8001:8000"  # Exponerlo a toda la red
```

Reiniciar:
```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/tejido-ngx
docker compose down
docker compose up -d
```

### Configurar Firewall

```bash
# Permitir puerto 8001
sudo ufw allow 8001/tcp
```

### Probar Conexión desde Dispositivo

En el dispositivo Android, abrir navegador:
```
http://192.168.X.X:8001
```

Debería cargar la interfaz de Tejido.

---

## 🐛 DEBUGGING SI BUILD FALLA

### Ver logs detallados

```bash
flutter build apk --release --verbose 2>&1 | tee build.log
```

### Verificar dependencias específicas

```bash
flutter pub deps | grep drift
flutter pub deps | grep workmanager
```

### Limpiar completamente

```bash
flutter clean
rm -rf .dart_tool/
rm -rf build/
rm pubspec.lock
flutter pub get
```

### Verificar versión de Java

```bash
java -version
# Debería ser Java 11 o superior
```

### Verificar Android SDK

```bash
flutter doctor -v
```

Buscar:
```
[✓] Android toolchain - develop for Android devices
```

---

## 📊 CHECKLIST POST-DIAGNÓSTICO

### Estado Actual

- [x] Código fuente completo
- [x] Archivo generado (app_database.g.dart)
- [x] Census data presente
- [x] Flutter SDK instalado (pero roto)
- [ ] ❌ Dependencias instaladas
- [ ] ❌ .dart_tool/ creado
- [ ] ❌ pubspec.lock creado
- [ ] ❌ Build funcional

### Bloqueadores

1. 🔴 **CRÍTICO:** Flutter Snap no funciona correctamente
2. 🔴 **CRÍTICO:** No se pueden instalar dependencias
3. 🔴 **CRÍTICO:** No se puede compilar sin dependencias

### Próximos Pasos

1. **Ejecutar Solución 1** (reinstalar Flutter manualmente)
   - O intentar build desde tu terminal directamente

2. **Una vez Flutter funcione:**
   - `flutter pub get` creará .dart_tool/
   - `flutter build apk` compilará correctamente
   - APK estará en build/app/outputs/

3. **Configurar conexión Tejido:**
   - Cambiar IP en api_constants.dart
   - Exponer Tejido en red
   - Probar desde navegador del dispositivo

---

## 🎯 COMANDO FINAL PARA TI

**Opción 1: Reinstalar Flutter (recomendado)**

```bash
# Copia y pega todo esto en tu terminal:

sudo snap remove flutter && \
cd ~ && \
git clone https://github.com/flutter/flutter.git -b stable --depth 1 && \
export PATH="$PATH:$HOME/flutter/bin" && \
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc && \
source ~/.bashrc && \
flutter doctor --android-licenses && \
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara && \
flutter clean && \
flutter pub get && \
flutter build apk --release
```

**Opción 2: Intentar directamente (más rápido si funciona)**

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
flutter clean
flutter pub get
flutter build apk --release
```

---

**Si ninguna opción funciona, avísame y probaremos Docker o Android Studio.**
