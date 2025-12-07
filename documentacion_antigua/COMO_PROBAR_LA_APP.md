# 📱 Cómo Probar la Aplicación Lumara Indígenas

**Guía rápida para compilar, instalar y probar la aplicación**

---

## ⚠️ Estado Actual

**La aplicación NO está disponible para descarga pública todavía.**

**¿Por qué?**
- ✅ Desarrollo: 100% completo
- ⏳ Producción: Pendiente de resolver 4 bloqueadores (SSL, URLs, pentesting)
- 🎯 Lanzamiento en Play Store: 2025-11-15

**Para probar la app AHORA, debes compilarla localmente.**

---

## 🎯 Opciones de Prueba

### Opción 1: Testing en Staging (Recomendado) ⭐
**Para:** QA, testing de funcionalidades, UAT
**Tiempo:** 10-15 minutos
**Requisitos:** Flutter instalado

### Opción 2: Instalación desde APK Pre-compilado
**Para:** Testing rápido sin Flutter
**Tiempo:** 2 minutos
**Requisitos:** APK ya compilado

### Opción 3: Producción (NO disponible aún)
**Para:** Usuarios finales
**Cuándo:** Después de resolver bloqueadores
**Dónde:** Google Play Store

---

## 📋 Prerrequisitos

Antes de empezar, verifica que tienes:

### 1. Flutter SDK Instalado
```bash
flutter --version
```

**Esperado:** Flutter 3.5.3 o superior

**Si NO está instalado:**
```bash
# En tu sistema ya tienes Flutter en /snap/bin/flutter
# Verifica:
/snap/bin/flutter --version

# O instala desde:
# https://docs.flutter.dev/get-started/install
```

### 2. Android SDK Configurado
```bash
flutter doctor
```

**Esperado:**
```
[✓] Flutter (Channel stable, 3.5.3)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio (version 2024.x)
```

**Si hay problemas:**
```bash
# Acepta licencias
flutter doctor --android-licenses

# Instala herramientas faltantes
flutter doctor
```

### 3. Dispositivo Android de Prueba

**Opción A: Dispositivo físico**
- Android 7.0 (API 24) o superior
- USB Debugging habilitado
- Cable USB conectado

**Opción B: Emulador**
```bash
# Crear emulador
flutter emulators --create

# Listar emuladores
flutter emulators

# Iniciar emulador
flutter emulators --launch <emulator_id>
```

### 4. Servidor Tejido para Testing

**Opción A: Servidor de desarrollo local**
```bash
# Si tienes Docker:
docker run -d -p 8001:8000 \
  -e TEJIDO_SECRET_KEY=test123 \
  ghcr.io/tejido-ngx/tejido-ngx:latest
```

**Opción B: Servidor staging**
- URL: `https://staging.lumara-indigenas.org` (si existe)
- Usuario: `test`
- Password: `test123`

**Opción C: Skip (testing offline)**
- Puedes probar la app sin servidor
- Las funciones offline funcionarán
- Los uploads quedarán en cola

---

## 🚀 OPCIÓN 1: Compilar y Probar (Staging)

### Paso 1: Navegar al proyecto
```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
```

### Paso 2: Verificar que todo está OK
```bash
# Ver estado del proyecto
flutter doctor

# Ver dispositivos conectados
flutter devices

# Debería mostrar algo como:
# Android SDK built for x86 (emulator-5554)
# o
# SM-G973F (tu dispositivo físico)
```

### Paso 3: Instalar dependencias
```bash
flutter pub get
```

**Esperado:**
```
Running "flutter pub get" in Lumara...
Got dependencies!
```

### Paso 4: Ejecutar tests (opcional pero recomendado)
```bash
# Ejecutar todos los tests
flutter test

# Ver cobertura
flutter test --coverage
```

**Esperado:**
```
00:02 +103: All tests passed!
```

### Paso 5: Compilar APK de Staging
```bash
# APK de staging (para pruebas)
flutter build apk --debug --dart-define=STAGING=true
```

**¿Qué hace?**
- Compila versión de pruebas (no optimizada)
- Usa configuración de staging
- Permite debugging
- No requiere certificados SSL configurados

**Tiempo:** 5-10 minutos la primera vez

**Resultado:**
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk (45.2MB)
```

### Paso 6: Instalar en dispositivo
```bash
# Instalar automáticamente
flutter install

# O manualmente:
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Esperado:**
```
Installing build/app/outputs/flutter-apk/app-debug.apk...
Success
```

### Paso 7: Ejecutar la app
```bash
# Ejecutar con hot-reload (recomendado para testing)
flutter run --dart-define=STAGING=true

# O abrir desde el dispositivo:
# Buscar icono "Lumara Indígenas"
```

---

## ⚡ OPCIÓN 2: APK Pre-compilado (Más Rápido)

### Paso 1: Compilar APK (solo una vez)
```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# Compilar APK debug
flutter build apk --debug --dart-define=STAGING=true
```

### Paso 2: Copiar APK a carpeta compartida
```bash
# Copiar APK a carpeta accesible
cp build/app/outputs/flutter-apk/app-debug.apk ~/Escritorio/lumara-staging.apk

echo "APK disponible en: ~/Escritorio/lumara-staging.apk"
```

### Paso 3: Transferir a dispositivo

**Opción A: Via USB (ADB)**
```bash
# Conectar dispositivo via USB
# Habilitar "USB Debugging" en el teléfono

# Instalar
adb install ~/Escritorio/lumara-staging.apk
```

**Opción B: Via Email/WhatsApp**
```bash
# Enviar archivo a tu email/WhatsApp
# Abrir en el teléfono
# Android preguntará si quieres instalar
# Habilitar "Instalar desde fuentes desconocidas"
```

**Opción C: Via Web/Cloud**
```bash
# Subir a Google Drive / Dropbox
# Descargar desde el teléfono
# Instalar
```

### Paso 4: Instalar en dispositivo
```
1. Abrir lumara-staging.apk en el teléfono
2. Android mostrará: "¿Instalar esta aplicación?"
3. Tap en "Configuración" → Habilitar "Fuentes desconocidas"
4. Volver y tap en "Instalar"
5. Esperar instalación (30 segundos)
6. Tap en "Abrir"
```

---

## 🧪 Cómo Probar la Aplicación

### Primera Ejecución

1. **Abrir app**
   - Buscar icono "Lumara Indígenas"
   - Tap para abrir

2. **Onboarding (primera vez)**
   - Leer 4 pantallas de introducción
   - Tap en "Comenzar"

3. **Permisos**
   - Cámara: Tap "Permitir"
   - Almacenamiento: Tap "Permitir"

4. **Login**
   - URL: `http://10.0.2.2:8001` (emulador) o tu IP local
   - Usuario: `admin`
   - Password: `admin` (o tu password)
   - Tap "Iniciar Sesión"

### Prueba 1: Captura de Documento ✅

```
1. Tap en botón "Capturar Documento" (flotante)
2. Cámara se abre
3. Apuntar a cualquier documento (cédula, pasaporte, papel)
4. Tap en botón de captura (centro)
5. Revisar imagen capturada
6. Si está bien: Tap "Continuar"
   Si no: Tap "Reintentar"
```

### Prueba 2: Asignación de Metadata ✅

```
7. Pantalla "Asignar Documento"
8. Campo "Persona": Tap y buscar "Juan" (hay 3,997 personas)
9. Seleccionar persona de la lista
10. Campo "Tipo de Documento": Seleccionar "Cédula"
11. Campo "Número": Ingresar "1234567890"
12. Campo "Digitalizado por": Ingresar tu nombre
13. Tap en "Guardar"
```

### Prueba 3: Sincronización (Online) ✅

**Si hay conexión al servidor:**
```
14. App muestra "Subiendo documento..."
15. Progreso: 0% → 50% → 100%
16. Notificación: "✅ Documento sincronizado"
17. Check: Ir al servidor Tejido en navegador
18. Verificar que documento aparece en lista
```

### Prueba 4: Modo Offline ✅

**Si NO hay conexión:**
```
14. App detecta que no hay conexión
15. Muestra mensaje: "Sin conexión - quedará en cola"
16. Documento se guarda localmente
17. Navegar a "Documentos Pendientes"
18. Verificar que documento aparece con estado "Pendiente"
19. Conectar a red WiFi
20. App sincroniza automáticamente
21. Verificar que estado cambia a "Sincronizado"
```

### Prueba 5: Reportes y Analytics ✅

```
22. Tap en menú (☰ arriba izquierda)
23. Tap en "Reportes"
24. Ver estadísticas:
    - Total documentos
    - Documentos por tipo
    - Tendencia de últimos 30 días
25. Tap en "Exportar PDF"
26. Verificar que se genera PDF
27. Compartir PDF via WhatsApp/Email
```

### Prueba 6: Análisis de Brechas ✅

```
28. Tap en menú (☰)
29. Tap en "Análisis de Brechas"
30. Ver resumen:
    - Documentos faltantes totales
    - Personas con brechas críticas
31. Tab "Por Persona"
32. Verificar personas con documentos faltantes
33. Ver prioridad (Alta/Media/Baja)
```

### Prueba 7: Panel de Administración ✅

```
34. Tap en menú (☰)
35. Tap en "Panel Admin"
36. Ver estado del sistema:
    - Versión de la app
    - Documentos en cola
    - Estado de conexión
37. Tap en "Sincronizar Ahora"
38. Verificar sincronización manual
```

---

## 🔧 Configuración para Testing

### Modo Staging (Testing)

**Archivo:** `lib/core/config/production_config.dart`

```dart
// Staging URL (línea 50)
static const String tejidoStagingUrl =
  'http://10.0.2.2:8001'; // ← CAMBIAR a tu servidor de prueba
```

**Compilar con staging:**
```bash
flutter build apk --debug --dart-define=STAGING=true
```

### Modo Development (Local)

**Archivo:** `lib/core/config/production_config.dart`

```dart
// Development URL (línea 58)
static const String tejidoDevelopmentUrl =
  'http://10.0.2.2:8001'; // Emulador
  // 'http://192.168.1.100:8001'; // Dispositivo físico (usar IP de tu PC)
```

**Ejecutar en modo development:**
```bash
flutter run
```

### Modo Producción (NO usar para testing)

**NO compilar en modo producción hasta resolver bloqueadores.**

```bash
# ❌ NO EJECUTAR ESTO TODAVÍA
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

**Por qué NO:**
- Requiere certificados SSL configurados
- Requiere URLs de producción válidas
- Bloqueará si falta alguna configuración

---

## 📱 Troubleshooting

### Error: "Flutter not found"

```bash
# Agregar Flutter al PATH
export PATH="$PATH:/snap/bin"

# O usar ruta completa
/snap/bin/flutter run
```

### Error: "No devices found"

```bash
# Verificar dispositivo conectado
adb devices

# Si no aparece:
# - Habilitar USB Debugging en teléfono
# - Reconectar cable USB
# - Instalar drivers USB (Windows)

# Para emulador:
flutter emulators --launch Pixel_5_API_30
```

### Error: "Build failed"

```bash
# Limpiar build
flutter clean

# Re-instalar dependencias
flutter pub get

# Intentar de nuevo
flutter build apk --debug
```

### Error: "Gradle build failed"

```bash
# Ir a carpeta android
cd android

# Limpiar gradle
./gradlew clean

# Volver y compilar
cd ..
flutter build apk --debug
```

### Error: "Installation failed"

```bash
# Desinstalar versión anterior
adb uninstall com.lumara.indigenas

# Instalar nueva versión
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Error: "Cannot connect to Tejido"

**Verificar servidor:**
```bash
# Probar desde PC
curl http://localhost:8001/api/

# Debería responder:
{"version": "2.11.3", ...}
```

**Verificar red:**
- Emulador: usar `10.0.2.2` (no `localhost`)
- Dispositivo físico: usar IP de tu PC (no `localhost`)
- WiFi: PC y teléfono en misma red

**Obtener IP de tu PC:**
```bash
# Linux
ip addr show | grep inet

# Usar IP que empieza con 192.168.x.x
# Ejemplo: 192.168.1.100
```

**Actualizar URL en app:**
```dart
// lib/core/config/production_config.dart
static const String tejidoDevelopmentUrl =
  'http://192.168.1.100:8001'; // ← Tu IP
```

### App crash al abrir

```bash
# Ver logs en tiempo real
flutter logs

# O con adb
adb logcat | grep flutter

# Buscar líneas con "E/flutter"
```

---

## 📊 Checklist de Testing

### Funcionalidades Core
- [ ] Login exitoso
- [ ] Captura de documento con cámara
- [ ] Validación de calidad de imagen
- [ ] Asignación de persona del censo
- [ ] Selección de tipo de documento
- [ ] Ingreso de metadatos
- [ ] Guardado en cola local

### Sincronización
- [ ] Upload exitoso (online)
- [ ] Progreso visible durante upload
- [ ] Confirmación de éxito
- [ ] Cola offline funciona
- [ ] Auto-sync después de 15 minutos
- [ ] Sincronización manual

### Reportes
- [ ] Dashboard muestra estadísticas
- [ ] Gráficos se renderizan correctamente
- [ ] Exportación a PDF funciona
- [ ] Exportación a Excel funciona
- [ ] Compartir reportes via WhatsApp/Email

### Análisis de Brechas
- [ ] Resumen muestra datos correctos
- [ ] Vista por persona funciona
- [ ] Vista por familia funciona
- [ ] Prioridades calculadas correctamente

### Workflows
- [ ] Auto-etiquetado funciona
- [ ] Notificaciones se muestran
- [ ] Workflows pueden activarse/desactivarse

### UI/UX
- [ ] Textos en español
- [ ] Navegación intuitiva
- [ ] Onboarding claro
- [ ] Sin crashes
- [ ] Performance aceptable (< 3s inicio)

---

## 🎯 Escenarios de Prueba Recomendados

### Escenario 1: Usuario de Campo (Happy Path)
```
1. Operador llega a comunidad sin internet
2. Abre app, login automático (token guardado)
3. Captura 10 documentos de 5 personas
4. Todos quedan en cola offline
5. Regresa a oficina con WiFi
6. App sincroniza automáticamente los 10 documentos
7. Operador revisa reportes
8. Exporta PDF con resumen del día
```

### Escenario 2: Documentos de Baja Calidad
```
1. Usuario intenta capturar documento borroso
2. App detecta baja calidad
3. Muestra alerta: "Imagen borrosa - Intenta de nuevo"
4. Usuario retoma foto con mejor iluminación
5. App acepta imagen
6. Upload exitoso
```

### Escenario 3: Pérdida de Conexión Durante Upload
```
1. Usuario inicia upload de documento
2. Progreso: 30%
3. Se pierde conexión WiFi
4. App detecta error de red
5. Marca documento como "pending"
6. Reintenta automáticamente cuando reconecta
7. Upload completa exitosamente
```

### Escenario 4: Múltiples Usuarios (Concurrencia)
```
1. 5 operadores digitalizan simultáneamente
2. Todos suben a mismo servidor Tejido
3. No hay conflictos
4. Cada documento tiene person_id único
5. Reportes agregados muestran datos correctos
```

---

## 📈 Métricas de Éxito

**La app está funcionando bien si:**

✅ **Performance:**
- Inicio < 3 segundos
- Captura de foto < 1 segundo
- Upload de documento < 5 segundos

✅ **Estabilidad:**
- 0 crashes durante 1 hora de uso
- Funciona después de 8 horas en background
- Sincroniza correctamente después de reinicio

✅ **Offline:**
- Puede capturar sin internet
- Cola mantiene 100+ documentos
- Auto-sincroniza al reconectar

✅ **Usabilidad:**
- Usuario nuevo completa onboarding sin ayuda
- Captura 10 documentos en < 5 minutos
- Encuentra reportes fácilmente

---

## 🚀 Próximos Pasos

### Para Testing Exhaustivo

1. **Leer:** [TESTING.md](docs/TESTING.md) - Guía completa de testing
2. **Ejecutar:** Test suite automatizada
   ```bash
   flutter test --coverage
   ```
3. **Reportar:** Bugs encontrados en GitHub Issues

### Para UAT (User Acceptance Testing)

1. **Leer:** [USER_MANUAL_ES.md](docs/USER_MANUAL_ES.md)
2. **Seguir:** Checklist de UAT en [PRODUCTION_DEPLOYMENT_CHECKLIST.md](PRODUCTION_DEPLOYMENT_CHECKLIST.md)
3. **Documentar:** Feedback de usuarios reales

### Para Producción

**NO compilar para producción hasta resolver bloqueadores:**
1. ⏳ SSL Certificate Pinning
2. ⏳ URLs de Producción
3. ⏳ Email de Soporte
4. ⏳ Penetration Testing

**Ver:** [NEXT_STEPS.md](NEXT_STEPS.md) - Plan de 5 semanas

---

## 📞 Soporte

**Problemas durante testing:**
- **Email:** dev@lumara-indigenas.org
- **GitHub:** [Issues](https://github.com/yourusername/lumara-indigenas/issues)

**Bugs encontrados:**
- Crear issue en GitHub con:
  - Pasos para reproducir
  - Screenshots
  - Logs (`flutter logs`)
  - Versión de Android

---

## ✅ Resumen Rápido

```bash
# 1. Clonar/navegar al proyecto
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# 2. Instalar dependencias
flutter pub get

# 3. Conectar dispositivo
flutter devices

# 4. Compilar y ejecutar
flutter run --dart-define=STAGING=true

# 5. Probar la app
# - Capturar documento
# - Asignar persona
# - Verificar sincronización

# 6. Ver logs
flutter logs
```

**Tiempo total:** 15-20 minutos

**Resultado:** App funcionando en tu dispositivo de prueba ✅

---

**¿Listo para comenzar?** Ejecuta el comando del paso 1 y sigue la guía. 🚀
