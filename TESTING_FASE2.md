# 🧪 GUÍA DE TESTING - LUMARA v5.6.1 FASE 2

**Fecha:** 2025-10-31
**Versión:** 5.6.1+57
**Features:** Session Tracking + Review Workflow + CSV Export

---

## 📋 RESUMEN DE INTEGRACIÓN

### ✅ Completado (100%)

| Componente | Status | Líneas Modificadas | Testing |
|-----------|--------|-------------------|---------|
| **UploadScreen** | ✅ | ~10 | ⏳ Pendiente |
| **DigitizorDashboard** | ✅ | ~80 | ⏳ Pendiente |
| **ReviewerDashboard** | ✅ | ~50 | ⏳ Pendiente |
| **ViewerDashboard** | ✅ | ~170 | ⏳ Pendiente |
| **AdminDashboard** | ✅ | ~75 | ⏳ Pendiente |
| **Build APK Debug** | ✅ | - | ⏳ Pendiente |
| **Build APK Release** | ✅ | - | ⏳ Pendiente |

---

## 📦 ARTEFACTOS GENERADOS

### APKs Disponibles

```bash
# APK Debug (190MB) - Para desarrollo
~/Descargas/Lumara_v5.6.1_Fase2_DEBUG.apk

# APK Release (96MB) - Optimizado para producción
~/Descargas/Lumara_v5.6.1_Fase2_SessionTracking_Reviews_CSVExport.apk
```

### Scripts de Testing

```bash
# Script de instalación interactivo
./install_fase2_apk.sh

# Script de testing E2E del backend
./test_fase2_e2e.sh
```

---

## 🚀 INSTRUCCIONES DE TESTING

### Paso 1: Verificar Backend

```bash
# Verificar que Docker está corriendo
docker ps | grep tejido

# Si no está corriendo, iniciar:
cd /home/smt/Escritorio/programacion_proyectos/tejido/tejido-ngx
docker-compose up -d

# Verificar que responde:
curl -s http://192.168.40.17:8001/api/ | jq '.'
```

**Resultado esperado:** JSON con información de la API

---

### Paso 2: Testing Backend E2E (AUTOMÁTICO)

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# Ejecutar script de testing automatizado
./test_fase2_e2e.sh
```

**Tests que ejecuta:**
1. ✅ Verificar Backend disponible
2. ✅ Verificar Token de autenticación
3. ✅ Iniciar sesión de digitalización
4. ✅ Incrementar contador de documentos (x3)
5. ✅ Finalizar sesión
6. ✅ Verificar productividad con datos reales
7. ✅ Obtener lista de asignaciones
8. ✅ Aprobar asignación (Review Workflow)
9. ✅ Exportar CSV de asignaciones
10. ✅ Exportar CSV de productividad
11. ✅ Exportar CSV de resumen de equipo

**Resultado esperado:** Todos los tests ✅ en verde

---

### Paso 3: Instalación en Dispositivo

```bash
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# Conectar dispositivo por USB y habilitar Depuración USB

# Ejecutar script de instalación
./install_fase2_apk.sh

# Seleccionar:
#   1) DEBUG   - Para ver logs detallados
#   2) RELEASE - Versión optimizada
```

**Resultado esperado:** APK instalado exitosamente en el dispositivo

---

### Paso 4: Testing Manual en Dispositivo

#### 🎯 Test 1: Session Tracking End-to-End

**Duración:** 5 minutos
**Usuario:** DIGITALIZADOR

**Pasos:**
1. Login en la app con usuario DIGITALIZADOR
2. Navegar a **Digitizor Dashboard**
3. Observar AppBar superior derecha (sin badge verde = sin sesión)
4. Click en área superior derecha → Dialog "No hay sesión activa"
5. Click **"Iniciar Sesión"**
6. ✅ **VERIFICAR:** Badge verde pulsante aparece en AppBar
7. Navegar a **Person Selection** → Seleccionar persona
8. Capturar documento con cámara → Click **Upload**
9. ✅ **VERIFICAR:** Upload exitoso
10. Repetir captura y upload 2 veces más (total 3 documentos)
11. Regresar a **Digitizor Dashboard**
12. Click en badge verde → Dialog "Tienes una sesión activa"
13. Click **"Finalizar Sesión"**
14. ✅ **VERIFICAR:** Badge verde desaparece

**Logs a verificar (adb logcat):**
```
✅ Session document count incremented
✅ Starting digitization session
✅ Ending digitization session
```

**Backend a verificar:**
```bash
# Ver sesiones del usuario
curl -X GET "http://192.168.40.17:8001/api/auth/my-sessions/?active_only=false" \
  -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096"

# Verificar productividad
curl -X GET "http://192.168.40.17:8001/api/auth/my-productivity/?period=day" \
  -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096"
```

---

#### 🎯 Test 2: Assignment Review Workflow

**Duración:** 3 minutos
**Usuario:** REVISOR

**Pre-requisito:** Debe haber al menos 1 asignación con status=COMPLETED

**Pasos:**
1. Login en la app con usuario REVISOR
2. Navegar a **Reviewer Dashboard**
3. Scroll hasta **"Próximas Revisiones"**
4. ✅ **VERIFICAR:** Aparece lista de asignaciones completadas
5. Click botón **"Revisar"** en primera asignación
6. ✅ **VERIFICAR:** Se abre **AssignmentReviewDialog**
7. Verificar que dialog muestra:
   - Nombre de la persona
   - Digitalizador
   - Documentos completados
   - Toggle "Aprobar" / "Rechazar"
8. **Probar APROBAR:**
   - Asegurar que toggle está en "Aprobar"
   - Ajustar slider de calidad a 85
   - ✅ **VERIFICAR:** Label muestra "Bueno (85/100)"
   - Escribir feedback: "Documentos correctos, buena calidad"
   - Click **"Aprobar Asignación"**
   - ✅ **VERIFICAR:** Mensaje verde "✅ Asignación aprobada"
   - ✅ **VERIFICAR:** Dashboard se recarga automáticamente
9. **Probar RECHAZAR** (con otra asignación):
   - Click toggle para cambiar a "Rechazar"
   - ✅ **VERIFICAR:** Color cambia a rojo
   - Escribir feedback: "Documentos borrosos, recapturar"
   - Escribir issues: "Cédula ilegible, Registro Civil incompleto"
   - Click **"Rechazar Asignación"**
   - ✅ **VERIFICAR:** Mensaje "✅ Asignación rechazada - Notificado al digitalizador"

**Logs a verificar:**
```
✅ Approving assignment
✅ Rejecting assignment
```

**Backend a verificar:**
```bash
# Ver review de la asignación
curl -X GET "http://192.168.40.17:8001/api/auth/assignment-review/1/" \
  -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096"
```

---

#### 🎯 Test 3: CSV Export

**Duración:** 2 minutos
**Usuario:** VIEWER

**Pasos:**
1. Login en la app con usuario VIEWER
2. Navegar a **Viewer Dashboard**
3. Click botón **Export** (icono de descarga) en AppBar
4. ✅ **VERIFICAR:** Se abre dialog con 3 opciones:
   - Exportar Asignaciones
   - Exportar Productividad
   - Exportar Resumen Equipo
5. **Probar Exportar Asignaciones:**
   - Click **"Exportar Asignaciones"**
   - ✅ **VERIFICAR:** Loading dialog "Generando CSV de Asignaciones..."
   - ✅ **VERIFICAR:** Aparece share dialog de Android
   - Seleccionar app (Gmail, WhatsApp, Drive, etc.)
   - ✅ **VERIFICAR:** CSV se adjunta correctamente
   - Abrir CSV en Excel/Sheets
   - ✅ **VERIFICAR:** CSV tiene columnas: assignment_id, person_id, person_name, digitizer, status, etc.
6. **Probar Exportar Productividad:**
   - Regresar al dashboard
   - Seleccionar filtro de tiempo: "Semana"
   - Click **Export** → **"Exportar Productividad"**
   - ✅ **VERIFICAR:** Loading → Share dialog → CSV generado
   - Abrir CSV
   - ✅ **VERIFICAR:** CSV tiene columnas: user_id, username, documents_digitized, sessions, etc.
7. **Probar Exportar Resumen Equipo:**
   - Regresar al dashboard
   - Click **Export** → **"Exportar Resumen Equipo"**
   - ✅ **VERIFICAR:** Loading → Share dialog → CSV generado
   - Abrir CSV
   - ✅ **VERIFICAR:** CSV tiene métricas globales del equipo

**Logs a verificar:**
```
✅ Exporting CSV
✅ CSVExportService
```

**Backend a verificar:**
```bash
# Endpoint de exportación
curl -X GET "http://192.168.40.17:8001/api/auth/export-assignments-csv/" \
  -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096" \
  --output assignments.csv

# Verificar CSV generado
head assignments.csv
wc -l assignments.csv
```

---

#### 🎯 Test 4: Upload con Sesión Activa vs Sin Sesión

**Duración:** 3 minutos
**Usuario:** DIGITALIZADOR

**Parte A: Upload SIN Sesión**
1. Login como DIGITALIZADOR
2. **NO** iniciar sesión en Digitizor Dashboard
3. Navegar a Person Selection → Seleccionar persona
4. Capturar documento → Upload
5. ✅ **VERIFICAR:** Upload exitoso SIN errores
6. ✅ **VERIFICAR:** Logs NO muestran "Session document count incremented"

**Parte B: Upload CON Sesión**
1. Regresar a Digitizor Dashboard
2. Iniciar sesión (badge verde aparece)
3. Navegar a Person Selection → Seleccionar persona
4. Capturar documento → Upload
5. ✅ **VERIFICAR:** Upload exitoso
6. ✅ **VERIFICAR:** Logs SÍ muestran "✅ Session document count incremented"

**Resultado esperado:** Upload funciona correctamente en ambos casos, pero solo incrementa contador cuando hay sesión activa.

---

#### 🎯 Test 5: Admin Dashboard Session Indicator

**Duración:** 2 minutos
**Usuario:** ADMIN

**Pasos:**
1. Login como ADMIN
2. Navegar a **Admin Dashboard**
3. ✅ **VERIFICAR:** AppBar muestra SessionIndicatorWidget (igual que Digitizor)
4. Click en badge/área → Dialog de sesión aparece
5. Iniciar sesión → Badge verde pulsante aparece
6. Finalizar sesión → Badge desaparece

**Resultado esperado:** Admin puede usar session tracking igual que digitalizadores.

---

## 📊 MONITOREO DE LOGS EN TIEMPO REAL

### Iniciar Monitoreo Completo

```bash
# Terminal 1: Logs de Flutter (filtrados)
adb logcat | grep --color=auto -E "(Lumara|Session|CSV|Review|✅|❌|⏱️)"

# Terminal 2: Logs solo de errores
adb logcat | grep --color=auto -E "(ERROR|FATAL|Exception)"

# Terminal 3: Backend logs
docker logs -f tejido-webserver-1 | grep --color=auto -E "(auth|Session|Review|CSV)"
```

### Keywords a buscar

**Session Tracking:**
- `"Starting digitization session"`
- `"Session document count incremented"`
- `"Ending digitization session"`
- `"hasActiveSession: true"`

**Review Workflow:**
- `"Approving assignment"`
- `"Rejecting assignment"`
- `"showAssignmentReviewDialog"`
- `"quality_score"`

**CSV Export:**
- `"Exporting CSV"`
- `"CSVExportService"`
- `"exportAndShare"`
- `"Share.shareXFiles"`

---

## ❌ TROUBLESHOOTING

### Problema: Badge verde no aparece

**Síntomas:** Iniciar sesión no muestra el badge verde pulsante

**Diagnóstico:**
```dart
// Logs a verificar:
"hasActiveSession: true"  // Debe aparecer
"SessionIndicatorWidget build"  // Debe aparecer
```

**Soluciones:**
1. Verificar que `AssignmentProvider.hasActiveSession` retorna `true`
2. Verificar que backend retorna `session_id` en respuesta
3. Verificar logs: `adb logcat | grep "Session"`

---

### Problema: Upload no incrementa contador

**Síntomas:** Documentos se suben pero contador de sesión no aumenta

**Diagnóstico:**
```bash
# Verificar sesión activa en backend
curl -X GET "http://192.168.40.17:8001/api/auth/my-sessions/?active_only=true" \
  -H "Authorization: Token TOKEN"
```

**Soluciones:**
1. Verificar que hay sesión activa en frontend
2. Verificar que `incrementSessionDocuments()` se llama en UploadScreen
3. Revisar logs del backend para ver POST a `/api/auth/increment-session-documents/`

---

### Problema: CSV Export no comparte

**Síntomas:** Loading aparece pero share dialog no se abre

**Diagnóstico:**
```dart
// Logs a verificar:
"Exporting CSV..."
"CSVExportService"
"Share.shareXFiles"
```

**Soluciones:**
1. Verificar permisos de almacenamiento
2. Verificar que `path_provider` funciona: logs con rutas temporales
3. Verificar que backend retorna CSV válido (no JSON error)

---

### Problema: Review Dialog crashea

**Síntomas:** App crashea al abrir dialog de review

**Diagnóstico:**
```bash
# Ver stack trace completo
adb logcat | grep -A 20 "FATAL"
```

**Soluciones:**
1. Verificar que `AssignmentReviewDialog` widget existe
2. Verificar que `PersonAssignment` tiene todos los campos necesarios
3. Verificar imports: `import '../widgets/assignment_review_dialog.dart';`

---

## ✅ CHECKLIST DE TESTING COMPLETADO

### Backend E2E
- [ ] Backend disponible y respondiendo
- [ ] Auth token válido
- [ ] Session tracking: inicio, incremento, fin
- [ ] Productividad con datos reales
- [ ] Review workflow: aprobar y rechazar
- [ ] CSV export: 3 endpoints funcionando

### Frontend Manual
- [ ] Test 1: Session Tracking End-to-End
- [ ] Test 2: Assignment Review (aprobar + rechazar)
- [ ] Test 3: CSV Export (3 tipos de exportación)
- [ ] Test 4: Upload con/sin sesión
- [ ] Test 5: Admin Dashboard session indicator

### Verificación de Logs
- [ ] Logs sin errores fatales
- [ ] Keywords de session tracking presentes
- [ ] Keywords de review workflow presentes
- [ ] Keywords de CSV export presentes

### Verificación de UI
- [ ] Badge verde pulsante visible (sesión activa)
- [ ] Badge desaparece (sesión finalizada)
- [ ] Review dialog se abre correctamente
- [ ] Quality slider funciona (1-100)
- [ ] Toggle Aprobar/Rechazar funciona
- [ ] Share dialog de Android aparece
- [ ] CSVs se abren en Excel/Sheets

---

## 🎯 CRITERIOS DE ACEPTACIÓN

### ✅ Testing Exitoso Si:

1. **Session Tracking:**
   - Badge verde aparece/desaparece correctamente
   - Contador incrementa con cada upload
   - Backend registra sesiones con datos correctos

2. **Review Workflow:**
   - Dialog se abre sin errores
   - Aprobar funciona con quality score
   - Rechazar funciona con feedback
   - Dashboard se recarga después de review

3. **CSV Export:**
   - 3 tipos de exportación funcionan
   - Share dialog de Android aparece
   - CSVs tienen formato correcto
   - Datos en CSV son coherentes

4. **Logs:**
   - Sin errores fatales
   - Keywords esperados presentes
   - Backend registra requests correctamente

---

## 📝 REPORTE DE TESTING

Al completar testing, documentar:

```markdown
# REPORTE DE TESTING - FASE 2

**Fecha:** [FECHA]
**Tester:** [NOMBRE]
**Dispositivo:** [MODELO] (Android [VERSION])

## Resultados

### Backend E2E
- Session Tracking: ✅ / ❌
- Review Workflow: ✅ / ❌
- CSV Export: ✅ / ❌

### Frontend Manual
- Test 1 (Session): ✅ / ❌
- Test 2 (Review): ✅ / ❌
- Test 3 (CSV): ✅ / ❌
- Test 4 (Upload): ✅ / ❌
- Test 5 (Admin): ✅ / ❌

## Issues Encontrados
1. [Descripción del issue]
2. [Descripción del issue]

## Observaciones
- [Observaciones adicionales]
```

---

**Creado por:** AI Assistant (Anthropic)
**Última Actualización:** 2025-10-31
**Status:** ✅ Listo para Testing
