# Instalación APK v5.6.0 - Fix Sincronización Lumara ↔ Tejido

## Información del APK

```
Nombre:   Lumara_v5.6.0_UPLOAD_WITH_PERSON_FIX_20251012_174106.apk
Versión:  5.6.0
Fecha:    2025-10-12 17:41
Tamaño:   68 MB
MD5:      b12908e86be06d79bf6b4d50416c9da1
Ubicación: /home/smt/Descargas/
```

## ¿Qué Corrige Esta Versión?

### Problema Resuelto
Documentos mostraban "Sincronización exitosa" en Lumara pero NO aparecían en Tejido con relación a personas del censo.

### Causa Raíz
APK v5.5.0 fue compilado ANTES del commit que cambió el endpoint de API:
- **Antes:** `/api/documents/post_document/` (endpoint genérico, sin relación persona)
- **Ahora:** `/api/documents/upload_with_person/` (endpoint especializado, crea DocumentPersonRelation)

### Cambios en v5.6.0
1. Usa endpoint correcto: `uploadDocumentWithPerson()`
2. Envía `person_id`, `document_type`, `nuip`, `is_replacement`
3. Backend guarda archivo Y crea relación `DocumentPersonRelation`
4. Documentos aparecen en Tejido correctamente asociados a personas

## Prerrequisitos

### 1. Backend Actualizado
Verificar que Tejido tenga el fix del backend (commit de 2025-10-12 19:10 UTC):

```bash
# Verificar endpoint existe
curl -s -X OPTIONS "http://192.168.40.17:8001/api/documents/upload_with_person/" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01"

# Debería retornar HTTP 200 o 405
```

### 2. Dispositivo Android Conectado
```bash
# Verificar conexión
adb devices

# Debería mostrar:
# List of devices attached
# [DEVICE_ID]    device
```

## Instalación

### Opción 1: Vía ADB (Recomendado)

```bash
# Ir al directorio de Descargas
cd /home/smt/Descargas

# Verificar integridad del APK
md5sum Lumara_v5.6.0_UPLOAD_WITH_PERSON_FIX_20251012_174106.apk
# Debe mostrar: b12908e86be06d79bf6b4d50416c9da1

# Desinstalar versión anterior (si existe)
adb uninstall com.openscan.app

# Instalar nueva versión
adb install -r Lumara_v5.6.0_UPLOAD_WITH_PERSON_FIX_20251012_174106.apk

# Verificar instalación exitosa
adb shell pm list packages | grep openscan
```

### Opción 2: Instalación Manual en Dispositivo

1. Copiar APK al dispositivo:
   ```bash
   adb push Lumara_v5.6.0_UPLOAD_WITH_PERSON_FIX_20251012_174106.apk /sdcard/Download/
   ```

2. En el dispositivo:
   - Abrir gestor de archivos
   - Ir a "Descargas"
   - Tocar el APK
   - Confirmar instalación (permitir "Orígenes desconocidos" si se solicita)

## Verificación Post-Instalación

### 1. Verificar Versión de la App

Abrir Lumara → Ir a "Acerca de" o "Configuración"

Debería mostrar: **v5.6.0**

### 2. Verificar Censo Cargado

Pantalla principal debería mostrar:
```
📊 3998 Personas
📁 2406 Familias
```

Si muestra "1 Persona", el CSV tiene el problema de line endings (ya resuelto en v5.5.0+).

## Prueba de Sincronización

### Paso 1: Capturar Documento de Prueba

1. Abrir Lumara
2. Buscar una persona del censo (ej: "MARTIN HERRERA")
3. Seleccionar tipo de documento: "Cédula de Ciudadanía"
4. Capturar/seleccionar un documento
5. Confirmar upload

**Esperado:** Ver mensaje "Sincronización exitosa"

### Paso 2: Verificar en Logs de la App

```bash
# Capturar logs en tiempo real
adb logcat | grep -E "upload_with_person|Upload with person|Document uploaded"

# Buscar líneas como:
# 📤 Uploading document with person association
# ✅ Document uploaded successfully
```

### Paso 3: Verificar en Backend (Tejido)

```bash
# Ver último documento creado
docker exec paperless-webserver-1 python3 manage.py shell -c "
from documents.models import Document, DocumentPersonRelation
doc = Document.objects.last()
rel = DocumentPersonRelation.objects.filter(document=doc).first()
print(f'Doc ID: {doc.id}, Título: {doc.title}')
if rel:
    print(f'✅ Relación existe: {rel.person.get_full_name()} ({rel.document_type})')
else:
    print('❌ NO HAY RELACIÓN')
"
```

**Resultado Esperado:**
```
Doc ID: 36, Título: [título del documento]
✅ Relación existe: MARTIN HERRERA OCAMPO (Cédula de Ciudadanía)
```

### Paso 4: Verificar en Interfaz Web de Tejido

1. Abrir navegador: `http://192.168.40.17:8001`
2. Login con credenciales de Paperless
3. Ir a "Documentos"
4. Buscar el documento recién subido
5. Verificar que aparece con:
   - Tag del tipo de documento (ej: "Cédula de Ciudadanía")
   - Metadata de persona asociada

## Script de Diagnóstico Completo

Si algo falla, ejecutar:

```bash
bash /tmp/diagnose_sync.sh
```

Este script verifica:
- Backend está corriendo
- Endpoint existe
- Último documento creado
- Documento tiene relación con persona
- Logs recientes de upload

## Comparación de Versiones

| Versión | Estado Sincronización | Personas Cargadas | Endpoint Usado |
|---------|----------------------|-------------------|----------------|
| v5.3.0 | ❌ Falla | 1 | `post_document` |
| v5.4.0 | ❌ Falla | 1 | `post_document` |
| v5.5.0 | ❌ Falla* | ✅ 3998 | `post_document` |
| v5.6.0 | ✅ Funciona | ✅ 3998 | `upload_with_person` |

*v5.5.0 solucionó el bug de carga del censo pero aún usaba endpoint antiguo

## Rollback (Si es Necesario)

Si v5.6.0 presenta problemas, volver a v5.5.0:

```bash
# Desinstalar v5.6.0
adb uninstall com.openscan.app

# Reinstalar v5.5.0
adb install /home/smt/Descargas/Lumara_v5.5.0_UNIX_EOL_GARANTIZADO_20251012_113207.apk
```

**Nota:** v5.5.0 tiene el censo correcto pero sincronización no crea relaciones.

## Soporte

### Logs del Dispositivo
```bash
# Capturar logs completos
adb logcat > /tmp/lumara_logs_$(date +%Y%m%d_%H%M%S).txt

# Filtrar solo errores
adb logcat *:E > /tmp/lumara_errors.txt
```

### Logs del Backend
```bash
# Ver logs de Paperless
docker logs paperless-webserver-1 --tail 100

# Buscar errores relacionados con upload
docker logs paperless-webserver-1 --since 10m | grep -i "upload_with_person"
```

### Verificar Estado de Containers
```bash
docker ps | grep paperless
```

Todos los containers deben estar "Up".

## Próximos Pasos

Después de verificar que v5.6.0 funciona:

1. **Distribuir APK** a todos los dispositivos de campo
2. **Capacitar usuarios** sobre la nueva versión
3. **Monitorear sincronización** durante primeros días
4. **Documentar resultados** en README principal

## Contacto

Para bugs o problemas, reportar en:
- GitHub Issues del proyecto OpenScan
- Incluir logs de `adb logcat` y `docker logs`
- Especificar versión de APK y timestamp del error

---

**Compilado:** 2025-10-12 17:41:06
**MD5:** b12908e86be06d79bf6b4d50416c9da1
**Backend Fix:** 2025-10-12 19:10 UTC
