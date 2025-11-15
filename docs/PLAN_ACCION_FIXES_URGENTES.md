# 🚨 PLAN DE ACCIÓN: Fixes Urgentes Lumara

**Fecha**: 27 de octubre de 2025
**Objetivo**: Resolver 2 problemas críticos detectados en Workflow 3

---

## 📋 Problemas Identificados

### ❌ PROBLEMA 1: Lumara no crea relaciones documento-persona
**Evidencia**: 0 relaciones antes de pruebas, backend funciona 100%
**Impacto**: CRÍTICO - Sistema inutilizable sin asociaciones

### ❌ PROBLEMA 2: Backend permite duplicados
**Evidencia**: Persona 3998 tiene 2 cédulas (docs 38 y 43)
**Impacto**: ALTO - Datos inconsistentes, confusión operativa

---

## 🔍 ANÁLISIS DE CÓDIGO (Completado)

### Hallazgos del Análisis

**✅ Código de Lumara PARECE CORRECTO**:

1. **upload_service.dart:455-463** ✅
   - Llama a `_documentRepository.uploadDocumentForPerson()`
   - Pasa todos los parámetros correctamente
   - Incluye person, documentType, isReplacement

2. **document_repository.dart:91** ✅
   - Llama a `_apiClient.uploadDocumentWithPerson()`
   - Pasa personId, documentType, etc.

3. **paperless_api_client.dart:381** ✅
   - Llama al endpoint correcto: `/api/documents/upload_with_person/`
   - Con form data correcto: person_id, document_type, nuip, etc.

### 🤔 Entonces, ¿Por Qué Falla?

**Hipótesis**:
1. ❓ Los uploads NO se están ejecutando (pending uploads vacíos)
2. ❓ Los uploads FALLAN silenciosamente sin reportar al usuario
3. ❓ El `personId` es NULL al crear pending uploads
4. ❓ Error en flujo de captura que no llega a crear upload

**Necesitamos**: Logging detallado para rastrear el flujo completo

---

## 🎯 PLAN DE ACCIÓN

---

## 📱 TAREA 1: Investigar y Diagnosticar Lumara

**Prioridad**: 🔴 URGENTE
**Tiempo estimado**: 2-3 horas
**Dependencias**: Ninguna

### Objetivo
Agregar logging exhaustivo para identificar dónde se rompe el flujo de asociación persona-documento.

### Pasos de Implementación

#### PASO 1.1: Agregar Logging en DocumentCaptureScreen

**Archivo**: `lib/presentation/document_capture/document_capture_screen.dart`

**Ubicación**: Método donde se guarda el documento capturado

```dart
// DESPUÉS de capturar documento, ANTES de crear pending upload
_logger.i('═══════════════════════════════════════════════════════');
_logger.i('📸 DOCUMENTO CAPTURADO - Diagnóstico Completo');
_logger.i('═══════════════════════════════════════════════════════');
_logger.i('Archivo: $filePath');
_logger.i('Tamaño: ${File(filePath).lengthSync()} bytes');
_logger.i('');
_logger.i('👤 DATOS DE PERSONA:');
_logger.i('   Person ID: ${widget.selectedPerson?.personId ?? "NULL ⚠️"}');
_logger.i('   Nombre: ${widget.selectedPerson?.fullName ?? "NULL ⚠️"}');
_logger.i('   NUIP: ${widget.selectedPerson?.documentNumber ?? "NULL ⚠️"}');
_logger.i('   Family ID: ${widget.selectedPerson?.familyId ?? "NULL ⚠️"}');
_logger.i('');
_logger.i('📄 DATOS DE DOCUMENTO:');
_logger.i('   Tipo: ${widget.selectedDocumentType ?? "NULL ⚠️"}');
_logger.i('   Número: ${widget.documentNumber ?? "N/A"}');
_logger.i('');
_logger.i('🔄 CREANDO PENDING UPLOAD...');

// Aquí va el código que crea el pending upload

_logger.i('✅ Pending upload creado con ID: $uploadId');
_logger.i('═══════════════════════════════════════════════════════');
```

**Validaciones a Agregar**:
```dart
// ANTES de crear pending upload
if (widget.selectedPerson == null) {
  _logger.e('❌ PROBLEMA CRÍTICO: selectedPerson es NULL');
  _logger.e('   No se puede crear asociación sin persona');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: No se seleccionó ninguna persona'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
  return; // DETENER flujo
}

if (widget.selectedPerson!.personId.isEmpty) {
  _logger.e('❌ PROBLEMA CRÍTICO: personId está vacío');
  _logger.e('   Persona: ${widget.selectedPerson!.fullName}');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: Persona sin ID válido'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
  return; // DETENER flujo
}

if (widget.selectedDocumentType == null || widget.selectedDocumentType!.isEmpty) {
  _logger.e('❌ PROBLEMA CRÍTICO: documentType no seleccionado');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: No se seleccionó tipo de documento'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
  return; // DETENER flujo
}
```

#### PASO 1.2: Agregar Logging en upload_service.dart

**Archivo**: `lib/services/upload_service.dart`

**Ubicación 1**: Método `_uploadDocument` (línea ~420)

```dart
Future<Map<String, dynamic>> _uploadDocument(
  PendingUpload upload,
  String filePath,
  Map<String, dynamic> metadata,
) async {
  _logger.i('═══════════════════════════════════════════════════════');
  _logger.i('📤 INICIANDO UPLOAD - Diagnóstico');
  _logger.i('═══════════════════════════════════════════════════════');
  _logger.i('Upload ID: ${upload.id}');
  _logger.i('File: ${upload.fileName}');
  _logger.i('File exists: ${File(filePath).existsSync()}');
  _logger.i('');
  _logger.i('👤 PERSONA (desde upload):');
  _logger.i('   Person ID: ${upload.personId ?? "NULL ⚠️⚠️⚠️"}');
  _logger.i('   Person Name: ${upload.personName ?? "NULL ⚠️"}');
  _logger.i('   Family ID: ${upload.familyId ?? "NULL ⚠️"}');
  _logger.i('');
  _logger.i('📄 DOCUMENTO (desde upload):');
  _logger.i('   Document Type: ${upload.documentType}');
  _logger.i('   Document Number: ${upload.documentNumber ?? "N/A"}');
  _logger.i('');

  // Validación CRÍTICA
  if (upload.personId == null || upload.personId!.isEmpty) {
    _logger.e('❌❌❌ PROBLEMA CRÍTICO DETECTADO ❌❌❌');
    _logger.e('   personId es NULL o vacío en PendingUpload');
    _logger.e('   Este upload NO se podrá asociar con persona');
    _logger.e('   Causas posibles:');
    _logger.e('   1. selectedPerson era null al crear upload');
    _logger.e('   2. personId no se guardó en base de datos');
    _logger.e('   3. Error en pantalla de captura');
    _logger.e('');
    _logger.e('⚠️ ABORTANDO upload - No tiene sentido continuar sin person_id');

    throw Exception(
      'Upload sin person_id. No se puede crear asociación documento-persona. '
      'Verifica que se seleccionó una persona antes de capturar.'
    );
  }

  _logger.i('✅ Validación pasada: person_id presente');
  _logger.i('');
  _logger.i('🔄 Determinando tipo de upload...');

  // El resto del código continúa...
```

**Ubicación 2**: Dentro del bloque `if (upload.personId != null)` (línea ~435)

```dart
if (upload.personId != null && upload.personId!.isNotEmpty) {
  _logger.i('');
  _logger.i('═══════════════════════════════════════════════════════');
  _logger.i('📋 UPLOAD CON PERSONA - Construyendo objeto Person');
  _logger.i('═══════════════════════════════════════════════════════');

  // Construct person object from upload data
  final person = entities.Person(
    personId: upload.personId,
    fullName: upload.personName,
    firstName: upload.personName.split(' ').first,
    lastName: upload.personName.split(' ').skip(1).join(' '),
    familyId: upload.familyId,
    requiredDocumentsCount: 0,
    requiredDocuments: [],
  );

  _logger.i('✅ Person object construido:');
  _logger.i('   ID: ${person.personId}');
  _logger.i('   Nombre: ${person.fullName}');
  _logger.i('   First: ${person.firstName}');
  _logger.i('   Last: ${person.lastName}');
  _logger.i('');

  final isReplacement = metadata['is_replacement'] as bool? ?? false;

  _logger.i('🎯 LLAMANDO A REPOSITORY...');
  _logger.i('   Endpoint: uploadDocumentForPerson');
  _logger.i('   Is Replacement: $isReplacement');
  _logger.i('');

  try {
    final result = await _documentRepository.uploadDocumentForPerson(
      filePath: filePath,
      fileName: upload.fileName,
      person: person,
      documentType: upload.documentType,
      documentNumber: upload.documentNumber,
      digitizedBy: upload.digitizedBy,
      isReplacement: isReplacement,
    );

    _logger.i('');
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('✅✅✅ UPLOAD EXITOSO ✅✅✅');
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('Response: $result');
    _logger.i('');

    if (result['success'] == true) {
      _logger.i('🎉 Backend confirmó éxito:');
      _logger.i('   Document ID: ${result['document_id']}');
      _logger.i('   Person ID: ${result['person_id']}');
      _logger.i('   Relation ID: ${result['relation_id']} ⭐ ASOCIACIÓN CREADA');
      _logger.i('   Person Name: ${result['person_name']}');
    }

    _logger.i('═══════════════════════════════════════════════════════');

    return result;

  } catch (e) {
    _logger.e('');
    _logger.e('═══════════════════════════════════════════════════════');
    _logger.e('❌❌❌ ERROR EN UPLOAD CON PERSONA ❌❌❌');
    _logger.e('═══════════════════════════════════════════════════════');
    _logger.e('Error: $e');
    _logger.e('Upload ID: ${upload.id}');
    _logger.e('Person ID que se envió: ${upload.personId}');
    _logger.e('═══════════════════════════════════════════════════════');
    rethrow;
  }
}
```

#### PASO 1.3: Agregar Logging en document_repository.dart

**Archivo**: `lib/data/repositories/document_repository.dart`

**Ubicación**: Método `uploadDocumentForPerson` (línea ~71)

```dart
Future<Map<String, dynamic>> uploadDocumentForPerson({
  required String filePath,
  required String fileName,
  required entities.Person person,
  required String documentType,
  String? documentNumber,
  String? digitizedBy,
  bool isReplacement = false,
}) async {
  try {
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('📦 DOCUMENT REPOSITORY - uploadDocumentForPerson');
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('Person:');
    _logger.i('   ID: ${person.personId}');
    _logger.i('   Name: ${person.fullName}');
    _logger.i('   NUIP: ${person.documentNumber}');
    _logger.i('');
    _logger.i('Document:');
    _logger.i('   Type: $documentType');
    _logger.i('   File: $fileName');
    _logger.i('   Is Replacement: $isReplacement');
    _logger.i('   Document Number: ${documentNumber ?? person.documentNumber}');
    _logger.i('');

    final docTypeLabel = _getDocumentTypeLabel(documentType);
    _logger.i('Document Type Label: $docTypeLabel');
    _logger.i('');
    _logger.i('🌐 Llamando a API Client...');

    // Use new specialized endpoint
    final response = await _apiClient.uploadDocumentWithPerson(
      personId: person.personId,
      documentType: docTypeLabel,
      filePath: filePath,
      fileName: fileName,
      isReplacement: isReplacement,
      documentNumber: documentNumber ?? person.documentNumber,
      digitizedBy: digitizedBy,
    );

    _logger.i('');
    _logger.i('✅ API Client respondió exitosamente');
    _logger.i('Response data: $response');
    _logger.i('═══════════════════════════════════════════════════════');

    return response;
  } catch (e) {
    _logger.e('═══════════════════════════════════════════════════════');
    _logger.e('❌ REPOSITORY ERROR');
    _logger.e('═══════════════════════════════════════════════════════');
    _logger.e('Error: $e');
    _logger.e('Person ID: ${person.personId}');
    _logger.e('Document Type: $documentType');
    _logger.e('═══════════════════════════════════════════════════════');
    rethrow;
  }
}
```

#### PASO 1.4: Agregar Logging en paperless_api_client.dart

**Archivo**: `lib/data/datasources/paperless_api_client.dart`

**Ubicación**: Método `uploadDocumentWithPerson` (línea ~351)

```dart
Future<Map<String, dynamic>> uploadDocumentWithPerson({
  required String personId,
  required String documentType,
  required String filePath,
  required String fileName,
  bool isReplacement = false,
  String? documentNumber,
  String? digitizedBy,
}) async {
  try {
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('🌐 API CLIENT - uploadDocumentWithPerson');
    _logger.i('═══════════════════════════════════════════════════════');
    _logger.i('Endpoint: /api/documents/upload_with_person/');
    _logger.i('');
    _logger.i('Parameters:');
    _logger.i('   person_id: $personId');
    _logger.i('   document_type: $documentType');
    _logger.i('   file_path: $filePath');
    _logger.i('   file_name: $fileName');
    _logger.i('   is_replacement: $isReplacement');
    _logger.i('   nuip: ${documentNumber ?? ""}');
    _logger.i('   digitized_by: ${digitizedBy ?? "N/A"}');
    _logger.i('   association_method: APP');
    _logger.i('');

    final file = File(filePath);
    _logger.i('File validation:');
    _logger.i('   Exists: ${file.existsSync()}');
    if (file.existsSync()) {
      _logger.i('   Size: ${file.lengthSync()} bytes');
    }
    _logger.i('');

    // Create form data
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(filePath, filename: fileName),
      'person_id': personId,
      'document_type': documentType,
      'is_replacement': isReplacement.toString(),
      'nuip': documentNumber ?? '',
      if (digitizedBy != null) 'digitized_by': digitizedBy,
      'association_method': 'APP',
    });

    _logger.i('📡 Enviando request POST...');
    final startTime = DateTime.now();

    final response = await _dio.post(
      '/api/documents/upload_with_person/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final duration = DateTime.now().difference(startTime);

    _logger.i('');
    _logger.i('📥 Respuesta recibida:');
    _logger.i('   Status Code: ${response.statusCode}');
    _logger.i('   Duration: ${duration.inMilliseconds}ms');
    _logger.i('   Response Data: ${response.data}');
    _logger.i('');

    if (response.statusCode == 201 || response.statusCode == 200) {
      _logger.i('✅ Upload exitoso (HTTP ${response.statusCode})');

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _logger.i('');
        _logger.i('🎉 Backend confirmó creación de asociación:');
        _logger.i('   Document ID: ${data['document_id']}');
        _logger.i('   Person ID: ${data['person_id']}');
        _logger.i('   Relation ID: ${data['relation_id']} ⭐⭐⭐');
        _logger.i('   Person Name: ${data['person_name']}');
      }
    }

    _logger.i('═══════════════════════════════════════════════════════');

    return response.data as Map<String, dynamic>;

  } on DioException catch (e) {
    _logger.e('═══════════════════════════════════════════════════════');
    _logger.e('❌ API CLIENT ERROR (DioException)');
    _logger.e('═══════════════════════════════════════════════════════');
    _logger.e('Error message: ${e.message}');
    _logger.e('Error type: ${e.type}');
    _logger.e('Status code: ${e.response?.statusCode}');
    _logger.e('Response data: ${e.response?.data}');
    _logger.e('');
    _logger.e('Request details:');
    _logger.e('   URL: /api/documents/upload_with_person/');
    _logger.e('   person_id: $personId');
    _logger.e('   document_type: $documentType');
    _logger.e('═══════════════════════════════════════════════════════');

    // Provide more context for common errors
    if (e.response?.statusCode == 400) {
      _logger.e('⚠️ HTTP 400: Parámetros inválidos');
      throw Exception('Parámetros inválidos: ${e.response?.data}');
    } else if (e.response?.statusCode == 404) {
      _logger.e('⚠️ HTTP 404: Persona no encontrada en censo');
      throw Exception('Persona no encontrada en censo');
    } else if (e.response?.statusCode == 401) {
      _logger.e('⚠️ HTTP 401: No autorizado');
      throw Exception('No autorizado. Por favor inicia sesión de nuevo.');
    } else if (e.response?.statusCode == 409) {
      _logger.e('⚠️ HTTP 409: Documento duplicado detectado');
      // No lanzar excepción, pasar respuesta al caller para manejar
      return e.response?.data as Map<String, dynamic>;
    }

    rethrow;
  }
}
```

#### PASO 1.5: Verificar creación de PendingUpload

**Archivo**: Donde se crea el PendingUpload (probablemente DocumentCaptureScreen o similar)

```dart
// ANTES de insertar en BD
_logger.i('🗃️ Creando PendingUpload en BD:');
_logger.i('   fileName: $fileName');
_logger.i('   personId: ${widget.selectedPerson?.personId} ⭐ CRÍTICO');
_logger.i('   personName: ${widget.selectedPerson?.fullName}');
_logger.i('   familyId: ${widget.selectedPerson?.familyId}');
_logger.i('   documentType: $documentType');
_logger.i('   documentNumber: $documentNumber');

final uploadId = await database.insertPendingUpload(
  fileName: fileName,
  filePath: savedFilePath,
  documentType: documentType,
  personId: widget.selectedPerson?.personId, // ⚠️ Verificar que NO sea null
  personName: widget.selectedPerson?.fullName,
  familyId: widget.selectedPerson?.familyId,
  documentNumber: documentNumber,
  digitizedBy: currentUser?.username,
  metadata: metadata,
);

_logger.i('✅ PendingUpload insertado con ID: $uploadId');

// INMEDIATAMENTE DESPUÉS de insertar, leer de nuevo para verificar
final verificacion = await database.getPendingUploadById(uploadId);
_logger.i('');
_logger.i('🔍 Verificación de lo que se guardó en BD:');
_logger.i('   Upload ID: ${verificacion?.id}');
_logger.i('   personId guardado: ${verificacion?.personId ?? "NULL ⚠️⚠️⚠️"}');
_logger.i('   personName guardado: ${verificacion?.personName}');
_logger.i('   documentType guardado: ${verificacion?.documentType}');

if (verificacion?.personId == null || verificacion!.personId!.isEmpty) {
  _logger.e('');
  _logger.e('❌❌❌ PROBLEMA DETECTADO ❌❌❌');
  _logger.e('El personId NO se guardó en la base de datos');
  _logger.e('Causa probable: widget.selectedPerson era null al crear upload');
  _logger.e('');

  throw Exception('No se pudo guardar person_id. Verifica que se seleccionó una persona.');
}

_logger.i('✅ Verificación pasada: personId se guardó correctamente');
```

### Entregables del Paso 1

- [ ] 5 archivos modificados con logging exhaustivo
- [ ] Validaciones que detienen flujo si falta person_id
- [ ] Mensajes visuales al usuario cuando hay errores
- [ ] Verificación de datos guardados en BD

### Cómo Probar

1. Compilar APK con logging
2. Instalar en dispositivo
3. Intentar capturar documento para persona del censo
4. Revisar logs con `./scripts/watch_logs.sh`
5. Buscar en logs:
   - ⭐ "ASOCIACIÓN CREADA" → Éxito
   - ⚠️ "NULL" en person_id → Problema identificado
   - ❌ "ERROR" → Punto exacto de falla

---

## 🖥️ TAREA 2: Implementar Validación de Duplicados en Backend

**Prioridad**: 🔴 URGENTE
**Tiempo estimado**: 1 hora
**Dependencias**: Ninguna (independiente de Tarea 1)

### Objetivo
Prevenir duplicados a nivel de servidor rechazando uploads de documentos del mismo tipo para la misma persona.

### Pasos de Implementación

#### PASO 2.1: Modificar views_census.py

**Archivo**: `/paperless-ngx/src/documents/views_census.py`

**Ubicación**: Después de línea 110 (verificar persona existe)

**Código a Agregar**:

```python
# Después de esta línea:
# except CensusPerson.DoesNotExist:
#     return Response(...)

# ═══════════════════════════════════════════════════════════
# VALIDACIÓN DE DUPLICADOS
# Verificar si ya existe documento del mismo tipo para esta persona
# Si existe Y no es reemplazo → RECHAZAR con HTTP 409
# ═══════════════════════════════════════════════════════════

existing_relation = DocumentPersonRelation.objects.filter(
    person=person,
    document_type=document_type,
).select_related('document').first()

if existing_relation and not is_replacement:
    # Ya existe documento del mismo tipo Y usuario NO indicó reemplazo
    existing_doc = existing_relation.document
    ocr_confidence = existing_relation.ocr_confidence or 0.0
    has_min_data = existing_relation.has_minimum_data

    logger.warning(
        f"DUPLICADO DETECTADO: {person.get_full_name()} ya tiene "
        f"documento de tipo '{document_type}' (Doc ID: {existing_doc.id}, "
        f"Calidad OCR: {ocr_confidence*100:.0f}%, "
        f"Has data: {has_min_data}). "
        f"Upload rechazado porque is_replacement=false"
    )

    # Determinar si se puede reemplazar
    can_replace = (ocr_confidence < 0.8) or not has_min_data

    return Response(
        {
            'success': False,
            'error': (
                f'Ya existe un documento de tipo "{document_type}" '
                f'para {person.get_full_name()}.'
            ),
            'error_code': 'DUPLICATE_DOCUMENT',
            'existing_document': {
                'id': existing_doc.id,
                'title': existing_doc.title,
                'created': existing_doc.created.isoformat(),
                'ocr_confidence': ocr_confidence,
                'has_minimum_data': has_min_data,
            },
            'suggestion': (
                f'Para reemplazar el documento existente por uno de mejor calidad, '
                f'envía is_replacement=true en tu request.'
                if can_replace
                else (
                    f'El documento existente tiene buena calidad ({ocr_confidence*100:.0f}%). '
                    f'No es necesario reemplazarlo.'
                )
            ),
            'can_replace': can_replace,
        },
        status=status.HTTP_409_CONFLICT,  # 409 = Conflict
    )

# Si llegamos aquí, o no existe duplicado O is_replacement=true
# Continuar con la lógica existente de reemplazo (línea 111+)
```

#### PASO 2.2: Actualizar Manejo de HTTP 409 en Lumara

**Archivo**: `lib/data/datasources/paperless_api_client.dart`

**Ubicación**: En el catch de `uploadDocumentWithPerson`, línea ~404

**Modificar el código existente**:

```dart
} else if (e.response?.statusCode == 409) {
  _logger.w('⚠️ HTTP 409: Documento duplicado detectado por backend');
  _logger.w('Response data: ${e.response?.data}');

  // NO lanzar excepción, devolver respuesta para que UI la maneje
  return e.response?.data as Map<String, dynamic>;
}
```

#### PASO 2.3: Manejar Respuesta de Duplicado en UI

**Archivo**: `lib/services/upload_service.dart`

**Ubicación**: Después de recibir respuesta de repository

```dart
final result = await _documentRepository.uploadDocumentForPerson(...);

// Verificar si el backend rechazó por duplicado
if (result['success'] == false && result['error_code'] == 'DUPLICATE_DOCUMENT') {
  _logger.w('⚠️ Backend rechazó upload: Documento duplicado');
  _logger.w('   Existing doc ID: ${result['existing_document']?['id']}');
  _logger.w('   Can replace: ${result['can_replace']}');

  // Marcar upload como failed con información de duplicado
  await _database.updateUploadStatus(
    upload.id,
    UploadStatus.failed,
    errorMessage: result['error'] as String? ?? 'Documento duplicado',
  );

  // Lanzar excepción específica que UI puede manejar
  throw DuplicateDocumentException(
    message: result['error'] as String,
    existingDocumentId: result['existing_document']?['id'],
    canReplace: result['can_replace'] as bool? ?? false,
    suggestion: result['suggestion'] as String?,
  );
}
```

**Crear nueva excepción**:

**Archivo**: `lib/core/exceptions/exceptions.dart`

```dart
class DuplicateDocumentException implements Exception {
  final String message;
  final int? existingDocumentId;
  final bool canReplace;
  final String? suggestion;

  DuplicateDocumentException({
    required this.message,
    this.existingDocumentId,
    this.canReplace = false,
    this.suggestion,
  });

  @override
  String toString() => message;
}
```

#### PASO 2.4: Mostrar Diálogo al Usuario

**Archivo**: Donde se maneja el resultado del upload (probablemente DocumentCaptureScreen)

```dart
try {
  await uploadService.uploadDocument(...);
  // Éxito
} on DuplicateDocumentException catch (e) {
  // Mostrar diálogo informativo
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Documento Ya Existe'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.message),
          if (e.suggestion != null) ...[
            SizedBox(height: 16),
            Text(
              e.suggestion!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Ver Documento Existente'),
        ),
        if (e.canReplace)
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar flujo de reemplazo
              Navigator.pop(context);
            },
            child: Text('Reemplazar'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
      ],
    ),
  );
} catch (e) {
  // Otros errores
}
```

### Entregables del Paso 2

- [ ] views_census.py modificado con validación
- [ ] paperless_api_client.dart actualizado para HTTP 409
- [ ] Nueva excepción DuplicateDocumentException
- [ ] Diálogo de usuario para manejar duplicados

### Cómo Probar

**Test Manual**:

```bash
# 1. Subir documento para persona 3998
curl -X POST "http://localhost:8001/api/documents/upload_with_person/" \
  -H "Authorization: Token TOKEN" \
  -F "document=@test.pdf" \
  -F "person_id=3998" \
  -F "document_type=Cédula de Ciudadanía" \
  -F "nuip=1021315923" \
  -F "is_replacement=false"

# Resultado esperado: HTTP 201, documento creado

# 2. Intentar subir OTRO documento del mismo tipo
curl -X POST "http://localhost:8001/api/documents/upload_with_person/" \
  -H "Authorization: Token TOKEN" \
  -F "document=@test2.pdf" \
  -F "person_id=3998" \
  -F "document_type=Cédula de Ciudadanía" \  # MISMO TIPO
  -F "nuip=1021315923" \
  -F "is_replacement=false"  # NO reemplazo

# Resultado esperado: HTTP 409, rechazado con mensaje claro

# 3. Intentar con is_replacement=true
curl -X POST "http://localhost:8001/api/documents/upload_with_person/" \
  -H "Authorization: Token TOKEN" \
  -F "document=@test3.pdf" \
  -F "person_id=3998" \
  -F "document_type=Cédula de Ciudadanía" \
  -F "nuip=1021315923" \
  -F "is_replacement=true"  # CON reemplazo

# Resultado esperado: HTTP 201, documento reemplazado
```

---

## 📊 CRONOGRAMA DE EJECUCIÓN

### Día 1 (Hoy)

**09:00 - 11:00**: TAREA 2 (Backend Anti-duplicados)
- Implementar validación en views_census.py
- Actualizar manejo HTTP 409 en Lumara
- Crear excepción DuplicateDocumentException
- Tests manuales con curl

**11:00 - 14:00**: TAREA 1 Parte 1 (Logging Lumara)
- Agregar logging en DocumentCaptureScreen
- Agregar logging en upload_service.dart
- Agregar logging en document_repository.dart
- Agregar logging en paperless_api_client.dart

**14:00 - 15:00**: Compilar APK con Logging

**15:00 - 17:00**: TAREA 1 Parte 2 (Testing y Diagnóstico)
- Instalar APK en dispositivo
- Ejecutar pruebas end-to-end
- Revisar logs con watch_logs.sh
- Identificar problema exacto

**17:00 - 18:00**: Análisis de Resultados
- Documentar hallazgos
- Determinar fix necesario
- Planear implementación de fix

### Día 2 (Mañana)

**09:00 - 11:00**: Implementar Fix Identificado
- Basado en logs de día 1
- Corrección del problema de asociación

**11:00 - 12:00**: Compilar APK Final

**12:00 - 14:00**: Testing E2E Completo
- Verificar asociaciones se crean
- Verificar anti-duplicados funciona
- Verificar flujo completo

**14:00 - 15:00**: Documentación Final
- Actualizar WORKFLOW_3_RESULTADOS.md
- Crear guía de usuario
- Commit final

---

## ✅ CRITERIOS DE ÉXITO

### Para TAREA 1 (Investigación Lumara)

- [ ] Logs detallados en cada paso del flujo
- [ ] Problema exacto identificado
- [ ] Punto de falla localizado (línea específica)
- [ ] Causa raíz documentada

### Para TAREA 2 (Anti-duplicados)

- [ ] Backend rechaza duplicados con HTTP 409
- [ ] Mensaje claro al usuario
- [ ] Permite reemplazo cuando is_replacement=true
- [ ] No se pueden crear 2 docs del mismo tipo

### Para Solución Completa

- [ ] Upload desde Lumara crea relación documento-persona
- [ ] Relaciones visibles en base de datos
- [ ] API devuelve relation_id en respuesta
- [ ] No se permiten duplicados
- [ ] Usuario ve mensajes claros en caso de error

---

## 🔧 HERRAMIENTAS NECESARIAS

- [ ] Android Studio o VS Code con Flutter
- [ ] Dispositivo Android conectado o emulador
- [ ] Terminal para watch_logs.sh
- [ ] Acceso a servidor Paperless
- [ ] curl para tests de API
- [ ] jq para parsear JSON

---

## 📞 CONTACTO Y SOPORTE

Si encuentras problemas durante la implementación:

1. Revisar logs detallados en cada capa
2. Verificar que todos los parámetros se pasan correctamente
3. Confirmar que backend está accesible
4. Validar que person_id no es null en ningún punto

---

**Próximo Paso**: ¿Proceder con la implementación?

**Opción A**: Implementar TODO el plan (Tarea 1 + Tarea 2)
**Opción B**: Solo Tarea 2 primero (más rápido, backend seguro)
**Opción C**: Solo Tarea 1 primero (diagnosticar antes de arreglar)

**Recomendación**: Opción B (Tarea 2) primero porque:
- Es independiente
- Se puede probar inmediatamente
- Resuelve problema confirmado
- Toma solo 1 hora

Luego Opción C (Tarea 1) para:
- Entender por qué Lumara falla
- Implementar fix específico
- Recompilar APK final
