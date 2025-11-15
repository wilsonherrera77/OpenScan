# ✅ CHECKLIST PRE-COMPILACIÓN - Lumara Scan

## ⚠️ EJECUTAR ESTE CHECKLIST ANTES DE CADA COMPILACIÓN

**Propósito:** Evitar errores comunes que requieren recompilaciones y garantizar que cada versión funcione correctamente en el primer intento.

---

## 1️⃣ VALIDACIÓN DE CONFIGURACIÓN

### URL por Defecto
```bash
grep -n "defaultBaseUrl" lib/core/constants/api_constants.dart
```
**Debe mostrar:**
```
5:  static const String defaultBaseUrl = 'http://192.168.40.17:8001';
```

- [ ] ✅ URL es `http://192.168.40.17:8001`
- [ ] ✅ NO es `http://10.0.2.2:8001` (emulador)

### Versión de la App
```bash
grep "version:" pubspec.yaml
```

- [ ] ✅ Versión actualizada correctamente (ejemplo: `4.0.4+8`)
- [ ] ✅ Build number incrementado

### Archivos de Firma
```bash
ls -la android/lumara-release-key.jks
ls -la android/key.properties
```

- [ ] ✅ `lumara-release-key.jks` existe
- [ ] ✅ `key.properties` existe
- [ ] ✅ `key.properties` contiene credenciales correctas

---

## 2️⃣ VALIDACIÓN DE SEGURIDAD

### Validación HTTPS para Red Local
```bash
grep -A 30 "isLocalNetwork" lib/data/datasources/paperless_api_client.dart
```

**Verificar que incluye:**
```dart
final isLocalNetwork =
  host == 'localhost' ||
  host == '127.0.0.1' ||
  host.startsWith('192.168.') ||
  host.startsWith('10.') ||
  host.startsWith('172.16.') ||
  // ... etc
```

- [ ] ✅ Validación permite IPs locales (192.168.x.x, 10.x.x.x, etc.)
- [ ] ✅ Validación requiere HTTPS para IPs públicas
- [ ] ✅ Logging incluye advertencia para HTTP local

### Validación de Formato URL
```bash
grep -B 5 -A 10 "Invalid URL format" lib/presentation/auth/login_screen.dart
```

- [ ] ✅ Valida formato `http://IP:PUERTO`
- [ ] ✅ Mensaje de error es claro
- [ ] ✅ Helper text menciona "misma WiFi"

---

## 3️⃣ FUNCIONALIDADES CRÍTICAS

### UCropActivity en AndroidManifest
```bash
grep -n "UCropActivity" android/app/src/main/AndroidManifest.xml
```

**Debe mostrar:**
```xml
<activity
  android:name="com.yalantis.ucrop.UCropActivity"
  android:screenOrientation="portrait"
  android:theme="@style/Theme.AppCompat.Light.NoActionBar"
  android:exported="false" />
```

- [ ] ✅ UCropActivity está declarada (líneas 27-32 aprox.)
- [ ] ✅ `exported="false"` está configurado
- [ ] ✅ Tema está configurado

### Campo URL Visible en Login
```bash
grep -n "URL del Servidor Paperless" lib/presentation/auth/login_screen.dart
```

- [ ] ✅ Campo URL es siempre visible (NO en "Configuración Avanzada")
- [ ] ✅ Label es claro: "URL del Servidor Paperless"
- [ ] ✅ Helper text menciona WiFi

### Instrucciones de Uso
```bash
grep -n "Instrucciones de Uso" lib/screens/home_screen.dart
wc -l lib/Utilities/slide.dart
```

- [ ] ✅ Menú dice "Instrucciones de Uso" (NO "Demo")
- [ ] ✅ `slide.dart` tiene títulos y descripciones (6 slides)
- [ ] ✅ Instrucciones están en español

### ProGuard Rules (si minify activado)
```bash
grep "minifyEnabled" android/app/build.gradle
cat android/app/proguard-rules.pro | head -20
```

- [ ] ✅ Si `minifyEnabled true`: `proguard-rules.pro` existe
- [ ] ✅ Reglas incluyen OkHttp, UCrop, Flutter
- [ ] ✅ O `minifyEnabled false` (más seguro)

---

## 4️⃣ COMPILACIÓN

### Clean Build
```bash
flutter clean
```

- [ ] ✅ Build artifacts eliminados

### Compilación Debug (PRIMERO)
```bash
flutter build apk --debug
```

- [ ] ✅ Compilación debug exitosa
- [ ] ✅ Sin errores de sintaxis
- [ ] ✅ Sin warnings críticos

### Prueba en Debug (OPCIONAL pero recomendado)
```bash
flutter run --debug
# Conectar dispositivo y probar funcionalidades básicas
```

- [ ] ✅ App inicia correctamente
- [ ] ✅ Login permite ingresar URL
- [ ] ✅ Login NO muestra error HTTPS con URL local

### Compilación Release (SOLO SI DEBUG FUNCIONA)
```bash
flutter build apk --release
```

- [ ] ✅ Compilación release exitosa
- [ ] ✅ Sin errores de ProGuard/R8
- [ ] ✅ Sin errores de firma

---

## 5️⃣ VALIDACIÓN DEL APK

### Tamaño y Checksum
```bash
ls -lh build/app/outputs/flutter-apk/app-release.apk
md5sum build/app/outputs/flutter-apk/app-release.apk
```

- [ ] ✅ Tamaño es razonable (60-80 MB)
- [ ] ✅ MD5 generado correctamente
- [ ] ✅ MD5 anotado para documentación

### Copiar APK
```bash
VERSION="4.0.X"  # Cambiar según versión
cp build/app/outputs/flutter-apk/app-release.apk LumaraScan_v${VERSION}_STABLE.apk
```

- [ ] ✅ APK copiado a directorio raíz
- [ ] ✅ Nombre correcto: `LumaraScan_vX.X.X_STABLE.apk`

---

## 6️⃣ ACTUALIZACIÓN DE ARCHIVOS

### install_apk.sh
```bash
# Actualizar versión y MD5
nano install_apk.sh
```

- [ ] ✅ `APK_PATH` apunta a nueva versión
- [ ] ✅ `APK_MD5` actualizado
- [ ] ✅ Mensajes muestran versión correcta

### Documentación
- [ ] ✅ Crear `RESUMEN_vX.X.X_FINAL.txt`
- [ ] ✅ Crear `CAMBIOS_vX.X.X.md` (opcional, para cambios importantes)
- [ ] ✅ Actualizar README si es necesario

---

## 7️⃣ PRUEBA DE INSTALACIÓN (CRÍTICO)

### En Dispositivo de Prueba
```bash
adb devices
./install_apk.sh
```

- [ ] ✅ Script detecta dispositivo
- [ ] ✅ Script desinstala versión anterior
- [ ] ✅ Script instala nueva versión correctamente
- [ ] ✅ APK se instala sin errores

### Pruebas en Dispositivo

#### Login y Configuración
- [ ] ✅ App abre correctamente
- [ ] ✅ Versión mostrada es correcta
- [ ] ✅ Campo URL es visible
- [ ] ✅ URL por defecto es `http://192.168.40.17:8001`
- [ ] ✅ Login con URL local NO muestra error HTTPS ← **CRÍTICO**
- [ ] ✅ Login funciona con credenciales correctas

#### Diagnóstico de Red
- [ ] ✅ Icono `network_check` accesible
- [ ] ✅ Muestra estado de internet
- [ ] ✅ Muestra URL del servidor
- [ ] ✅ Muestra si servidor es alcanzable
- [ ] ✅ Muestra latencia en ms

#### Captura de Fotos
- [ ] ✅ Botón `+` funciona
- [ ] ✅ "Normal Scan" captura foto
- [ ] ✅ Pantalla de recorte aparece (azul/cyan)
- [ ] ✅ Recorte permite ajustar bordes
- [ ] ✅ Tocar ✓ guarda foto
- [ ] ✅ App NO crashea ← **CRÍTICO**

#### Sincronización
- [ ] ✅ Icono de sincronización funciona
- [ ] ✅ Si en misma WiFi: sincroniza correctamente
- [ ] ✅ Documentos aparecen en Paperless web

#### Instrucciones de Uso
- [ ] ✅ Menú lateral accesible
- [ ] ✅ "Instrucciones de Uso" presente
- [ ] ✅ 6 pantallas con títulos y descripciones
- [ ] ✅ Instrucciones claras y útiles

---

## 8️⃣ PRUEBAS DE REGRESIÓN

**Funcionalidades que NO deben fallar:**

### Funcionalidad Core
- [ ] ✅ Login con URL local sin error HTTPS
- [ ] ✅ Recorte automático al capturar foto
- [ ] ✅ App no crashea al aceptar/cancelar recorte
- [ ] ✅ Diagnóstico de red funciona
- [ ] ✅ Sincronización funciona (misma WiFi)

### UI/UX
- [ ] ✅ Campo URL siempre visible
- [ ] ✅ Instrucciones de uso accesibles
- [ ] ✅ Colores Lumara (Indigo + Cyan) presentes
- [ ] ✅ Textos en español

### Seguridad
- [ ] ✅ HTTPS requerido para URLs externas
- [ ] ✅ HTTP permitido solo para IPs locales
- [ ] ✅ Validación de formato URL funciona

---

## 9️⃣ DISTRIBUCIÓN

### Antes de Distribuir al Usuario
- [ ] ✅ **TODAS** las pruebas anteriores pasaron
- [ ] ✅ Sin crasheos reportados
- [ ] ✅ Sin errores en logs de adb
- [ ] ✅ Funcionalidades críticas verificadas

### Documentos para Usuario
- [ ] ✅ `RESUMEN_vX.X.X_FINAL.txt` creado
- [ ] ✅ `install_apk.sh` funciona correctamente
- [ ] ✅ Instrucciones claras en resumen

---

## 🔴 SI ALGUNA PRUEBA FALLA

### NO DISTRIBUIR EL APK

1. **Identificar el problema exacto**
2. **Corregir el código**
3. **Volver a ejecutar checklist completo desde el inicio**
4. **Recompilar y probar nuevamente**

### Errores Comunes a Revisar

#### Error: "HTTPS required in production"
→ Revisar validación en `paperless_api_client.dart`
→ Asegurar que permite IPs locales (192.168.x.x)

#### Error: "Paquete no es válido"
→ Verificar que `lumara-release-key.jks` existe
→ Verificar que `key.properties` es correcto

#### App crashea al tomar foto
→ Verificar UCropActivity en AndroidManifest.xml
→ Revisar proguard-rules.pro si minify activado

#### Sincronización no funciona
→ Verificar URL por defecto en api_constants.dart
→ Probar diagnóstico de red en dispositivo

---

## ✅ CHECKLIST COMPLETADO

Fecha de validación: __________________
Versión compilada: __________________
APK generado: __________________
MD5: __________________

**Firmado por:** __________________

**Estado final:**
- [ ] ✅ LISTO PARA DISTRIBUIR
- [ ] ❌ REQUIERE CORRECCIONES

**Notas adicionales:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## 📚 REFERENCIAS

- Plan sin retrocesos: `PLAN_SIN_RETROCESOS_v4.0.4.md`
- Errores pasados: Ver sección "REGISTRO DE ERRORES" en plan
- Instalación: `./install_apk.sh`

---

**Última actualización:** 8 Octubre 2025
**Creado para:** Lumara Scan v4.0.4+
