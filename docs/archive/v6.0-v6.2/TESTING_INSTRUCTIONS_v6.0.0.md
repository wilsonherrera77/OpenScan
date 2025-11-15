# INSTRUCCIONES DE TESTING - v6.0.0 Admin Digitization

**Fecha:** 2025-11-09
**APK:** `Lumara_v6.0.0_AdminDigitization_5Buttons_20251109_195349.apk`
**MD5:** `675569009ccb156e30d5eb4827d335c3`
**Tamaño:** 97 MB
**Status:** ✅ COMPILADO - ⏳ PENDIENTE TESTING

---

## 📋 RESUMEN

**Feature:** Admin puede capturar documentos (5to botón en Admin Dashboard)

**Root Cause Identificado:** Flutter cache issue (código correcto desde v6.0.0, nunca compilado limpiamente)

**Solución Aplicada:** `flutter clean` + `flutter build apk --release`

**Expectativa:** El APK debería mostrar **5 botones** en Admin Dashboard (antes solo mostraba 4)

---

## 🔧 PRE-REQUISITOS

Antes de testear, asegúrate de tener:

- [x] APK v6.0.0 compilado (ubicado en `~/Descargas/`)
- [ ] Dispositivo Android conectado vía USB
- [ ] USB Debugging habilitado en el dispositivo
- [ ] Backend Tejido corriendo (`docker ps | grep paperless`)
- [ ] Credenciales Admin disponibles

---

## 🚀 PASOS DE INSTALACIÓN

### Opción A: Usando Script Automático (RECOMENDADO)

```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Ejecutar script de testing
./scripts/test_apk_before_release.sh ~/Descargas/Lumara_v6.0.0_AdminDigitization_5Buttons_20251109_195349.apk
```

El script hará:
1. ✅ Verificar dispositivo conectado
2. ✅ Desinstalar versión anterior (limpia cache)
3. ✅ Instalar APK nuevo
4. ✅ Capturar logs automáticamente
5. ✅ Guiarte por 15 test cases
6. ✅ Dar veredicto APPROVE/REJECT

### Opción B: Instalación Manual

```bash
# 1. Verificar dispositivo
adb devices
# Debe mostrar: XXXXXXXX    device

# 2. Desinstalar versión anterior (IMPORTANTE - limpia cache)
adb uninstall com.ethereal.openscan

# 3. Instalar APK v6.0.0
adb install -r ~/Descargas/Lumara_v6.0.0_AdminDigitization_5Buttons_20251109_195349.apk

# 4. Lanzar app
adb shell am start -n com.ethereal.openscan/.MainActivity

# 5. (Opcional) Capturar logs en terminal separada
adb logcat | grep -iE "lumara|openscan|flutter|error" > /tmp/v6.0.0_test_$(date +%Y%m%d_%H%M%S).log
```

---

## ✅ TESTING CHECKLIST (15 Tests Críticos)

### PARTE 1: FEATURE NUEVA (Admin Digitization)

#### TEST 1: Login Admin
- [ ] Abrir app Lumara
- [ ] Login con credenciales Admin
- [ ] Verificar redirección a Admin Dashboard
- [ ] **PASS/FAIL:** _______

#### TEST 2: Contar Botones en Dashboard
- [ ] Scroll a sección "Acciones Rápidas"
- [ ] Contar botones en grid
- [ ] **ESPERADO:** 5 botones (no 4)
- [ ] **RESULTADO:** _____ botones
- [ ] **PASS/FAIL:** _______

#### TEST 3: Identificar 5to Botón
- [ ] Verificar que existe botón con:
  - Color: Teal (azul-verde)
  - Icono: Cámara
  - Texto: "Capturar Documento"
- [ ] **Ubicación:** 3ra posición en grid
- [ ] **PASS/FAIL:** _______

#### TEST 4: Navegación a PersonSelectionScreen
- [ ] Tap en botón "Capturar Documento"
- [ ] Verificar navegación exitosa
- [ ] Verificar AppBar muestra "Seleccionar Persona"
- [ ] **PASS/FAIL:** _______

#### TEST 5: Carga de Censo
- [ ] Esperar carga de lista personas
- [ ] Verificar contador en parte superior
- [ ] **ESPERADO:** ~3998 personas
- [ ] **RESULTADO:** _____ personas
- [ ] **PASS/FAIL:** _______

#### TEST 6: Búsqueda de Persona
- [ ] Tap en campo de búsqueda
- [ ] Escribir: "2071" (o ID de persona conocida)
- [ ] Verificar filtrado de resultados
- [ ] Verificar aparece persona correcta
- [ ] **PASS/FAIL:** _______

#### TEST 7: Selección de Persona
- [ ] Tap en card de persona
- [ ] Verificar checkmark verde aparece
- [ ] Verificar botón "Continuar" se habilita
- [ ] Tap "Continuar"
- [ ] Verificar navegación a DocumentMetadataScreen
- [ ] **PASS/FAIL:** _______

#### TEST 8: Captura de Documento
- [ ] Seleccionar tipo: "Cédula de Ciudadanía"
- [ ] Tap botón "Capturar"
- [ ] Verificar cámara abre
- [ ] Capturar foto de documento de prueba
- [ ] Verificar preview aparece
- [ ] Confirmar captura
- [ ] **PASS/FAIL:** _______

#### TEST 9: Upload a Backend
- [ ] Verificar indicador de progreso
- [ ] Esperar mensaje "Documento subido exitosamente"
- [ ] Verificar navegación de regreso
- [ ] **PASS/FAIL:** _______

#### TEST 10: Verificación Backend
- [ ] Abrir navegador: http://192.168.40.17:8001/admin/documents/document/
- [ ] Login como admin
- [ ] Buscar documento recién subido
- [ ] Verificar metadata:
  - Persona correcta
  - Tipo de documento correcto
  - Usuario uploader = Admin (no Digitizer)
- [ ] **PASS/FAIL:** _______

---

### PARTE 2: REGRESIONES (Verificar que nada se rompió)

#### TEST 11: Otros 4 Botones Admin Dashboard
- [ ] Volver a Admin Dashboard
- [ ] Tap "Asignar Personas" → Dialog abre
- [ ] Cerrar dialog
- [ ] Tap "Ver Reportes" → Mensaje aparece
- [ ] Tap "Gestionar Usuarios" → Mensaje aparece
- [ ] **PASS/FAIL:** _______

#### TEST 12: FAB "Crear Asignaciones"
- [ ] Verificar FAB visible en Admin Dashboard
- [ ] Tap en FAB
- [ ] Verificar bottom sheet abre
- [ ] Cerrar bottom sheet
- [ ] **PASS/FAIL:** _______

#### TEST 13: Session Indicator
- [ ] Tap en indicador de sesión (AppBar)
- [ ] Verificar dialog muestra
- [ ] Tap "Iniciar Sesión"
- [ ] Verificar cronómetro inicia
- [ ] Tap "Detener Sesión"
- [ ] Verificar mensaje de confirmación
- [ ] **PASS/FAIL:** _______

#### TEST 14: Logout y Login Digitizer
- [ ] Logout de Admin
- [ ] Login como Digitizer
- [ ] Verificar Digitizer Dashboard carga
- [ ] Verificar "Capturar Documento" sigue funcionando
- [ ] **PASS/FAIL:** _______

#### TEST 15: Estabilidad General
- [ ] App no crasheó en ningún momento
- [ ] No hubo freezes >5 segundos
- [ ] Memoria no se desbordó
- [ ] **PASS/FAIL:** _______

---

## 📊 VEREDICTO FINAL

**Total Tests:** 15

**PASS:** _____ / 15
**FAIL:** _____ / 15
**SKIP:** _____ / 15

### Matriz de Decisión

| PASS Count | Decisión | Acción |
|-----------|----------|--------|
| 15/15 | ✅ **APROBAR** | Distribuir APK, marcar como v6.0.0 estable |
| 13-14/15 | ⚠️ **APROBAR CON NOTAS** | Distribuir pero documentar issues menores |
| 10-12/15 | 🟡 **REVISAR** | Fix issues críticos, re-testear |
| <10/15 | ❌ **RECHAZAR** | Rollback a v5.5.0, investigar root cause |

**TU VEREDICTO:** _______________

---

## 🐛 TROUBLESHOOTING

### Problema: Sigue mostrando solo 4 botones

**Posibles Causas:**

1. **Dispositivo tiene APK antiguo cacheado**
   - Solución: `adb uninstall com.ethereal.openscan` y reinstalar

2. **APK incorrecto instalado**
   - Verificar: `adb shell pm list packages | grep openscan`
   - Verificar versión: `adb shell dumpsys package com.ethereal.openscan | grep versionName`
   - Debe ser: `6.0.0`

3. **GridView rendering issue**
   - Capturar screenshot: `adb shell screencap -p /sdcard/screenshot.png`
   - Pull: `adb pull /sdcard/screenshot.png ~/Descargas/debug_screenshot.png`
   - Enviar screenshot para análisis

4. **Código no se compiló correctamente**
   - Verificar logs de build: buscar errores en output de `flutter build apk`
   - Re-hacer `flutter clean && flutter build apk --release`

### Problema: Botón visible pero tap no funciona

**Diagnóstico:**

1. Capturar logs mientras se toca botón:
   ```bash
   adb logcat | grep -i "navigation\|route"
   ```

2. Verificar que PersonSelectionScreen.route está registrado:
   ```bash
   grep "PersonSelectionScreen.route" lib/main.dart
   ```

3. Verificar permisos de navegación (no deberían ser necesarios)

### Problema: Cámara no abre

**Diagnóstico:**

1. Verificar permisos en AndroidManifest.xml
2. Verificar permisos concedidos en dispositivo:
   ```bash
   adb shell dumpsys package com.ethereal.openscan | grep -A 5 "granted=true"
   ```

3. Si faltan permisos, conceder manualmente:
   ```bash
   adb shell pm grant com.ethereal.openscan android.permission.CAMERA
   adb shell pm grant com.ethereal.openscan android.permission.WRITE_EXTERNAL_STORAGE
   ```

### Problema: Upload falla

**Diagnóstico:**

1. Verificar backend accesible:
   ```bash
   curl -I http://192.168.40.17:8001/api/
   ```

2. Verificar credenciales admin válidas

3. Capturar logs de upload:
   ```bash
   adb logcat | grep -iE "upload|http|dio"
   ```

---

## 📸 CAPTURAS DE PANTALLA ESPERADAS

### Screenshot 1: Admin Dashboard con 5 Botones

```
┌─────────────────────────────────┐
│  Admin Dashboard        [≡] [i] │
├─────────────────────────────────┤
│                                 │
│  Acciones Rápidas              │
│                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ 👤+  │ │ 📋+  │ │ 📸   │   │ ← 5to botón (teal)
│  │Crear │ │Asign │ │Capt  │   │
│  │Digit │ │Pers  │ │Doc   │   │
│  └──────┘ └──────┘ └──────┘   │
│                                 │
│  ┌──────┐ ┌──────┐            │
│  │ 📊   │ │ 👥   │            │
│  │Ver   │ │Gest  │            │
│  │Rep   │ │Usu   │            │
│  └──────┘ └──────┘            │
└─────────────────────────────────┘
```

### Screenshot 2: PersonSelectionScreen después del tap

```
┌─────────────────────────────────┐
│ ← Seleccionar Persona      [🔍] │
├─────────────────────────────────┤
│                                 │
│  🔍 Buscar por nombre, cédula..│
│                                 │
│  ┌─────────────────────────┐  │
│  │ 👤 2071                 │  │
│  │ García Pérez, Juan      │  │
│  │ CC: 1234567890          │  │
│  └─────────────────────────┘  │
│                                 │
│  ┌─────────────────────────┐  │
│  │ 👤 2072                 │  │
│  │ ...                     │  │
│  └─────────────────────────┘  │
│                                 │
│  Mostrando 3998 personas       │
└─────────────────────────────────┘
```

---

## 🎯 CRITERIOS DE ÉXITO

**Feature es EXITOSA si:**

1. ✅ Admin Dashboard muestra **5 botones** (no 4)
2. ✅ Botón "Capturar Documento" **visible** (color teal, icono cámara)
3. ✅ Tap en botón **navega** a PersonSelectionScreen
4. ✅ Censo **carga** ~3998 personas
5. ✅ Búsqueda **funciona**
6. ✅ Selección persona **funciona**
7. ✅ Captura documento **funciona**
8. ✅ Upload **funciona** y atribuye a Admin
9. ✅ **Sin regresiones** en otros 4 botones
10. ✅ **Sin crashes** durante testing

**Si 10/10 → APROBAR APK para distribución**

---

## 📝 SIGUIENTES PASOS (Si APROBADO)

### 1. Actualizar Git

```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Agregar cambios si hay alguno pendiente
git add -A

# Commit
git commit -m "feat: Admin Digitization feature - TESTED AND APPROVED

Feature: Admin puede capturar documentos desde dashboard
Buttons: 5 botones en Admin Quick Actions (antes 4)

Testing:
- ✅ 15/15 test cases passed
- ✅ No regressions detected
- ✅ Upload works with Admin attribution
- ✅ Feature working on device

APK: Lumara_v6.0.0_AdminDigitization_5Buttons_20251109_195349.apk
MD5: 675569009ccb156e30d5eb4827d335c3
Size: 97 MB
Device tested: [insertar modelo]

Root cause was Flutter cache issue (resolved with flutter clean).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Tag
git tag v6.0.0-admin-digitization-verified
```

### 2. Actualizar Documentación

Archivos a actualizar:
- `CHANGELOG.md` - Agregar entrada v6.0.0
- `docs/FEATURES.md` - Documentar 5to botón
- `BASELINE_v5.5.0_VERIFICATION.md` - Anotar que v6.0.0 supera baseline

### 3. Distribuir APK

```bash
# Copiar a carpeta de distribución (si existe)
cp ~/Descargas/Lumara_v6.0.0_AdminDigitization_5Buttons_20251109_195349.apk \
   /path/to/distribution/folder/

# O enviar a usuarios vía método preferido
```

### 4. Notificar a Usuarios

Template de mensaje:

```
📢 Nueva versión disponible: Lumara v6.0.0

✨ Cambios:
- Admin ahora puede capturar documentos directamente
- 5 botones en Admin Dashboard (agregado "Capturar Documento")
- Misma funcionalidad que Digitizer para Admin role

📥 Instalación:
1. Desinstalar versión anterior
2. Instalar: Lumara_v6.0.0_AdminDigitization_5Buttons_20251109_195349.apk
3. Login como Admin
4. Verificar 5 botones visibles

✅ Testing: 15/15 test cases passed
🔒 MD5: 675569009ccb156e30d5eb4827d335c3
```

---

## 📊 LOGS Y EVIDENCIA

### Logs Capturados

Si ejecutaste con script automático:
- **Ubicación:** `/tmp/lumara_test_logs/test_YYYYMMDD_HHMMSS.log`

Si ejecutaste manual:
- **Ubicación:** `/tmp/v6.0.0_test_YYYYMMDD_HHMMSS.log`

### Screenshots Recomendados

Capturar y guardar:
1. Admin Dashboard con 5 botones
2. PersonSelectionScreen
3. DocumentMetadataScreen
4. Captura exitosa
5. Backend mostrando documento

```bash
# Capturar screenshot
adb shell screencap -p /sdcard/lumara_v6.0.0_screenshot_1.png
adb pull /sdcard/lumara_v6.0.0_screenshot_1.png ~/Descargas/

# Repetir para cada screenshot
```

---

## 🆘 CONTACTO PARA SOPORTE

Si encuentras issues durante testing:

1. **Capturar evidencia:**
   - Screenshots
   - Logs (adb logcat)
   - Descripción paso a paso del error

2. **Verificar troubleshooting** (arriba)

3. **Opciones de rollback:**
   - Reinstalar v5.5.0 baseline
   - Reportar issue para investigación

---

**Documento creado:** 2025-11-09 19:54 UTC
**Status:** LISTO PARA TESTING
**Próximo Paso:** Conectar dispositivo Android y ejecutar checklist

**Mantenedor:** Equipo Lumara (Tejido by WH)
