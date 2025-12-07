# 🔨 Compilación del APK en Proceso

**Estado:** Compilando APK de pruebas...

---

## 📊 Estado Actual

```bash
# Comando ejecutándose:
flutter build apk --debug --dart-define=STAGING=true

# Tiempo estimado: 5-10 minutos (primera vez)
# Próximas compilaciones: 2-3 minutos
```

---

## ✅ Progreso Completado

1. ✅ Detectado error de dependencias duplicadas
2. ✅ Eliminado `pdf: ^3.10.7` duplicado (manteniendo ^3.11.1)
3. ✅ Eliminado `path_provider: ^2.1.1` duplicado (manteniendo ^2.1.4)
4. ✅ `flutter pub get` ejecutado exitosamente
5. ✅ Dependencias instaladas: excel, fl_chart, printing, share_plus
6. 🔄 Compilando APK...

---

## ⏱️ Qué Está Pasando Ahora

Flutter está:
1. Generando código de Drift (ORM para base de datos)
2. Compilando código Dart a código nativo (ARM/x86)
3. Empaquetando assets (imágenes, fuentes, datos del censo)
4. Generando APK debug con símbolos de debugging
5. Firmando APK con certificado de debug

**Esto es NORMAL y toma tiempo la primera vez.**

---

## 🔍 Cómo Verificar el Progreso

### Opción 1: En esta terminal

Espera a que el comando termine. Verás:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XX.XMB)
```

### Opción 2: Otra terminal

```bash
# Ver progreso en tiempo real
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
flutter build apk --debug --dart-define=STAGING=true
```

### Opción 3: Ver logs

```bash
# Ver archivos generados
ls -lh build/app/intermediates/ 2>/dev/null || echo "Aún compilando..."

# Ver uso de CPU (debe estar alto)
top -bn1 | grep -E "java|gradle|flutter"
```

---

## 📱 Qué Obtendrás

### APK de Debug/Staging

**Ubicación final:**
```
build/app/outputs/flutter-apk/app-debug.apk
```

**Características:**
- ✅ Modo debug habilitado
- ✅ Símbolos de debugging incluidos
- ✅ Configuración STAGING activada
- ✅ No requiere certificados SSL configurados
- ✅ Acepta URLs de desarrollo/staging
- ⚠️ NO optimizado (más grande y más lento)
- ⚠️ NO para usuarios finales (solo testing)

**Tamaño esperado:** 40-50 MB

---

## 🎯 Próximos Pasos

### 1. Cuando termine la compilación

```bash
# Verificar que existe
ls -lh build/app/outputs/flutter-apk/app-debug.apk

# Copiar a escritorio
cp build/app/outputs/flutter-apk/app-debug.apk ~/Escritorio/lumara-test.apk

# Ver info del APK
file build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Instalar en dispositivo

**Opción A: Via ADB (recomendado)**
```bash
# Conectar teléfono via USB
# Habilitar "Depuración USB" en el teléfono

# Verificar dispositivo conectado
adb devices

# Instalar
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Opción B: Via archivo**
```bash
# Copiar APK a carpeta compartida
cp build/app/outputs/flutter-apk/app-debug.apk ~/Escritorio/lumara-test.apk

# Enviar a teléfono via:
# - Email
# - WhatsApp
# - Google Drive
# - Cable USB (copiar a /sdcard/Download/)

# En el teléfono:
# 1. Abrir archivo
# 2. Permitir "Fuentes desconocidas"
# 3. Instalar
```

### 3. Probar la aplicación

Ver guía completa: **[COMO_PROBAR_LA_APP.md](COMO_PROBAR_LA_APP.md)**

```
1. Abrir app "Lumara Indígenas"
2. Completar onboarding (4 pantallas)
3. Permitir permisos (cámara, almacenamiento)
4. Login:
   - URL: http://10.0.2.2:8001 (emulador)
   - URL: http://192.168.x.x:8001 (dispositivo físico)
   - Usuario: admin
   - Password: admin
5. Capturar documento de prueba
6. Asignar a persona del censo
7. Verificar sincronización
```

---

## ⚠️ Problemas Comunes

### Compilación falla con error de memoria

```bash
# Incrementar memoria para Gradle
export GRADLE_OPTS="-Xmx4g -XX:MaxPermSize=1024m"

# Intentar de nuevo
flutter build apk --debug
```

### Compilación falla con error de permisos

```bash
# Dar permisos a gradlew
chmod +x android/gradlew

# Limpiar y reintentar
flutter clean
flutter pub get
flutter build apk --debug
```

### "Task assembleDebug FAILED"

```bash
# Ver error completo
flutter build apk --debug --verbose

# Limpiar build anterior
cd android
./gradlew clean
cd ..

# Reintentar
flutter build apk --debug
```

---

## 📊 Monitoreo del Proceso

### Ver uso de recursos

```bash
# CPU y memoria
htop

# Espacio en disco
df -h

# Procesos de Flutter/Gradle
ps aux | grep -E "flutter|gradle|java"
```

### Tamaño de carpetas

```bash
# Ver tamaño de build/
du -sh build/

# Ver archivos más grandes
du -h build/ | sort -rh | head -20
```

---

## 🚀 Optimizaciones Futuras

Para compilaciones más rápidas:

### 1. Habilitar Gradle Daemon
```bash
echo "org.gradle.daemon=true" >> ~/.gradle/gradle.properties
echo "org.gradle.parallel=true" >> ~/.gradle/gradle.properties
echo "org.gradle.configureondemand=true" >> ~/.gradle/gradle.properties
```

### 2. Incrementar memoria
```bash
echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=1024m" >> ~/.gradle/gradle.properties
```

### 3. Usar build cache
```bash
# En android/gradle.properties
android.enableBuildCache=true
```

---

## 📝 Checklist Post-Compilación

Cuando termine la compilación:

- [ ] APK creado en `build/app/outputs/flutter-apk/app-debug.apk`
- [ ] APK tiene tamaño razonable (40-50 MB)
- [ ] APK es instalable (`adb install ...` funciona)
- [ ] App abre sin crashes
- [ ] Onboarding se muestra
- [ ] Permisos se solicitan correctamente
- [ ] Login screen funciona
- [ ] Cámara abre correctamente

---

## 🔗 Referencias

- **[COMO_PROBAR_LA_APP.md](COMO_PROBAR_LA_APP.md)** - Guía completa de testing
- **[USER_MANUAL_ES.md](docs/USER_MANUAL_ES.md)** - Manual de usuario
- **[FIELD_GUIDE_ES.md](docs/FIELD_GUIDE_ES.md)** - Guía rápida de campo
- **[TESTING.md](docs/TESTING.md)** - Guía de testing técnico

---

## ⏰ Tiempo Estimado por Paso

| Paso | Tiempo Primera Vez | Próximas Veces |
|------|-------------------|----------------|
| flutter pub get | 1-2 min | 10-30 seg |
| Generar código Drift | 30-60 seg | 10-20 seg |
| Compilar Dart → Native | 3-5 min | 1-2 min |
| Empaquetar assets | 1-2 min | 30 seg |
| Generar APK | 30-60 seg | 10-20 seg |
| **TOTAL** | **6-11 min** | **2-4 min** |

---

## 💡 Tip

**Para desarrollo activo (con hot-reload):**

En lugar de compilar APK cada vez, usa:
```bash
flutter run --dart-define=STAGING=true
```

Esto:
- Inicia la app en el dispositivo conectado
- Permite hot-reload (Ctrl+S para aplicar cambios)
- Más rápido que compilar APK completo
- Ideal para testing iterativo

---

**Estado:** ⏳ Compilando... (verifica progreso en la terminal donde ejecutaste el comando)

**Próximo paso:** Cuando veas `✓ Built build/app/outputs/flutter-apk/app-debug.apk`, seguir pasos de instalación arriba.
