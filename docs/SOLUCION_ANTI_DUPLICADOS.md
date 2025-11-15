# 🛡️ Solución: Sistema Anti-Duplicados

**Fecha**: 27 de octubre de 2025
**Problema**: El sistema permite subir múltiples documentos del mismo tipo para la misma persona
**Ejemplo**: Persona 3998 tiene 2 documentos de "Cédula de Ciudadanía" (IDs 38 y 43)

---

## 🎯 Estrategia: Defensa en Dos Capas

### Capa 1: Frontend (Lumara) - Prevención Proactiva
**Objetivo**: Evitar capturas innecesarias

### Capa 2: Backend (Paperless) - Validación Obligatoria
**Objetivo**: Rechazar duplicados como última línea de defensa

---

## 📱 CAPA 1: Validación en Lumara (Frontend)

### Endpoint Existente

El backend ya tiene un endpoint para verificar ANTES de capturar:

```http
GET /api/documents/check_exists/?person_id={id}&document_type={type}
```

**Respuesta**:
```json
{
  "exists": true,
  "person": {
    "id": 3998,
    "full_name": "MARTIN HERRERA OCAMPO",
    "document_number": "1021315923"
  },
  "existing_document": {
    "id": 38,
    "title": "Cédula de Ciudadanía - MARTIN HERRERA OCAMPO",
    "created": "2025-10-27T22:51:26Z",
    "ocr_confidence": 0.95
  },
  "ocr_confidence": 0.95,
  "has_minimum_data": true,
  "can_replace": false,
  "message": "Documento ya existe con buena calidad (95%). No es necesario reemplazar."
}
```

### Implementación en Lumara

**Ubicación**: `lib/services/upload_service.dart`

**ANTES de capturar** (en DocumentCaptureScreen):

```dart
// En DocumentCaptureScreen
Future<void> _checkExistingDocument() async {
  if (widget.selectedPerson == null || widget.selectedDocumentType == null) {
    return;
  }

  try {
    final response = await _apiClient.checkDocumentExists(
      personId: widget.selectedPerson!.personId,
      documentType: widget.selectedDocumentType!,
    );

    if (response['exists'] == true) {
      final canReplace = response['can_replace'] ?? false;
      final confidence = (response['ocr_confidence'] ?? 0.0) * 100;

      if (!canReplace) {
        // Documento ya existe con buena calidad
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('⚠️ Documento Ya Existe'),
            content: Text(
              'Esta persona ya tiene un documento de tipo '
              '${widget.selectedDocumentType} con calidad del ${confidence.toInt()}%.\n\n'
              'No es necesario capturar otro documento.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Ver Documento Existente'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Regresar a lista
                },
                child: Text('Regresar'),
              ),
            ],
          ),
        );
        return;
      } else {
        // Documento existe pero con baja calidad, ofrecer reemplazo
        final shouldReplace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('🔄 Reemplazar Documento'),
            content: Text(
              'Ya existe un documento de tipo ${widget.selectedDocumentType} '
              'pero con calidad baja (${confidence.toInt()}%).\n\n'
              '¿Deseas capturar uno nuevo para reemplazarlo?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sí, Reemplazar'),
              ),
            ],
          ),
        );

        if (shouldReplace == true) {
          _isReplacement = true;
          // Continuar con captura
        } else {
          Navigator.pop(context); // Regresar
          return;
        }
      }
    }
  } catch (e) {
    _logger.w('Error verificando documento existente: $e');
    // Continuar con captura normalmente (no bloquear por error de red)
  }
}

@override
void initState() {
  super.initState();
  // Verificar ANTES de mostrar cámara
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkExistingDocument();
  });
}
```

**Modificar `paperless_api_client.dart`**:

```dart
Future<Map<String, dynamic>> checkDocumentExists({
  required String personId,
  required String documentType,
}) async {
  try {
    final response = await _dio.get(
      '/api/documents/check_exists/',
      queryParameters: {
        'person_id': personId,
        'document_type': documentType,
      },
    );
    return response.data;
  } on DioException catch (e) {
    _logger.e('Error checking document: ${e.message}');
    rethrow;
  }
}
```

### Flujo de Usuario Mejorado

```
1. Usuario selecciona persona → "MARTIN HERRERA"
2. Usuario selecciona tipo documento → "Cédula de Ciudadanía"
3. Usuario toca botón "Capturar"
   ↓
4. [NUEVO] App llama check_exists ANTES de abrir cámara
   ↓
5a. SI NO EXISTE → Abrir cámara normalmente
5b. SI EXISTE (buena calidad) → Mostrar diálogo:
    "⚠️ Ya existe documento con calidad 95%. No es necesario capturar otro."
    [Ver Documento] [Regresar]
5c. SI EXISTE (baja calidad) → Mostrar diálogo:
    "🔄 Existe documento con calidad 45%. ¿Reemplazar?"
    [Cancelar] [Sí, Reemplazar]
```

**Beneficios**:
- ✅ Evita capturas innecesarias
- ✅ Ahorra tiempo del operador
- ✅ Reduce tráfico de red
- ✅ Mejora UX con feedback inmediato

---

## 🖥️ CAPA 2: Validación en Backend (Obligatoria)

### Problema Actual

En `views_census.py`, línea 110-152:
- La validación de duplicados SOLO ocurre si `is_replacement=true`
- Si `is_replacement=false` (default), NO hay validación
- Resultado: Se permiten duplicados

### Solución

Agregar validación OBLIGATORIA después de verificar que la persona existe.

**Ubicación**: `/paperless-ngx/src/documents/views_census.py` después de línea 110

```python
# Después de verificar que la persona existe (línea 110)

# ═══════════════════════════════════════════════════════════
# VALIDACIÓN DE DUPLICADOS
# ═══════════════════════════════════════════════════════════

# Verificar si ya existe un documento del mismo tipo para esta persona
existing_relation = DocumentPersonRelation.objects.filter(
    person=person,
    document_type=document_type,
).first()

if existing_relation and not is_replacement:
    # Ya existe documento Y el usuario NO indicó reemplazo
    existing_doc = existing_relation.document
    ocr_confidence = existing_relation.ocr_confidence or 0.0

    logger.warning(
        f"DUPLICADO DETECTADO: {person.get_full_name()} ya tiene "
        f"documento de tipo '{document_type}' (Doc ID: {existing_doc.id}, "
        f"Calidad OCR: {ocr_confidence*100:.0f}%). "
        f"Upload rechazado porque is_replacement=false"
    )

    return Response(
        {
            'success': False,
            'error': f'Ya existe un documento de tipo "{document_type}" para {person.get_full_name()}.',
            'error_code': 'DUPLICATE_DOCUMENT',
            'existing_document': {
                'id': existing_doc.id,
                'title': existing_doc.title,
                'created': existing_doc.created.isoformat(),
                'ocr_confidence': ocr_confidence,
            },
            'suggestion': (
                'Si deseas reemplazar el documento existente por uno de mejor calidad, '
                'envía is_replacement=true en tu request.'
                if ocr_confidence < 0.8
                else 'El documento existente tiene buena calidad. No es necesario reemplazarlo.'
            ),
            'can_replace': ocr_confidence < 0.8 or not existing_relation.has_minimum_data,
        },
        status=status.HTTP_409_CONFLICT,  # 409 = Conflict
    )

# Si llegamos aquí, o no existe duplicado O es_replacement=true
# Continuar con lógica existente...

if is_replacement:
    # La lógica de reemplazo EXISTENTE continúa aquí (línea 116-152)
    ...
```

### Código Modificado Completo

```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_document_with_person(request):
    """
    Endpoint para subir documento desde app móvil con datos de persona.

    PREVENCIÓN DE DUPLICADOS:
    - Si ya existe documento del mismo tipo para la persona
    - Y is_replacement=false
    - → Rechazar con HTTP 409 CONFLICT

    Para reemplazar, enviar is_replacement=true
    """

    # ... validaciones de campos requeridos (líneas 76-98)

    # Verificar que la persona existe
    try:
        person = CensusPerson.objects.get(id=person_id)
    except CensusPerson.DoesNotExist:
        return Response(
            {'error': f'Persona con ID {person_id} no encontrada en censo'},
            status=status.HTTP_404_NOT_FOUND,
        )

    # ═══════════════════════════════════════════════════════════
    # NUEVO: VALIDACIÓN DE DUPLICADOS
    # ═══════════════════════════════════════════════════════════

    existing_relation = DocumentPersonRelation.objects.filter(
        person=person,
        document_type=document_type,
    ).select_related('document').first()

    if existing_relation and not is_replacement:
        existing_doc = existing_relation.document
        ocr_confidence = existing_relation.ocr_confidence or 0.0

        logger.warning(
            f"DUPLICADO DETECTADO: {person.get_full_name()} ya tiene "
            f"'{document_type}' (Doc {existing_doc.id}, "
            f"Calidad: {ocr_confidence*100:.0f}%). Rechazado."
        )

        return Response(
            {
                'success': False,
                'error': f'Ya existe un documento de tipo "{document_type}" para {person.get_full_name()}.',
                'error_code': 'DUPLICATE_DOCUMENT',
                'existing_document': {
                    'id': existing_doc.id,
                    'title': existing_doc.title,
                    'created': existing_doc.created.isoformat(),
                    'ocr_confidence': ocr_confidence,
                },
                'suggestion': (
                    'Para reemplazar el documento existente, envía is_replacement=true.'
                    if ocr_confidence < 0.8
                    else 'El documento existente tiene buena calidad.'
                ),
                'can_replace': ocr_confidence < 0.8,
            },
            status=status.HTTP_409_CONFLICT,
        )

    # ═══════════════════════════════════════════════════════════
    # MANEJO DE REEMPLAZOS (código existente continúa)
    # ═══════════════════════════════════════════════════════════

    old_document_id = None
    if is_replacement:
        # Lógica existente de reemplazo (líneas 116-152)
        ...

    # Resto del código continúa igual...
```

### Respuesta del Endpoint

**Caso 1: Upload normal, no existe duplicado**
```json
{
  "success": true,
  "document_id": 38,
  "person_id": 3998,
  "person_name": "MARTIN HERRERA OCAMPO",
  "relation_id": 7,
  "is_replacement": false,
  "message": "Documento subido y asociado exitosamente."
}
```

**Caso 2: Duplicado detectado (NUEVO)**
```json
{
  "success": false,
  "error": "Ya existe un documento de tipo \"Cédula de Ciudadanía\" para MARTIN HERRERA OCAMPO.",
  "error_code": "DUPLICATE_DOCUMENT",
  "existing_document": {
    "id": 38,
    "title": "Cédula de Ciudadanía - MARTIN HERRERA OCAMPO",
    "created": "2025-10-27T22:51:26.156845Z",
    "ocr_confidence": 0.95
  },
  "suggestion": "El documento existente tiene buena calidad.",
  "can_replace": false
}
```
**HTTP Status**: 409 Conflict

**Caso 3: Reemplazo exitoso**
```json
{
  "success": true,
  "document_id": 43,
  "person_id": 3998,
  "person_name": "MARTIN HERRERA OCAMPO",
  "relation_id": 12,
  "is_replacement": true,
  "replaced_document_id": 38,
  "message": "Documento reemplazado exitosamente (anterior: 38)."
}
```

---

## 🧪 Tests Automatizados

### Test 1: Prevenir Duplicado

```python
def test_upload_duplicate_document_rejected(self):
    """Verificar que se rechaza duplicado cuando is_replacement=false"""

    # Upload inicial
    response1 = self.client.post('/api/documents/upload_with_person/', {
        'document': SimpleUploadedFile('test.pdf', b'PDF content'),
        'person_id': 3998,
        'document_type': 'Cédula de Ciudadanía',
        'nuip': '1021315923',
        'is_replacement': 'false',
    })
    self.assertEqual(response1.status_code, 201)

    # Intentar duplicado
    response2 = self.client.post('/api/documents/upload_with_person/', {
        'document': SimpleUploadedFile('test2.pdf', b'PDF content 2'),
        'person_id': 3998,
        'document_type': 'Cédula de Ciudadanía',  # MISMO TIPO
        'nuip': '1021315923',
        'is_replacement': 'false',  # NO reemplazo
    })

    # Debe rechazar con 409 Conflict
    self.assertEqual(response2.status_code, 409)
    self.assertEqual(response2.json()['error_code'], 'DUPLICATE_DOCUMENT')
    self.assertIn('Ya existe un documento', response2.json()['error'])
```

### Test 2: Permitir Reemplazo

```python
def test_upload_replacement_allowed(self):
    """Verificar que se permite reemplazo cuando is_replacement=true"""

    # Upload inicial
    response1 = self.client.post('/api/documents/upload_with_person/', {
        'document': SimpleUploadedFile('test.pdf', b'PDF content'),
        'person_id': 3998,
        'document_type': 'Cédula de Ciudadanía',
        'nuip': '1021315923',
        'is_replacement': 'false',
    })
    doc_id_1 = response1.json()['document_id']

    # Reemplazo con is_replacement=true
    response2 = self.client.post('/api/documents/upload_with_person/', {
        'document': SimpleUploadedFile('test2.pdf', b'Better PDF'),
        'person_id': 3998,
        'document_type': 'Cédula de Ciudadanía',  # MISMO TIPO
        'nuip': '1021315923',
        'is_replacement': 'true',  # SÍ reemplazo
    })

    # Debe permitir
    self.assertEqual(response2.status_code, 201)
    self.assertTrue(response2.json()['success'])
    self.assertEqual(response2.json()['is_replacement'], True)
    self.assertEqual(response2.json()['replaced_document_id'], doc_id_1)

    # Verificar que el documento viejo fue eliminado
    self.assertFalse(Document.objects.filter(id=doc_id_1).exists())
```

### Test 3: Permitir Diferentes Tipos

```python
def test_upload_different_types_allowed(self):
    """Verificar que se permiten diferentes tipos de documento para misma persona"""

    # Cédula
    response1 = self.client.post('/api/documents/upload_with_person/', {
        'document': SimpleUploadedFile('cedula.pdf', b'Cedula'),
        'person_id': 3998,
        'document_type': 'Cédula de Ciudadanía',
        'nuip': '1021315923',
    })
    self.assertEqual(response1.status_code, 201)

    # Tarjeta (diferente tipo)
    response2 = self.client.post('/api/documents/upload_with_person/', {
        'document': SimpleUploadedFile('tarjeta.pdf', b'Tarjeta'),
        'person_id': 3998,
        'document_type': 'Tarjeta de Identidad',  # TIPO DIFERENTE
        'nuip': '1021315923',
    })

    # Debe permitir
    self.assertEqual(response2.status_code, 201)

    # Verificar que existen ambas relaciones
    relations = DocumentPersonRelation.objects.filter(person_id=3998)
    self.assertEqual(relations.count(), 2)
    doc_types = set(rel.document_type for rel in relations)
    self.assertEqual(doc_types, {'Cédula de Ciudadanía', 'Tarjeta de Identidad'})
```

---

## 📊 Comparación: Antes vs Después

### ANTES (Comportamiento Actual)

```
Usuario sube Cédula para persona 3998
→ ✅ Creado (Doc 38)

Usuario sube OTRA Cédula para persona 3998
→ ✅ Creado (Doc 43)  ← PROBLEMA: Duplicado permitido

Resultado: Persona tiene 2 cédulas
```

### DESPUÉS (Con Validación)

```
Usuario sube Cédula para persona 3998
→ ✅ Creado (Doc 38)

Usuario sube OTRA Cédula con is_replacement=false
→ ❌ Rechazado (HTTP 409)
→ Error: "Ya existe documento..."
→ Sugerencia: "Envía is_replacement=true si quieres reemplazar"

Usuario sube OTRA Cédula con is_replacement=true
→ ✅ Doc 38 eliminado
→ ✅ Doc 43 creado como reemplazo

Resultado: Persona tiene 1 cédula (la más reciente)
```

---

## 🚀 Plan de Implementación

### Fase 1: Backend (CRÍTICO)
- [ ] Agregar validación de duplicados en `upload_document_with_person`
- [ ] Retornar HTTP 409 con mensaje claro
- [ ] Crear tests automatizados
- [ ] Desplegar en servidor

**Tiempo estimado**: 1-2 horas
**Prioridad**: 🔴 CRÍTICA

### Fase 2: Frontend (ALTA)
- [ ] Implementar `checkDocumentExists()` en `paperless_api_client.dart`
- [ ] Modificar `DocumentCaptureScreen` para verificar antes de capturar
- [ ] Agregar diálogos de confirmación
- [ ] Manejar respuesta HTTP 409 en caso de error

**Tiempo estimado**: 2-3 horas
**Prioridad**: 🟡 ALTA

### Fase 3: Testing E2E (MEDIA)
- [ ] Test: Intentar duplicado desde Lumara → debe mostrar advertencia
- [ ] Test: Intentar reemplazo → debe funcionar
- [ ] Test: Capturar diferentes tipos → debe permitir
- [ ] Documentar comportamiento en manual de usuario

**Tiempo estimado**: 1 hora
**Prioridad**: 🟢 MEDIA

---

## 📝 Documentación de API

### Endpoint: Check Document Exists

```http
GET /api/documents/check_exists/
```

**Query Parameters**:
- `person_id` (required): ID de la persona
- `document_type` (required): Tipo de documento

**Respuesta Exitosa** (200 OK):
```json
{
  "exists": true,
  "person": {
    "id": 3998,
    "full_name": "MARTIN HERRERA OCAMPO",
    "document_number": "1021315923"
  },
  "existing_document": {
    "id": 38,
    "title": "Cédula de Ciudadanía - MARTIN HERRERA OCAMPO",
    "created": "2025-10-27T22:51:26Z",
    "ocr_confidence": 0.95
  },
  "ocr_confidence": 0.95,
  "has_minimum_data": true,
  "can_replace": false
}
```

### Endpoint: Upload with Duplicate Prevention

```http
POST /api/documents/upload_with_person/
```

**Form Data**:
- `document` (file, required): Archivo PDF/imagen
- `person_id` (string, required): ID de la persona
- `document_type` (string, required): Tipo de documento
- `nuip` (string, required): Número de identificación
- `is_replacement` (string, optional): "true" o "false" (default: "false")

**Respuesta Duplicado Detectado** (409 Conflict):
```json
{
  "success": false,
  "error": "Ya existe un documento de tipo \"Cédula de Ciudadanía\"...",
  "error_code": "DUPLICATE_DOCUMENT",
  "existing_document": {...},
  "suggestion": "Para reemplazar...",
  "can_replace": false
}
```

---

## 🎯 Conclusión

Esta solución de dos capas proporciona:

1. **UX Mejorada**: Usuario sabe ANTES de capturar si el documento existe
2. **Seguridad**: Backend valida SIEMPRE, aunque Lumara falle
3. **Flexibilidad**: Permite reemplazos cuando la calidad es baja
4. **Claridad**: Mensajes de error descriptivos guían al usuario

**Resultado esperado**: 0 duplicados accidentales, mejor eficiencia operativa

---

**Próximo paso**: ¿Implementamos primero el backend (Fase 1) o prefieres revisar la solución completa?
