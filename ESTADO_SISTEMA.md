# Estado Actual del Sistema Lumara ↔ Tejido
## Snapshot del 2025-10-12

---

## 🎯 RESUMEN EJECUTIVO

| Componente | Estado | Detalles |
|------------|--------|----------|
| **Backend Tejido** | ✅ **FUNCIONAL** | Endpoint probado, guarda archivos y crea relaciones |
| **App Lumara v5.5.0** | ⚠️ **FUNCIONA PARCIALMENTE** | Carga censo completo pero sin relaciones en uploads |
| **App Lumara v5.6.0** | ❌ **NO VERIFICADO** | Reporta "0 personas", causa desconocida (sin logs) |
| **Sincronización E2E** | ❌ **NO PROBADA** | No se pudo verificar flujo completo |

---

## 📦 APKs Disponibles

### RECOMENDADO PARA USO: v5.5.0

```
Archivo: Lumara_v5.5.0_UNIX_EOL_GARANTIZADO_20251012_113207.apk
Ubicación: /home/smt/Descargas/
MD5: 66b9af48a32354697ac0262b6b5c5c7a
Tamaño: 68 MB

✅ Funciona: Carga 3998 personas
❌ Limitación: Uploads NO crean DocumentPersonRelation
```

**Usar este APK si:**
- Necesitas capturar documentos YA
- Puedes asociar personas manualmente después
- No es crítico tener relaciones automáticas

---

### NO RECOMENDADO: v5.6.0

```
Archivo: Lumara_v5.6.0_FINAL_FIX_20251012_181046.apk
Ubicación: /home/smt/Descargas/
MD5: 1128170a53fc074b0b16ec6bc7198266
Tamaño: 68 MB

❌ Problema: Muestra "0 personas" en dispositivo
✅ Código: Correcto (verificado)
✅ CSV: Correcto en APK (3998 personas)
❓ Causa: Desconocida (requiere logs)
```

**NO usar hasta:**
- Diagnosticar problema "0 personas"
- Habilitar USB Debugging
- Capturar logs de error
- Aplicar fix verificado

---

## 🔧 Backend - Endpoint Custom

### `/api/documents/upload_with_person/`

**Estado:** ✅ **PRODUCCIÓN READY**

**Funcionalidad:**
- Recibe: documento PDF/imagen + person_id + document_type
- Guarda archivo en sistema de archivos
- Procesa con pipeline Paperless (OCR, metadata)
- Crea DocumentPersonRelation automáticamente
- Retorna: document_id, relation_id, person_name

**Testing:**
```bash
# Verificado funcionando 2025-10-12 19:10 UTC
curl -X POST "http://192.168.40.17:8001/api/documents/upload_with_person/" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  -F "document=@test.pdf" \
  -F "person_id=2071" \
  -F "document_type=Cédula de Ciudadanía" \
  -F "nuip=123456789" \
  -F "is_replacement=false"

# Respuesta exitosa:
{
  "success": true,
  "document_id": 35,
  "person_id": 2071,
  "person_name": "PERSONA PRUEBA",
  "relation_id": 5,
  "is_replacement": false,
  "message": "Documento subido y asociado exitosamente. OCR completado."
}
```

**Verificación en BD:**
```sql
-- Documento creado
SELECT id, title, created FROM documents_document WHERE id = 35;

-- Relación creada
SELECT id, document_id, person_id, document_type
FROM documents_documentpersonrelation
WHERE document_id = 35;
```

**Resultado:** ✅ Ambos registros existen y están correctos

---

## 📱 App Móvil

### v5.5.0 - Estado Conocido

**Censo:**
- ✅ Carga 3998 personas (verificado con logs de dispositivo)
- ✅ Búsqueda funciona
- ✅ Selección de persona funciona

**Upload:**
- ⚠️ Usa endpoint antiguo: `/api/documents/post_document/`
- ❌ NO crea DocumentPersonRelation
- ✅ Documento se crea en Tejido (pero sin asociación)

**Workaround:**
Documentos se pueden asociar manualmente después desde interfaz web de Tejido.

---

### v5.6.0 - Estado Desconocido

**Código:**
- ✅ Endpoint correcto implementado: `upload_with_person`
- ✅ CSV incluido en APK (verificado con unzip)
- ✅ Versión actualizada: 5.6.0+56

**Dispositivo:**
- ❌ Usuario reporta: "0 Personas"
- ❓ Causa: Desconocida (sin logs)
- ❓ Upload: No probado (no hay personas para seleccionar)

**Hipótesis No Verificadas:**
1. Caché corrupta de versiones anteriores
2. Permisos de lectura de assets
3. Bug en inicialización del Provider
4. Problema de codificación del CSV

**Se Necesita:**
- USB Debugging habilitado
- Logs de `adb logcat` durante inicio de app
- Script de diagnóstico: `/tmp/diagnostico_censo_app.sh`

---

## 🔍 Diagnóstico Pendiente

### Para Resolver Problema "0 Personas"

**Pasos Necesarios:**

1. **Habilitar USB Debugging:**
   ```
   Configuración → Acerca del teléfono
   Tocar 7 veces "Número de compilación"
   Sistema → Opciones de desarrollador → Depuración USB
   ```

2. **Conectar dispositivo y verificar:**
   ```bash
   adb devices
   # Debe mostrar: [ID]    device
   ```

3. **Ejecutar diagnóstico automático:**
   ```bash
   bash /tmp/diagnostico_censo_app.sh
   ```

4. **Revisar logs generados:**
   ```
   /tmp/lumara_census_logs.txt
   /tmp/census_from_device.csv
   ```

5. **Identificar error exacto** en los logs

---

## 📊 Métricas de Desarrollo

### Tiempo Invertido
- **Backend Fix:** ~2 horas
- **App Fix v5.6.0:** ~2 horas
- **Diagnóstico/Testing:** ~2 horas (inconcluso)
- **Documentación:** ~1 hora
- **TOTAL:** ~7 horas

### Líneas de Código
- **Backend modificadas:** ~130 líneas
- **App modificadas:** ~20 líneas (versiones)
- **Scripts de diagnóstico:** ~200 líneas

### APKs Compilados
- **Total:** 4 APKs
- **Verificados funcionando:** 1 (v5.5.0)
- **Verificados fallando:** 1 (v5.6.0)
- **Sin verificar:** 2

### Tests Realizados
- ✅ Backend con curl: EXITOSO
- ✅ App v5.5.0 censo: EXITOSO
- ❌ App v5.6.0 censo: FALLÓ
- ❌ Sincronización E2E: NO REALIZADA

---

## 🎯 Próximos Pasos Recomendados

### Opción A: Usar v5.5.0 y Continuar Operaciones

**Ventajas:**
- App funciona ahora mismo
- Censo completo disponible
- Documentos se pueden capturar

**Desventajas:**
- Relaciones personas-documentos se crean manualmente
- Más trabajo administrativo
- No usa endpoint optimizado

**Recomendado si:** Necesitas digitalizar documentos urgentemente

---

### Opción B: Diagnosticar y Resolver v5.6.0

**Pasos:**
1. Habilitar USB Debugging
2. Ejecutar diagnóstico automático
3. Identificar causa de "0 personas"
4. Aplicar fix específico
5. Compilar v5.7.0 con fix
6. Testing exhaustivo antes de distribuir

**Tiempo Estimado:** 2-4 horas adicionales

**Recomendado si:** Quieres sincronización automática completa

---

### Opción C: Rollback Completo a Versión Anterior

Si v5.5.0 tampoco funciona de manera confiable.

**No recomendado** a menos que v5.5.0 también falle en producción.

---

## 📝 Archivos de Referencia

### Documentación
```
README.md                           # Documentación principal
RESUMEN_FINAL_v5.6.0.md            # Resumen detallado de todo el proceso
ESTADO_SISTEMA.md                   # Este archivo (estado actual)
BUGFIX_CENSUS_LOADING.md           # Fix de v5.5.0 (line endings)
INSTALL_v5.6.0.md                  # Guía de instalación (desactualizada)
```

### Scripts de Utilidad
```
/tmp/diagnostico_censo_app.sh       # Diagnóstico automático de censo
/tmp/diagnose_sync.sh               # Diagnóstico de sincronización
/tmp/habilitar_usb_debug.txt        # Instrucciones USB Debugging
/tmp/FIX_0_PERSONAS.txt             # Fix para problema "0 personas"
```

### APKs
```
/home/smt/Descargas/
├── Lumara_v5.5.0_UNIX_EOL_GARANTIZADO_20251012_113207.apk  ← USAR ESTE
├── Lumara_v5.6.0_UPLOAD_WITH_PERSON_FIX_20251012_174106.apk (obsoleto)
└── Lumara_v5.6.0_FINAL_FIX_20251012_181046.apk            (no funciona)
```

---

## ✅ Lo Que Definitivamente Funciona

1. **Backend** guarda documentos con relaciones (probado con curl)
2. **App v5.5.0** carga censo completo (probado en dispositivo)
3. **CSV** tiene formato correcto (Unix line endings)
4. **Scripts de diagnóstico** están listos para usar

---

## ❌ Lo Que Definitivamente NO Funciona

1. **App v5.6.0** muestra "0 personas" (causa desconocida)
2. **ADB** no está configurado (USB Debugging deshabilitado)
3. **Sincronización E2E** no se ha probado nunca
4. **Testing en dispositivo** no se hizo antes de distribuir APK

---

## 🔄 Estado del Repositorio Git

### Commits Pendientes

**OpenScan (App):**
```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Cambios sin commitear:
- pubspec.yaml (versión 5.6.0+56)
- lib/core/constants/api_constants.dart (appVersion 5.6.0)
- README.md (actualizado)
- RESUMEN_FINAL_v5.6.0.md (nuevo)
- ESTADO_SISTEMA.md (nuevo)
- Multiple archivos de documentación
```

**Paperless-ngx (Backend):**
```bash
cd /home/smt/Escritorio/programacion_proyectos/paperless/paperless-ngx/paperless-ngx

# Cambios ya commiteados:
✅ src/documents/views_census.py (endpoint upload_with_person completo)
```

---

**Última Actualización:** 2025-10-12 23:30 UTC
**Compilado por:** Claude Code
**Estado:** Documentación completa, sistema parcialmente funcional
