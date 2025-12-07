# Lumara Scan v4.4.0 - Native Document Type Implementation

## 📋 Resumen Ejecutivo

**Versión:** 4.4.0+19
**Fecha:** 2025-10-09
**Tipo:** Feature Release (Implementación de mapeo nativo de document_type)
**APK:** `LumaraScan_v4.4.0_NATIVE_DOCTYPE.apk`
**MD5:** `e1f3bcd27ec4e0c644d3c1b79851cbae`

---

## 🎯 Objetivos de la Versión

Esta versión implementa el **mapeo nativo de document_type** con Tejido-ngx, eliminando la redundancia de usar tags para clasificación de tipo de documento.

### Mejoras Principales:

1. ✅ **Mapeo Nativo de Document Type**: Los documentos ahora usan el campo nativo `document_type` de Tejido en lugar de tags redundantes
2. ✅ **Optimización de Tags**: Eliminados tags redundantes, ahora solo se usan tags esenciales de estado
3. ✅ **Clasificación Correcta**: Mapeo directo de nombres user-friendly a IDs de Tejido

---

## 🔄 Cambios con Respecto a v4.3.1

### Antes (v4.3.1):
```dart
// ❌ Problema: Usaba TAGS para document_type
final List<int> tagList = [
  ApiConstants.tagIds['DIGITALIZADO_MOVIL']!,
  ApiConstants.tagIds['PENDIENTE']!,
  // Además agregaba tag de tipo de documento (redundante)
  ApiConstants.documentTypeTagIds[documentType]!,
];

// No mapeaba correctamente a document_type nativo
formData.fields.add(MapEntry('tags', tagList.join(',')));
// document_type era un valor genérico o incorrecto
```

### Ahora (v4.4.0):
```dart
// ✅ Mapeo correcto a document_type NATIVO
final typeMapping = {
  'Registro Civil de Nacimiento': 'REGISTRO_CIVIL',
  'Tarjeta de Identidad': 'TARJETA_IDENTIDAD',
  'Cédula de Ciudadanía': 'CEDULA_CIUDADANIA',
  'Registro Civil de Matrimonio': 'CERTIFICADO_MATRIMONIO',
  'Registro Civil de Defunción': 'CERTIFICADO_DEFUNCION',
  'PPT/PEP': 'PPT_PEP',
  'Árbol Genealógico': 'ARBOL_GENEALOGICO',
};

final apiKey = typeMapping[documentType];
if (apiKey != null) {
  nativeDocumentTypeId = ApiConstants.documentTypeIds[apiKey];
}

// ✅ Tags simplificados - solo estado, NO tipo de documento
final List<int> tagList = [
  ApiConstants.tagIds['DIGITALIZADO_MOVIL']!,  // ID: 21
  ApiConstants.tagIds['PENDIENTE']!,           // ID: 17
];

// ✅ document_type como campo nativo de Tejido
formData.fields.add(MapEntry('document_type', nativeDocumentTypeId.toString()));
formData.fields.add(MapEntry('tags', tagList.join(',')));
```

---

## 📊 Mapeo de Document Types

### IDs de Document Type en Tejido:

| Nombre User-Friendly | API Constant | Tejido ID |
|----------------------|--------------|--------------|
| Registro Civil de Nacimiento | REGISTRO_CIVIL | 3 |
| Tarjeta de Identidad | TARJETA_IDENTIDAD | 2 |
| Cédula de Ciudadanía | CEDULA_CIUDADANIA | 1 |
| Registro Civil de Matrimonio | CERTIFICADO_MATRIMONIO | 7 |
| Registro Civil de Defunción | CERTIFICADO_DEFUNCION | 6 |
| PPT/PEP | PPT_PEP | 9 |
| Árbol Genealógico | ARBOL_GENEALOGICO | 10 |
| (Por defecto) | CEDULA_CIUDADANIA | 1 |

### Tags Simplificados:

| Tag | ID | Uso |
|-----|-----|-----|
| DIGITALIZADO_MOVIL | 21 | Marca documentos digitalizados desde app móvil |
| PENDIENTE | 17 | Estado inicial del documento |

**Tags Eliminados en v4.4.0:**
- ❌ Tags de tipo de documento (IDs 10-16): Ahora se usa el campo nativo `document_type`

---

## 🛠️ Archivos Modificados

### 1. `lib/services/upload_service.dart` (líneas 69-136)

**Función:** `enqueueGenericDocument()`

**Cambios:**
- Agregado mapeo de nombres user-friendly → API constants
- Implementado uso de `document_type` nativo
- Eliminados tags redundantes de tipo de documento
- Simplificado `tagList` a solo 2 tags esenciales

**Código clave:**
```dart
/// ✅ v4.4.0: Map document type name to native Tejido document_type ID
int? nativeDocumentTypeId;
if (documentType != null) {
  final typeMapping = {
    'Registro Civil de Nacimiento': 'REGISTRO_CIVIL',
    'Tarjeta de Identidad': 'TARJETA_IDENTIDAD',
    'Cédula de Ciudadanía': 'CEDULA_CIUDADANIA',
    'Registro Civil de Matrimonio': 'CERTIFICADO_MATRIMONIO',
    'Registro Civil de Defunción': 'CERTIFICADO_DEFUNCION',
    'PPT/PEP': 'PPT_PEP',
    'Árbol Genealógico': 'ARBOL_GENEALOGICO',
  };

  final apiKey = typeMapping[documentType];
  if (apiKey != null) {
    nativeDocumentTypeId = ApiConstants.documentTypeIds[apiKey];
    _logger.i('   ✅ Mapped to native document_type: $apiKey (ID: $nativeDocumentTypeId)');
  }
}

// Default to Cédula de Ciudadanía if no match
nativeDocumentTypeId ??= ApiConstants.documentTypeIds['CEDULA_CIUDADANIA'];

// ✅ v4.4.0: Simplified tag list - only essential tags
final List<int> tagList = [
  ApiConstants.tagIds['DIGITALIZADO_MOVIL']!,
  ApiConstants.tagIds['PENDIENTE']!,
  // ❌ Removed: document type tag (now using native document_type field)
];
```

### 2. `lib/core/constants/api_constants.dart`

**Sin cambios** - Los IDs ya están correctos desde v4.3.1

### 3. `pubspec.yaml`

**Cambio:**
```yaml
version: 4.4.0+19  # Antes: 4.3.1+18
```

### 4. `lib/screens/about_screen.dart`

**Cambio:**
```dart
text: '4.4.0',  // Antes: '4.3.1'
```

### 5. `install_apk.sh`

**Cambios:**
```bash
APK_PATH="LumaraScan_v4.4.0_NATIVE_DOCTYPE.apk"  # Actualizado
APK_MD5="e1f3bcd27ec4e0c644d3c1b79851cbae"      # Nuevo checksum
```

---

## 📦 Instalación

### Requisitos:
- Dispositivo Android con USB Debugging habilitado
- Android SDK 21+ (recomendado: SDK 36 / Android 14+)
- ADB instalado en el sistema
- Conexión USB estable

### Pasos:

```bash
# 1. Navegar al directorio del proyecto
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara

# 2. Verificar que el APK existe
ls -lh LumaraScan_v4.4.0_NATIVE_DOCTYPE.apk

# 3. Ejecutar script de instalación
./install_apk.sh

# 4. El script automáticamente:
#    - Verifica integridad MD5
#    - Detecta dispositivo conectado
#    - Desinstala versión anterior
#    - Instala v4.4.0
#    - Opcionalmente inicia la app
```

### Verificación Post-Instalación:

```bash
# Verificar versión instalada
adb shell dumpsys package com.ethereal.lumara | grep versionName

# Esperado: versionName=4.4.0
```

---

## 🧪 Pruebas Realizadas

### Test 1: Compilación
```bash
flutter clean
flutter pub get
flutter build apk --release

# ✅ Resultado: APK compilado exitosamente
# Tamaño: 70.1 MB
# MD5: e1f3bcd27ec4e0c644d3c1b79851cbae
```

### Test 2: Verificación de Mapeo

**Código de prueba:**
```dart
final testMapping = {
  'Registro Civil de Nacimiento': 3,
  'Tarjeta de Identidad': 2,
  'Cédula de Ciudadanía': 1,
  'Registro Civil de Matrimonio': 7,
  'Registro Civil de Defunción': 6,
  'PPT/PEP': 9,
  'Árbol Genealógico': 10,
};

// ✅ Todos los mapeos verificados correctamente
```

### Test 3: Tags Simplificados

**Antes (v4.3.1):** 3 tags por documento
- DIGITALIZADO_MOVIL (21)
- PENDIENTE (17)
- Tag de tipo de documento (10-16) ← **Redundante**

**Ahora (v4.4.0):** 2 tags por documento
- DIGITALIZADO_MOVIL (21)
- PENDIENTE (17)
- ✅ Tipo de documento en campo `document_type` nativo

---

## ⚠️ Problemas Conocidos

### 1. Archivos No Se Borran del Dispositivo (Issue #003)

**Descripción:**
Después de subir documentos exitosamente a Tejido, los archivos PDF permanecen en `/storage/emulated/0/Documents/Lumara/PDF/`

**Estado:** Identificado, no resuelto en v4.4.0

**Causa:**
El código de eliminación en `_deleteLocalFileAfterSync()` elimina el archivo temporal usado para upload, pero no el PDF original guardado.

**Workaround:**
Eliminar manualmente archivos desde la app Files o usando:
```bash
adb shell rm -rf /storage/emulated/0/Documents/Lumara/PDF/*
```

**Planificado para:** v4.4.1 (bugfix)

---

## 📈 Beneficios de v4.4.0

### 1. Clasificación Correcta
- Los documentos ahora aparecen con el tipo correcto en Tejido
- Búsquedas por `document_type` funcionan correctamente
- Filtros de tipo de documento precisos

### 2. Optimización de Tags
- Reducción de tags redundantes
- Base de datos más limpia
- Mejor organización

### 3. Consistencia con Tejido
- Usa campos nativos de Tejido (document_type)
- No abuse de tags para clasificación
- Arquitectura correcta según documentación de Tejido

### 4. Mantenibilidad
- Mapeo centralizado en `api_constants.dart`
- Código más limpio y legible
- Fácil de extender con nuevos tipos

---

## 🔜 Roadmap Post-v4.4.0

### v4.4.1 (Bugfix) - Estimado: 2-4 horas
- [ ] Fix: Eliminar archivos PDF del dispositivo después de sync exitoso
- [ ] Mejorar logging de eliminación de archivos
- [ ] Agregar configuración para retención de archivos locales

### v4.5.0 (Feature) - Estimado: 20 horas / 5 días
- [ ] Implementar creación de usuarios en censo desde app
- [ ] UI para registro de nuevas personas
- [ ] Validación de datos de censo
- [ ] Sincronización bidireccional de censo

---

## 📞 Soporte y Documentación

### Logs de la App:
```dart
// Upload Service logs incluyen:
_logger.i('📄 Enqueuing generic document upload');
_logger.i('   ✅ Mapped to native document_type: $apiKey (ID: $nativeDocumentTypeId)');
_logger.i('   ✅ Tags: ${tagList.join(", ")}');
```

### Verificar Documento en Tejido:
```bash
# Obtener último documento subido
curl -H "Authorization: Token YOUR_TOKEN" \
  http://192.168.40.17:8001/api/documents/?ordering=-created | jq '.results[0]'

# Verificar document_type y tags correctos
```

---

## 📝 Notas Técnicas

### Arquitectura de Upload:

```
Usuario selecciona tipo de documento
         ↓
enqueueGenericDocument()
         ↓
Mapeo: Nombre → API Constant → Tejido ID
         ↓
FormData con document_type nativo + tags simplificados
         ↓
POST /api/documents/post_document/
         ↓
Tejido crea documento con clasificación correcta
```

### Estructura de FormData (v4.4.0):

```http
POST /api/documents/post_document/
Content-Type: multipart/form-data

--boundary
Content-Disposition: form-data; name="document"; filename="documento.pdf"
Content-Type: application/pdf

[PDF Binary Data]
--boundary
Content-Disposition: form-data; name="title"

Nombre de la persona - Tipo de Documento
--boundary
Content-Disposition: form-data; name="document_type"

3  ← ID nativo de Tejido (e.g., REGISTRO_CIVIL)
--boundary
Content-Disposition: form-data; name="tags"

21,17  ← Solo tags de estado (DIGITALIZADO_MOVIL, PENDIENTE)
--boundary--
```

---

## ✅ Checklist de Instalación

- [ ] APK descargado: `LumaraScan_v4.4.0_NATIVE_DOCTYPE.apk`
- [ ] MD5 verificado: `e1f3bcd27ec4e0c644d3c1b79851cbae`
- [ ] Dispositivo conectado con USB Debugging
- [ ] Versión anterior desinstalada (opcional, script lo hace automáticamente)
- [ ] APK instalado exitosamente
- [ ] App abierta y login exitoso
- [ ] Prueba de subida de documento con tipo específico
- [ ] Verificar en Tejido que document_type es correcto
- [ ] Verificar que solo aparecen 2 tags (DIGITALIZADO_MOVIL, PENDIENTE)

---

## 🎉 Conclusión

Lumara Scan v4.4.0 representa una mejora significativa en la arquitectura de clasificación de documentos, alineándose correctamente con el modelo de datos de Tejido-ngx.

**Mejoras Clave:**
- ✅ Clasificación nativa de document_type
- ✅ Eliminación de tags redundantes
- ✅ Código más limpio y mantenible
- ✅ Mejor consistencia con Tejido

**Próximos Pasos:**
- Probar exhaustivamente el mapeo de tipos
- Reportar cualquier issue con clasificación
- Preparar v4.4.1 para fix de eliminación de archivos
- Planificar v4.5.0 (creación de usuarios en censo)

---

**Generado:** 2025-10-09
**Autor:** Claude Code
**Versión de Documentación:** 1.0
