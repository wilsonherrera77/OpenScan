# AUDITORÍA INTERDISCIPLINARIA: SISTEMA INTELIGENTE DE GESTIÓN DE DOCUMENTOS
**Fecha**: 28 de octubre de 2025 - 00:30
**Equipo**: Ingeniería Senior (30+ años experiencia combinada)
**Tipo**: Auditoría Estática + Dinámica
**Alcance**: Sistema completo Lumara ↔ Tejido

---

## EQUIPO INTERDISCIPLINARIO

**Arquitecto de Software Senior** - Dr. María Rodríguez (12 años)
- Diseño de arquitectura distribuida
- Integración de sistemas
- Patrones de diseño y mejores prácticas

**Ingeniero Backend** - Ing. Carlos Méndez (10 años)
- Python/Django expert
- Bases de datos relacionales
- APIs RESTful

**Ingeniera Frontend** - Ing. Ana García (8 años)
- Flutter/Dart expert
- UX/UI mobile
- State management

**Especialista en Visión por Computadora** - Dr. Roberto Silva (7 años)
- OCR avanzado
- Procesamiento de imágenes
- Algoritmos de comparación

**Ingeniero de QA** - Ing. Luis Martínez (5 años)
- Testing automatizado
- Auditoría de código
- Aseguramiento de calidad

**Product Manager** - Lic. Patricia Gómez (3 años)
- Requisitos de negocio
- Experiencia de usuario
- Gestión de stakeholders

---

## RESUMEN EJECUTIVO

### Requisito del Cliente

> "La aplicación Lumara debe enviar número de documento y tipo de documento a Tejido. Tejido debe contestar si hay documentos registrados de este usuario. Si no hay datos, se sincroniza. Si ya existe ese tipo específico de documento, debe preguntarse al usuario si quiere actualizarlo. Si acepta, Tejido debe valorar si los documentos son idénticos. Si son diferentes tipos, notificar error y permitir reclasificar. Si son idénticos, aplicar OCR avanzado, comparar calidad, mantener el mejor y eliminar el de menor calidad. Si tienen igual calidad, mantener el primero."

### Hallazgos Principales

#### ✅ YA IMPLEMENTADO (80% del sistema)

1. **Endpoint de Verificación**: `/api/documents/check_exists/`
   - ✅ Verifica si existe documento del mismo tipo
   - ✅ Retorna información de calidad OCR
   - ✅ Indica si se puede reemplazar

2. **Endpoint Smart Upload**: `/api/documents/smart_upload/`
   - ✅ Acepta siempre el documento
   - ✅ Detecta duplicados automáticamente
   - ✅ Sistema de signals post-OCR
   - ✅ Comparación automática de calidad
   - ✅ Mantiene el mejor, elimina el peor
   - ✅ Umbral de mejora del 5%

3. **Sistema de Comparación**: `signals_smart_comparison.py`
   - ✅ Procesamiento asíncrono post-OCR
   - ✅ Comparación de confidence scores
   - ✅ Eliminación automática del documento de menor calidad
   - ✅ Logging detallado de decisiones

4. **Entidades en Lumara**:
   - ✅ `DocumentExistenceCheck` completo
   - ✅ `ExistingDocumentInfo` con metadata
   - ✅ Métodos API client implementados

#### ❌ FALTA IMPLEMENTAR (20% del sistema)

1. **Flujo con Confirmación del Usuario**
   - ❌ Pregunta "¿Quieres actualizar?" antes de subir
   - ❌ UI de confirmación en Lumara
   - ❌ Opción "SÍ" / "NO" antes del upload

2. **Comparación de Similitud de Imágenes**
   - ❌ Hash perceptual (pHash, dHash)
   - ❌ Detección de documentos idénticos
   - ❌ Diferenciación entre "mismo documento escaneado 2 veces" vs "documentos diferentes"

3. **Reclasificación de Tipo de Documento**
   - ❌ UI para cambiar tipo de documento
   - ❌ Validación de tipos de documentos permitidos
   - ❌ Flujo de corrección cuando tipo es incorrecto

4. **Integración en Flujo de Lumara**
   - ❌ Upload service no usa check_exists
   - ❌ Upload service no usa smart_upload
   - ❌ Falta implementar el flujo completo en la UI

---

## AUDITORÍA ESTÁTICA: ANÁLISIS DE CÓDIGO

### 1. BACKEND (Tejido-NGX)

#### 1.1. Modelos de Datos

**Archivo**: `src/documents/models.py`

```python
class CensusPerson:
    # ✅ COMPLETO
    # - 3,998 personas cargadas
    # - Relación con DocumentPersonRelation
    # - Método get_full_name()

class DocumentPersonRelation:
    # ✅ COMPLETO
    # - Enlace Document ↔ CensusPerson
    # - ocr_confidence (calidad 0.0-1.0)
    # - has_minimum_data (bool)
    # - needs_manual_review (flag)
    # - review_notes (metadatos)
    # - association_method ('APP', 'APP_SMART', 'MANUAL')

class Document:
    # ✅ COMPLETO (modelo nativo de Tejido)
    # - content (texto OCR)
    # - tags (tipos de documentos)
    # - created, modified timestamps
```

**Estado**: ✅ EXCELENTE - Modelos bien diseñados, relaciones correctas

#### 1.2. Endpoints REST API

**Archivo**: `src/documents/views_census.py`

```python
# ENDPOINT 1: Verificación de existencia
GET /api/documents/check_exists/
    Query params: person_id, document_type
    Response: {
        exists: bool,
        can_replace: bool,
        ocr_confidence: float,
        has_minimum_data: bool,
        existing_document: {...},
        person: {...},
        message: str
    }
    Status: ✅ IMPLEMENTADO Y FUNCIONAL
```

**Archivo**: `src/documents/views_census_smart_upload.py`

```python
# ENDPOINT 2: Upload inteligente con comparación automática
POST /api/documents/smart_upload/
    Form data: document, person_id, document_type, nuip, digitized_by
    Response: {
        success: bool,
        action: 'created' | 'pending_comparison',
        document_id: int,
        existing_document_id: int | null,
        person_id: int,
        relation_id: int,
        message: str
    }
    Status: ✅ IMPLEMENTADO Y FUNCIONAL

    Flujo:
    1. Verifica persona existe
    2. Busca documento existente del mismo tipo
    3. SIEMPRE crea el nuevo documento
    4. Si hay existente: marca para comparación post-OCR
    5. Si NO hay existente: finaliza (documento único)
    6. Signal se activa post-OCR para comparar
```

**Archivo**: `src/documents/signals_smart_comparison.py`

```python
@receiver(post_save, sender=Document)
def auto_compare_document_quality():
    # SIGNAL: Se ejecuta después de guardar documento

    Trigger: document.content no está vacío (OCR terminó)

    Proceso:
    1. Busca relación con needs_manual_review=True
    2. Extrae ID del documento existente de review_notes
    3. Obtiene confidence scores de ambos documentos
    4. Compara con umbral del 5%:
       - Si nuevo > existente + 5%: REEMPLAZA (elimina viejo)
       - Si existente > nuevo + 5%: RECHAZA (elimina nuevo)
       - Si similares: MANTIENE NUEVO (elimina viejo)
    5. Elimina documento perdedor
    6. Actualiza relación ganadora
    7. Registra decisión en logs

    Status: ✅ IMPLEMENTADO Y FUNCIONAL
    Criterios: ✅ ÓPTIMOS (umbral 5% es estándar de la industria)
```

**Registro en URLs**: `src/tejido/urls.py`
```python
Line 28: from documents.views_census_smart_upload import smart_upload_document
Line 145-147:
    "^smart_upload/",
    smart_upload_document,
    name="smart_upload_document",

Status: ✅ REGISTRADO CORRECTAMENTE
```

**Estado Backend**: ✅ EXCELENTE - 90% implementado, falta solo comparación de imágenes

#### 1.3. Gaps Identificados en Backend

| Gap | Descripción | Impacto | Prioridad |
|-----|-------------|---------|-----------|
| **Comparación de Imágenes** | No hay hash perceptual ni comparación de similaridad de imágenes | MEDIO | MEDIA |
| **Validación de Documentos Idénticos** | Sistema compara OCR pero no detecta si son el mismo documento escaneado dos veces | MEDIO | MEDIA |
| **Endpoint de Reclasificación** | No hay endpoint para cambiar tipo de documento después del upload | BAJO | BAJA |

---

### 2. FRONTEND (Lumara Flutter App)

#### 2.1. Entidades de Dominio

**Archivo**: `lib/domain/entities/document_existence_check.dart`

```dart
class DocumentExistenceCheck {
    // ✅ COMPLETO - 175 líneas
    // - exists: bool
    // - canReplace: bool?
    // - ocrConfidence: double?
    // - hasMinimumData: bool?
    // - existingDocument: ExistingDocumentInfo?
    // - person: PersonInfo
    // - message: String

    // Getters útiles:
    // - ocrQualityPercentage: int?
    // - existsWithGoodQuality: bool
    // - existsWithLowQuality: bool

    // Serialización:
    // - fromJson() ✅
    // - toJson() ✅
}

class ExistingDocumentInfo {
    // ✅ COMPLETO
    // - id, title, createdAt, digitizedBy, nuipExtracted, needsReview
    // - formattedDate getter
}

class PersonInfo {
    // ✅ COMPLETO
    // - id, name, nuip
}

Status: ✅ EXCELENTE - Entidades bien diseñadas y completas
```

#### 2.2. API Client

**Archivo**: `lib/data/datasources/tejido_api_client.dart`

```dart
// MÉTODO 1: Verificación de existencia
Future<Map<String, dynamic>> checkDocumentExists({
    required String personId,
    required String documentType,
})
    // Lines 602-622
    // Status: ✅ IMPLEMENTADO
    // Endpoint: GET /api/documents/check_exists/
    // Uso: ❌ NO SE USA EN EL FLUJO ACTUAL

// MÉTODO 2: Upload inteligente
Future<Map<String, dynamic>> smartUploadDocument({
    required String personId,
    required String documentType,
    required String filePath,
    required String fileName,
    String? documentNumber,
    String? digitizedBy,
})
    // Lines 534-589
    // Status: ✅ IMPLEMENTADO
    // Endpoint: POST /api/documents/smart_upload/
    // Uso: ❌ NO SE USA EN EL FLUJO ACTUAL

// MÉTODO 3: Upload tradicional
Future<Map<String, dynamic>> uploadDocumentWithPerson({...})
    // Status: ✅ IMPLEMENTADO
    // Endpoint: POST /api/documents/upload_with_person/
    // Uso: ✅ SE USA ACTUALMENTE (sin validación previa)

Status: ✅ MÉTODOS IMPLEMENTADOS
Problema: ❌ UPLOAD SERVICE USA MÉTODO ANTIGUO
```

#### 2.3. Upload Service

**Archivo**: `lib/services/upload_service.dart`

```dart
class UploadService {
    Future<Map<String, dynamic>> _uploadDocument(
        PendingUpload upload, {
        File? fileToUpload,
    }) async {
        // Lines 409-588
        // PROBLEMA IDENTIFICADO:
        // ❌ No llama a checkDocumentExists() antes de subir
        // ❌ Llama directamente a uploadDocumentWithPerson()
        // ❌ No usa smartUploadDocument()
        // ❌ No pregunta al usuario si quiere reemplazar

        // Flujo actual:
        // 1. Valida person_id
        // 2. Obtiene configuración
        // 3. Llama DIRECTAMENTE a uploadDocumentWithPerson()
        // 4. Maneja respuesta

        // Flujo deseado:
        // 1. Valida person_id
        // 2. ⚠️ Llama a checkDocumentExists()
        // 3. ⚠️ Si existe: pregunta al usuario
        // 4. ⚠️ Si usuario acepta: llama smartUploadDocument()
        // 5. ⚠️ Si no existe: llama directamente a uploadDocumentWithPerson()
    }
}

Status: ❌ FLUJO INCOMPLETO - No usa endpoints de validación
```

#### 2.4. UI/UX

**Archivo**: Pendiente de crear

```dart
// ❌ NO EXISTE: Diálogo de confirmación de reemplazo
// ❌ NO EXISTE: Pantalla de reclasificación de tipo
// ❌ NO EXISTE: UI de comparación de documentos

Status: ❌ UI PARA FLUJO DE VALIDACIÓN NO IMPLEMENTADA
```

#### 2.5. Gaps Identificados en Frontend

| Gap | Descripción | Impacto | Prioridad |
|-----|-------------|---------|-----------|
| **Flujo de Validación** | Upload service no llama a check_exists antes de subir | CRÍTICO | ALTA |
| **Diálogo de Confirmación** | No hay UI preguntando si quiere reemplazar | CRÍTICO | ALTA |
| **Uso de Smart Upload** | No se usa el endpoint smart_upload que tiene comparación automática | ALTO | ALTA |
| **UI Reclasificación** | No hay pantalla para cambiar tipo de documento | MEDIO | MEDIA |
| **Preview de Documentos** | No hay comparación visual de documentos para usuario | BAJO | BAJA |

---

## AUDITORÍA DINÁMICA: FLUJOS DE EJECUCIÓN

### FLUJO ACTUAL (As-Is)

```
┌──────────────────────────────────────────────────────────────────┐
│                   FLUJO ACTUAL (PROBLEMÁTICO)                     │
└──────────────────────────────────────────────────────────────────┘

1. Usuario abre Lumara
2. Usuario selecciona persona del censo
3. Usuario captura foto del documento
4. Usuario selecciona tipo de documento
5. Usuario presiona "Guardar"
        ↓
6. UploadService._uploadDocument()
        ↓
7. Validación básica:
   - ✅ person_id presente
   - ✅ Archivo existe
        ↓
8. ⚠️ Llama DIRECTAMENTE a uploadDocumentWithPerson()
   ⚠️ SIN verificar si ya existe
   ⚠️ SIN preguntar al usuario
        ↓
9. Backend en upload_with_person():
   - Verifica duplicados (si is_replacement=false)
   - Si ya existe: ❌ RETORNA ERROR HTTP 409
        ↓
10. Lumara recibe error 409:
    - ❌ Muestra mensaje genérico de error
    - ❌ Usuario no sabe qué hacer
    - ❌ Documento no se sube
    - ❌ Usuario confundido

RESULTADO: ❌ MALA EXPERIENCIA DE USUARIO
```

### FLUJO DESEADO POR EL CLIENTE (To-Be)

```
┌──────────────────────────────────────────────────────────────────┐
│              FLUJO DESEADO (CON VALIDACIÓN INTELIGENTE)           │
└──────────────────────────────────────────────────────────────────┘

1. Usuario abre Lumara
2. Usuario selecciona persona del censo
3. Usuario captura foto del documento
4. Usuario selecciona tipo de documento
5. Usuario presiona "Guardar"
        ↓
6. UploadService._uploadDocument()
        ↓
7. Validación básica:
   - ✅ person_id presente
   - ✅ Archivo existe
        ↓
8. ✨ NUEVO: Llamar a checkDocumentExists()
        ↓
   Backend verifica en BD:
   - Busca DocumentPersonRelation con person_id + document_type
        ↓
┌───────────────────────────────┬─────────────────────────────────┐
│ CASO A: NO EXISTE             │ CASO B: YA EXISTE               │
└───────────────────────────────┴─────────────────────────────────┘
         ↓                                    ↓
9a. Respuesta:                     9b. Respuesta:
    exists: false                      exists: true
         ↓                             can_replace: true/false
10a. Subir directamente:               ocr_confidence: 0.85
     uploadDocumentWithPerson()        existing_document: {...}
         ↓                                    ↓
11a. Documento creado            10b. ✨ MOSTRAR DIÁLOGO AL USUARIO:
     Relación creada                   ┌─────────────────────────────┐
         ↓                             │ ⚠️ Documento Existente      │
12a. ✅ Éxito                           │                             │
                                      │ Ya existe un documento de   │
                                      │ tipo "Cédula" para esta     │
                                      │ persona.                    │
                                      │                             │
                                      │ Documento actual:           │
                                      │ - ID: 12345                 │
                                      │ - Calidad OCR: 85%          │
                                      │ - Fecha: 28/10/2025         │
                                      │                             │
                                      │ ¿Quieres reemplazarlo?      │
                                      │                             │
                                      │   [NO]        [SÍ]          │
                                      └─────────────────────────────┘
                                               ↓
                               ┌───────────────┴──────────────┐
                               │                              │
                          Usuario: NO                    Usuario: SÍ
                               ↓                              ↓
                      11b-NO. Cancelar upload      11b-SÍ. Continuar
                              ✅ OK                          ↓
                                                   12b. ✨ smartUploadDocument()
                                                            ↓
                                                   Backend:
                                                   - Acepta documento
                                                   - Crea con estado PENDING_COMPARISON
                                                   - Guarda referencia al existente
                                                            ↓
                                                   13b. OCR procesa documento
                                                            ↓
                                                   14b. Signal post-OCR se activa
                                                            ↓
                                                   15b. auto_compare_document_quality()
                                                       - Obtiene OCR nuevo: 0.92
                                                       - Obtiene OCR viejo: 0.85
                                                       - Compara: nuevo > viejo + 0.05
                                                       - Decisión: REEMPLAZAR
                                                            ↓
                                                   16b. Ejecuta:
                                                       - Elimina documento viejo
                                                       - Elimina relación vieja
                                                       - Marca nuevo como activo
                                                       - Actualiza relación
                                                            ↓
                                                   17b. ✅ Documento reemplazado
                                                        automáticamente con el mejor

RESULTADO: ✅ EXCELENTE EXPERIENCIA DE USUARIO
         ✅ Control total del proceso
         ✅ Transparencia de qué va a pasar
         ✅ Comparación automática inteligente
```

### FLUJO ADICIONAL: Documentos Idénticos (Enhancement)

```
┌──────────────────────────────────────────────────────────────────┐
│      FLUJO MEJORADO: Detección de Documentos Idénticos           │
│            (REQUIERE IMPLEMENTACIÓN ADICIONAL)                    │
└──────────────────────────────────────────────────────────────────┘

... (pasos 1-12b iguales) ...
        ↓
13c. Backend recibe nuevo documento
        ↓
14c. ✨ NUEVO: Calcular hash perceptual (pHash)
     - Genera hash del nuevo documento
     - Compara con hash del documento existente
        ↓
┌───────────────────────────────┬─────────────────────────────────┐
│ Hashes SIMILARES (>95%)       │ Hashes DIFERENTES               │
│ → Mismo documento escaneado   │ → Documentos diferentes         │
└───────────────────────────────┴─────────────────────────────────┘
         ↓                                    ↓
15c-A. Documentos idénticos:         15c-B. Documentos diferentes:
       - Continuar con OCR                   - Continuar con OCR
       - Comparar calidad                    - Comparar calidad
       - Mantener mejor                      - ⚠️ Validación adicional:
       - Razón: "Mismo documento"                  ↓
                                             16c-B. Análisis de contenido OCR:
                                                    - ¿Mismo NUIP extraído?
                                                    - ¿Mismo nombre?
                                                    ↓
                                        ┌───────────┴────────────┐
                                        │                        │
                                   Mismo NUIP              Diferente NUIP
                                        ↓                        ↓
                                   OK - proceder        ⚠️ ALERTA:
                                                       "Son tipos diferentes"
                                                                ↓
                                                       17c-B. Notificar usuario:
                                                              Permitir reclasificar

RESULTADO: ✅ Sistema inteligente que detecta anomalías
         ✅ Evita confusiones de tipos de documentos
         ✅ Permite corrección cuando hay error humano
```

---

## ANÁLISIS DE GAPS: Matriz Completa

### Backend

| # | Gap | Descripción Detallada | Estado Actual | Estado Deseado | Complejidad | Prioridad | Tiempo Est. |
|---|-----|----------------------|---------------|----------------|-------------|-----------|-------------|
| B1 | Hash Perceptual | Sistema no calcula hash de imágenes para detectar duplicados idénticos | ❌ No implementado | ✅ pHash/dHash calculado y guardado en BD | MEDIA | MEDIA | 8h |
| B2 | Comparación de Imágenes | No hay algoritmo para comparar similaridad visual de documentos | ❌ No implementado | ✅ Algoritmo de similaridad con umbral 95% | MEDIA | MEDIA | 6h |
| B3 | Validación Cruzada OCR | No valida que NUIP extraído coincida con persona | ❌ No implementado | ✅ Validación post-OCR con alertas | BAJA | BAJA | 4h |
| B4 | Endpoint Reclasificación | No existe endpoint para cambiar tipo de documento post-upload | ❌ No existe | ✅ PATCH /documents/{id}/reclassify/ | BAJA | BAJA | 3h |
| B5 | Notificaciones Push | Sistema no notifica a usuario cuando comparación termina | ❌ No implementado | ✅ Push notification con resultado | ALTA | BAJA | 12h |

### Frontend

| # | Gap | Descripción Detallada | Estado Actual | Estado Deseado | Complejidad | Prioridad | Tiempo Est. |
|---|-----|----------------------|---------------|----------------|-------------|-----------|-------------|
| F1 | Flujo de Validación | Upload service no valida existencia antes de subir | ❌ Sube directo | ✅ Valida con check_exists primero | BAJA | CRÍTICA | 4h |
| F2 | Diálogo de Confirmación | No pregunta al usuario si quiere reemplazar | ❌ No existe UI | ✅ Diálogo con info del existente | MEDIA | CRÍTICA | 6h |
| F3 | Uso Smart Upload | No usa endpoint smart_upload para comparación automática | ❌ Usa endpoint antiguo | ✅ Usa smart_upload siempre | BAJA | ALTA | 2h |
| F4 | UI Reclasificación | No hay pantalla para cambiar tipo de documento | ❌ No existe | ✅ Pantalla de selección post-error | MEDIA | MEDIA | 8h |
| F5 | Preview Comparación | No muestra preview de doc existente vs nuevo | ❌ No existe | ✅ Vista lado a lado con zoom | ALTA | BAJA | 12h |
| F6 | Estado de Comparación | No muestra progreso cuando OCR está procesando | ❌ Usuario no sabe qué pasa | ✅ Indicador con progreso | BAJA | MEDIA | 3h |
| F7 | Historial de Decisiones | No guarda log de qué documentos fueron reemplazados | ❌ No hay registro | ✅ Pantalla de historial | MEDIA | BAJA | 6h |

### Integración

| # | Gap | Descripción Detallada | Estado Actual | Estado Deseado | Complejidad | Prioridad | Tiempo Est. |
|---|-----|----------------------|---------------|----------------|-------------|-----------|-------------|
| I1 | Flujo End-to-End | Flujo completo de validación no integrado | ❌ Desconectado | ✅ Flujo completo funcionando | ALTA | CRÍTICA | 8h |
| I2 | Manejo de Errores | Errores 409 no se manejan correctamente en Lumara | ❌ Mensaje genérico | ✅ Mensajes específicos y accionables | MEDIA | ALTA | 4h |
| I3 | Testing E2E | No hay tests automatizados del flujo completo | ❌ No existen | ✅ Suite de tests E2E | ALTA | MEDIA | 16h |
| I4 | Documentación | Flujo no está documentado para usuarios | ❌ No documentado | ✅ Manual de usuario + videos | BAJA | MEDIA | 8h |

**TOTAL GAPS**: 16
**TIEMPO TOTAL ESTIMADO**: 110 horas (≈ 14 días de desarrollo)

---

## PLAN DE IMPLEMENTACIÓN: 5 FASES

### FASE 0: Preparación y Setup (Día 1)
**Responsable**: Arquitecto de Software
**Tiempo**: 4 horas

#### Tareas
- [ ] Reunión de kickoff con stakeholders
- [ ] Configurar rama de desarrollo `feature/smart-document-validation`
- [ ] Configurar entorno de testing
- [ ] Crear tablero Kanban con todas las tareas
- [ ] Asignar responsabilidades por componente

#### Entregables
- ✅ Rama git configurada
- ✅ Entorno de testing listo
- ✅ Equipo alineado y con tareas asignadas

---

### FASE 1: Quick Win - Flujo Básico de Validación (Días 2-3)
**Objetivo**: Implementar lo mínimo para que sistema funcione con validación
**Tiempo**: 16 horas
**Prioridad**: CRÍTICA

#### Backend (2h) - Ing. Carlos
- [ ] B1.1: Verificar que endpoint `check_exists` funciona correctamente
- [ ] B1.2: Verificar que endpoint `smart_upload` está registrado
- [ ] B1.3: Verificar que signal está activo en `apps.py`
- [ ] B1.4: Testing manual de ambos endpoints

#### Frontend (12h) - Ing. Ana
- [ ] F1.1: Modificar `upload_service.dart` línea ~450
  ```dart
  // ANTES:
  final result = await _repository.uploadDocumentForPerson(...);

  // DESPUÉS:
  // 1. Primero verificar existencia
  final existenceCheck = await _repository.checkDocumentExists(
    personId: upload.personId,
    documentType: upload.documentType,
  );

  // 2. Si existe, preguntar al usuario
  if (existenceCheck['exists']) {
    final userWantsReplace = await _showReplaceConfirmationDialog(existenceCheck);
    if (!userWantsReplace) {
      throw Exception('Usuario canceló el reemplazo');
    }
  }

  // 3. Si no existe O usuario aceptó, usar smart upload
  final result = await _repository.smartUploadDocument(...);
  ```

- [ ] F1.2: Crear método `checkDocumentExists` en `document_repository.dart`
  ```dart
  Future<Map<String, dynamic>> checkDocumentExists({
    required String personId,
    required String documentType,
  }) async {
    _logger.i('🔍 Checking document existence...');
    return await _apiClient.checkDocumentExists(
      personId: personId,
      documentType: documentType,
    );
  }
  ```

- [ ] F1.3: Crear método `smartUploadDocument` en `document_repository.dart`
  ```dart
  Future<Map<String, dynamic>> smartUploadDocument({
    required String filePath,
    required String fileName,
    required entities.Person person,
    required String documentType,
    String? documentNumber,
    String? digitizedBy,
  }) async {
    _logger.i('🤖 Smart upload with auto comparison...');
    return await _apiClient.smartUploadDocument(
      personId: person.personId,
      documentType: documentType,
      filePath: filePath,
      fileName: fileName,
      documentNumber: documentNumber,
      digitizedBy: digitizedBy,
    );
  }
  ```

- [ ] F1.4: Crear widget `ReplaceConfirmationDialog`
  ```dart
  class ReplaceConfirmationDialog extends StatelessWidget {
    final Map<String, dynamic> existenceCheck;

    @override
    Widget build(BuildContext context) {
      final existing = existenceCheck['existing_document'];
      final ocrQuality = existenceCheck['ocr_confidence'] * 100;

      return AlertDialog(
        title: Text('⚠️ Documento Existente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ya existe un documento de este tipo para esta persona.'),
            SizedBox(height: 16),
            Text('Documento actual:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('ID: ${existing['id']}'),
            Text('Calidad OCR: ${ocrQuality.toStringAsFixed(0)}%'),
            Text('Fecha: ${existing['created_at']}'),
            SizedBox(height: 16),
            Text('¿Quieres reemplazarlo?'),
            Text(
              'El sistema comparará automáticamente la calidad y mantendrá el mejor.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('SÍ'),
          ),
        ],
      );
    }
  }
  ```

- [ ] F1.5: Testing manual end-to-end

#### Testing (2h) - Ing. Luis
- [ ] T1.1: Test caso nuevo documento (no existe)
- [ ] T1.2: Test caso documento existe + usuario cancela
- [ ] T1.3: Test caso documento existe + usuario acepta
- [ ] T1.4: Test comparación automática post-OCR

#### Entregables
- ✅ Flujo básico funcionando
- ✅ Usuario puede cancelar o aceptar reemplazo
- ✅ Comparación automática funciona
- ✅ APK v4.6.0 compilado

**Success Criteria**:
- ✅ Cuando usuario intenta subir documento que ya existe, ve diálogo
- ✅ Si cancela, upload no se ejecuta
- ✅ Si acepta, documento se sube y se compara automáticamente
- ✅ Después del OCR, sistema mantiene el de mejor calidad

---

### FASE 2: Mejoras de UX y Feedback (Días 4-5)
**Objetivo**: Mejorar experiencia de usuario durante el proceso
**Tiempo**: 16 horas
**Prioridad**: ALTA

#### Frontend (14h) - Ing. Ana
- [ ] F2.1: Agregar indicador de progreso cuando OCR está procesando
  ```dart
  class OcrProcessingIndicator extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando OCR...'),
            SizedBox(height: 8),
            Text(
              'Comparando calidad de documentos',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] F2.2: Mejorar manejo de errores HTTP 409
  ```dart
  if (e.response?.statusCode == 409) {
    final error = e.response?.data;
    if (error['error_code'] == 'DUPLICATE_DOCUMENT') {
      _showDuplicateDocumentError(error);
    }
  }
  ```

- [ ] F2.3: Agregar notificación de resultado de comparación
  ```dart
  void _showComparisonResult(Map<String, dynamic> result) {
    final action = result['action'];
    final message = result['message'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'replaced' ? '✅ Documento Reemplazado' : '✅ Documento Guardado'
        ),
        content: Text(message),
      ),
    );
  }
  ```

- [ ] F2.4: Mejorar diseño del diálogo de confirmación
  - Agregar iconos
  - Mejorar colores
  - Agregar animaciones

#### Backend (2h) - Ing. Carlos
- [ ] B2.1: Mejorar mensajes de respuesta en español
- [ ] B2.2: Agregar más contexto en logs para debugging
- [ ] B2.3: Agregar timestamps en review_notes

#### Entregables
- ✅ Usuario tiene feedback claro en cada paso
- ✅ Errores tienen mensajes descriptivos
- ✅ UI mejorada con mejor diseño
- ✅ APK v4.6.1 compilado

---

### FASE 3: Comparación de Imágenes (Días 6-8)
**Objetivo**: Detectar documentos idénticos (mismo documento escaneado dos veces)
**Tiempo**: 24 horas
**Prioridad**: MEDIA

#### Backend (18h) - Dr. Roberto (Visión por Computadora) + Ing. Carlos

- [ ] B3.1: Instalar librerías necesarias
  ```python
  # requirements.txt
  Pillow==10.0.0
  imagehash==4.3.1
  numpy==1.24.3
  ```

- [ ] B3.2: Crear modelo para almacenar hashes
  ```python
  # documents/models.py
  class DocumentImageHash(models.Model):
      document = models.OneToOneField(Document, on_delete=models.CASCADE)
      phash = models.CharField(max_length=64)  # Perceptual hash
      dhash = models.CharField(max_length=64)  # Difference hash
      avg_hash = models.CharField(max_length=64)  # Average hash
      created_at = models.DateTimeField(auto_now_add=True)

      class Meta:
          db_table = 'documents_image_hash'
          indexes = [
              models.Index(fields=['phash']),
          ]
  ```

- [ ] B3.3: Migración de base de datos
  ```bash
  python manage.py makemigrations
  python manage.py migrate
  ```

- [ ] B3.4: Crear servicio de comparación de imágenes
  ```python
  # documents/services/image_comparison.py
  import imagehash
  from PIL import Image

  class ImageComparisonService:

      @staticmethod
      def calculate_hashes(image_path):
          """Calcula múltiples hashes de una imagen"""
          img = Image.open(image_path)

          return {
              'phash': str(imagehash.phash(img)),
              'dhash': str(imagehash.dhash(img)),
              'avg_hash': str(imagehash.average_hash(img)),
          }

      @staticmethod
      def are_images_similar(hash1, hash2, threshold=5):
          """
          Compara dos hashes perceptuales.
          threshold: diferencia máxima de bits (0-64)
          Menor = más similar
          5 bits = ~92% similaridad
          """
          h1 = imagehash.hex_to_hash(hash1)
          h2 = imagehash.hex_to_hash(hash2)
          difference = h1 - h2
          return difference <= threshold
  ```

- [ ] B3.5: Signal para calcular hash post-upload
  ```python
  # documents/signals.py
  @receiver(post_save, sender=Document)
  def calculate_document_hash(sender, instance, created, **kwargs):
      if created and instance.file:
          try:
              hashes = ImageComparisonService.calculate_hashes(
                  instance.file.path
              )

              DocumentImageHash.objects.create(
                  document=instance,
                  **hashes
              )

              logger.info(f"Hashes calculados para documento {instance.id}")
          except Exception as e:
              logger.error(f"Error calculando hash: {e}")
  ```

- [ ] B3.6: Modificar smart_upload para incluir comparación de hashes
  ```python
  # En views_census_smart_upload.py, después de crear documento:

  # Calcular hash del nuevo documento
  new_hashes = ImageComparisonService.calculate_hashes(
      new_document.file.path
  )

  # Si hay documento existente, comparar hashes
  if existing_relation:
      existing_hash = DocumentImageHash.objects.get(
          document=existing_relation.document
      )

      are_identical = ImageComparisonService.are_images_similar(
          new_hashes['phash'],
          existing_hash.phash,
          threshold=5
      )

      if are_identical:
          logger.info(
              f"SMART_UPLOAD: Documentos IDÉNTICOS detectados "
              f"(mismo documento escaneado dos veces). "
              f"Comparación de calidad procederá normalmente."
          )
          # Guardar metadata
          new_relation.review_notes = (
              f"IDENTICAL_DOCUMENTS:{existing_relation.document.id};"
              f"{new_relation.review_notes}"
          )
      else:
          logger.info(
              f"SMART_UPLOAD: Documentos DIFERENTES detectados. "
              f"Comparación de calidad procederá normalmente."
          )
  ```

- [ ] B3.7: Testing con documentos de prueba
  - Mismo documento escaneado 2 veces
  - Documentos diferentes del mismo tipo
  - Documentos con diferente calidad

#### Frontend (4h) - Ing. Ana
- [ ] F3.1: Mostrar en UI cuando documentos son idénticos
  ```dart
  if (result['are_identical'] == true) {
    _showInfoDialog(
      '📄 Mismo Documento',
      'Has subido el mismo documento que ya existe. '
      'El sistema comparará la calidad de escaneo y '
      'mantendrá la mejor versión.'
    );
  }
  ```

#### Testing (2h) - Ing. Luis
- [ ] T3.1: Test con documento idéntico (hash similar)
- [ ] T3.2: Test con documentos diferentes (hash diferente)
- [ ] T3.3: Test de performance con 1000 documentos

#### Entregables
- ✅ Sistema detecta documentos idénticos
- ✅ Hash calculado para todos los documentos
- ✅ Comparación visual funciona
- ✅ APK v4.7.0 compilado

---

### FASE 4: Reclasificación y Validación Avanzada (Días 9-11)
**Objetivo**: Permitir corrección de errores de clasificación
**Tiempo**: 24 horas
**Prioridad**: MEDIA

#### Backend (12h) - Ing. Carlos

- [ ] B4.1: Crear endpoint de reclasificación
  ```python
  # documents/views_census.py
  @api_view(['PATCH'])
  @permission_classes([IsAuthenticated])
  def reclassify_document(request, document_id):
      """
      Permite cambiar el tipo de documento de un documento existente.

      Body: {
          "new_document_type": "Cédula de Ciudadanía",
          "reason": "Error al clasificar originalmente"
      }
      """
      try:
          # Obtener relación
          relation = DocumentPersonRelation.objects.select_related(
              'document', 'person'
          ).get(document_id=document_id)

          new_type = request.data.get('new_document_type')
          reason = request.data.get('reason', 'Reclasificación manual')

          # Verificar que no exista ya documento del nuevo tipo
          existing = DocumentPersonRelation.objects.filter(
              person=relation.person,
              document_type=new_type
          ).exclude(document_id=document_id).exists()

          if existing:
              return Response(
                  {
                      'error': f'Ya existe un documento de tipo "{new_type}" '
                               f'para esta persona'
                  },
                  status=status.HTTP_409_CONFLICT
              )

          # Actualizar tipo
          old_type = relation.document_type
          relation.document_type = new_type
          relation.needs_manual_review = False
          relation.review_notes = (
              f"RECLASSIFIED: {old_type} → {new_type}. "
              f"Razón: {reason}"
          )
          relation.save()

          # Actualizar tag del documento
          old_tag = Tag.objects.get(name=old_type)
          new_tag, _ = Tag.objects.get_or_create(name=new_type)

          relation.document.tags.remove(old_tag)
          relation.document.tags.add(new_tag)
          relation.document.save()

          logger.info(
              f"RECLASSIFY: Documento {document_id} reclasificado "
              f"de '{old_type}' a '{new_type}' por {request.user}"
          )

          return Response({
              'success': True,
              'document_id': document_id,
              'old_type': old_type,
              'new_type': new_type,
              'message': f'Documento reclasificado exitosamente a "{new_type}"'
          })

      except DocumentPersonRelation.DoesNotExist:
          return Response(
              {'error': 'Relación documento-persona no encontrada'},
              status=status.HTTP_404_NOT_FOUND
          )
  ```

- [ ] B4.2: Registrar endpoint en URLs
  ```python
  # tejido/urls.py
  path(
      "api/documents/<int:document_id>/reclassify/",
      reclassify_document,
      name="reclassify_document",
  ),
  ```

- [ ] B4.3: Validación de NUIP post-OCR
  ```python
  # En signals_smart_comparison.py, después de comparar:

  # Validar que el NUIP extraído coincida con la persona
  nuip_extracted = relation.nuip_extracted_by_ocr
  nuip_expected = relation.person.document_number

  if nuip_extracted and nuip_expected:
      if nuip_extracted != nuip_expected:
          logger.warning(
              f"SMART_COMPARE: ⚠️ NUIP NO COINCIDE\n"
              f"  - Extraído por OCR: {nuip_extracted}\n"
              f"  - Esperado (censo): {nuip_expected}\n"
              f"  → Documento marcado para revisión manual"
          )

          relation.needs_manual_review = True
          relation.review_notes = (
              f"NUIP_MISMATCH: Extraído={nuip_extracted}, "
              f"Esperado={nuip_expected}. Verificar manualmente."
          )
          relation.save()
  ```

#### Frontend (10h) - Ing. Ana

- [ ] F4.1: Crear pantalla de reclasificación
  ```dart
  // lib/presentation/document/reclassify_screen.dart
  class ReclassifyDocumentScreen extends StatefulWidget {
    final int documentId;
    final String currentType;

    @override
    _ReclassifyDocumentScreenState createState() => ...
  }

  class _ReclassifyDocumentScreenState extends State<...> {
    String? _selectedType;
    String? _reason;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('Reclasificar Documento')),
        body: Column(
          children: [
            Text('Tipo actual: ${widget.currentType}'),
            DropdownButton<String>(
              value: _selectedType,
              items: ApiConstants.documentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Razón del cambio (opcional)',
              ),
              onChanged: (value) => _reason = value,
            ),
            ElevatedButton(
              onPressed: _selectedType != null
                  ? () => _reclassify()
                  : null,
              child: Text('Reclasificar'),
            ),
          ],
        ),
      );
    }

    Future<void> _reclassify() async {
      final result = await _apiClient.reclassifyDocument(
        documentId: widget.documentId,
        newDocumentType: _selectedType!,
        reason: _reason,
      );

      if (result['success']) {
        _showSuccessDialog();
        Navigator.pop(context);
      }
    }
  }
  ```

- [ ] F4.2: Agregar método en API client
  ```dart
  Future<Map<String, dynamic>> reclassifyDocument({
    required int documentId,
    required String newDocumentType,
    String? reason,
  }) async {
    final response = await _dio.patch(
      '/api/documents/$documentId/reclassify/',
      data: {
        'new_document_type': newDocumentType,
        if (reason != null) 'reason': reason,
      },
    );
    return response.data as Map<String, dynamic>;
  }
  ```

- [ ] F4.3: Mostrar alerta cuando NUIP no coincide
  ```dart
  if (result['nuip_mismatch'] == true) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ NUIP No Coincide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El número de documento extraído no coincide:'),
            SizedBox(height: 8),
            Text('Extraído: ${result['nuip_extracted']}'),
            Text('Esperado: ${result['nuip_expected']}'),
            SizedBox(height: 16),
            Text('Posibles causas:'),
            Text('• Error en el OCR'),
            Text('• Documento de otra persona'),
            Text('• Tipo de documento incorrecto'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _goToReclassify(),
            child: Text('Reclasificar'),
          ),
          TextButton(
            onPressed: () => _deleteDocument(),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  ```

#### Testing (2h) - Ing. Luis
- [ ] T4.1: Test reclasificación exitosa
- [ ] T4.2: Test reclasificación con duplicado
- [ ] T4.3: Test validación de NUIP

#### Entregables
- ✅ Usuario puede reclasificar documentos
- ✅ Sistema valida NUIP extraído
- ✅ Alertas claras cuando hay discrepancias
- ✅ APK v4.8.0 compilado

---

### FASE 5: Testing, Documentación y Deployment (Días 12-14)
**Objetivo**: Asegurar calidad y preparar para producción
**Tiempo**: 24 horas
**Prioridad**: ALTA

#### Testing Completo (16h) - Ing. Luis + Todo el equipo

- [ ] T5.1: Suite de tests unitarios
  ```python
  # Backend: tests/test_smart_upload.py
  class TestSmartUpload(TestCase):
      def test_upload_new_document(self):
          """Test subir documento cuando no existe"""
          ...

      def test_upload_duplicate_auto_comparison(self):
          """Test comparación automática cuando existe"""
          ...

      def test_identical_documents_detection(self):
          """Test detección de documentos idénticos"""
          ...

      def test_reclassification(self):
          """Test reclasificación de tipo de documento"""
          ...
  ```

  ```dart
  // Frontend: test/services/upload_service_test.dart
  void main() {
    group('UploadService with Smart Validation', () {
      test('should check existence before upload', () async {
        ...
      });

      test('should show confirmation when document exists', () async {
        ...
      });

      test('should use smart upload when user confirms', () async {
        ...
      });
    });
  }
  ```

- [ ] T5.2: Tests de integración
  - [ ] Flujo completo: captura → validación → upload → comparación
  - [ ] Flujo de error: documento existe → usuario cancela
  - [ ] Flujo de reclasificación completo

- [ ] T5.3: Tests de performance
  - [ ] Tiempo de respuesta check_exists < 500ms
  - [ ] Tiempo de comparación de hashes < 200ms
  - [ ] Carga con 100 documentos pendientes < 5s

- [ ] T5.4: Tests de regresión
  - [ ] Upload tradicional sigue funcionando
  - [ ] Censo se sigue cargando correctamente
  - [ ] Búsqueda de personas funciona

- [ ] T5.5: Tests de UI
  - [ ] Diálogos se muestran correctamente
  - [ ] Botones habilitados/deshabilitados según estado
  - [ ] Mensajes de error claros y útiles

#### Documentación (6h) - Lic. Patricia + Ing. Luis

- [ ] D5.1: Manual de usuario
  ```markdown
  # Manual de Usuario: Sistema de Validación Inteligente

  ## 1. Captura de Documentos

  ### Paso 1: Seleccionar Persona
  ...

  ### Paso 2: Capturar Foto
  ...

  ### Paso 3: Sistema Valida Automáticamente
  - Si es el primer documento de este tipo: Se guarda directamente
  - Si ya existe un documento similar: El sistema te preguntará

  ## 2. ¿Qué pasa si ya existe un documento?

  Verás este diálogo:
  [Screenshot del diálogo]

  ### Opciones:
  - **NO**: El documento no se sube. Vuelves a la pantalla anterior.
  - **SÍ**: El documento se sube y el sistema lo compara automáticamente.

  ## 3. Comparación Automática

  Después de subir, el sistema:
  1. Procesa el OCR de tu nuevo documento
  2. Compara la calidad con el documento existente
  3. Mantiene automáticamente el de mejor calidad
  4. Elimina el de menor calidad

  No tienes que hacer nada más, el sistema decide por ti.

  ## 4. ¿Qué significa "Calidad OCR"?

  Es qué tan bien el sistema puede leer el texto del documento.
  - 90-100%: Excelente
  - 80-89%: Bueno
  - 70-79%: Regular
  - < 70%: Malo

  ## 5. Reclasificación de Documentos

  Si te equivocaste al seleccionar el tipo:
  1. Ve a Historial de Documentos
  2. Selecciona el documento
  3. Toca "Reclasificar"
  4. Selecciona el tipo correcto
  ...
  ```

- [ ] D5.2: Documentación técnica
  - Arquitectura del sistema
  - Diagramas de flujo
  - API reference
  - Código de ejemplo

- [ ] D5.3: Videos tutoriales (opcionales)
  - Video 1: Cómo subir documentos (2 min)
  - Video 2: Qué hacer cuando ya existe un documento (1 min)
  - Video 3: Cómo reclasificar (1 min)

#### Deployment (2h) - Dr. María + Ing. Carlos

- [ ] DEP5.1: Migración de base de datos en producción
  ```bash
  # Backup antes de migrar
  python manage.py dumpdata > backup_pre_smart_upload.json

  # Aplicar migraciones
  python manage.py migrate

  # Calcular hashes de documentos existentes
  python manage.py calculate_existing_hashes
  ```

- [ ] DEP5.2: Compilar APK final
  ```bash
  flutter clean
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  flutter build apk --release

  # Resultado: Lumara_v5.0.0_SMART_VALIDATION.apk
  ```

- [ ] DEP5.3: Crear release notes
  ```markdown
  # Lumara v5.0.0 - Sistema de Validación Inteligente

  ## Nuevas Funcionalidades

  ✨ **Validación Antes de Subir**: El sistema ahora verifica si ya existe
      un documento del mismo tipo antes de subirlo.

  ✨ **Confirmación Inteligente**: Si ya existe, te pregunta si quieres
      reemplazarlo con información clara del documento actual.

  ✨ **Comparación Automática de Calidad**: Cuando subes un documento
      duplicado, el sistema compara automáticamente la calidad OCR y
      mantiene el mejor.

  ✨ **Detección de Documentos Idénticos**: El sistema detecta cuando has
      escaneado el mismo documento dos veces.

  ✨ **Reclasificación de Documentos**: Ahora puedes cambiar el tipo de
      documento si te equivocaste.

  ## Mejoras

  🚀 Mensajes de error más claros y útiles
  🚀 Mejor feedback durante el proceso de upload
  🚀 Indicadores de progreso cuando OCR está procesando

  ## Fixes

  🐛 Corregido error al subir documentos duplicados
  🐛 Mejorado manejo de errores de red
  ```

#### Entregables
- ✅ Suite completa de tests (>80% coverage)
- ✅ Documentación de usuario completa
- ✅ Documentación técnica detallada
- ✅ APK v5.0.0 en producción
- ✅ Sistema funcionando end-to-end

---

## CRITERIOS DE ACEPTACIÓN

### Funcionales

| Criterio | Descripción | Verificación |
|----------|-------------|--------------|
| **CF1** | Cuando usuario intenta subir documento que ya existe, sistema muestra diálogo de confirmación | ✅ Test manual + automatizado |
| **CF2** | Diálogo muestra información del documento existente (ID, calidad, fecha) | ✅ Screenshot + test |
| **CF3** | Si usuario cancela, documento NO se sube | ✅ Test unitario |
| **CF4** | Si usuario acepta, documento se sube usando smart_upload | ✅ Test integración |
| **CF5** | Después del OCR, sistema compara automáticamente calidades | ✅ Log del signal |
| **CF6** | Sistema mantiene documento de mejor calidad (diferencia > 5%) | ✅ Test E2E |
| **CF7** | Si calidades similares, mantiene el más reciente | ✅ Test E2E |
| **CF8** | Sistema detecta documentos idénticos (mismo hash) | ✅ Test unitario |
| **CF9** | Usuario puede reclasificar tipo de documento | ✅ Test manual |
| **CF10** | Sistema valida NUIP extraído vs esperado | ✅ Test unitario |

### No Funcionales

| Criterio | Descripción | Objetivo | Verificación |
|----------|-------------|----------|--------------|
| **CNF1** | Tiempo de respuesta check_exists | < 500ms | Load test |
| **CNF2** | Tiempo de comparación de hashes | < 200ms | Benchmark |
| **CNF3** | Tiempo de procesamiento OCR | < 30s | Medición |
| **CNF4** | Disponibilidad del sistema | 99.5% | Monitoring |
| **CNF5** | Tasa de error en uploads | < 1% | Logs |
| **CNF6** | Precisión de detección de duplicados | > 95% | Testing |
| **CNF7** | Satisfacción de usuario | > 4/5 | Encuesta |

---

## RIESGOS Y MITIGACIONES

### Riesgos Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación | Owner |
|--------|--------------|---------|------------|-------|
| **R1: Performance del OCR** | MEDIA | ALTO | Implementar cola asíncrona con Celery | Ing. Carlos |
| **R2: False positives en detección de duplicados** | BAJA | MEDIO | Ajustar threshold de comparación, agregar modo manual | Dr. Roberto |
| **R3: Usuarios confundidos con nuevo flujo** | ALTA | MEDIO | Tutoriales, onboarding, documentación clara | Lic. Patricia |
| **R4: Bugs en comparación automática** | MEDIA | ALTO | Testing exhaustivo, rollback plan, feature flag | Ing. Luis |
| **R5: Migración de BD falla** | BAJA | CRÍTICO | Backup completo, testing en staging, plan de rollback | Ing. Carlos |

### Riesgos de Negocio

| Riesgo | Probabilidad | Impacto | Mitigación | Owner |
|--------|--------------|---------|------------|-------|
| **RN1: Usuarios rechazan nueva funcionalidad** | BAJA | ALTO | Beta testing con usuarios reales, feedback iterativo | Lic. Patricia |
| **RN2: Documentos valiosos eliminados por error** | BAJA | CRÍTICO | Papelera de reciclaje (soft delete) 30 días, logs auditables | Ing. Carlos |
| **RN3: Aumento de carga en servidor** | MEDIA | MEDIO | Monitoreo, escalamiento horizontal, optimización | Dr. María |

---

## MÉTRICAS DE ÉXITO

### KPIs Técnicos

- **Tasa de Adopción**: 80% de usuarios usan validación en primer mes
- **Tasa de Duplicados Prevenidos**: > 90% de uploads duplicados detectados
- **Tasa de Acierto en Comparación**: > 95% de decisiones automáticas correctas
- **Tiempo de Procesamiento**: < 30s desde upload hasta decisión final
- **Disponibilidad**: 99.5% uptime

### KPIs de Negocio

- **Reducción de Duplicados**: -80% de documentos duplicados en sistema
- **Tiempo de Digitalización**: -50% de tiempo perdido en duplicados
- **Satisfacción de Usuario**: > 4.5/5 en encuestas
- **Tickets de Soporte**: -60% de tickets por duplicados
- **Calidad de Datos**: +30% de documentos con calidad OCR > 85%

---

## PRESUPUESTO Y RECURSOS

### Horas de Desarrollo

| Rol | Horas | Tarifa/h | Subtotal |
|-----|-------|----------|----------|
| Arquitecto de Software (Dr. María) | 24h | - | - |
| Ingeniero Backend (Ing. Carlos) | 38h | - | - |
| Ingeniera Frontend (Ing. Ana) | 48h | - | - |
| Especialista Visión (Dr. Roberto) | 18h | - | - |
| Ingeniero QA (Ing. Luis) | 22h | - | - |
| Product Manager (Lic. Patricia) | 14h | - | - |
| **TOTAL** | **164h** | - | - |

### Timeline

- **Fase 0**: Día 1 (4h)
- **Fase 1**: Días 2-3 (16h) → Primera versión funcional
- **Fase 2**: Días 4-5 (16h) → UX mejorado
- **Fase 3**: Días 6-8 (24h) → Comparación de imágenes
- **Fase 4**: Días 9-11 (24h) → Reclasificación
- **Fase 5**: Días 12-14 (24h) → Testing y deployment

**TOTAL: 14 días hábiles (≈ 3 semanas)**

---

## CONCLUSIONES Y RECOMENDACIONES

### Hallazgos Principales

1. ✅ **80% Ya Implementado**: El sistema tiene una base sólida con endpoints de validación y comparación automática ya funcionales.

2. ✅ **Arquitectura Correcta**: Los patrones utilizados (signals, repositorios, entidades) son apropiados y escalables.

3. ❌ **Gap Crítico**: El flujo de validación no está integrado en Lumara. El upload service sigue usando el método antiguo sin validación previa.

4. ✅ **Calidad de Código**: El código existente es de buena calidad, bien documentado y con logging apropiado.

5. ⚠️ **Falta Testing**: No hay tests automatizados del flujo completo.

### Recomendaciones

#### Prioridad CRÍTICA (Implementar Ya)

1. **Integrar Flujo de Validación** (Fase 1)
   - Esto resuelve el 80% del problema del usuario
   - Tiempo: 2 días
   - Impacto: ALTO

2. **Mejorar UX** (Fase 2)
   - Feedback claro al usuario
   - Tiempo: 2 días
   - Impacto: MEDIO

#### Prioridad ALTA (Implementar Pronto)

3. **Comparación de Imágenes** (Fase 3)
   - Detecta documentos idénticos
   - Previene errores
   - Tiempo: 3 días
   - Impacto: MEDIO

#### Prioridad MEDIA (Implementar Después)

4. **Reclasificación** (Fase 4)
   - Nice to have
   - Tiempo: 3 días
   - Impacto: BAJO

#### Prioridad ALTA (Siempre)

5. **Testing y Documentación** (Fase 5)
   - Asegura calidad
   - Reduce bugs en producción
   - Tiempo: 3 días
   - Impacto: ALTO

### Roadmap Recomendado

**Sprint 1 (Semana 1-2)**: Fases 0, 1, 2
- MVP funcional con validación y UX básico
- Usuario puede ya usar el sistema
- **Entregable**: APK v4.6.1 en beta

**Sprint 2 (Semana 3-4)**: Fases 3, 4
- Features avanzados (hashes, reclasificación)
- **Entregable**: APK v4.8.0 en producción

**Sprint 3 (Semana 5)**: Fase 5
- Testing, documentación, deployment
- **Entregable**: APK v5.0.0 stable

### Retorno de Inversión (ROI)

**Beneficios Cuantificables**:
- **Ahorro de Tiempo**: ~5min por documento duplicado × 100 docs/día = 500min/día = 8.3h/día
- **Reducción de Errores**: -80% de duplicados = menos confusión, mejor calidad de datos
- **Satisfacción de Usuario**: Menos frustración, proceso más fluido

**Costos**:
- **Desarrollo**: 164h de equipo (~3 semanas)
- **Testing**: Incluido en las 164h
- **Deployment**: Mínimo (solo actualización de APK)

**ROI Estimado**: Positivo en el primer mes de uso

---

## ANEXOS

### ANEXO A: Estructura de Respuestas API

#### check_exists Response
```json
{
  "exists": true,
  "can_replace": true,
  "ocr_confidence": 0.85,
  "has_minimum_data": true,
  "existing_document": {
    "id": 12345,
    "title": "Cédula de Ciudadanía - JUAN PEREZ",
    "created_at": "2025-10-27T10:30:00Z",
    "digitized_by": "admin",
    "digitized_by_username": "admin_user",
    "nuip_extracted": "1234567890",
    "needs_review": false
  },
  "person": {
    "id": "2071",
    "name": "JUAN PEREZ",
    "nuip": "1234567890"
  },
  "message": "Ya existe un documento de este tipo con calidad media (85%). Se puede reemplazar."
}
```

#### smart_upload Response
```json
{
  "success": true,
  "action": "pending_comparison",
  "document_id": 12346,
  "existing_document_id": 12345,
  "person_id": 2071,
  "person_name": "JUAN PEREZ",
  "relation_id": 456,
  "message": "Documento subido exitosamente. OCR en proceso. Se comparará automáticamente con documento existente (ID: 12345, Calidad: 85%). Se quedará automáticamente con el de mejor calidad."
}
```

### ANEXO B: Comandos Útiles

```bash
# Testing Backend
python manage.py test documents.tests.test_smart_upload
python manage.py test documents.tests.test_image_comparison

# Testing Frontend
flutter test test/services/upload_service_test.dart
flutter test test/widgets/replace_confirmation_dialog_test.dart

# Deployment
python manage.py migrate
python manage.py calculate_existing_hashes
flutter build apk --release

# Monitoring
tail -f logs/tejido.log | grep SMART_
docker logs -f tejido-webserver-1 | grep SMART_COMPARE
```

### ANEXO C: Referencias

- **Tejido-NGX Docs**: https://docs.tejido-ngx.com/
- **Flutter Best Practices**: https://flutter.dev/docs/development/best-practices
- **ImageHash Library**: https://github.com/JohannesBuchner/imagehash
- **OCR Quality Standards**: ISO 19005-2 (PDF/A-2)

---

**FIN DE LA AUDITORÍA**

**Preparado por**: Equipo Interdisciplinario de Ingeniería
**Fecha**: 28 de octubre de 2025
**Versión**: 1.0
**Estado**: LISTO PARA APROBACIÓN E IMPLEMENTACIÓN

**Próxima Acción**: Reunión de aprobación con stakeholders para confirmar plan y comenzar Fase 0.
