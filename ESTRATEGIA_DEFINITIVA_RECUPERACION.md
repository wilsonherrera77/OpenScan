# ESTRATEGIA DEFINITIVA DE RECUPERACIÓN
## Sistema Lumara + Tejido - Análisis y Plan de Acción

**Fecha:** 2025-11-09
**Estado:** SITUACIÓN CRÍTICA - Ciclo Vicioso Identificado
**Prioridad:** 🔴 MÁXIMA

---

## 🚨 DIAGNÓSTICO: EL CÍRCULO VICIOSO

### Síntomas Observados

1. **20+ APKs en 10 días** - Sin claridad de cuál funciona
2. **QR Configuration**: 6 intentos fallidos (v5.8.0 → v5.8.3 → v5.9.0)
3. **Admin Digitization**: Código agregado pero no funciona (v6.0.0/v6.0.1)
4. **Frontend Tejido**: Link QR no aparece a pesar de múltiples rebuilds
5. **Testing Gap**: APKs distribuidos sin testing en dispositivo real
6. **Version Confusion**: README dice v5.6.0 es la actual, pero tenemos v6.0.1

### Causas Raíz Identificadas

#### 1. **AUSENCIA DE CONTROL DE VERSIONES REAL**
```bash
# Estado actual Git:
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
git status
# Resultado: "Not a git repository"
```

**Impacto:**
- No hay historial de qué cambió entre versiones
- Imposible hacer rollback a versión funcionando
- No se puede hacer diff entre v5.7.0 (funciona?) y v6.0.0 (no funciona)
- Cada build es un "salto al vacío"

#### 2. **NO HAY PROTOCOLO DE TESTING**
```bash
# Proceso actual (INCORRECTO):
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ~/Descargas/Lumara_vX.X.X.apk
# Usuario instala → "No funciona"
```

**Debería ser:**
```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
# TESTING MANUAL: verificar 5 features críticas
# LOGS: adb logcat para confirmar sin errores
# SOLO ENTONCES copiar a Descargas
```

#### 3. **DEMASIADAS FEATURES PARALELAS**

**Últimas 48 horas:**
- QR Configuration (Tejido dashboard + Lumara scanning)
- Admin Digitization (nuevo botón)
- Instant IP Configuration (sin QR)
- Cleartext traffic fix
- Timeout increases
- Debug logging

**Resultado:** Ninguna feature funciona completamente porque se mezclan cambios

#### 4. **PROBLEMAS DE CACHÉ SIN RESOLVER**

**Tejido (Angular):**
- Código actualizado en archivos
- Docker rebuild ejecutado
- Pero navegador sigue mostrando versión anterior
- **Nunca se ejecutó:** `Ctrl+Shift+R` (hard refresh)

**Lumara (Flutter):**
- Cambios en `admin_dashboard_screen.dart`
- Build exitoso
- Pero dispositivo no muestra cambios
- **Nunca se ejecutó:** `flutter clean` antes de build

#### 5. **DOCUMENTACIÓN DESORGANIZADA**

```bash
# 43 archivos markdown encontrados
# Cuáles son actuales?
- ESTADO_SISTEMA.md (oct 12) - desactualizado 28 días
- README.md (oct 12) - menciona v5.6.0 como actual
- RESUMEN_FINAL_v5.6.0.md - pero ahora estamos en v6.0.1?
- ROADMAP dice FASE 1 completa, pero no funciona?
```

---

## 🎯 ESTRATEGIA DE RECUPERACIÓN (3 FASES)

### FASE 1: ESTABILIZACIÓN (2-3 horas)
**Objetivo:** Encontrar UNA versión funcionando y establecerla como baseline

#### Paso 1.1: Identificar Última Versión Funcional VERIFICADA

Según documentación:
- **v5.5.0** (oct 12): ✅ Verificado - carga 3998 personas, uploads funcionan (sin relaciones)
- **v5.7.0** (nov 3): ✅ Existe en Descargas (96MB)
- **v5.6.0**: ❌ "0 personas" - no funcionar
- **v5.8.x - v6.0.x**: ❓ Sin verificación

**Acción Inmediata:**
```bash
# 1. Buscar v5.7.0 (última "FINAL" antes de QR chaos)
ls -lh ~/Descargas/Lumara_v5.7.0*.apk
# Si existe: este es candidato #1

# 2. Si no existe, usar v5.5.0 (última verificada)
# Según ESTADO_SISTEMA.md: "RECOMENDADO PARA USO"
```

**Testing Protocol (OBLIGATORIO antes de declarar "funcional"):**
```bash
# A. Desinstalar completamente
adb uninstall com.ethereal.lumara

# B. Instalar candidato
adb install -r ~/Descargas/Lumara_v5.7.0_FINAL_20251103.apk

# C. Capturar logs durante inicio
adb logcat -c
adb logcat | tee /tmp/baseline_test_$(date +%Y%m%d_%H%M%S).log &
LOGCAT_PID=$!

# D. Abrir app y verificar MANUALMENTE:
echo "✓ 1. ¿Muestra 3998 personas?"
echo "✓ 2. ¿Login funciona?"
echo "✓ 3. ¿Puede seleccionar persona?"
echo "✓ 4. ¿Puede capturar documento?"
echo "✓ 5. ¿Upload exitoso?"

# E. Detener logs
kill $LOGCAT_PID

# F. Verificar en backend
curl -s -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  "http://192.168.40.17:8001/api/documents/" | jq '.count'
```

**Output esperado:**
```
✅ 1. Censo: 3998 Personas
✅ 2. Login: exitoso
✅ 3. Selección: búsqueda funciona
✅ 4. Captura: cámara abre, foto tomada
✅ 5. Upload: "Sincronización exitosa"
Backend: count incrementó en 1
```

**Si v5.7.0 NO existe o NO funciona:**
```bash
# Rollback a v5.5.0 (última verificada)
adb install -r ~/Descargas/Lumara_v5.5.0_UNIX_EOL_GARANTIZADO_20251012_113207.apk
# Repetir testing protocol
```

#### Paso 1.2: Establecer Baseline en Git

**CRÍTICO:** Sin Git, imposible avanzar de forma segura

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# 1. Verificar si hay .git oculto
ls -la | grep .git

# 2. Si NO existe, inicializar
git init
git config user.name "Equipo Lumara"
git config user.email "equipo@lumara.local"

# 3. Crear .gitignore
cat > .gitignore <<EOF
# Build outputs
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/

# IDE
.idea/
.vscode/
*.iml

# Android
android/app/debug
android/app/profile
android/app/release
*.apk

# Secrets (importante!)
*.env
**/google-services.json
**/firebase_options.dart
EOF

# 4. Commit BASELINE (versión que funciona)
git add .
git commit -m "baseline: Lumara v5.7.0 - última versión funcional verificada

Features funcionando:
- Censo: 3998 personas
- Login con token
- Selección de persona con búsqueda
- Captura de documentos
- Upload a Tejido-ngx

Known issues:
- Sin relaciones automáticas persona-documento
- Sin QR configuration
- Admin no puede digitalizar (solo reportes)

Testing: Verificado en dispositivo 2025-11-09
APK: Lumara_v5.7.0_FINAL_20251103.apk
MD5: [copiar de ls -l]"

# 5. Crear tag para fácil referencia
git tag -a v5.7.0-baseline -m "Baseline - Última versión funcional verificada"
```

#### Paso 1.3: Establecer Branch Strategy

```bash
# 1. Branch principal = baseline estable
git branch -M main

# 2. NUNCA trabajar en main directamente
# SIEMPRE crear feature branch

# Ejemplo:
git checkout -b feature/qr-configuration
# ... hacer cambios ...
# ... testing COMPLETO ...
# ... SI funciona, merge a main
git checkout main
git merge feature/qr-configuration
```

**REGLA DE ORO:**
```
main = SIEMPRE funcional, SIEMPRE testeado
feature/* = experimental, puede romperse
```

---

### FASE 2: IMPLEMENTACIÓN CONTROLADA (4-6 horas)
**Objetivo:** Agregar features UNA POR UNA con testing exhaustivo

#### Feature Priority Matrix

| Feature | Prioridad | Complejidad | Riesgo | Orden |
|---------|-----------|-------------|--------|-------|
| Admin puede digitalizar | 🔴 ALTA | 🟢 Baja | 🟢 Bajo | 1 |
| Instant IP config (sin QR) | 🟠 MEDIA | 🟢 Baja | 🟢 Bajo | 2 |
| QR configuration (mobile) | 🟡 BAJA | 🔴 Alta | 🔴 Alto | 4 |
| QR link en Tejido dashboard | 🟡 BAJA | 🟠 Media | 🟠 Medio | 3 |

**Razón del orden:**
1. **Admin digitization**: Cambio simple, crítico para usuarios
2. **Instant IP config**: No depende de QR, fácil de testear
3. **Tejido QR link**: Prerequisito para QR mobile
4. **QR mobile**: Mayor complejidad, requiere 1-3 funcionando

#### Workflow por Feature (OBLIGATORIO)

**Ejemplo: Feature 1 - Admin Digitization**

```bash
# PASO 1: Branch desde baseline
git checkout main
git checkout -b feature/admin-digitization

# PASO 2: TodoWrite para trackear
# (usar TodoWrite tool de AI Assistant)

# PASO 3: Implementación focalizada
# SOLO modificar archivos de esta feature
# NO mezclar con otras features

# PASO 4: Build local
flutter clean
flutter pub get
flutter build apk --release

# PASO 5: Testing exhaustivo
adb uninstall com.ethereal.lumara  # Limpio
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Verificar feature específica:
echo "Test 1: Admin login → Dashboard"
echo "Test 2: Verificar 5 botones (no 4)"
echo "Test 3: Click 'Capturar Documento'"
echo "Test 4: Navega a PersonSelectionScreen"
echo "Test 5: Captura completa funciona"

# PASO 6: Verificar NO REGRESIONES
echo "Test 6: Censo sigue mostrando 3998?"
echo "Test 7: Login sigue funcionando?"
echo "Test 8: Upload sigue funcionando?"

# PASO 7: SOLO si TODO funciona
git add .
git commit -m "feat: admin can digitize documents

Added 'Capturar Documento' button to AdminDashboard.
Admin users can now access PersonSelectionScreen.

Files changed:
- lib/presentation/admin/admin_dashboard_screen.dart

Testing:
- ✅ Admin sees 5 buttons (not 4)
- ✅ Button navigates to PersonSelectionScreen
- ✅ Full capture flow works
- ✅ No regressions in existing features

APK: Lumara_v5.7.1_AdminDigitization_$(date +%Y%m%d_%H%M%S).apk"

# PASO 8: Copiar APK con nombre descriptivo
cp build/app/outputs/flutter-apk/app-release.apk \
   ~/Descargas/Lumara_v5.7.1_AdminDigitization_$(date +%Y%m%d_%H%M%S).apk

# PASO 9: Merge a main SOLO si testing completo
git checkout main
git merge feature/admin-digitization --no-ff
git tag v5.7.1-admin-digitization

# PASO 10: Actualizar versión en pubspec.yaml para siguiente feature
```

#### Feature 2: Instant IP Configuration

```bash
git checkout main
git checkout -b feature/instant-ip-config

# Implementación:
# - Ya existe en login_screen.dart (líneas 272-458)
# - Verificar si está presente en baseline

# Testing:
# 1. Click "Configurar IP Manualmente"
# 2. Ingresar IP 192.168.40.17, Puerto 8001
# 3. Verificar campo URL actualiza
# 4. Verificar SharedPreferences guarda
# 5. Verificar login funciona con nueva IP

# Si funciona en baseline:
git commit --allow-empty -m "docs: instant IP config already working in baseline"

# Si NO está en baseline:
# ... implementar ...
# ... testing completo ...
git add .
git commit -m "feat: instant IP configuration without QR"
git checkout main
git merge feature/instant-ip-config --no-ff
git tag v5.7.2-instant-ip-config
```

#### Feature 3: QR Link en Tejido Dashboard (COMPLEJO)

**Pre-requisitos:**
- Backend endpoint `/dashboard/qr-setup/` funcional (✅ ya existe)
- Angular template actualizado (✅ ya hecho, pero no visible)

**Problema:** Browser cache

```bash
# 1. Branch
git checkout main
cd /home/smt/Escritorio/programacion_proyectos/tejido/tejido-ngx/tejido-ngx
git status  # Verificar si hay .git

# 2. Verificar cambios en app-frame.component.html
grep -n "QR Mobile Setup" src-ui/src/app/components/app-frame/app-frame.component.html

# Si líneas 277-285 tienen el código @if...

# 3. Docker rebuild FORZADO
docker-compose stop webserver
docker-compose rm -f webserver
docker-compose build --no-cache webserver
docker-compose up -d webserver

# 4. Esperar compilación Angular (2-3 minutos)
docker-compose logs -f webserver | grep -i "webpack compiled"

# 5. Verificar en archivos compilados
docker exec tejido-webserver-1 grep -r "dashboard/qr-setup" /usr/src/tejido/static/frontend/

# 6. CRÍTICO: Browser hard refresh
# En navegador: Ctrl+Shift+R (Linux/Windows) o Cmd+Shift+R (Mac)
# O en Chrome DevTools: Network tab → Disable cache

# 7. Verificar en navegador incógnito
# Abrir http://192.168.40.17:8001/dashboard en modo incógnito
```

**Si TODAVÍA no aparece:**

```bash
# Diagnostic profundo
Task(
  subagent_type="Explore",
  model="sonnet",
  prompt="""
  Analyze why 'QR Mobile Setup' link is not appearing in Tejido sidebar despite:
  1. Code present in app-frame.component.html (lines 277-285)
  2. Docker container rebuilt with --no-cache
  3. 'dashboard/qr-setup' found in compiled JavaScript

  Check:
  - Angular version and @if syntax compatibility
  - PermissionsService.isAdmin() implementation
  - Component imports (CommonModule not needed for @if)
  - Possible conflicting CSS (display:none)
  - Angular AOT compilation issues

  Thoroughness: very thorough
  """
)
```

#### Feature 4: QR Mobile Scanning (MÁS COMPLEJO)

**SOLO intentar después de Feature 3 funcionando**

**Problema conocido:** TimeoutException después de 30s

**Hipótesis:**
1. Network connectivity (phone no alcanza server)
2. Endpoint `/api/` no responde
3. Android blocking (ya resuelto con cleartext)

**Antes de re-implementar:**

```bash
# 1. Verificar conectividad básica
# En terminal del dispositivo (si tiene):
ping 192.168.40.17

# O desde PC:
adb shell ping -c 3 192.168.40.17

# 2. Verificar ambos en misma red WiFi
# PC IP:
ip addr show | grep "inet 192"

# Phone IP:
adb shell ip addr show wlan0 | grep "inet "

# Deben estar en misma subnet (192.168.40.x)

# 3. Test endpoint desde PC en misma WiFi
curl -v http://192.168.40.17:8001/api/

# 4. Si PC puede pero phone no:
# - Firewall en server bloqueando phone?
# - Router isolating clients?
# - VPN en phone?
```

**Si connectivity OK pero sigue timeout:**

```bash
# Delegar a Explore subagent
Task(
  subagent_type="Explore",
  model="sonnet",
  prompt="""
  Analyze QR configuration timeout in Lumara app:

  Known facts:
  - Cleartext traffic enabled (AndroidManifest.xml)
  - Timeout increased to 30s
  - 3 retry attempts with 2s delay
  - PC can reach server, phone cannot

  Files to analyze:
  - lib/presentation/auth/qr_config_screen.dart (lines 140-214)
  - android/app/src/main/AndroidManifest.xml

  Investigate:
  - Network security config needed?
  - DNS resolution issues?
  - Proxy configuration?
  - Certificate validation failing?

  Provide specific fixes with code.
  Thoroughness: very thorough
  """
)
```

---

### FASE 3: PROCESO SOSTENIBLE (2 horas setup)
**Objetivo:** Prevenir futuras regresiones

#### 3.1: Testing Automatizado

```bash
# Crear script de testing
cat > scripts/test_apk_before_release.sh <<'EOF'
#!/bin/bash
set -e

APK_PATH="$1"
if [ -z "$APK_PATH" ]; then
  echo "Usage: $0 <path-to-apk>"
  exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "  LUMARA APK TESTING PROTOCOL"
echo "════════════════════════════════════════════════════════"

# 1. Verificar APK existe
if [ ! -f "$APK_PATH" ]; then
  echo "❌ APK no encontrado: $APK_PATH"
  exit 1
fi

# 2. Verificar device conectado
if ! adb devices | grep -q "device$"; then
  echo "❌ No device connected. Enable USB debugging."
  exit 1
fi

# 3. Uninstall anterior
echo "🧹 Desinstalando versión anterior..."
adb uninstall com.ethereal.lumara 2>/dev/null || true

# 4. Install nueva
echo "📦 Instalando $APK_PATH..."
adb install -r "$APK_PATH"

# 5. Clear logs
adb logcat -c

# 6. Iniciar logs en background
echo "📝 Capturando logs..."
LOG_FILE="/tmp/lumara_test_$(date +%Y%m%d_%H%M%S).log"
adb logcat > "$LOG_FILE" &
LOGCAT_PID=$!

# 7. Launch app
echo "🚀 Lanzando app..."
adb shell monkey -p com.ethereal.lumara 1
sleep 5

# 8. Tests manuales
echo ""
echo "════════════════════════════════════════════════════════"
echo "  TESTS MANUALES (verificar en dispositivo)"
echo "════════════════════════════════════════════════════════"
echo ""
echo "✓ 1. ¿Muestra 'Lumara Scan' en header?"
echo "✓ 2. ¿Login screen visible?"
echo "✓ 3. Login con credenciales → ¿exitoso?"
echo "✓ 4. ¿Censo muestra 3998 personas?"
echo "✓ 5. ¿Búsqueda de persona funciona?"
echo "✓ 6. Seleccionar persona → ¿navega a tipos de doc?"
echo "✓ 7. Capturar documento → ¿cámara abre?"
echo "✓ 8. Tomar foto → ¿muestra preview?"
echo "✓ 9. Guardar → ¿muestra 'Sincronizando...'?"
echo "✓ 10. ¿Muestra 'Sincronización exitosa'?"
echo ""
read -p "¿Todos los tests pasaron? (y/n): " PASSED

# 9. Stop logs
kill $LOGCAT_PID

# 10. Analyze logs
echo ""
echo "Analizando logs..."
if grep -qi "error\|exception\|crash" "$LOG_FILE"; then
  echo "⚠️  ADVERTENCIA: Errores encontrados en logs"
  grep -i "error\|exception" "$LOG_FILE" | head -20
fi

# 11. Resultado
if [ "$PASSED" == "y" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  ✅ APK APROBADO PARA RELEASE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Logs guardados en: $LOG_FILE"
  echo ""
  echo "Próximos pasos:"
  echo "1. git add ."
  echo "2. git commit -m 'release: vX.X.X - descripción'"
  echo "3. git tag vX.X.X"
  echo "4. cp $APK_PATH ~/Descargas/Lumara_vX.X.X_RELEASE_$(date +%Y%m%d_%H%M%S).apk"
  exit 0
else
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  ❌ APK RECHAZADO - NO LIBERAR"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Logs guardados en: $LOG_FILE"
  echo "Revisar errores antes de continuar"
  exit 1
fi
EOF

chmod +x scripts/test_apk_before_release.sh
```

**Uso:**
```bash
flutter build apk --release
./scripts/test_apk_before_release.sh build/app/outputs/flutter-apk/app-release.apk
```

#### 3.2: Pre-commit Hooks

```bash
# Crear hook para prevenir commits accidentales con TODOs críticos
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash

# Buscar TODOs críticos
if git diff --cached | grep -i "TODO.*CRITICAL\|FIXME.*URGENT"; then
  echo "❌ Commit bloqueado: TODOs críticos sin resolver"
  echo ""
  git diff --cached | grep -i "TODO.*CRITICAL\|FIXME.*URGENT"
  exit 1
fi

# Buscar hardcoded tokens
if git diff --cached | grep -E "token.*=.*['\"][a-f0-9]{40}"; then
  echo "❌ Commit bloqueado: Token hardcoded detectado"
  exit 1
fi

# Verificar que pubspec.yaml version coincide con tag
# (implementar si es necesario)

exit 0
EOF

chmod +x .git/hooks/pre-commit
```

#### 3.3: Documentation Protocol

```bash
# Crear template para release notes
cat > RELEASE_TEMPLATE.md <<'EOF'
# Release vX.X.X - [Título Descriptivo]

**Fecha:** YYYY-MM-DD
**Branch:** feature/xxx
**APK:** Lumara_vX.X.X_[Descriptor]_YYYYMMDD_HHMMSS.apk
**MD5:** [md5sum del APK]
**Testing:** ✅ Aprobado / ❌ Pendiente

---

## Cambios

### Added
- [Nueva funcionalidad 1]
- [Nueva funcionalidad 2]

### Fixed
- [Bug fix 1]
- [Bug fix 2]

### Changed
- [Cambio 1]

### Removed
- [Feature removida]

---

## Testing Realizado

**Device:** [Modelo de dispositivo]
**Android:** [Versión Android]

- [ ] 1. Censo carga 3998 personas
- [ ] 2. Login funciona
- [ ] 3. Búsqueda funciona
- [ ] 4. Captura funciona
- [ ] 5. Upload funciona
- [ ] 6. [Feature específica nueva] funciona
- [ ] 7. No regresiones detectadas

---

## Known Issues

- [Issue 1 si existe]
- [Issue 2 si existe]

---

## Archivos Modificados

```
lib/presentation/xxx.dart
pubspec.yaml
```

---

## Commits Incluidos

```
git log v[anterior]..v[actual] --oneline
```
EOF
```

#### 3.4: Subagent Strategy (AI Assistant Specific)

**Cuándo usar cada subagent:**

```markdown
| Tarea | Subagent | Model | Razón |
|-------|----------|-------|-------|
| Buscar archivos relacionados a feature | Explore | haiku | Rápido, económico |
| Planificar feature compleja | Plan | sonnet | Calidad, análisis profundo |
| Implementar feature > 100 líneas | general-purpose | sonnet | Calidad código |
| Generar tests | general-purpose | sonnet | Coverage completo |
| Code review multi-perspectiva | Explore | sonnet | Análisis detallado |
| Debugging error desconocido | general-purpose | sonnet | Troubleshooting |
| Documentación | Explore | haiku | Suficiente para docs |
```

**Ejemplo de uso correcto:**

```bash
# INCORRECTO (no usar):
Grep(pattern="admin_dashboard", output_mode="files_with_matches")
Read("lib/presentation/admin/admin_dashboard_screen.dart")
# ... análisis manual ...

# CORRECTO (delegar a subagent):
Task(
  subagent_type="Explore",
  model="haiku",
  prompt="""
  Find all files related to admin dashboard functionality:
  1. Screen file
  2. Provider/state management
  3. Routes definition
  4. Any widgets used

  Provide file paths with brief description.
  Thoroughness: medium
  """
)
```

---

## 📊 MÉTRICAS DE ÉXITO

### Indicadores a Trackear

**Por Feature:**
- ✅ Tests manuales pasan (10/10)
- ✅ Tests automatizados pasan (si existen)
- ✅ Logs sin errores críticos
- ✅ No regresiones detectadas
- ✅ Backend verifica cambios (si aplica)
- ✅ Commit con mensaje descriptivo
- ✅ Tag creado
- ✅ APK copiado con nombre descriptivo
- ✅ Release notes escritas

**Por Sprint (1 semana):**
- Features completadas: [meta: 2-3]
- Bugs introducidos: [meta: 0]
- Tests coverage: [meta: >80%]
- Tiempo promedio por feature: [meta: <4 horas]

**Salud del Proyecto:**
- Git commits por semana: [meta: 10-20]
- Branches activos: [meta: 1-3]
- APKs generados: [meta: 1 por feature]
- Documentación actualizada: [meta: 100%]

---

## 🚀 PLAN DE ACCIÓN INMEDIATO (PRÓXIMAS 8 HORAS)

### Hora 0-1: Estabilización
```bash
# 1. Encontrar baseline funcional
./verificar_baseline.sh

# 2. Inicializar Git
cd Lumara && git init && git add . && git commit -m "baseline"

# 3. Testing exhaustivo de baseline
./scripts/test_apk_before_release.sh ~/Descargas/Lumara_v5.7.0*.apk
```

### Hora 1-3: Feature #1 - Admin Digitization
```bash
# 1. Branch
git checkout -b feature/admin-digitization

# 2. Verificar si ya existe en código
grep -n "Capturar Documento" lib/presentation/admin/admin_dashboard_screen.dart

# 3. Si existe pero no funciona: debugging
Task(subagent_type="Explore", model="sonnet", prompt="Why admin button not showing...")

# 4. Si no existe: implementar
# ... código ...

# 5. Testing completo
flutter clean && flutter build apk --release
./scripts/test_apk_before_release.sh build/app/outputs/flutter-apk/app-release.apk

# 6. Commit y merge
git add . && git commit -m "feat: admin digitization"
git checkout main && git merge feature/admin-digitization --no-ff
```

### Hora 3-5: Feature #2 - Instant IP Config
```bash
# Similar workflow
git checkout -b feature/instant-ip-config
# ... implementar/verificar ...
# ... testing ...
# ... merge ...
```

### Hora 5-7: Feature #3 - Tejido QR Link
```bash
# 1. Docker hard rebuild
docker-compose build --no-cache webserver

# 2. Browser hard refresh
# Ctrl+Shift+R en navegador

# 3. Verificar con incógnito
```

### Hora 7-8: Documentación y Entrega
```bash
# 1. Actualizar README.md
# 2. Crear ESTADO_ACTUAL_$(date +%Y%m%d).md
# 3. Commit final
git add . && git commit -m "docs: update to v5.7.3"
# 4. Push a remote (si existe)
```

---

## 🛡️ REGLAS DE ORO (NO ROMPER NUNCA)

1. **NUNCA compilar sin Git commit**
2. **NUNCA distribuir APK sin testing en dispositivo**
3. **NUNCA mezclar múltiples features en un branch**
4. **NUNCA hacer cambios directos en `main`**
5. **NUNCA omitir `flutter clean` antes de build crítico**
6. **NUNCA asumir "funcionó en mi máquina" = "funciona en producción"**
7. **NUNCA olvidar actualizar documentación**
8. **SIEMPRE capturar logs durante testing**
9. **SIEMPRE verificar en backend después de upload**
10. **SIEMPRE nombrar APKs descriptivamente**

---

## 🆘 CONTACTO DE EMERGENCIA

Si algo sale mal:

1. **Rollback inmediato:**
   ```bash
   git checkout main
   adb install -r ~/Descargas/Lumara_v5.7.0_BASELINE*.apk
   ```

2. **Capturar estado:**
   ```bash
   adb logcat > /tmp/emergency_$(date +%Y%m%d_%H%M%S).log
   git log --oneline -10 > /tmp/git_history.txt
   ```

3. **Leer este documento completo nuevamente**

---

**Fin del Documento de Estrategia Definitiva**
**Siguiente paso:** Ejecutar FASE 1, Paso 1.1
