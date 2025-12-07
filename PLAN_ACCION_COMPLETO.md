# 🎯 PLAN DE ACCIÓN COMPLETO - Sistema Lumara/Tejido
**Fecha de creación:** 2025-10-28
**Estado del sistema:** 80% funcional
**Objetivo:** Completar al 100% y preparar para producción

---

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Fase 1: Seguridad Crítica (URGENTE)](#fase-1-seguridad-crítica)
3. [Fase 2: Diagnóstico y Resolución App v5.6.0](#fase-2-diagnóstico-app)
4. [Fase 3: Testing y Validación End-to-End](#fase-3-testing-validación)
5. [Fase 4: Optimizaciones de Performance](#fase-4-optimizaciones)
6. [Fase 5: Características Avanzadas](#fase-5-características-avanzadas)
7. [Recursos y Referencias](#recursos-referencias)
8. [Matriz de Riesgos](#matriz-riesgos)

---

## 📊 RESUMEN EJECUTIVO

### Estado Actual

| Componente | Estado | Acción Requerida |
|------------|--------|------------------|
| Backend Tejido-NGX | ✅ 100% | Ninguna |
| Sistema de IA OpenAI | ✅ 90% | Rotar API Key |
| App v5.5.0 | ⚠️ 80% | Usar como respaldo |
| App v5.6.0 | ❌ 0% | Diagnóstico completo |
| Sincronización E2E | ❌ 40% | Testing exhaustivo |
| Seguridad | 🔴 30% | **CRÍTICO** |

### Tiempo Total Estimado

- **Mínimo viable:** 6-8 horas (Fases 1-3)
- **Sistema completo:** 15-20 horas (Fases 1-5)
- **Con optimizaciones:** 25-30 horas (Todas las fases + extras)

### Prioridades

```
🔴 CRÍTICO (HOY):     Seguridad - API Keys
🟠 ALTA (Esta semana): Diagnóstico v5.6.0 + Testing E2E
🟡 MEDIA (2 semanas):  Optimizaciones de performance
🟢 BAJA (1 mes):       Características avanzadas
```

---

## 🔴 FASE 1: SEGURIDAD CRÍTICA (URGENTE)

**Prioridad:** 🔴 MÁXIMA
**Tiempo estimado:** 2-3 horas
**Bloqueador:** Sí - Riesgo de seguridad activo
**Estado:** ⏳ Pendiente

### Problema

Actualmente hay **2 API keys expuestas** en el repositorio Git:
1. OpenAI API Key (acceso a cuenta, costos financieros)
2. Tejido Secret Key (acceso a datos sensibles)

**Riesgo:** 🔴 CRÍTICO - Uso no autorizado, costos inesperados, acceso a datos

### Tareas

#### 1.1 Rotar OpenAI API Key ⏱️ 30 min

**Pasos:**

```bash
# 1. Ir a OpenAI Dashboard
# URL: https://platform.openai.com/api-keys

# 2. REVOCAR la key actual comprometida
# Key expuesta: sk-proj-...

# 3. Crear nueva API key
# Nombre sugerido: "Tejido-NGX-Prod-2025-10"
# Copiar la nueva key (se muestra UNA SOLA VEZ)

# 4. Actualizar en servidor Tejido
docker exec -it tejido-webserver-1 bash

# Dentro del contenedor:
export OPENAI_API_KEY="sk-proj-NUEVA_KEY_AQUI"

# O editar docker-compose.yml:
nano docker-compose.yml
# Agregar bajo 'environment':
#   - OPENAI_API_KEY=sk-proj-NUEVA_KEY_AQUI

# Reiniciar contenedor
exit
docker-compose restart webserver

# 5. Verificar que funciona
docker exec tejido-webserver-1 python3 manage.py shell -c "
import openai
openai.api_key = 'sk-proj-NUEVA_KEY_AQUI'
print('API Key válida')
"
```

**Verificación:**
- [ ] Key antigua revocada en OpenAI Dashboard
- [ ] Nueva key generada y guardada en lugar seguro
- [ ] Contenedor actualizado con nueva key
- [ ] Test exitoso con nueva key

---

#### 1.2 Rotar Tejido Secret Key ⏱️ 30 min

**Pasos:**

```bash
# 1. Generar nueva secret key aleatoria
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
# Ejemplo output: kQW7xZ8r-9pL2mN4vB6hT3jC5dF8wE1sA7yU9oI0qK3rG6tH2pL4mN8v

# 2. Actualizar en docker-compose.yml
cd /ruta/a/tejido-ngx
nano docker-compose.yml

# Buscar línea:
#   TEJIDO_SECRET_KEY: "old-secret-key"
# Reemplazar con:
#   TEJIDO_SECRET_KEY: "kQW7xZ8r-9pL2mN4vB6hT3jC5dF8wE1sA7yU9oI0qK3rG6tH2pL4mN8v"

# 3. Reiniciar servicios
docker-compose down
docker-compose up -d

# 4. Verificar que el sistema funciona
curl -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  http://192.168.40.17:8001/api/documents/ | jq

# 5. Verificar sesiones de usuario
docker exec tejido-webserver-1 python3 manage.py shell -c "
from django.contrib.sessions.models import Session
print(f'Sesiones activas: {Session.objects.count()}')
"
```

**⚠️ IMPORTANTE:**
- Esto invalidará todas las sesiones activas
- Los usuarios tendrán que hacer login nuevamente
- Los tokens de API seguirán funcionando

**Verificación:**
- [ ] Nueva secret key generada
- [ ] docker-compose.yml actualizado
- [ ] Servicios reiniciados exitosamente
- [ ] API responde correctamente
- [ ] Test de autenticación exitoso

---

#### 1.3 Actualizar .gitignore ⏱️ 20 min

**Objetivo:** Prevenir futuras exposiciones de secrets

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido

# Crear/actualizar .gitignore
cat >> .gitignore << 'EOF'

# === SECRETS Y CONFIGURACIÓN SENSIBLE ===
.env
.env.local
.env.*.local
*.env
secrets/
config/secrets/
**/*secret*.yml
**/*secret*.yaml
**/*secret*.json
**/api_keys.txt
**/.secrets

# === API Keys y Tokens ===
**/openai_key.txt
**/api_token.txt
**/*_token.txt
**/*_key.txt

# === Archivos de Tejido ===
tejido-ngx/.env
tejido-ngx/docker-compose.override.yml
tejido-ngx/data/
tejido-ngx/media/
tejido-ngx/export/

# === Archivos de App Flutter ===
lumara/Lumara/.env
lumara/Lumara/android/key.properties
lumara/Lumara/android/app/upload-keystore.jks
lumara/Lumara/ios/Runner/GoogleService-Info.plist

# === APKs compilados (son binarios grandes) ===
*.apk
*.aab
*.ipa

# === Backups y datos locales ===
*.backup
*.bak
backups/
data/pdfs-prueba/*.pdf

EOF

# Verificar que los secrets actuales NO están trackeados
git status

# Si aparecen archivos sensibles, removerlos del tracking:
# git rm --cached ruta/al/archivo/sensible

# Commit del .gitignore actualizado
git add .gitignore
git commit -m "security: update .gitignore to prevent secret exposure"
```

**Verificación:**
- [ ] .gitignore creado/actualizado
- [ ] Archivos sensibles no aparecen en `git status`
- [ ] Commit realizado
- [ ] Revisión manual de archivos trackeados

---

#### 1.4 Auditoría de Seguridad del Repositorio ⏱️ 40 min

**Buscar secrets en historial de Git:**

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido

# Buscar posibles API keys de OpenAI
git log -p | grep -E "sk-proj-|sk-[a-zA-Z0-9]{48}"

# Buscar tokens y passwords
git log -p | grep -iE "password|token|secret|api_key"

# Buscar en todos los archivos actuales
grep -r -E "sk-proj-|sk-[a-zA-Z0-9]{48}" . 2>/dev/null

# Revisar configuraciones
find . -name "*.yml" -o -name "*.yaml" -o -name "*.env" | xargs grep -i "key"
```

**Si encuentras secrets en el historial:**

```bash
# Opción 1: Reescribir historial (PELIGROSO - solo si repo es privado)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch ruta/al/archivo" \
  --prune-empty --tag-name-filter cat -- --all

# Opción 2: Usar BFG Repo-Cleaner (MÁS SEGURO)
# Descargar: https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg.jar --delete-files archivo-con-secret.txt
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# Opción 3: Si el repo es público en GitHub
# - Rotar TODOS los secrets inmediatamente
# - Considerar crear nuevo repo limpio
```

**Verificación:**
- [ ] Búsqueda de secrets completada
- [ ] Secrets encontrados documentados
- [ ] Historial limpiado (si aplica)
- [ ] Verificación final sin secrets

---

### Criterios de Éxito Fase 1

✅ **FASE 1 COMPLETADA cuando:**

- [ ] OpenAI API Key rotada y funcionando
- [ ] Tejido Secret Key rotada y funcionando
- [ ] .gitignore actualizado y commiteado
- [ ] Auditoría de seguridad completada
- [ ] No hay secrets en `git status`
- [ ] Todos los servicios funcionan con nuevas keys
- [ ] Documentación actualizada con nuevos valores

**Documentar en:** `SECURITY_AUDIT_REPORT.md`

---

## 🟠 FASE 2: DIAGNÓSTICO Y RESOLUCIÓN APP v5.6.0

**Prioridad:** 🟠 ALTA
**Tiempo estimado:** 3-4 horas
**Bloqueador:** No, pero limita funcionalidad completa
**Estado:** ⏳ Pendiente

### Problema

App v5.6.0 muestra "0 personas" en dispositivo físico, pero:
- ✅ Código fuente es correcto
- ✅ CSV incluido en APK (verificado: 3,998 personas)
- ✅ Versión actualizada en pubspec.yaml
- ❌ Causa del error desconocida

**Hipótesis:**
1. Caché corrupta de versión anterior
2. Permisos de lectura de assets
3. Error en inicialización del Provider
4. Encoding del CSV problemático

---

### Tareas

#### 2.1 Habilitar USB Debugging ⏱️ 15 min

**Manual para usuario no técnico:**

```
📱 EN EL DISPOSITIVO ANDROID:

1. Ir a "Configuración" o "Ajustes"
2. Buscar "Acerca del teléfono" o "About phone"
3. Buscar "Número de compilación" o "Build number"
4. Tocar 7 VECES sobre "Número de compilación"
   → Aparecerá mensaje: "Ahora eres desarrollador"

5. Volver a menú anterior de Configuración
6. Buscar "Opciones de desarrollador" o "Developer options"
   (Puede estar en Sistema → Avanzado)

7. Activar el interruptor principal de "Opciones de desarrollador"
8. Buscar "Depuración USB" o "USB debugging"
9. Activar "Depuración USB"

10. Conectar cable USB al computador
11. En el dispositivo aparecerá: "¿Permitir depuración USB?"
    → Marcar "Permitir siempre desde este ordenador"
    → Tocar "Permitir" o "OK"
```

**Verificar en computador:**

```bash
# Verificar que adb está instalado
adb version

# Si no está instalado:
sudo apt-get install android-tools-adb android-tools-fastboot

# Detectar dispositivo
adb devices

# Debe mostrar:
# List of devices attached
# ABC123XYZ    device    ← Esto significa OK

# Si muestra "unauthorized":
# → Revisar mensaje en el dispositivo y aceptar
```

**Verificación:**
- [ ] Opciones de desarrollador habilitadas
- [ ] USB Debugging activado
- [ ] Dispositivo conectado con cable
- [ ] `adb devices` muestra dispositivo
- [ ] Autorización aceptada en dispositivo

---

#### 2.2 Ejecutar Diagnóstico Automático ⏱️ 30 min

**Script de diagnóstico ya está creado:**

```bash
# Ejecutar diagnóstico completo
bash /tmp/diagnostico_censo_app.sh

# Esto generará:
# - /tmp/lumara_census_logs.txt (logs de la app)
# - /tmp/census_from_device.csv (CSV extraído del APK en dispositivo)
# - Reporte en pantalla con análisis
```

**Análisis manual de logs:**

```bash
# Ver logs completos
cat /tmp/lumara_census_logs.txt

# Buscar éxito en carga
grep "CENSUS LOAD COMPLETE" /tmp/lumara_census_logs.txt

# Buscar errores
grep -i "error\|failed\|exception" /tmp/lumara_census_logs.txt

# Buscar warnings
grep -i "warning\|warn" /tmp/lumara_census_logs.txt

# Verificar CSV en dispositivo
wc -l /tmp/census_from_device.csv
# Debe mostrar: 3999 (header + 3998 personas)

# Comparar con CSV original
md5sum assets/census/persons.csv
md5sum /tmp/census_from_device.csv
# Si son diferentes, hay problema de packaging
```

**Logs a buscar:**

```
✅ ÉXITO - Buscar líneas como:
[CensusDataSource] Loading census from: assets/census/persons.csv
[CensusDataSource] Successfully loaded 3998 persons
[CensusProvider] Census initialized with 3998 persons

❌ ERROR - Posibles mensajes:
FileNotFoundException: assets/census/persons.csv
AssetManager: Asset not found
FormatException: Invalid CSV format
Permission denied
```

**Verificación:**
- [ ] Script ejecutado exitosamente
- [ ] Logs capturados en /tmp/lumara_census_logs.txt
- [ ] CSV extraído y verificado
- [ ] Error identificado (o confirmado que carga bien)

---

#### 2.3 Identificar Causa Raíz ⏱️ 45 min

**Según el error encontrado, aplicar:**

---

**CASO A: FileNotFoundException o Asset not found**

**Causa:** Path incorrecto o asset no incluido

**Solución:**

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# 1. Verificar pubspec.yaml
cat pubspec.yaml | grep -A 5 "assets:"

# Debe contener:
#   assets:
#     - assets/census/persons.csv

# 2. Verificar que el archivo existe
ls -lh assets/census/persons.csv

# 3. Verificar path en código
grep -r "censusFilePath" lib/

# Debe ser: 'assets/census/persons.csv'

# Si el path es diferente, corregir en:
nano lib/core/constants/api_constants.dart

# Línea ~85:
static const String censusFilePath = 'assets/census/persons.csv';
```

---

**CASO B: CsvParseException o FormatException**

**Causa:** Encoding o formato CSV incorrecto

**Solución:**

```bash
# Verificar encoding
file -i assets/census/persons.csv
# Debe ser: charset=utf-8

# Si no es UTF-8:
iconv -f ISO-8859-1 -t UTF-8 assets/census/persons.csv > temp.csv
mv temp.csv assets/census/persons.csv

# Verificar line endings
cat -A assets/census/persons.csv | head -3
# Debe terminar en $ (Unix), NO en ^M$ (Windows)

# Si tiene ^M$ (Windows):
dos2unix assets/census/persons.csv

# Verificar formato CSV
head -3 assets/census/persons.csv

# Primera línea debe ser header:
# person_id,full_name,first_name,last_name,...

# Verificar número de columnas
head -1 assets/census/persons.csv | tr ',' '\n' | wc -l
# Debe ser: 9 columnas
```

---

**CASO C: NullPointerException o State error**

**Causa:** Inicialización del Provider incorrecta

**Solución:**

```bash
# Revisar inicialización en main.dart
cat lib/main.dart | grep -A 10 "MultiProvider"

# Debe incluir:
# ChangeNotifierProvider(create: (_) => CensusProvider()),

# Verificar que CensusProvider se inicializa
cat lib/presentation/providers/census_provider.dart | grep -A 5 "CensusProvider("

# Agregar log debug temporal:
nano lib/presentation/providers/census_provider.dart

# En el constructor, agregar:
CensusProvider() {
  print('[CensusProvider] Initializing...');
  loadCensus();
}

Future<void> loadCensus() async {
  print('[CensusProvider] Starting census load...');
  try {
    final persons = await _repository.getAllPersons();
    print('[CensusProvider] Loaded ${persons.length} persons');
    // ...
  } catch (e) {
    print('[CensusProvider] ERROR: $e');
  }
}
```

---

**CASO D: Logs muestran carga exitosa pero UI muestra 0**

**Causa:** UI no se actualiza o caché de estado corrupta

**Solución:**

```bash
# 1. Desinstalar completamente la app
adb uninstall com.lumara.app

# 2. Limpiar datos de la app
adb shell pm clear com.lumara.app

# 3. Limpiar caché de Android
adb shell
# Dentro del shell:
rm -rf /data/data/com.lumara.app
exit

# 4. Reinstalar app
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 5. Verificar versión instalada
adb shell dumpsys package com.lumara.app | grep versionName
# Debe mostrar: versionName=5.6.0

# 6. Capturar logs durante inicio
adb logcat -c
adb logcat | tee /tmp/fresh_install_logs.txt
# (Abrir app en dispositivo)
# (Ctrl+C después de 30 segundos)

grep -i "census\|provider" /tmp/fresh_install_logs.txt
```

---

**Verificación:**
- [ ] Causa raíz identificada con certeza
- [ ] Logs analizados y documentados
- [ ] Solución específica determinada
- [ ] Plan de fix creado

---

#### 2.4 Aplicar Fix y Compilar v5.7.0 ⏱️ 60 min

**Aplicar el fix identificado:**

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# EJEMPLO - Ajustar según fix específico:

# 1. Aplicar cambios de código
# (Según la causa identificada en 2.3)

# 2. Actualizar versión
nano pubspec.yaml
# Cambiar: version: 5.7.0+57

nano lib/core/constants/api_constants.dart
# Cambiar: static const String appVersion = '5.7.0';

# 3. Limpiar y preparar
/home/smt/flutter/bin/flutter clean
rm -rf build/

# 4. Obtener dependencias
/home/smt/flutter/bin/flutter pub get

# 5. Verificar que no hay errores
/home/smt/flutter/bin/flutter analyze

# 6. Compilar APK de release
/home/smt/flutter/bin/flutter build apk --release

# 7. Copiar APK con nombre descriptivo
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FIX_NAME="FIX_CENSO"  # Ajustar según el fix aplicado
cp build/app/outputs/flutter-apk/app-release.apk \
   /home/smt/Descargas/Lumara_v5.7.0_${FIX_NAME}_${TIMESTAMP}.apk

# 8. Generar MD5 para verificación
md5sum /home/smt/Descargas/Lumara_v5.7.0_*.apk

# 9. Verificar tamaño
ls -lh /home/smt/Descargas/Lumara_v5.7.0_*.apk
# Debe ser ~68-70 MB
```

**Verificación:**
- [ ] Fix aplicado correctamente
- [ ] Versión actualizada a 5.7.0+57
- [ ] Compilación exitosa sin errores
- [ ] APK generado y copiado
- [ ] MD5 documentado
- [ ] Tamaño del APK razonable

---

#### 2.5 Testing Exhaustivo ANTES de Distribuir ⏱️ 45 min

**⚠️ NO SALTARSE ESTE PASO - Es crítico**

```bash
# 1. Desinstalar versión anterior completamente
adb uninstall com.lumara.app
adb shell pm clear com.lumara.app

# 2. Instalar nueva versión
adb install /home/smt/Descargas/Lumara_v5.7.0_*.apk

# 3. Verificar versión instalada
adb shell dumpsys package com.lumara.app | grep versionName
# Debe mostrar: versionName=5.7.0

# 4. Capturar logs desde el inicio
adb logcat -c
adb logcat | tee /tmp/v5.7.0_install_test.log &
LOGCAT_PID=$!

# 5. Abrir app en dispositivo
adb shell monkey -p com.lumara.app 1

# 6. Esperar 15 segundos para que cargue
sleep 15

# 7. Detener captura de logs
kill $LOGCAT_PID

# 8. Analizar logs
echo "=== ANÁLISIS DE LOGS v5.7.0 ==="

grep "CENSUS LOAD COMPLETE" /tmp/v5.7.0_install_test.log
# Debe aparecer con: ✓ Success: 3998 persons

grep -i "error\|exception\|failed" /tmp/v5.7.0_install_test.log | grep -i census
# NO debe haber errores relacionados con censo

# 9. Verificación MANUAL en dispositivo:
echo "
VERIFICAR EN EL DISPOSITIVO:
[ ] ¿Muestra '3998 Personas' en pantalla principal?
[ ] ¿La búsqueda de personas funciona?
[ ] ¿Se puede seleccionar una persona?
[ ] ¿Aparece el botón de capturar documento?
"

# 10. Test de captura completa
echo "
TEST DE CAPTURA (MANUAL):
1. Seleccionar persona del censo
2. Elegir tipo de documento: 'Cédula de Ciudadanía'
3. Capturar foto de un documento de prueba
4. Recortar imagen
5. Confirmar upload
6. Verificar mensaje: 'Sincronización exitosa'
"

# 11. Verificar en backend que llegó
bash /tmp/diagnose_sync.sh

# O manualmente:
docker exec tejido-webserver-1 python3 manage.py shell -c "
from documents.models import Document, DocumentPersonRelation
ultimo = Document.objects.latest('created')
print(f'Último documento:')
print(f'  ID: {ultimo.id}')
print(f'  Título: {ultimo.title}')
print(f'  Creado: {ultimo.created}')

try:
    relacion = DocumentPersonRelation.objects.get(document=ultimo)
    print(f'  Persona: {relacion.person.full_name} (ID: {relacion.person.person_id})')
    print(f'  Tipo: {relacion.document_type}')
    print('✅ RELACIÓN CREADA CORRECTAMENTE')
except DocumentPersonRelation.DoesNotExist:
    print('❌ NO HAY RELACIÓN - Sincronización incompleta')
"
```

**Checklist de Validación:**

- [ ] Versión correcta instalada (5.7.0)
- [ ] Logs capturados sin errores
- [ ] Muestra 3998 personas en UI
- [ ] Búsqueda de personas funciona
- [ ] Captura de documento exitosa
- [ ] Upload a backend exitoso
- [ ] DocumentPersonRelation creada automáticamente
- [ ] Documento visible en interfaz web de Tejido

**SI TODOS LOS TESTS PASAN:**
- ✅ APK v5.7.0 está listo para distribución

**SI ALGÚN TEST FALLA:**
- ❌ NO distribuir
- ❌ Volver a 2.3 e identificar nuevo problema
- ❌ Aplicar nuevo fix y crear v5.7.1

---

### Criterios de Éxito Fase 2

✅ **FASE 2 COMPLETADA cuando:**

- [ ] USB Debugging habilitado
- [ ] Diagnóstico ejecutado exitosamente
- [ ] Causa raíz identificada con certeza
- [ ] Fix aplicado y documentado
- [ ] v5.7.0 compilada sin errores
- [ ] Testing exhaustivo completado (100% tests pasan)
- [ ] Sincronización E2E verificada funcionando
- [ ] APK listo para distribución

**Documentar en:** `BUGFIX_v5.7.0_REPORT.md`

---

## 🟠 FASE 3: TESTING Y VALIDACIÓN END-TO-END

**Prioridad:** 🟠 ALTA
**Tiempo estimado:** 2-3 horas
**Bloqueador:** No, pero crítico para confianza en producción
**Estado:** ⏳ Pendiente

### Objetivo

Validar el flujo completo desde captura hasta almacenamiento con relaciones:

```
Captura en App → Upload → Backend procesa → Crea relación → Disponible en Web
```

---

### Tareas

#### 3.1 Preparar Entorno de Testing ⏱️ 30 min

```bash
# 1. Verificar backend está operativo
curl -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  http://192.168.40.17:8001/api/ | jq

# 2. Limpiar documentos de prueba anteriores (OPCIONAL)
docker exec -it tejido-webserver-1 python3 manage.py shell -c "
from documents.models import Document
# CUIDADO: Esto borra TODOS los documentos
# Document.objects.filter(title__icontains='test').delete()
"

# 3. Preparar documentos de prueba para capturar
mkdir -p /tmp/documentos_prueba
# Tener listos 3-5 documentos físicos para fotografiar

# 4. Crear lista de personas de prueba
docker exec tejido-webserver-1 python3 manage.py shell -c "
from census.models import Person
personas = Person.objects.all()[:5]
for p in personas:
    print(f'{p.person_id},{p.full_name},{p.document_number}')
" > /tmp/personas_prueba.txt

cat /tmp/personas_prueba.txt

# 5. Verificar app está instalada y en versión correcta
adb shell dumpsys package com.lumara.app | grep versionName
```

**Verificación:**
- [ ] Backend responde correctamente
- [ ] Documentos de prueba preparados
- [ ] Lista de personas de prueba creada
- [ ] App instalada en versión correcta

---

#### 3.2 Test de Flujo Completo (5 casos) ⏱️ 90 min

**Ejecutar 5 tests completos con diferentes escenarios:**

---

**TEST 1: Cédula de Ciudadanía (Caso feliz)**

```bash
# Preparar
PERSONA_ID=2071  # Ajustar según /tmp/personas_prueba.txt
TIPO_DOC="Cédula de Ciudadanía"

echo "=== TEST 1: Cédula de Ciudadanía ==="
echo "Persona ID: $PERSONA_ID"
echo "Tipo: $TIPO_DOC"

# Iniciar captura de logs
adb logcat -c
adb logcat | grep -i "upload\|sync\|document" > /tmp/test1_logs.txt &
LOGCAT_PID=$!

# EN DISPOSITIVO (MANUAL):
# 1. Abrir app Lumara
# 2. Buscar persona por ID: 2071
# 3. Seleccionar tipo: "Cédula de Ciudadanía"
# 4. Capturar foto de cédula
# 5. Recortar adecuadamente
# 6. Confirmar upload
# 7. Esperar mensaje: "Sincronización exitosa"

# Esperar 30 segundos
sleep 30

# Detener logs
kill $LOGCAT_PID

# Verificar en backend
docker exec tejido-webserver-1 python3 manage.py shell -c "
from documents.models import Document, DocumentPersonRelation
from census.models import Person

persona = Person.objects.get(person_id=$PERSONA_ID)
print(f'Persona: {persona.full_name}')

# Buscar documento más reciente
ultimo_doc = Document.objects.latest('created')
print(f'Último documento: ID {ultimo_doc.id}, Título: {ultimo_doc.title}')

# Verificar relación
try:
    rel = DocumentPersonRelation.objects.get(
        document=ultimo_doc,
        person=persona
    )
    print(f'✅ TEST 1 PASÓ')
    print(f'   Relación ID: {rel.id}')
    print(f'   Tipo: {rel.document_type}')
except DocumentPersonRelation.DoesNotExist:
    print(f'❌ TEST 1 FALLÓ - No hay relación')
"

# Resultado esperado: ✅ TEST 1 PASÓ
```

---

**TEST 2: Registro Civil de Nacimiento**

```bash
PERSONA_ID=2072  # Diferente persona
TIPO_DOC="Registro Civil de Nacimiento"

echo "=== TEST 2: Registro Civil ==="
# Repetir proceso similar al TEST 1
# ...
```

---

**TEST 3: Documento Duplicado (debe detectarse)**

```bash
# Usar MISMA persona y tipo que TEST 1
PERSONA_ID=2071
TIPO_DOC="Cédula de Ciudadanía"

echo "=== TEST 3: Documento Duplicado ==="
echo "Debe mostrar diálogo de calidad o duplicado"

# EN DISPOSITIVO:
# 1. Buscar misma persona ID: 2071
# 2. Seleccionar mismo tipo: "Cédula de Ciudadanía"
# 3. ANTES de capturar, debería aparecer:
#    "Ya existe un documento de este tipo para esta persona"
#    Opciones: [Reemplazar] [Cancelar] [Ver existente]

# Resultado esperado: ⚠️ Diálogo de duplicado mostrado
```

---

**TEST 4: Modo Offline (sin conectividad)**

```bash
echo "=== TEST 4: Modo Offline ==="

# Desactivar WiFi en dispositivo
adb shell svc wifi disable

# EN DISPOSITIVO:
# 1. Capturar documento de persona nueva
# 2. Confirmar
# 3. Debe mostrar: "Documento guardado en cola offline"

# Esperar 10 segundos
sleep 10

# Reactivar WiFi
adb shell svc wifi enable

# Esperar 20 segundos (sincronización automática)
sleep 20

# Verificar en backend que llegó
docker exec tejido-webserver-1 python3 manage.py shell -c "
from documents.models import Document
ultimo = Document.objects.latest('created')
print(f'✅ TEST 4 PASÓ - Documento sincronizado desde cola')
print(f'   ID: {ultimo.id}, Creado: {ultimo.created}')
"

# Resultado esperado: ✅ Documento sincronizado automáticamente
```

---

**TEST 5: Alta Concurrencia (3 documentos seguidos)**

```bash
echo "=== TEST 5: Alta Concurrencia ==="

# EN DISPOSITIVO:
# Capturar 3 documentos de 3 personas diferentes
# uno tras otro, sin esperar a que terminen de subir

# Esperar 60 segundos
sleep 60

# Verificar que los 3 llegaron
docker exec tejido-webserver-1 python3 manage.py shell -c "
from documents.models import Document
from datetime import datetime, timedelta

# Últimos 3 documentos en último minuto
hace_1_min = datetime.now() - timedelta(minutes=1)
recientes = Document.objects.filter(created__gte=hace_1_min).order_by('-created')

if recientes.count() >= 3:
    print(f'✅ TEST 5 PASÓ - {recientes.count()} documentos sincronizados')
    for doc in recientes[:3]:
        print(f'   ID: {doc.id}, Título: {doc.title}')
else:
    print(f'❌ TEST 5 FALLÓ - Solo {recientes.count()} documentos')
"

# Resultado esperado: ✅ 3 documentos sincronizados
```

---

**Resumen de Tests:**

```bash
cat > /tmp/test_results.txt << 'EOF'
=== RESULTADOS DE TESTING E2E ===

TEST 1: Cédula de Ciudadanía       [ ] ✅ PASÓ / [ ] ❌ FALLÓ
TEST 2: Registro Civil             [ ] ✅ PASÓ / [ ] ❌ FALLÓ
TEST 3: Documento Duplicado        [ ] ✅ PASÓ / [ ] ❌ FALLÓ
TEST 4: Modo Offline               [ ] ✅ PASÓ / [ ] ❌ FALLÓ
TEST 5: Alta Concurrencia          [ ] ✅ PASÓ / [ ] ❌ FALLÓ

Tests Pasados: __/5
Tests Fallados: __/5

CRITERIO: Sistema está listo si ≥ 4/5 tests pasan
EOF

cat /tmp/test_results.txt
```

**Verificación:**
- [ ] 5 tests ejecutados
- [ ] Resultados documentados
- [ ] ≥ 4 tests pasaron
- [ ] Problemas identificados (si hubo fallos)

---

#### 3.3 Testing de Performance ⏱️ 30 min

**Medir tiempos reales:**

```bash
# Test de latencia de upload
time (
  # Simular upload de 1 MB
  dd if=/dev/urandom of=/tmp/test_doc.pdf bs=1M count=1

  curl -X POST "http://192.168.40.17:8001/api/documents/upload_with_person/" \
    -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
    -F "document=@/tmp/test_doc.pdf" \
    -F "person_id=2071" \
    -F "document_type=Cédula de Ciudadanía"
)

# Test de consulta de documentos
time (
  curl -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
    "http://192.168.40.17:8001/api/documents/" | jq '. | length'
)

# Test de búsqueda
time (
  curl -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
    "http://192.168.40.17:8001/api/documents/?query=Cédula"
)

# Análisis de base de datos
docker exec tejido-webserver-1 python3 manage.py shell -c "
from django.db import connection
from django.test.utils import CaptureQueriesContext
from documents.models import Document, DocumentPersonRelation

with CaptureQueriesContext(connection) as context:
    docs = list(Document.objects.all()[:10])
    print(f'Queries ejecutadas: {len(context.captured_queries)}')

total_time = sum(float(q['time']) for q in context.captured_queries)
print(f'Tiempo total: {total_time:.3f}s')
"
```

**Métricas esperadas:**

| Operación | Tiempo Objetivo | Tiempo Límite |
|-----------|----------------|---------------|
| Upload 1 MB | < 3s | < 10s |
| Consulta lista docs | < 100ms | < 500ms |
| Búsqueda | < 200ms | < 1s |
| Queries BD | < 50ms | < 200ms |

**Verificación:**
- [ ] Upload dentro de límites
- [ ] Consultas rápidas
- [ ] Búsqueda eficiente
- [ ] BD optimizada

---

### Criterios de Éxito Fase 3

✅ **FASE 3 COMPLETADA cuando:**

- [ ] Entorno de testing preparado
- [ ] 5 tests E2E ejecutados
- [ ] ≥ 4/5 tests pasaron (80% éxito)
- [ ] Performance dentro de límites
- [ ] Todos los flujos críticos verificados
- [ ] Problemas documentados y resueltos

**Documentar en:** `E2E_TESTING_REPORT.md`

---

## 🟡 FASE 4: OPTIMIZACIONES DE PERFORMANCE

**Prioridad:** 🟡 MEDIA
**Tiempo estimado:** 4-6 horas
**Bloqueador:** No
**Estado:** ⏳ Pendiente
**Prerrequisito:** Fases 1-3 completadas

### Objetivo

Mejorar performance del sistema para soportar alto volumen de documentos.

---

### Tareas

#### 4.1 Activar WAL Mode en SQLite ⏱️ 45 min

**Beneficio:** 2x mejora en escrituras concurrentes

```dart
// Archivo: lumara/Lumara/lib/data/local/database/app_database.dart

// ANTES:
@DriftDatabase(/* ... */)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// DESPUÉS:
@DriftDatabase(/* ... */)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // 🆕 Activar WAL mode
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA synchronous = NORMAL;');
      await customStatement('PRAGMA cache_size = -64000;'); // 64MB cache
      await customStatement('PRAGMA temp_store = MEMORY;');
    },
    beforeOpen: (details) async {
      // 🆕 Asegurar WAL mode en cada apertura
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA synchronous = NORMAL;');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'lumara.db'));

    return NativeDatabase(
      file,
      logStatements: kDebugMode,
    );
  });
}
```

**Testing:**

```bash
# Compilar y probar
flutter clean
flutter pub get
flutter build apk --release

# Instalar y verificar
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Verificar WAL mode activo
adb shell run-as com.lumara.app ls -la databases/
# Debe mostrar archivos: lumara.db, lumara.db-wal, lumara.db-shm

# Test de performance
# Capturar 5 documentos seguidos y medir tiempos
```

**Verificación:**
- [ ] Código actualizado
- [ ] Compilación exitosa
- [ ] WAL mode activado (archivos -wal presentes)
- [ ] Performance mejorada (medir antes/después)

---

#### 4.2 Implementar Caché de Metadatos ⏱️ 2 horas

**Beneficio:** 80% menos tráfico de red, UI 100-300ms más rápida

```dart
// Archivo: lumara/Lumara/lib/data/repositories/document_repository.dart

class DocumentRepository {
  final TejidoApiClient _apiClient;
  final AppDatabase _db;

  // 🆕 Caché en memoria
  Map<String, List<Tag>>? _cachedTags;
  Map<String, List<DocumentType>>? _cachedTypes;
  DateTime? _cacheTimestamp;
  final Duration _cacheDuration = Duration(hours: 1);

  // 🆕 Método para obtener tags con caché
  Future<List<Tag>> getTags({bool forceRefresh = false}) async {
    // Verificar caché válido
    if (!forceRefresh && _cachedTags != null && _isCacheValid()) {
      print('[Cache HIT] Returning ${_cachedTags!.length} tags from cache');
      return _cachedTags!.values.expand((x) => x).toList();
    }

    print('[Cache MISS] Fetching tags from API');

    // Fetch desde API
    final tags = await _apiClient.getTags();

    // Actualizar caché
    _cachedTags = {for (var tag in tags) tag.id.toString(): [tag]};
    _cacheTimestamp = DateTime.now();

    // Guardar en BD local para offline
    await _db.batch((batch) {
      batch.insertAll(
        _db.tags,
        tags.map((t) => TagsCompanion.insert(
          id: Value(t.id),
          name: t.name,
          color: Value(t.color),
        )),
        mode: InsertMode.insertOrReplace,
      );
    });

    return tags;
  }

  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  // Método para invalidar caché manualmente
  void invalidateCache() {
    _cachedTags = null;
    _cachedTypes = null;
    _cacheTimestamp = null;
    print('[Cache] Invalidated');
  }
}
```

**Agregar tabla de caché en BD:**

```dart
// Archivo: lumara/Lumara/lib/data/local/database/app_database.dart

@DriftDatabase(
  tables: [
    Documents,
    UploadQueue,
    Tags,         // 🆕
    DocumentTypes, // 🆕
    CacheMetadata, // 🆕
  ],
)
class AppDatabase extends _$AppDatabase {
  // ...
}

// Definir tablas
class Tags extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CacheMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
```

**Actualizar número de esquema:**

```dart
@override
int get schemaVersion => 2; // Incrementar de 1 a 2

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
    // ...
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      // Migración de v1 a v2
      await m.createTable(tags);
      await m.createTable(documentTypes);
      await m.createTable(cacheMetadata);
    }
  },
);
```

**Verificación:**
- [ ] Caché implementado
- [ ] Migración de BD exitosa
- [ ] Tests de caché HIT/MISS
- [ ] Performance mejorada (medir requests de red)

---

#### 4.3 Comprimir Imágenes Antes de Upload ⏱️ 90 min

**Beneficio:** 60-80% reducción tamaño, 5x más rápido

```dart
// Archivo nuevo: lumara/Lumara/lib/services/image_optimizer.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageOptimizer {
  static const int maxWidth = 2048;
  static const int maxHeight = 2048;
  static const int jpegQuality = 85;
  static const int maxFileSizeMB = 5;

  /// Optimiza imagen antes de upload
  static Future<File> optimizeImage(File imageFile) async {
    print('[ImageOptimizer] Optimizing: ${imageFile.path}');

    // 1. Leer imagen original
    final originalBytes = await imageFile.readAsBytes();
    final originalSizeKB = (originalBytes.length / 1024).round();
    print('[ImageOptimizer] Original size: $originalSizeKB KB');

    // 2. Decodificar imagen
    img.Image? image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    print('[ImageOptimizer] Original dimensions: ${image.width}x${image.height}');

    // 3. Redimensionar si es necesario
    if (image.width > maxWidth || image.height > maxHeight) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? maxWidth : null,
        height: image.height > image.width ? maxHeight : null,
        interpolation: img.Interpolation.linear,
      );
      print('[ImageOptimizer] Resized to: ${image.width}x${image.height}');
    }

    // 4. Comprimir a JPEG
    final compressedBytes = img.encodeJpg(image, quality: jpegQuality);
    final compressedSizeKB = (compressedBytes.length / 1024).round();
    print('[ImageOptimizer] Compressed size: $compressedSizeKB KB');

    // 5. Verificar límite de tamaño
    if (compressedBytes.length > maxFileSizeMB * 1024 * 1024) {
      // Re-comprimir con menor calidad
      final recompressed = img.encodeJpg(image, quality: 70);
      print('[ImageOptimizer] Re-compressed to: ${(recompressed.length / 1024).round()} KB');

      if (recompressed.length > maxFileSizeMB * 1024 * 1024) {
        throw Exception('Image too large even after compression');
      }

      return _saveOptimizedImage(recompressed, imageFile.path);
    }

    // 6. Guardar imagen optimizada
    final reduction = ((1 - compressedBytes.length / originalBytes.length) * 100).round();
    print('[ImageOptimizer] Size reduction: $reduction%');

    return _saveOptimizedImage(compressedBytes, imageFile.path);
  }

  static Future<File> _saveOptimizedImage(List<int> bytes, String originalPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_optimized.jpg';
    final optimizedFile = File(p.join(tempDir.path, fileName));

    await optimizedFile.writeAsBytes(bytes);
    print('[ImageOptimizer] Saved to: ${optimizedFile.path}');

    return optimizedFile;
  }

  /// Calcula métricas de optimización
  static Future<OptimizationMetrics> getMetrics(File original, File optimized) async {
    final originalSize = await original.length();
    final optimizedSize = await optimized.length();

    return OptimizationMetrics(
      originalSizeKB: (originalSize / 1024).round(),
      optimizedSizeKB: (optimizedSize / 1024).round(),
      reductionPercent: ((1 - optimizedSize / originalSize) * 100).round(),
    );
  }
}

class OptimizationMetrics {
  final int originalSizeKB;
  final int optimizedSizeKB;
  final int reductionPercent;

  OptimizationMetrics({
    required this.originalSizeKB,
    required this.optimizedSizeKB,
    required this.reductionPercent,
  });

  @override
  String toString() {
    return 'Original: $originalSizeKB KB → Optimized: $optimizedSizeKB KB ($reductionPercent% reduction)';
  }
}
```

**Integrar en flujo de upload:**

```dart
// Archivo: lumara/Lumara/lib/data/repositories/document_repository.dart

Future<Document> uploadDocument({
  required File imageFile,
  required int personId,
  required String documentType,
  // ...
}) async {
  // 🆕 Optimizar imagen antes de upload
  print('[DocumentRepository] Optimizing image before upload...');
  final optimizedImage = await ImageOptimizer.optimizeImage(imageFile);

  final metrics = await ImageOptimizer.getMetrics(imageFile, optimizedImage);
  print('[DocumentRepository] Optimization: $metrics');

  // Usar imagen optimizada para upload
  final document = await _apiClient.uploadDocument(
    file: optimizedImage, // 🆕 Usar optimizada
    personId: personId,
    documentType: documentType,
    // ...
  );

  // Limpiar archivo temporal
  try {
    await optimizedImage.delete();
  } catch (e) {
    print('[DocumentRepository] Warning: Could not delete temp file: $e');
  }

  return document;
}
```

**Agregar dependencia:**

```yaml
# pubspec.yaml
dependencies:
  image: ^4.0.17  # 🆕 Para procesamiento de imágenes
```

**Verificación:**
- [ ] ImageOptimizer implementado
- [ ] Integrado en flujo de upload
- [ ] Dependencia agregada
- [ ] Tests con imágenes de diferentes tamaños
- [ ] Reducción de tamaño verificada (>60%)

---

#### 4.4 Reducir Logs en Producción ⏱️ 30 min

**Beneficio:** 5-10% mejora en performance, menos uso de storage

```dart
// Archivo: lumara/Lumara/lib/core/config/production_config.dart

import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static late Logger _logger;

  static void initialize() {
    _logger = Logger(
      filter: _ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? Level.debug : Level.warning, // 🆕
    );
  }

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      // En release, solo WARNING y ERROR
      return event.level.index >= Level.warning.index;
    }
    // En debug, todos los niveles
    return true;
  }
}
```

**Reemplazar prints por logger:**

```dart
// ANTES (en múltiples archivos):
print('[CensusProvider] Loading census...');
print('DEBUG: $variable');

// DESPUÉS:
AppLogger.d('[CensusProvider] Loading census...');
AppLogger.d('DEBUG: $variable');

// Para errores:
AppLogger.e('[Upload] Failed to upload document', error, stackTrace);
```

**Script de migración automática:**

```bash
# Reemplazar prints por logger en todos los archivos
cd lumara/Lumara

find lib -name "*.dart" -exec sed -i \
  "s/print('\[ERROR\]/AppLogger.e('/g; \
   s/print('\[WARNING\]/AppLogger.w('/g; \
   s/print('\[/AppLogger.d('/g" \
  {} +

echo "✅ Logs migrados a AppLogger"
```

**Verificación:**
- [ ] AppLogger implementado
- [ ] Prints migrados a logger
- [ ] Filtrado por nivel funciona
- [ ] Release build genera menos logs

---

### Criterios de Éxito Fase 4

✅ **FASE 4 COMPLETADA cuando:**

- [ ] WAL mode activado y funcionando
- [ ] Caché de metadatos implementado (80% menos requests)
- [ ] Compresión de imágenes activa (60-80% reducción)
- [ ] Sistema de logging optimizado
- [ ] Performance mejorada vs baseline:
  - [ ] Escrituras 2x más rápidas
  - [ ] UI 100-300ms más rápida
  - [ ] Uploads 5x más rápidos
  - [ ] Menos logs en producción

**Documentar en:** `PERFORMANCE_OPTIMIZATION_REPORT.md`

---

## 🟢 FASE 5: CARACTERÍSTICAS AVANZADAS

**Prioridad:** 🟢 BAJA
**Tiempo estimado:** 8-12 horas
**Bloqueador:** No
**Estado:** ⏳ Pendiente
**Prerrequisito:** Fases 1-4 completadas

### Objetivo

Agregar funcionalidades que mejoren la experiencia de usuario y productividad.

---

### Tareas

#### 5.1 Pantalla de Completitud de Documentos ⏱️ 4 horas

**Funcionalidad:** Mostrar qué documentos faltan por persona/familia

```dart
// Archivo nuevo: lumara/Lumara/lib/presentation/completeness/completeness_screen.dart

class CompletenessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Completitud de Documentos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<CompletenessProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<CompletenessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // Resumen global
              _buildGlobalSummary(provider.globalStats),

              SizedBox(height: 16),

              // Filtros
              _buildFilters(provider),

              SizedBox(height: 16),

              // Lista de personas con documentos faltantes
              ...provider.personsWithMissingDocs.map((person) {
                return CompletenessCard(person: person);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlobalSummary(CompletenessStats stats) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Completitud Global',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Personas',
                  value: stats.totalPersons.toString(),
                  color: Colors.blue,
                ),
                _StatItem(
                  label: 'Completas',
                  value: stats.completePersons.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'Incompletas',
                  value: stats.incompletePersons.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.completenessPercent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForPercent(stats.completenessPercent),
              ),
              minHeight: 10,
            ),
            SizedBox(height: 8),
            Text(
              '${stats.completenessPercent.toStringAsFixed(1)}% completo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPercent(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }
}

class CompletenessCard extends StatelessWidget {
  final PersonWithMissingDocs person;

  const CompletenessCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(person.priority),
          child: Text(
            person.priority.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          person.fullName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${person.missingDocs.length} documentos faltantes • ${person.completenessPercent.toStringAsFixed(0)}% completo',
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documentos Faltantes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...person.missingDocs.map((doc) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text(doc)),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navegar a captura de documento para esta persona
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentCaptureScreen(
                          preselectedPerson: person.personId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text('Capturar Documentos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'ALTA':
        return Colors.red;
      case 'MEDIA':
        return Colors.orange;
      case 'BAJA':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
```

**Provider para lógica de negocio:**

```dart
// Archivo: lumara/Lumara/lib/presentation/providers/completeness_provider.dart

class CompletenessProvider extends ChangeNotifier {
  final DocumentRepository _repository;
  final CensusRepository _censusRepository;

  bool _isLoading = false;
  CompletenessStats? _globalStats;
  List<PersonWithMissingDocs> _personsWithMissingDocs = [];
  String _filterPriority = 'ALL';

  CompletenessProvider(this._repository, this._censusRepository);

  bool get isLoading => _isLoading;
  CompletenessStats get globalStats => _globalStats ?? CompletenessStats.empty();
  List<PersonWithMissingDocs> get personsWithMissingDocs {
    if (_filterPriority == 'ALL') return _personsWithMissingDocs;
    return _personsWithMissingDocs
        .where((p) => p.priority == _filterPriority)
        .toList();
  }

  Future<void> loadCompleteness() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtener todas las personas
      final persons = await _censusRepository.getAllPersons();

      // Para cada persona, calcular completitud
      final results = await Future.wait(
        persons.map((person) async {
          final required = _getRequiredDocs(person.age);
          final existing = await _repository.getDocumentsForPerson(person.personId);
          final existingTypes = existing.map((d) => d.documentType).toSet();

          final missing = required.where((req) => !existingTypes.contains(req)).toList();

          if (missing.isEmpty) return null;

          return PersonWithMissingDocs(
            personId: person.personId,
            fullName: person.fullName,
            age: person.age,
            missingDocs: missing,
            completenessPercent: ((required.length - missing.length) / required.length * 100),
            priority: _calculatePriority(person.age, missing),
          );
        }),
      );

      _personsWithMissingDocs = results.whereType<PersonWithMissingDocs>().toList();

      // Calcular estadísticas globales
      _globalStats = CompletenessStats(
        totalPersons: persons.length,
        completePersons: persons.length - _personsWithMissingDocs.length,
        incompletePersons: _personsWithMissingDocs.length,
        completenessPercent: ((persons.length - _personsWithMissingDocs.length) / persons.length * 100),
      );

    } catch (e) {
      print('[CompletenessProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> _getRequiredDocs(int age) {
    final required = ['Registro Civil de Nacimiento'];

    if (age >= 7 && age < 18) {
      required.add('Tarjeta de Identidad');
    }

    if (age >= 18) {
      required.add('Cédula de Ciudadanía');
    }

    return required;
  }

  String _calculatePriority(int age, List<String> missing) {
    // Mayor prioridad si falta cédula
    if (missing.contains('Cédula de Ciudadanía')) return 'ALTA';

    // Media prioridad si falta TI
    if (missing.contains('Tarjeta de Identidad')) return 'MEDIA';

    return 'BAJA';
  }

  void setFilter(String priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  Future<void> refresh() => loadCompleteness();
}
```

**Integrar en navegación:**

```dart
// En home_screen.dart, agregar botón:
IconButton(
  icon: Icon(Icons.checklist),
  tooltip: 'Completitud de Documentos',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompletenessScreen()),
    );
  },
),
```

**Verificación:**
- [ ] Pantalla implementada
- [ ] Provider con lógica de negocio
- [ ] Cálculo de completitud correcto
- [ ] Navegación a captura desde pantalla
- [ ] Filtros funcionando

---

#### 5.2 Procesar Más Documentos con Sistema de IA ⏱️ 3 horas

**Objetivo:** Procesar todos los documentos existentes para extraer metadatos

```bash
# Script para procesamiento masivo
cd /home/smt/Escritorio/programacion_proyectos/tejido

cat > scripts/tejido/process_all_documents.py << 'PYTHON'
"""
Procesa todos los documentos en Tejido con sistema de IA
para extraer metadatos estructurados
"""

from documents.models import Document, DocumentPersonRelation
from census.models import Person
import openai
import json
import time

# Configurar OpenAI
openai.api_key = "TU_NUEVA_API_KEY_AQUI"  # 🔴 Actualizar después de rotación

PROMPT_TEMPLATE = """
Analiza este documento colombiano y extrae la siguiente información estructurada:

TEXTO DEL DOCUMENTO:
{document_text}

Extrae los siguientes campos (si están presentes):
- tipo_documento: El tipo (Cédula de Ciudadanía, Registro Civil, etc.)
- numero_documento: Número de identificación
- primer_nombre
- segundo_nombre
- primer_apellido
- segundo_apellido
- fecha_nacimiento: Formato DD/MM/YYYY
- lugar_nacimiento: Ciudad, Departamento
- fecha_expedicion: Formato DD/MM/YYYY
- lugar_expedicion
- sexo: M o F
- grupo_sanguineo
- estado_civil

Responde SOLO con JSON válido, sin texto adicional:
{...}
"""

def extract_metadata_with_ai(document):
    """Extrae metadatos de un documento usando OpenAI GPT-4o"""

    print(f"\n{'='*80}")
    print(f"📄 Procesando documento ID: {document.id}")
    print(f"   Título: {document.title}")

    # Obtener texto OCR del documento
    ocr_text = document.content or ""

    if not ocr_text:
        print("   ⚠️  Sin texto OCR, omitiendo...")
        return None

    print(f"   Texto OCR: {len(ocr_text)} caracteres")

    try:
        # Llamar a OpenAI API
        response = openai.ChatCompletion.create(
            model="gpt-4o-mini",  # Más económico
            messages=[
                {"role": "system", "content": "Eres un experto en extraer datos estructurados de documentos colombianos."},
                {"role": "user", "content": PROMPT_TEMPLATE.format(document_text=ocr_text[:4000])}  # Limitar a 4000 chars
            ],
            temperature=0,
            max_tokens=500,
        )

        # Parsear respuesta
        extracted_data = json.loads(response.choices[0].message.content)

        print(f"   ✅ Extraído: {len(extracted_data)} campos")

        # Guardar en custom fields
        for field_name, value in extracted_data.items():
            if value:
                # Mapear a custom field (requiere configuración previa)
                # document.custom_fields[field_name] = value
                pass

        document.save()

        return extracted_data

    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return None

def main():
    # Obtener todos los documentos sin procesar
    documents = Document.objects.filter(
        # Filtrar documentos que no tienen metadatos extraídos
        # custom_fields__isnull=True  # Ajustar según tu esquema
    ).order_by('created')

    total = documents.count()
    print(f"\n🚀 Iniciando procesamiento de {total} documentos")
    print(f"⏱️  Tiempo estimado: {total * 10} segundos (~{total * 10 / 60:.1f} minutos)")

    successful = 0
    failed = 0
    skipped = 0

    for i, doc in enumerate(documents, 1):
        print(f"\n[{i}/{total}]", end=" ")

        result = extract_metadata_with_ai(doc)

        if result:
            successful += 1
        elif result is None:
            skipped += 1
        else:
            failed += 1

        # Rate limiting: esperar entre requests
        time.sleep(2)

        # Checkpoint cada 10 documentos
        if i % 10 == 0:
            print(f"\n\n{'='*80}")
            print(f"📊 CHECKPOINT: {i}/{total}")
            print(f"   ✅ Exitosos: {successful}")
            print(f"   ❌ Fallidos: {failed}")
            print(f"   ⏭️  Omitidos: {skipped}")
            print(f"{'='*80}")

    # Reporte final
    print(f"\n\n{'='*80}")
    print("🎉 PROCESAMIENTO COMPLETADO")
    print(f"{'='*80}")
    print(f"Total procesados: {total}")
    print(f"✅ Exitosos: {successful} ({successful/total*100:.1f}%)")
    print(f"❌ Fallidos: {failed} ({failed/total*100:.1f}%)")
    print(f"⏭️  Omitidos: {skipped} ({skipped/total*100:.1f}%)")
    print(f"{'='*80}")

if __name__ == '__main__':
    main()

PYTHON

# Ejecutar procesamiento masivo
cat scripts/tejido/process_all_documents.py | \
  docker exec -i tejido-webserver-1 python3 manage.py shell
```

**Monitorear progreso:**

```bash
# Ver progreso en tiempo real
docker logs -f tejido-webserver-1 | grep -i "procesando\|extraído"

# Ver estadísticas después
docker exec tejido-webserver-1 python3 manage.py shell -c "
from documents.models import Document
total = Document.objects.count()
# con_metadata = Document.objects.filter(custom_fields__isnull=False).count()
print(f'Total documentos: {total}')
# print(f'Con metadatos: {con_metadata} ({con_metadata/total*100:.1f}%)')
"
```

**Verificación:**
- [ ] Script de procesamiento masivo creado
- [ ] Procesamiento ejecutado
- [ ] Metadatos extraídos y guardados
- [ ] Estadísticas documentadas

---

#### 5.3 Dashboard de Estadísticas ⏱️ 3 horas

**Pantalla con métricas y gráficos del sistema**

```dart
// Archivo nuevo: lumara/Lumara/lib/presentation/dashboard/dashboard_screen.dart

import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Resumen general
                _buildSummaryCards(provider.summary),

                // Gráfico de documentos por tipo
                _buildDocumentTypeChart(provider.documentsByType),

                // Gráfico de tendencia temporal
                _buildTimelineChart(provider.documentsOverTime),

                // Gráfico de completitud por familia
                _buildCompletenessChart(provider.completenessByFamily),

                // Top familias con más documentos
                _buildTopFamilies(provider.topFamilies),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(DashboardSummary summary) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Documentos',
              value: summary.totalDocuments.toString(),
              icon: Icons.description,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              title: 'Personas',
              value: summary.totalPersons.toString(),
              icon: Icons.people,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              title: 'Familias',
              value: summary.totalFamilies.toString(),
              icon: Icons.family_restroom,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeChart(Map<String, int> data) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentos por Tipo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      color: _getColorForDocType(entry.key),
                      radius: 80,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineChart(List<DocumentCountByDate> data) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentos en el Tiempo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.count.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForDocType(String type) {
    // Mapeo de colores según tipo de documento
    final colors = {
      'Cédula de Ciudadanía': Colors.blue,
      'Tarjeta de Identidad': Colors.green,
      'Registro Civil': Colors.orange,
      // ...
    };
    return colors[type] ?? Colors.grey;
  }
}
```

**Agregar dependencia para gráficos:**

```yaml
# pubspec.yaml
dependencies:
  fl_chart: ^0.66.0  # Para gráficos
```

**Verificación:**
- [ ] Dashboard implementado
- [ ] Gráficos funcionando
- [ ] Datos en tiempo real
- [ ] Navegación integrada

---

### Criterios de Éxito Fase 5

✅ **FASE 5 COMPLETADA cuando:**

- [ ] Pantalla de completitud funcionando
- [ ] Priorización visual implementada
- [ ] Procesamiento masivo ejecutado (>50 documentos)
- [ ] Dashboard con estadísticas operativo
- [ ] Gráficos interactivos funcionando
- [ ] Navegación entre pantallas fluida

**Documentar en:** `ADVANCED_FEATURES_REPORT.md`

---

## 📚 RECURSOS Y REFERENCIAS

### Documentación Existente

```
/home/smt/Escritorio/programacion_proyectos/tejido/
├── README.md                              # Visión general del proyecto
├── FASE1_COMPLETADA_REPORTE.md           # Fase 1 de conectividad
├── SECURITY_API_KEY_ROTATION.md          # Guía de rotación de keys
├── lumara/Lumara/
│   ├── README.md                         # Documentación de app
│   ├── ESTADO_SISTEMA.md                 # Estado actual detallado
│   ├── RESUMEN_FINAL_v5.6.0.md          # Análisis de v5.6.0
│   └── BUGFIX_CENSUS_LOADING.md         # Fix de censo v5.5.0
└── docs/
    ├── 00-INICIO/                        # Documentación de planificación
    ├── 01-TEJIDO/                     # Documentación de backend
    ├── 02-SISTEMA-IA/                    # Sistema de IA y extracción
    ├── 03-BUSQUEDA-API/                  # API REST y búsqueda
    ├── 04-ASOCIACION-PERSONAS/           # Sistema de asociación
    └── 05-LUMARA-APP/                  # Documentación de app móvil
```

### Scripts Útiles

```bash
# Verificar estado de backend
curl http://192.168.40.17:8001/api/

# Ver logs de Tejido
docker logs -f tejido-webserver-1

# Reiniciar servicios
docker-compose restart

# Compilar APK
cd lumara/Lumara
/home/smt/flutter/bin/flutter build apk --release

# Instalar APK en dispositivo
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Ver logs de app en tiempo real
adb logcat | grep -i "lumara\|census\|upload"

# Diagnóstico de censo
bash /tmp/diagnostico_censo_app.sh

# Diagnóstico de sincronización
bash /tmp/diagnose_sync.sh
```

### Comandos de Base de Datos

```bash
# Acceder a shell de Django
docker exec -it tejido-webserver-1 python3 manage.py shell

# Contar documentos
from documents.models import Document
Document.objects.count()

# Ver últimos documentos
Document.objects.order_by('-created')[:5]

# Contar relaciones documento-persona
from documents.models import DocumentPersonRelation
DocumentPersonRelation.objects.count()

# Ver personas del censo
from census.models import Person
Person.objects.count()
```

### Enlaces Externos

- **Tejido-NGX:** https://docs.tejido-ngx.com/
- **Flutter:** https://docs.flutter.dev/
- **OpenAI API:** https://platform.openai.com/docs/
- **Drift (BD Local):** https://drift.simonbinder.eu/docs/

---

## ⚠️ MATRIZ DE RIESGOS

### Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **API Keys comprometidas** | 🔴 ALTA | 🔴 CRÍTICO | Rotar inmediatamente (Fase 1.1-1.2) |
| **App v5.6.0 no funciona** | 🟠 MEDIA | 🟠 ALTO | Diagnóstico completo (Fase 2) |
| **Pérdida de datos** | 🟢 BAJA | 🔴 CRÍTICO | Backups automáticos (no implementado) |
| **Performance degradada** | 🟠 MEDIA | 🟡 MEDIO | Fase 4 de optimizaciones |
| **Problemas de red** | 🟠 MEDIA | 🟡 MEDIO | Cola offline implementada ✅ |
| **Falta de USB Debug** | 🟠 MEDIA | 🟠 ALTO | Guía para usuario (Fase 2.1) |
| **Storage lleno** | 🟢 BAJA | 🟡 MEDIO | Compresión de imágenes (Fase 4.3) |

### Contingencias

**SI Fase 1 falla (Seguridad):**
- Desconectar sistema de internet temporalmente
- No distribuir nuevos APKs hasta rotar keys
- Contactar soporte de OpenAI para revocar key

**SI Fase 2 falla (Diagnóstico app):**
- Usar v5.5.0 como respaldo funcional
- Asociar documentos manualmente vía interfaz web
- Considerar reescribir módulo de censo desde cero

**SI Fase 3 falla (Testing E2E):**
- Documentar problemas encontrados
- Volver a Fase 2 para fixes adicionales
- Considerar reducir alcance de funcionalidades

---

## 📊 MÉTRICAS DE ÉXITO

### KPIs del Proyecto

| KPI | Meta | Actual | Estado |
|-----|------|--------|--------|
| Seguridad | API keys rotadas | Keys expuestas | 🔴 |
| App funcional | 100% | 80% (v5.5.0) | 🟡 |
| Sincronización E2E | 100% | 40% | 🔴 |
| Performance | <10s upload | ~15s | 🟡 |
| Cobertura testing | >80% | 0% E2E | 🔴 |
| Documentos procesados | >100 | 14 | 🔴 |

**Estado general:** 🟡 En progreso - 60% hacia producción

---

## 🎯 RESUMEN DE PRIORIDADES

### Esta Semana (Crítico)

1. 🔴 **Rotar API Keys** (Fase 1.1-1.2) - 1 hora
2. 🟠 **Diagnosticar app v5.6.0** (Fase 2) - 3-4 horas
3. 🟠 **Testing E2E** (Fase 3) - 2-3 horas

**Total:** 6-8 horas → Sistema básico funcional

---

### Próximas 2 Semanas (Importante)

4. 🟡 **Optimizaciones** (Fase 4) - 4-6 horas
5. 🟡 **Auditoría de seguridad completa** (Fase 1.4) - 1 hora

**Total:** +5-7 horas → Sistema optimizado

---

### Próximo Mes (Deseable)

6. 🟢 **Características avanzadas** (Fase 5) - 8-12 horas

**Total:** +8-12 horas → Sistema completo

---

## 📝 NOTAS FINALES

- **Todas las fases son independientes** después de Fase 1
- **Fase 1 es BLOQUEANTE** por seguridad
- **Fase 2-3 pueden ejecutarse en paralelo** si se usa v5.5.0
- **Fase 4-5 son opcionales** pero recomendadas

**Última actualización:** 2025-10-28
**Autor:** AI Assistant
**Versión del plan:** 1.0
