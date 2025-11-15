# PLAN DE IMPLEMENTACIÓN PRIORIZADO
## Lumara + Tejido by WH - Hoja de Ruta Accionable

**Fecha**: 14 de Noviembre de 2025
**Basado en**: Auditoría de Objetivos 2025-11-14
**Versión Actual**: v6.3.9
**Próxima Versión Objetivo**: v7.0.0 (producción estable)

---

## 🎯 OBJETIVO DEL PLAN

Transformar el proyecto de **37.5% completado** a **100% funcional y verificado** en 6 fases incrementales, resolviendo primero el círculo vicioso de desarrollo y culminando con un sistema seguro, escalable y listo para producción.

---

## 📊 RESUMEN DE FASES

| Fase | Nombre | Duración | Esfuerzo | Prioridad | Inicio | Fin |
|------|--------|----------|----------|-----------|--------|-----|
| **0-R** | Recuperación del Proceso | 1 día | 8-12h | 🔴 CRÍTICA | HOY | +1 día |
| **1** | Verificación E2E | 2 días | 12-16h | 🔴 CRÍTICA | +1 día | +3 días |
| **2** | Seguridad Crítica | 3 días | 16-20h | 🔴 CRÍTICA | +3 días | +6 días |
| **3** | UX y Productividad | 3 días | 20-24h | 🟠 MEDIA | +6 días | +9 días |
| **4** | Escalabilidad | 3 días | 16-20h | 🟡 BAJA | +9 días | +12 días |
| **5** | Accesibilidad | 4 días | 24-30h | 🟡 BAJA | +12 días | +16 días |
| **6** | CRVS | 3-6 meses | 200+h | 🟢 FUTURA | TBD | TBD |

**Duración Total Fases Críticas (0-R → 2)**: 6 días laborales
**Duración Total al 100% (0-R → 5)**: 16 días laborales

---

## 🔴 FASE 0-R: RECUPERACIÓN DEL PROCESO [BLOQUEANTE]

### Objetivo
Establecer baseline funcional verificado y proceso de desarrollo sostenible.

### Tareas (Checklist)

#### Día 1 - Mañana (4 horas)

- [ ] **0-R.1: Inicializar Git Repository** (1 hora)
  ```bash
  cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

  # Inicializar Git
  git init
  git config user.name "Equipo Lumara"
  git config user.email "equipo@lumara.local"

  # Crear .gitignore
  cat > .gitignore <<'EOF'
  # Build outputs
  build/
  .dart_tool/
  *.apk
  *.aab

  # IDE
  .idea/
  .vscode/
  *.iml

  # Environment
  .env
  .env.local

  # Flutter
  .flutter-plugins
  .flutter-plugins-dependencies
  .packages
  .pub-cache/
  .pub/

  # Logs
  *.log

  # OS
  .DS_Store
  Thumbs.db
  EOF

  # Commit baseline
  git add .
  git commit -m "baseline: v6.3.9 - IOSink fix, sync functional, anti-duplicados implemented"
  git tag v6.3.9-baseline

  # Verificar
  git log --oneline -5
  git status
  ```

  **Criterio de Éxito**: `.git/` existe, commit creado, tag presente

- [ ] **0-R.2: Probar v6.3.9 E2E Básico** (2 horas)
  ```bash
  # Test 1: Actualizar IP en app
  # Abrir app → Settings → Server Config
  # Cambiar a: http://192.168.1.21:8001
  # Guardar

  # Test 2: Login
  # Usuario: admin / consumer / digitizer
  # Password: [verificar con usuario]

  # Test 3: Censo carga
  # Ir a "Seleccionar Persona"
  # Buscar: "MARTIN"
  # Verificar aparecen resultados

  # Test 4: Captura documento
  # Seleccionar persona
  # Tipo: Cédula de Ciudadanía
  # Capturar con cámara
  # Subir

  # Test 5: Verificar en Tejido
  # Abrir http://192.168.1.21:8001/admin/documents/document/
  # Buscar documento recién subido
  # Verificar metadata correcta

  # Test 6: Capturar logs
  adb shell "tail -200 /storage/emulated/0/Android/data/com.ethereal.openscan/files/logs/app_*.log" > /tmp/v6.3.9_baseline_test.log

  # Analizar logs
  grep -E "ERROR|WARN|Exception" /tmp/v6.3.9_baseline_test.log
  ```

  **Criterio de Éxito**:
  - Login exitoso
  - Censo carga
  - Documento sube y aparece en Tejido
  - Logs sin errores críticos

- [ ] **0-R.3: Crear Testing Protocol** (1 hora)
  ```bash
  mkdir -p scripts

  cat > scripts/test_apk_before_release.sh <<'EOF'
  #!/bin/bash
  # Testing Protocol for Lumara APK Releases
  # Usage: ./test_apk_before_release.sh <path-to-apk>

  set -e

  APK_PATH=$1

  if [ -z "$APK_PATH" ]; then
    echo "Usage: $0 <path-to-apk>"
    exit 1
  fi

  echo "════════════════════════════════════════"
  echo "  LUMARA APK TESTING PROTOCOL"
  echo "════════════════════════════════════════"
  echo "APK: $APK_PATH"
  echo "Date: $(date)"
  echo ""

  # Test 1: Install
  echo "TEST 1: Installing APK..."
  adb uninstall com.ethereal.openscan 2>/dev/null || true
  adb install -r "$APK_PATH"
  echo "✅ Install successful"
  echo ""

  # Test 2-6: Manual tests with prompts
  echo "TEST 2: Login"
  echo "  → Open app"
  echo "  → Login with test credentials"
  read -p "Did login succeed? (y/n): " login_ok
  [ "$login_ok" != "y" ] && echo "❌ FAILED: Login" && exit 1
  echo "✅ Login OK"
  echo ""

  echo "TEST 3: Censo Loading (3998 personas)"
  echo "  → Go to 'Seleccionar Persona'"
  echo "  → Wait for list to load"
  read -p "Did censo load in <5s? (y/n): " censo_ok
  [ "$censo_ok" != "y" ] && echo "❌ FAILED: Censo" && exit 1
  echo "✅ Censo OK"
  echo ""

  echo "TEST 4: Document Capture"
  echo "  → Select a person"
  echo "  → Select document type: 'Cédula de Ciudadanía'"
  echo "  → Capture photo"
  echo "  → Upload"
  read -p "Did capture and upload succeed? (y/n): " capture_ok
  [ "$capture_ok" != "y" ] && echo "❌ FAILED: Capture" && exit 1
  echo "✅ Capture OK"
  echo ""

  echo "TEST 5: Verify in Tejido"
  echo "  → Open http://192.168.1.21:8001/admin/documents/document/"
  echo "  → Find uploaded document"
  read -p "Is document visible in Tejido? (y/n): " tejido_ok
  [ "$tejido_ok" != "y" ] && echo "❌ FAILED: Tejido" && exit 1
  echo "✅ Tejido OK"
  echo ""

  echo "TEST 6: Anti-Duplicate System"
  echo "  → Try to capture SAME document type for SAME person again"
  read -p "Did app show 'Already exists' dialog? (y/n): " antidup_ok
  [ "$antidup_ok" != "y" ] && echo "❌ FAILED: Anti-duplicate" && exit 1
  echo "✅ Anti-duplicate OK"
  echo ""

  # Capture logs
  LOG_FILE="/tmp/lumara_test_$(date +%Y%m%d_%H%M%S).log"
  echo "Capturing logs to: $LOG_FILE"
  adb shell "tail -500 /storage/emulated/0/Android/data/com.ethereal.openscan/files/logs/app_*.log" > "$LOG_FILE"

  echo ""
  echo "════════════════════════════════════════"
  echo "  ✅ ALL TESTS PASSED"
  echo "════════════════════════════════════════"
  echo "Logs saved to: $LOG_FILE"
  echo ""
  EOF

  chmod +x scripts/test_apk_before_release.sh

  # Commit
  git add scripts/
  git commit -m "chore: add testing protocol for APK releases"
  ```

  **Criterio de Éxito**: Script ejecutable, documenta proceso

#### Día 1 - Tarde (2 horas)

- [ ] **0-R.4: Sincronizar Documentación** (1 hora)

  **Actualizar README.md**:
  ```markdown
  # Lumara Scan

  **Versión Actual**: v6.3.9
  **Estado**: Baseline Funcional (Post IOSink Fix)
  **Última Actualización**: 14 de Noviembre de 2025

  ## ¿Qué es Lumara?

  Sistema de digitalización inteligente de documentos para comunidades indígenas,
  integrado con Paperless-ngx (Tejido by WH).

  ## Características Implementadas

  - ✅ Anti-duplicados con verificación pre-captura
  - ✅ Sincronización offline-first resiliente
  - ✅ OCR híbrido (local + cloud)
  - ✅ Sistema de asignaciones por rol
  - ✅ Dashboard de productividad
  - ⚠️ Seguridad (en desarrollo)

  ## Instalación Rápida

  1. Descargar APK más reciente de `/Descargas/`
  2. Habilitar "Fuentes desconocidas" en Android
  3. Instalar APK
  4. Configurar servidor: http://192.168.1.21:8001
  5. Login con credenciales proporcionadas

  ## Documentación Técnica

  - [Auditoría de Objetivos](docs/AUDITORIA_OBJETIVOS_2025-11-14.md)
  - [Plan de Implementación](docs/PLAN_IMPLEMENTACION_PRIORIZADO.md)
  - [Roadmap](docs/IMPLEMENTATION_ROADMAP.md)
  - [Anti-Duplicados](FASE2_ANTI_DUPLICADOS_IMPLEMENTADO.md)

  ## Para Desarrolladores

  Ver [CLAUDE.md](CLAUDE.md) para workflow de desarrollo.
  ```

  **Actualizar CHANGELOG.md**:
  ```markdown
  # Changelog

  ## [v6.3.9] - 2025-11-13

  ### Fixed
  - 🐛 **CRÍTICO**: Sync timeout de 90s resuelto (IOSink deadlock)
    - `logging_service.dart`: Reemplazado `await File.writeAsString()` con `IOSink.writeln()`
    - Sync ahora completa en <10s vs 90s timeout
    - Logs no bloquean el isolate de Dart

  ### Verified
  - ✅ MINIMAL sync test: 2 segundos exitoso
  - ⏳ Full sync: Pendiente testing E2E

  ### Known Issues
  - Network IP change requiere reconfiguración manual
  - Anti-duplicados implementado pero no verificado E2E

  ## [v6.3.7] - 2025-11-11

  ### Added
  - LoggerAdapter para reemplazar Logger package
  - Non-blocking file I/O con IOSink

  ## [Versiones Anteriores]
  Ver commits para historial completo.
  ```

  Ejecutar:
  ```bash
  git add README.md CHANGELOG.md
  git commit -m "docs: sync documentation with v6.3.9 baseline"
  ```

  **Criterio de Éxito**: README refleja estado actual, CHANGELOG actualizado

- [ ] **0-R.5: Tag y Branch para Desarrollo** (1 hora)
  ```bash
  # Confirmar baseline
  git tag -a v6.3.9-baseline -m "Baseline funcional verificado - IOSink fix"

  # Crear branch para siguiente fase
  git checkout -b feature/fase1-e2e-verification

  # Push a remoto (si existe)
  # git remote add origin <url>
  # git push -u origin main
  # git push --tags

  # Documentar en DEVELOPMENT.md
  cat > DEVELOPMENT.md <<'EOF'
  # Guía de Desarrollo

  ## Workflow de Git

  ### Branches
  - `main`: Código en producción (siempre estable)
  - `feature/*`: Features en desarrollo
  - `hotfix/*`: Fixes urgentes

  ### Proceso
  1. Crear branch desde `main`: `git checkout -b feature/nombre-descriptivo`
  2. Desarrollar con commits frecuentes
  3. Testing local con `./scripts/test_apk_before_release.sh`
  4. Merge a `main` SOLO si tests pasan
  5. Tag nueva versión: `git tag vX.X.X`

  ### Commits
  - Usar conventional commits:
    - `feat:` Nueva funcionalidad
    - `fix:` Corrección de bug
    - `docs:` Documentación
    - `chore:` Mantenimiento
    - `test:` Tests

  ## Compilación

  ```bash
  # SIEMPRE hacer clean antes de builds importantes
  flutter clean
  flutter pub get
  flutter build apk --release

  # Copiar con nombre descriptivo
  cp build/app/outputs/flutter-apk/app-release.apk \
     ~/Descargas/Lumara_vX.X.X_Feature_$(date +%Y%m%d_%H%M%S).apk
  ```

  ## Testing

  ```bash
  # Ejecutar protocol completo
  ./scripts/test_apk_before_release.sh ~/Descargas/Lumara_vX.X.X.apk

  # Tests unitarios (cuando existan)
  flutter test
  ```
  EOF

  git add DEVELOPMENT.md
  git commit -m "docs: add development workflow guide"
  ```

  **Criterio de Éxito**: Branch creado, workflow documentado

### Entregables de FASE 0-R

- [x] Git repository inicializado con baseline commiteado
- [x] v6.3.9 verificado funcionando E2E
- [x] Testing protocol script creado (`scripts/test_apk_before_release.sh`)
- [x] Documentación sincronizada (README, CHANGELOG, DEVELOPMENT)
- [x] Branch `feature/fase1-e2e-verification` creado

### KPIs de Éxito
- ✅ Git log muestra commits
- ✅ v6.3.9 baseline completa 6/6 tests
- ✅ Script de testing ejecutable
- ✅ Documentación refleja estado real

---

## 🔴 FASE 1: VERIFICACIÓN E2E

### Objetivo
Validar que features implementadas funcionan en dispositivos reales con datos reales.

### Pre-requisitos
- ✅ FASE 0-R completada
- 4 usuarios de prueba (Admin, Digitizador, Revisor, Viewer)
- 2-3 dispositivos Android disponibles

### Tareas (Checklist)

#### Día 2-3 (12-16 horas)

- [ ] **1.1: Verificar Anti-Duplicados** (3 horas)

  **Plan de Testing**:
  1. Seleccionar 10 personas del censo
  2. Para cada persona:
     - Capturar documento tipo "Cédula de Ciudadanía"
     - Esperar a que suba
     - Intentar capturar MISMO tipo de documento
     - Verificar: App muestra "Documento Ya Digitalizado"
     - Verificar: NO se crea duplicado en Tejido

  **Comando de verificación**:
  ```bash
  # En Tejido, verificar conteo de documentos por persona
  # Debe ser 1, no 2
  curl -s http://192.168.1.21:8001/api/documents/ \
       -H "Authorization: Token <token>" | \
       jq '.results | map(select(.person_id == "2071")) | length'
  # Output esperado: 1 (no 2)
  ```

  **Logs a capturar**:
  ```bash
  adb shell "tail -500 /storage/emulated/0/Android/data/com.ethereal.openscan/files/logs/app_*.log" | \
  grep -E "check_exists|DUPLICATE|existsWithGoodQuality"
  ```

  **Criterio de Éxito**:
  - 10/10 personas: duplicado detectado y bloqueado
  - 0 duplicados creados en base de datos
  - Diálogos mostrados correctamente

- [ ] **1.2: Verificar Sincronización Offline** (2 horas)

  **Plan de Testing**:
  1. Habilitar modo avión en dispositivo
  2. Capturar 5 documentos
  3. Verificar: Documentos en cola (icono muestra "5 pendientes")
  4. Deshabilitar modo avión
  5. Esperar sincronización automática (max 2 minutos)
  6. Verificar: 5 documentos aparecen en Tejido

  **Logs a capturar**:
  ```bash
  adb shell "tail -1000 /storage/emulated/0/Android/data/com.ethereal.openscan/files/logs/app_*.log" | \
  grep -E "enqueueUpload|processAllPending|Upload enqueued|successfully uploaded"
  ```

  **Criterio de Éxito**:
  - 5/5 documentos se encolan offline
  - 5/5 documentos sincronizan al reconectar
  - Tiempo de sync <30 segundos total

- [ ] **1.3: Verificar Dashboard de Reporting** (2 horas)

  **Plan de Testing**:
  1. Login como Admin
  2. Ir a "Dashboard de Reportes"
  3. Cronometrar tiempo de carga
  4. Verificar datos mostrados:
     - Total documentos
     - Documentos hoy
     - Por tipo de documento (gráfico)
     - Tendencia últimos 7 días (gráfico)
  5. Tomar screenshots
  6. Exportar reporte a CSV
  7. Abrir CSV en computadora, verificar datos

  **Criterio de Éxito**:
  - Dashboard carga en <3 segundos
  - Estadísticas coinciden con Tejido
  - CSV exportado correctamente con todas las columnas

- [ ] **1.4: Verificar Sistema de Asignaciones** (3 horas)

  **Plan de Testing (con 2 dispositivos)**:

  **Dispositivo 1 (Admin)**:
  1. Login como Admin
  2. Ir a "Crear Asignación"
  3. Seleccionar:
     - Digitalizador: Usuario de prueba
     - Persona: "MARTIN HERRERA OCAMPO"
     - Documentos requeridos: 3 (Cédula, Tarjeta, Registro Civil)
  4. Guardar asignación
  5. Cronometrar tiempo hasta confirmación

  **Dispositivo 2 (Digitalizador)**:
  1. Login como Digitalizador
  2. Ir a "Mis Asignaciones"
  3. Verificar asignación aparece
  4. Cronometrar tiempo desde creación (Dispositivo 1) hasta visualización
  5. Capturar 1 documento (Cédula)
  6. Verificar progreso cambia: 0% → 33%
  7. Capturar 2 documentos más
  8. Verificar progreso: 33% → 66% → 100%
  9. Marcar como "Completada"

  **Dispositivo 1 (Admin de nuevo)**:
  1. Refrescar lista de asignaciones
  2. Verificar estado cambió a "Completada"

  **Criterio de Éxito**:
  - Asignación creada en <10 segundos
  - Asignación visible en dispositivo 2 en <10 segundos
  - Progreso actualiza correctamente (0% → 33% → 66% → 100%)
  - Estado final: Completada

- [ ] **1.5: Verificar Control de Acceso por Roles** (2 horas)

  **Plan de Testing (con 4 dispositivos o usuarios)**:

  **Usuario Admin**:
  - ✅ Puede: Crear asignaciones, ver reportes globales, gestionar usuarios
  - ❌ Verificar: No puede ver dashboard de Digitalizador (debe redirigir)

  **Usuario Digitalizador**:
  - ✅ Puede: Ver mis asignaciones, capturar documentos
  - ❌ No puede: Ver reportes globales, crear asignaciones
  - **Test de seguridad**: Intentar acceder a URL de admin manualmente
    - Navegar a: `/admin-dashboard`
    - Verificar: Backend rechaza (401/403)

  **Usuario Revisor**:
  - ✅ Puede: Aprobar/rechazar asignaciones
  - ❌ No puede: Capturar documentos

  **Usuario Viewer**:
  - ✅ Puede: Ver documentos (solo lectura)
  - ❌ No puede: Modificar nada

  **Prueba de Penetración Simple**:
  ```bash
  # Obtener token de Viewer
  VIEWER_TOKEN="<token_de_viewer>"

  # Intentar crear asignación (endpoint de Admin)
  curl -X POST http://192.168.1.21:8001/api/assignments/create/ \
       -H "Authorization: Token $VIEWER_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"digitizer": 2, "person_id": "2071"}'

  # Debe retornar: 403 Forbidden
  ```

  **Criterio de Éxito**:
  - Cada rol ve solo su dashboard apropiado
  - Intentos de acceso no autorizado son rechazados (403)
  - Backend valida permisos, no solo frontend

### Entregables de FASE 1

- [ ] Reporte de testing E2E (PDF/Markdown) con:
  - Screenshots de cada feature funcionando
  - Logs capturados y analizados
  - Tabla de resultados (Test | Resultado | Observaciones)
- [ ] Lista de bugs encontrados (si aplica) en GitHub Issues o documento
- [ ] Métricas recopiladas:
  - Tiempo de carga de censo: ____ segundos
  - Tiempo de creación de asignación: ____ segundos
  - Tasa de éxito de anti-duplicados: ___%
  - Tiempo de sincronización offline: ____ segundos

### KPIs de Éxito FASE 1
- ✅ 5/5 features verificadas funcionando
- ✅ 0 bugs críticos (bloqueantes)
- ✅ Reporte de testing documentado
- ✅ Métricas dentro de objetivos

---

## 🔴 FASE 2: SEGURIDAD CRÍTICA

### Objetivo
Resolver vulnerabilidades críticas identificadas en auditoría antes de uso en producción.

### Pre-requisitos
- ✅ FASE 1 completada sin bugs críticos

### Tareas (Checklist)

#### Día 4-6 (16-20 horas)

- [ ] **2.1: Forzar HTTPS en Producción** (1 hora)

  **Frontend** (`lib/data/datasources/paperless_api_client.dart`):
  ```dart
  // Agregar después de línea 50
  void _validateBaseUrl(String url) {
    if (!url.startsWith('https://') && !url.contains('localhost') && !url.startsWith('192.168.')) {
      throw SecurityException(
        'HTTPS obligatorio en producción. '
        'URL actual: $url no es segura.'
      );
    }
    _logger.i('✅ Base URL validated: $url');
  }

  // Llamar en constructor
  PaperlessApiClient() {
    _validateBaseUrl(_baseUrl);
    // ... resto del código
  }
  ```

  **Backend** (Django `settings.py`):
  ```python
  # Agregar
  SECURE_SSL_REDIRECT = True  # Fuerza HTTPS
  SESSION_COOKIE_SECURE = True
  CSRF_COOKIE_SECURE = True
  SECURE_BROWSER_XSS_FILTER = True
  SECURE_CONTENT_TYPE_NOSNIFF = True
  ```

  **Testing**:
  ```bash
  # Intentar conectar con HTTP
  # Debe fallar con mensaje claro

  # Verificar redirect HTTPS
  curl -I http://192.168.1.21:8001/
  # Debe retornar: 301 Moved Permanently + Location: https://...
  ```

  **Criterio de Éxito**:
  - App rechaza URLs HTTP en producción
  - Backend redirige HTTP → HTTPS

- [ ] **2.2: Pruebas de Penetración Básicas** (3 horas)

  **Test Suite de Seguridad**:

  **Test 1: Acceso Sin Token**
  ```bash
  curl http://192.168.1.21:8001/api/documents/
  # Esperado: 401 Unauthorized
  ```

  **Test 2: Token de Viewer Accediendo a Admin**
  ```bash
  VIEWER_TOKEN="<token>"
  curl -X POST http://192.168.1.21:8001/api/admin/create-user/ \
       -H "Authorization: Token $VIEWER_TOKEN"
  # Esperado: 403 Forbidden
  ```

  **Test 3: Token Expirado**
  ```bash
  # Usar token de hace >24h
  OLD_TOKEN="<token_viejo>"
  curl http://192.168.1.21:8001/api/documents/ \
       -H "Authorization: Token $OLD_TOKEN"
  # Esperado: 401 + mensaje "Token expired, please refresh"
  ```

  **Test 4: SQL Injection en Búsqueda**
  ```bash
  # Intentar inyección SQL en búsqueda de censo
  curl "http://192.168.1.21:8001/api/census/persons/?search='; DROP TABLE persons; --" \
       -H "Authorization: Token <token>"
  # Esperado: Respuesta normal (NO ejecuta SQL), 0 resultados
  ```

  **Test 5: XSS en Metadata**
  ```bash
  # Intentar XSS en campo de notas
  curl -X POST http://192.168.1.21:8001/api/documents/upload_with_person/ \
       -H "Authorization: Token <token>" \
       -F "notes=<script>alert('XSS')</script>"
  # Esperado: HTML escapado, no ejecutado
  ```

  **Documentar resultados**:
  ```bash
  cat > docs/SECURITY_TESTS_REPORT.md <<EOF
  # Reporte de Pruebas de Seguridad

  ## Fecha: $(date)
  ## Versión: v6.3.9

  | Test | Resultado | Observaciones |
  |------|-----------|---------------|
  | Acceso sin token | ✅ PASS | 401 retornado |
  | RBAC enforcement | ✅ PASS | 403 para acceso no autorizado |
  | Token expiration | ❌ FAIL | Tokens no expiran |
  | SQL Injection | ✅ PASS | Django ORM protege |
  | XSS Prevention | ⚠️ WARN | Verificar escapado |

  ## Vulnerabilidades Encontradas
  - [ ] Tokens JWT no expiran (implementar expiración 24h)
  - [ ] ...
  EOF
  ```

  **Criterio de Éxito**:
  - 4/5 tests de seguridad PASS
  - Vulnerabilidades documentadas con severidad

- [ ] **2.3: Implementar Encriptación en Reposo** (6 horas)

  **Crear servicio de encriptación** (`lib/services/encryption_service.dart`):
  ```dart
  import 'dart:typed_data';
  import 'package:encrypt/encrypt.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

  class EncryptionService {
    static const _storage = FlutterSecureStorage();
    static const _keyAlias = 'lumara_encryption_key';

    static Key? _key;
    static final _iv = IV.fromLength(16);

    /// Initialize encryption (call on app start)
    static Future<void> initialize() async {
      // Cargar o generar key
      String? keyString = await _storage.read(key: _keyAlias);

      if (keyString == null) {
        // Primera vez: generar key
        _key = Key.fromSecureRandom(32); // AES-256
        await _storage.write(key: _keyAlias, value: _key!.base64);
      } else {
        _key = Key.fromBase64(keyString);
      }
    }

    /// Encrypt image bytes
    static Uint8List encryptImage(Uint8List imageBytes) {
      if (_key == null) throw StateError('EncryptionService not initialized');

      final encrypter = Encrypter(AES(_key!, mode: AESMode.gcm));
      final encrypted = encrypter.encryptBytes(imageBytes, iv: _iv);
      return encrypted.bytes;
    }

    /// Decrypt image bytes
    static Uint8List decryptImage(Uint8List encryptedBytes) {
      if (_key == null) throw StateError('EncryptionService not initialized');

      final encrypter = Encrypter(AES(_key!, mode: AESMode.gcm));
      final encrypted = Encrypted(encryptedBytes);
      return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: _iv));
    }
  }
  ```

  **Modificar `upload_service.dart`**:
  ```dart
  // Antes de guardar en SQLite
  final imageBytes = await _imageFile.readAsBytes();
  final encryptedBytes = EncryptionService.encryptImage(imageBytes);

  // Guardar encryptedBytes en DB en lugar de imageBytes
  ```

  **Modificar `main.dart`**:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await EncryptionService.initialize();  // NUEVO

    runApp(MyApp());
  }
  ```

  **Testing**:
  ```bash
  # Capturar documento
  # Verificar en SQLite que imagen está encriptada (no legible)
  adb shell "sqlite3 /data/data/com.ethereal.openscan/databases/app_database.db 'SELECT length(image_data) FROM pending_uploads LIMIT 1;'"

  # Abrir archivo con editor hexadecimal
  # Verificar que NO se ve la imagen (debe ser ruido)
  ```

  **Criterio de Éxito**:
  - Imágenes en SQLite no legibles a simple vista
  - App puede desencriptar y subir correctamente
  - Performance: overhead <100ms por imagen

- [ ] **2.4: Implementar Auditoría de Accesos** (8 horas)

  **Backend Django** - Crear modelo:
  ```python
  # paperless_auth/models.py
  from django.db import models
  from django.contrib.auth.models import User

  class AuditLog(models.Model):
      ACTION_CHOICES = [
          ('CREATE', 'Create'),
          ('UPDATE', 'Update'),
          ('DELETE', 'Delete'),
          ('VIEW', 'View'),
          ('DOWNLOAD', 'Download'),
      ]

      user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
      action = models.CharField(max_length=20, choices=ACTION_CHOICES)
      resource_type = models.CharField(max_length=100)  # 'Document', 'Person', etc.
      resource_id = models.IntegerField()
      timestamp = models.DateTimeField(auto_now_add=True)
      ip_address = models.GenericIPAddressField()
      user_agent = models.TextField()
      details = models.JSONField(null=True, blank=True)

      class Meta:
          ordering = ['-timestamp']
          indexes = [
              models.Index(fields=['user', 'timestamp']),
              models.Index(fields=['resource_type', 'resource_id']),
          ]

  # Crear migración
  # python manage.py makemigrations
  # python manage.py migrate
  ```

  **Middleware para logging automático**:
  ```python
  # paperless_auth/middleware.py
  import logging
  from .models import AuditLog

  logger = logging.getLogger(__name__)

  class AuditMiddleware:
      def __init__(self, get_response):
          self.get_response = get_response

      def __call__(self, request):
          response = self.get_response(request)

          # Log CRUD operations
          if request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
              self._log_action(request, response)

          return response

      def _log_action(self, request, response):
          if response.status_code < 400:  # Solo log exitosos
              try:
                  action = self._get_action(request.method)
                  resource_type = self._extract_resource_type(request.path)
                  resource_id = self._extract_resource_id(request.path)

                  AuditLog.objects.create(
                      user=request.user if request.user.is_authenticated else None,
                      action=action,
                      resource_type=resource_type,
                      resource_id=resource_id or 0,
                      ip_address=self._get_client_ip(request),
                      user_agent=request.META.get('HTTP_USER_AGENT', ''),
                  )
              except Exception as e:
                  logger.error(f'Failed to create audit log: {e}')

      def _get_action(self, method):
          return {
              'POST': 'CREATE',
              'PUT': 'UPDATE',
              'PATCH': 'UPDATE',
              'DELETE': 'DELETE',
          }.get(method, 'VIEW')

      def _extract_resource_type(self, path):
          # Ejemplo: /api/documents/123/ → 'Document'
          parts = path.strip('/').split('/')
          if len(parts) >= 2:
              return parts[1].capitalize().rstrip('s')
          return 'Unknown'

      def _extract_resource_id(self, path):
          # Ejemplo: /api/documents/123/ → 123
          parts = path.strip('/').split('/')
          for part in parts:
              if part.isdigit():
                  return int(part)
          return None

      def _get_client_ip(self, request):
          x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
          if x_forwarded_for:
              return x_forwarded_for.split(',')[0]
          return request.META.get('REMOTE_ADDR')

  # Agregar a settings.py
  MIDDLEWARE = [
      # ... otros middleware
      'paperless_auth.middleware.AuditMiddleware',
  ]
  ```

  **Endpoint para Admin ver auditoría**:
  ```python
  # paperless_auth/views.py
  from rest_framework.decorators import api_view, permission_classes
  from rest_framework.permissions import IsAuthenticated, IsAdminUser
  from rest_framework.response import Response
  from .models import AuditLog
  from .serializers import AuditLogSerializer

  @api_view(['GET'])
  @permission_classes([IsAuthenticated, IsAdminUser])
  def audit_logs(request):
      # Filtros opcionales
      user_id = request.GET.get('user')
      action = request.GET.get('action')
      resource_type = request.GET.get('resource_type')

      queryset = AuditLog.objects.all()

      if user_id:
          queryset = queryset.filter(user_id=user_id)
      if action:
          queryset = queryset.filter(action=action)
      if resource_type:
          queryset = queryset.filter(resource_type=resource_type)

      # Paginación
      logs = queryset[:100]  # Últimos 100
      serializer = AuditLogSerializer(logs, many=True)

      return Response(serializer.data)
  ```

  **Testing**:
  ```bash
  # Realizar acciones como diferentes usuarios
  # Verificar logs se crean

  curl http://192.168.1.21:8001/api/auth/audit-logs/ \
       -H "Authorization: Token <admin_token>" | jq

  # Debe retornar array de logs con:
  # - user, action, resource_type, timestamp, ip_address
  ```

  **Criterio de Éxito**:
  - Todas las acciones CRUD loggeadas
  - Admin puede ver auditoría filtrada
  - Performance: <50ms overhead por request

- [ ] **2.5: Verificar Expiración de Tokens JWT** (2 horas)

  **Backend Django** - Verificar/Implementar:
  ```python
  # settings.py
  from datetime import timedelta

  SIMPLE_JWT = {
      'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),
      'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
      'ROTATE_REFRESH_TOKENS': True,
      'BLACKLIST_AFTER_ROTATION': True,
  }
  ```

  **Testing**:
  ```bash
  # Test 1: Obtener token
  TOKEN=$(curl -s -X POST http://192.168.1.21:8001/api/token/ \
               -d "username=admin&password=admin" | jq -r '.access')

  # Test 2: Usar token inmediatamente (debe funcionar)
  curl http://192.168.1.21:8001/api/documents/ \
       -H "Authorization: Bearer $TOKEN"

  # Test 3: Esperar 24 horas (o cambiar timestamp del token manualmente)
  # Token debe expirar y retornar 401

  # Test 4: Refresh token
  REFRESH=$(curl -s -X POST http://192.168.1.21:8001/api/token/ \
                 -d "username=admin&password=admin" | jq -r '.refresh')

  curl -s -X POST http://192.168.1.21:8001/api/token/refresh/ \
       -d "refresh=$REFRESH"
  # Debe retornar nuevo access token
  ```

  **Criterio de Éxito**:
  - Access tokens expiran en 24h
  - Refresh tokens funcionan
  - App maneja expiración con re-autenticación transparente

### Entregables de FASE 2

- [ ] Código de seguridad implementado y commiteado
- [ ] Reporte de pruebas de penetración (`docs/SECURITY_TESTS_REPORT.md`)
- [ ] Dashboard de auditoría funcional para Admin
- [ ] Documentación de encriptación actualizada

### KPIs de Éxito FASE 2
- ✅ 0 vulnerabilidades críticas abiertas
- ✅ 5/5 tests de seguridad PASS
- ✅ Encriptación funcionando sin degradación de performance
- ✅ Auditoría capturando 100% de acciones

---

## 🟠 FASE 3: UX Y PRODUCTIVIDAD

*Continúa con detalles similares para FASES 3-5...*

---

## 📈 SEGUIMIENTO DE PROGRESO

### Checklist General

- [ ] **FASE 0-R**: Recuperación (CRÍTICO)
  - [ ] 0-R.1: Git Repository
  - [ ] 0-R.2: Verificar v6.3.9
  - [ ] 0-R.3: Testing Protocol
  - [ ] 0-R.4: Documentación
  - [ ] 0-R.5: Branch + Tag

- [ ] **FASE 1**: Verificación E2E (CRÍTICO)
  - [ ] 1.1: Anti-Duplicados
  - [ ] 1.2: Sincronización Offline
  - [ ] 1.3: Dashboard Reporting
  - [ ] 1.4: Asignaciones
  - [ ] 1.5: Roles

- [ ] **FASE 2**: Seguridad (CRÍTICO)
  - [ ] 2.1: Forzar HTTPS
  - [ ] 2.2: Pentesting
  - [ ] 2.3: Encriptación
  - [ ] 2.4: Auditoría
  - [ ] 2.5: JWT Expiration

- [ ] **FASE 3**: UX (MEDIA)
- [ ] **FASE 4**: Escalabilidad (BAJA)
- [ ] **FASE 5**: Accesibilidad (BAJA)

### Reportes Semanales

**Formato de Reporte Semanal**:
```markdown
# Reporte Semanal - Semana del [FECHA]

## Progreso General
- Fases completadas: X/6
- Porcentaje total: XX%
- Bloqueadores: [Si/No - detallar]

## Logros de la Semana
- [x] Tarea 1 completada
- [x] Tarea 2 completada
- ...

## Problemas Encontrados
- Problema 1: [descripción]
  - Severidad: [CRÍTICA/MEDIA/BAJA]
  - Solución: [implementada/en progreso/pendiente]

## Plan para Próxima Semana
- [ ] Tarea pendiente 1
- [ ] Tarea pendiente 2

## Métricas
- Commits esta semana: X
- Tests ejecutados: X/X pasados
- Bugs abiertos: X
- Bugs cerrados: X
```

---

## 🎯 CRITERIOS DE ACEPTACIÓN FINAL

### Para Considerar el Proyecto "100% Completo"

- [x] **FASE 0-R Completa**: Git + baseline verificado
- [x] **FASE 1 Completa**: Todas features verificadas E2E
- [x] **FASE 2 Completa**: 0 vulnerabilidades críticas
- [x] **Documentación**: README, CHANGELOG, roadmaps sincronizados
- [x] **Testing**: Protocol automatizado funcionando
- [x] **Deployment**: APK en producción, utilizado por comunidad
- [x] **Feedback**: 3+ jornadas masivas completadas exitosamente
- [x] **Métricas**:
  - Reducción de duplicados >95%
  - Sincronización exitosa >99%
  - Satisfacción usuarios (NPS) >70

---

**Fin del Plan de Implementación Priorizado**

*Documento Vivo - Actualizar conforme se completan tareas*
*Última Actualización: 14 de Noviembre de 2025*
