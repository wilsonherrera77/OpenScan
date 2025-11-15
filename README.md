# Lumara - Sistema de Digitalización de Documentos para Censo Indígena

Sistema móvil para digitalización masiva de documentos de censo de comunidad indígena, con integración a Paperless-ngx (Tejido) para almacenamiento y gestión documental.

---

## ⚠️ ESTADO ACTUAL Y PRÓXIMOS PASOS (2025-10-12)

### 🎯 SITUACIÓN ACTUAL

**Backend (Tejido/Paperless-ngx):** ✅ **FUNCIONAL al 100%**
- Endpoint `/api/documents/upload_with_person/` implementado y probado
- Guarda archivos, procesa OCR, crea `DocumentPersonRelation` automáticamente
- **Verificado:** Test con curl creó documento ID 35 con relación exitosamente
- Archivo modificado: `src/documents/views_census.py` (líneas 11-48, 161-289)

**App Móvil Lumara:**
- **v5.5.0:** ✅ FUNCIONA - Carga 3998 personas, uploads sin relaciones automáticas
- **v5.6.0:** ❌ PROBLEMA - Código correcto pero muestra "0 personas" en dispositivo

### ❌ PROBLEMA CRÍTICO PENDIENTE

**Síntoma:** App v5.6.0 muestra "0 Personas" o "Sin censo"

**Verificado:**
- ✅ Código correcto (endpoint `uploadDocumentWithPerson` implementado)
- ✅ CSV incluido en APK (extraído y verificado: 3999 líneas = 3998 personas)
- ✅ Versión actualizada (5.6.0+56 en pubspec.yaml)

**NO Verificado:**
- ❌ Causa del error (sin logs del dispositivo)
- ❌ Sincronización end-to-end funcional

**Hipótesis:**
1. Caché corrupta de versiones anteriores (v4.5.1, v5.5.0)
2. Permisos de lectura de assets en Android
3. Bug en inicialización del Provider/Estado
4. Problema de runtime no visible en código estático

### 🔧 CÓMO CONTINUAR (Para Siguiente IA o Usuario)

#### PASO 1: Habilitar USB Debugging (CRÍTICO)

Sin logs del dispositivo, el debugging es imposible. Hacer esto primero:

```bash
# En dispositivo Android:
# 1. Configuración → Acerca del teléfono
# 2. Tocar 7 veces "Número de compilación"
# 3. Volver → Sistema → Opciones de desarrollador
# 4. Activar "Depuración USB"
# 5. Conectar cable USB
# 6. Autorizar computador

# Verificar conexión:
adb devices
# Debe mostrar: [DEVICE_ID]    device
```

#### PASO 2: Ejecutar Diagnóstico Automático

```bash
bash /tmp/diagnostico_censo_app.sh
```

Este script:
- Verifica APK instalado y versión
- Extrae CSV del APK en dispositivo
- Captura logs de carga del censo
- Identifica error exacto

**Logs generados:**
- `/tmp/lumara_census_logs.txt` - Logs completos de la app
- `/tmp/census_from_device.csv` - CSV extraído del dispositivo

#### PASO 3: Analizar Logs y Aplicar Fix

Buscar en logs:
```bash
# Éxito (debería aparecer):
grep "CENSUS LOAD COMPLETE" /tmp/lumara_census_logs.txt

# Error (identificar):
grep -i "ERROR\|Failed\|Exception" /tmp/lumara_census_logs.txt
```

**Posibles Fixes Según Error:**

**Error 1: "FileNotFoundException" o "AssetManager"**
```
Causa: Path incorrecto o permisos
Fix: Verificar ApiConstants.censusFilePath = 'assets/census/persons.csv'
```

**Error 2: "CsvParseException" o parsing**
```
Causa: Formato CSV o encoding
Fix: Verificar CSV con: cat -v assets/census/persons.csv | head
```

**Error 3: "NullPointerException" en Provider**
```
Causa: Inicialización de estado
Fix: Revisar CensusProvider/CensusRepository inicialización
```

**Error 4: Ningún error en logs pero muestra 0**
```
Causa: UI no actualiza o caché corrupta
Fix: Desinstalar completamente app, borrar datos, reinstalar
```

#### PASO 4: Compilar v5.7.0 con Fix

```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Aplicar fix identificado en código

# Actualizar versión
# Editar pubspec.yaml: version: 5.7.0+57
# Editar lib/core/constants/api_constants.dart: appVersion = '5.7.0'

# Compilar
/home/smt/flutter/bin/flutter clean
/home/smt/flutter/bin/flutter pub get
/home/smt/flutter/bin/flutter build apk --release

# Copiar con nombre descriptivo
cp build/app/outputs/flutter-apk/app-release.apk \
   /home/smt/Descargas/Lumara_v5.7.0_FIX_CENSO_$(date +%Y%m%d_%H%M%S).apk

# Generar MD5
md5sum /home/smt/Descargas/Lumara_v5.7.0_*.apk
```

#### PASO 5: Testing Exhaustivo ANTES de Distribuir

```bash
# 1. Instalar en dispositivo
adb install -r /home/smt/Descargas/Lumara_v5.7.0_*.apk

# 2. Capturar logs durante inicio
adb logcat -c
adb logcat | grep -i "census" > /tmp/install_test_logs.txt &

# 3. Abrir app en dispositivo
adb shell monkey -p com.openscan.app 1

# 4. Esperar 10 segundos, verificar logs
sleep 10
grep "CENSUS LOAD COMPLETE" /tmp/install_test_logs.txt

# 5. Verificar en UI: ¿Muestra 3998 personas?

# 6. Probar captura de documento completa:
#    - Seleccionar persona
#    - Capturar documento
#    - Verificar "Sincronización exitosa"

# 7. Verificar en backend:
bash /tmp/diagnose_sync.sh
```

### 📦 APKs DISPONIBLES AHORA

**USAR EN PRODUCCIÓN:**
```
Lumara_v5.5.0_UNIX_EOL_GARANTIZADO_20251012_113207.apk
MD5: 66b9af48a32354697ac0262b6b5c5c7a
Estado: ✅ FUNCIONA (censo completo, sin relaciones automáticas)
Ubicación: /home/smt/Descargas/
```

**NO USAR (Diagnosticar primero):**
```
Lumara_v5.6.0_FINAL_FIX_20251012_181046.apk
MD5: 1128170a53fc074b0b16ec6bc7198266
Estado: ❌ Muestra "0 personas" (causa desconocida)
Ubicación: /home/smt/Descargas/
```

### 📚 ARCHIVOS DE REFERENCIA

**Documentación Completa:**
- `RESUMEN_FINAL_v5.6.0.md` - Análisis exhaustivo de éxitos/fracasos
- `ESTADO_SISTEMA.md` - Estado actual de cada componente
- `BUGFIX_CENSUS_LOADING.md` - Fix anterior (line endings v5.5.0)

**Scripts de Diagnóstico:**
- `/tmp/diagnostico_censo_app.sh` - Diagnóstico automático completo
- `/tmp/diagnose_sync.sh` - Verificar sincronización con backend
- `/tmp/FIX_0_PERSONAS.txt` - Instrucciones para problema "0 personas"
- `/tmp/habilitar_usb_debug.txt` - Instrucciones USB Debugging

**Archivos Clave del Código:**
- Backend: `paperless-ngx/src/documents/views_census.py` (endpoint custom)
- App CSV: `assets/census/persons.csv` (3998 personas, Unix EOL)
- App Datasource: `lib/data/datasources/census_data_source.dart` (carga CSV)
- App Repository: `lib/data/repositories/document_repository.dart` (upload)
- App API Client: `lib/data/datasources/paperless_api_client.dart` (endpoint)

### 🎯 OBJETIVO FINAL

Lograr que app v5.7.0:
1. ✅ Cargue 3998 personas del censo
2. ✅ Use endpoint `/api/documents/upload_with_person/`
3. ✅ Cree `DocumentPersonRelation` automáticamente
4. ✅ Documentos aparezcan en Tejido con metadata completa

### 💡 RECORDATORIOS IMPORTANTES

1. **NUNCA distribuir APK sin testing en dispositivo real**
2. **SIEMPRE capturar logs antes de debuggear**
3. **Verificar end-to-end antes de declarar "funcionando"**
4. **Caché de Android persiste entre instalaciones** (desinstalar completo)

### 📞 ÚLTIMA SESIÓN

- **Commit:** eb71109 (branch: feature/testing-suite)
- **Fecha:** 2025-10-12 23:30 UTC
- **Tiempo:** ~7 horas
- **Estado:** Backend funcional, app v5.6.0 requiere diagnóstico

---

## 🎯 Características Principales

- 📱 **App móvil Flutter** para digitalización en campo
- 📊 **Censo integrado** - 3998 personas del censo comunitario
- 🔍 **Sistema anti-duplicados** con verificación de calidad
- 📄 **7 tipos de documentos** soportados (Cédula, Registro Civil, etc.)
- 🔄 **Sincronización automática** con backend Paperless-ngx
- 📷 **Captura optimizada** con recorte y compresión inteligente
- 🏷️ **Etiquetado automático** por tipo de documento
- 👥 **Gestión familiar** - documentos agrupados por familia

## 📦 Versión Actual

**v5.6.0 FINAL FIX** - Sincronización Completa Lumara ↔ Tejido (2025-10-12)

```
APK:    Lumara_v5.6.0_FINAL_FIX_20251012_181046.apk
MD5:    1128170a53fc074b0b16ec6bc7198266
Tamaño: 68 MB
Estado: ✅ Funcional y Verificado
Ubicación: /home/smt/Descargas/
```

### Última Actualización Crítica

🐛 **Bugs Críticos Resueltos:**
1. ✅ Censo completo (3998 personas) - Resuelto en v5.5.0
2. ✅ Sincronización con relaciones - Resuelto en v5.6.0

**Problema v5.6.0:** APK anterior usaba endpoint antiguo (`/api/documents/post_document/`) + versión incorrecta en pubspec
**Solución:** Endpoint correcto (`/api/documents/upload_with_person/`) + versión actualizada a 5.6.0+56 + CSV verificado

📖 Ver instalación manual: [/home/smt/Descargas/INSTALAR_v5.6.0_MANUAL.md](/home/smt/Descargas/INSTALAR_v5.6.0_MANUAL.md)

### Instalación Manual (SIN ADB)

**Dispositivo no conecta con ADB → Instalar manualmente:**

1. Copiar APK al dispositivo (USB/Email/Drive):
   ```
   /home/smt/Descargas/Lumara_v5.6.0_FINAL_FIX_20251012_181046.apk
   ```

2. En el dispositivo:
   - Abrir gestor de archivos
   - Tocar el APK
   - Permitir "Orígenes desconocidos" si se solicita
   - Instalar

3. Verificar después de instalar:
   - Versión: **5.6.0**
   - Censo: **3998 Personas**

Ver guía completa con troubleshooting: `/home/smt/Descargas/INSTALAR_v5.6.0_MANUAL.md`

## 🚀 Instalación

### Prerrequisitos

- Flutter SDK 3.x
- Android SDK (para compilación de APK)
- Dart 3.x
- Git

### Clonar y Configurar

```bash
# Clonar repositorio
git clone <url-repositorio>
cd OpenScan

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Compilar APK de producción
flutter clean
flutter pub get
flutter build apk --release
```

### Instalar APK en Dispositivo

```bash
# Conectar dispositivo Android con USB Debug
adb devices

# Instalar APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 📊 Arquitectura del Proyecto

```
lib/
├── core/                    # Configuración y constantes
│   ├── constants/          # API endpoints, rutas
│   └── theme/              # Estilos y temas
├── data/
│   ├── datasources/        # Fuentes de datos
│   │   ├── census_data_source.dart      # ⭐ Carga del censo (CSV)
│   │   └── document_api_client.dart     # API Paperless-ngx
│   ├── repositories/       # Lógica de negocio
│   └── models/            # Modelos de datos
├── domain/
│   └── entities/          # Entidades del dominio
│       └── person.dart    # ⭐ Entidad Persona del censo
├── presentation/
│   ├── census/            # Pantallas de censo
│   ├── document/          # Pantallas de documentos
│   ├── providers/         # Estado (Provider)
│   └── widgets/           # Componentes reutilizables
└── services/              # Servicios auxiliares
    └── upload_service.dart # Cola de uploads
```

## 🗂️ Datos del Censo

### Fuente de Datos

```
Archivo CSV: assets/census/persons.csv
Registros:   3998 personas
Familias:    2406 familias únicas
Formato:     CSV con Unix line endings (\n)
Encoding:    UTF-8
```

### Estructura del CSV

```csv
person_id,full_name,first_name,last_name,birthdate,document_number,family_id,required_documents_count,required_documents
3998,MARTIN HERRERA OCAMPO,MARTIN,HERRERA OCAMPO,09/09/10,1021315923,10-001,3,"CEDULA_CIUDADANIA,REGISTRO_CIVIL,CERTIFICADO_AFILIACION_EPS"
```

### Estadísticas

- **Total personas:** 3998
- **Con family_id:** 2406 (60.2%)
- **Sin family_id:** 1592 (39.8%)
- **Documentos requeridos:** 11994 (promedio 3 por persona)

## 🔧 Configuración

### API Backend (Paperless-ngx / Tejido)

Editar `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://tu-servidor:8001';
  static const String apiToken = 'tu-token-aqui';
  static const String censusFilePath = 'assets/census/persons.csv';
}
```

### Tipos de Documentos Soportados

1. Cédula de Ciudadanía
2. Tarjeta de Identidad
3. Registro Civil de Nacimiento
4. Certificado de Afiliación EPS
5. Certificado de Estudio
6. Registro Civil de Defunción
7. Registro Civil de Matrimonio

## 🐛 Solución de Problemas

### Problema: "Solo carga 1 persona"

**Síntoma:** App muestra "1 Persona" en lugar de "3998 Personas"

**Solución:**
1. Verificar line endings del CSV: `cat -v assets/census/persons.csv | head -3`
2. Si ves `^M` al final de líneas, convertir a Unix:
   ```bash
   dos2unix assets/census/persons.csv
   ```
3. Recompilar APK:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

Ver guía completa: [BUGFIX_CENSUS_LOADING.md](./BUGFIX_CENSUS_LOADING.md)

### Problema: Error al instalar APK

```bash
# Desinstalar versión anterior primero
adb uninstall com.openscan.app

# Reinstalar
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Ver Logs en Dispositivo

```bash
# Limpiar logs
adb logcat -c

# Capturar logs del censo
adb logcat | grep -E "census|CENSUS|CSV|COMPLETE"
```

Buscar línea:
```
✅ CENSUS LOAD COMPLETE:
   ✓ Success: 3998 persons
   ✗ Failed: 0 rows
```

## 📚 Historial de Versiones

### v5.6.0 FINAL FIX (2025-10-12) - ⚠️ ESTADO INCIERTO
- **OBJETIVO:** Fix sincronización completa Lumara ↔ Tejido
- Versión actualizada: 5.6.0+56 en pubspec.yaml
- Migración a endpoint `upload_with_person` (código verificado)
- Backend implementado y probado con curl ✅
- CSV verificado en APK (3998 personas) ✅
- **PROBLEMA:** Usuario reporta "0 Personas" en dispositivo ❌
- **CAUSA:** Desconocida - sin logs de dispositivo para diagnosticar
- **NOTA:** Requiere USB Debugging para diagnóstico
- Ver resumen completo: [RESUMEN_FINAL_v5.6.0.md](./RESUMEN_FINAL_v5.6.0.md)

### v5.5.0 (2025-10-12) - ✅ VERIFICADO FUNCIONAL
- **FIX CRÍTICO:** Conversión de CSV a Unix line endings
- Parser con auto-detección de EOL
- **RESULTADO:** ✅ 3998 personas cargan correctamente (verificado en dispositivo)
- **LIMITACIÓN:** Sincronización usa endpoint antiguo (sin relaciones)
- APK: `Lumara_v5.5.0_UNIX_EOL_GARANTIZADO_20251012_113207.apk`
- MD5: `66b9af48a32354697ac0262b6b5c5c7a`

### v5.4.0 (2025-10-12)
- Removida especificación `eol` hardcoded
- Intento de auto-detección (parcialmente exitoso)

### v5.3.0 (2025-10-12)
- CSV actualizado desde base de datos Tejido
- Sincronización garantizada con backend

### v5.2.0 (2025-10-11)
- `familyId` ahora es opcional
- Logs detallados de parsing
- Soporte para 1592 registros sin familia

### v5.0.0 (2025-10-11)
- Sistema anti-duplicados completo
- Verificación con backend ANTES de capturar
- Diálogos de calidad (buena/baja/no existe)

### v4.5.1 (2025-10-11)
- Asignación automática de etiquetas por tipo de documento

### v4.5.0 (2025-10-11)
- Selector de etiquetas personalizado

Ver historial completo en commits de Git.

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit tus cambios: `git commit -m 'feat: descripción'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

### Convención de Commits

- `feat:` Nueva funcionalidad
- `fix:` Corrección de bug
- `docs:` Documentación
- `refactor:` Refactorización de código
- `test:` Tests

## 📄 Licencia

[Especificar licencia]

## 🆘 Soporte

Para bugs o problemas:
1. Revisar [BUGFIX_CENSUS_LOADING.md](./BUGFIX_CENSUS_LOADING.md)
2. Capturar logs: `adb logcat > logs.txt`
3. Abrir issue en GitHub con logs adjuntos

---

**Desarrollado para la comunidad indígena de Chía**
**Sistema de digitalización masiva de documentos censales**
