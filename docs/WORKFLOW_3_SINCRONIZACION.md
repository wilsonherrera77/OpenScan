# 🧪 WORKFLOW 3: Testing de Sincronización Lumara ↔ Paperless

**Fecha**: 27 de octubre de 2025
**Versión**: Lumara v4.5.2 - FASE 1+2+3 Optimizado
**Duración Estimada**: 30-45 minutos
**Prerrequisito**: APK instalado, censo cargado en ambos sistemas

---

## 📋 Objetivo

Verificar que los documentos subidos desde **Lumara** se **asocian correctamente** con las personas del censo en **Paperless**, creando las relaciones documento-persona necesarias para el sistema de seguimiento.

**Problema a resolver**: Actualmente hay **0 relaciones** documento-persona en Paperless, lo que indica que los uploads desde Lumara no están creando las asociaciones.

---

## 🎯 Criterios de Éxito

### Criterios BLOQUEANTES (deben pasar todos)

| ID | Criterio | Métrica Objetivo | Cómo Medir |
|----|----------|------------------|------------|
| **B1** | Documento se crea en Paperless | 100% success | Verificar ID de documento en respuesta |
| **B2** | Relación documento-persona se crea | 100% success | Consultar `DocumentPersonRelation` |
| **B3** | person_id correcto en relación | 100% match | Comparar person_id enviado vs. almacenado |
| **B4** | document_type correcto | 100% match | Verificar tag en Paperless |
| **B5** | NUIP correcto en metadata | 100% match | Verificar NUIP almacenado |

### Criterios DESEABLES (recomendados)

| ID | Criterio | Métrica Objetivo | Cómo Medir |
|----|----------|------------------|------------|
| **D1** | Múltiples docs para misma persona | Funciona | Subir 2+ documentos, verificar relaciones |
| **D2** | Endpoint correcto usado | Verificado | Logs muestran `upload_with_person` |
| **D3** | Consulta de docs por persona | Funciona | API devuelve documentos asociados |
| **D4** | Interfaz web muestra asociación | Visible | Ver documento en Paperless con person_id |
| **D5** | Detección de duplicados | Funciona | check_exists devuelve true |

---

## 🔧 Preparación del Entorno

### 1. Verificar Estado Inicial

```bash
# Verificar censo en Paperless
docker exec paperless-webserver-1 python3 manage.py shell -c \
  "from documents.models import CensusPerson; \
   print(f'Personas en censo: {CensusPerson.objects.count()}')"

# Debe mostrar: 3998
```

```bash
# Verificar relaciones existentes (debe ser 0 o muy pocas)
docker exec paperless-webserver-1 python3 manage.py shell -c \
  "from documents.models import DocumentPersonRelation; \
   print(f'Relaciones actuales: {DocumentPersonRelation.objects.count()}')"
```

**Baseline esperado**: 0 relaciones (o las que existían antes)

### 2. Verificar APK Instalado

```bash
# Verificar versión instalada
adb shell dumpsys package com.lumara.app | grep versionName

# Debe ser: versionName=4.5.2
```

### 3. Iniciar Monitoreo de Logs

Abrir **3 terminales** para monitorear diferentes aspectos:

**Terminal 1 - Logs de Upload**:
```bash
./scripts/watch_logs.sh '' all
```

**Terminal 2 - Logs de Errores**:
```bash
./scripts/watch_logs.sh '' errors
```

**Terminal 3 - Logs de Optimizaciones**:
```bash
./scripts/watch_logs.sh '' optimizations
```

---

## 📝 Procedimiento de Ejecución

### FASE A: Verificación de Conectividad

#### A1. Verificar Servidor Paperless Activo

```bash
curl -s -X GET "http://172.20.10.3:8001/api/" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  | jq -r '.version'
```

**Resultado Esperado**: Versión de Paperless (ej: "2.8.0")

#### A2. Verificar Endpoint upload_with_person

```bash
curl -s -X OPTIONS "http://172.20.10.3:8001/api/documents/upload_with_person/" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01"
```

**Resultado Esperado**: HTTP 200 OK

---

### FASE B: Test Case 1 - Upload Simple con Persona

#### TC-3-01: Upload de Cédula de Ciudadanía

**Objetivo**: Verificar que un upload básico crea documento Y relación.

**Pasos**:

1. **En Lumara**:
   - Abrir app
   - Ir a "Upload Document"
   - Seleccionar persona: **MARTIN HERRERA OCAMPO** (NUIP: 1021315923)
   - Seleccionar tipo: **Cédula de Ciudadanía**
   - Tomar foto o seleccionar imagen
   - Confirmar upload

2. **Observar logs en Terminal 1**:

**Logs esperados si funciona correctamente**:
```
📤 Uploading document for: MARTIN HERRERA OCAMPO
📡 Using endpoint: /api/documents/upload_with_person/
   person_id: 3998
   document_type: Cédula de Ciudadanía
   nuip: 1021315923

🖼️ Image optimized: 4.2MB → 890KB (78.8% reduction)
🗜️ Compressed: 890KB → 178KB (80% reduction)

📡 Sending request...
✅ Document uploaded successfully
   document_id: 123
   relation_id: 1
```

**Logs problemáticos a buscar**:
```
❌ Error: Person not found
❌ Failed to create relation
❌ Using generic upload endpoint (BAD)
⚠️  person_id is null
```

3. **Verificar en Paperless** (inmediatamente después):

```bash
# Anotar cuántas relaciones había antes
BEFORE_COUNT=$(docker exec paperless-webserver-1 python3 manage.py shell -c \
  "from documents.models import DocumentPersonRelation; \
   print(DocumentPersonRelation.objects.count())" 2>/dev/null | tail -1)

echo "Relaciones ANTES del upload: $BEFORE_COUNT"
```

**Después del upload**:
```bash
AFTER_COUNT=$(docker exec paperless-webserver-1 python3 manage.py shell -c \
  "from documents.models import DocumentPersonRelation; \
   print(DocumentPersonRelation.objects.count())" 2>/dev/null | tail -1)

echo "Relaciones DESPUÉS del upload: $AFTER_COUNT"

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
  echo "✅ Relación creada correctamente"
else
  echo "❌ NO se creó relación - PROBLEMA CONFIRMADO"
fi
```

4. **Verificar datos de la relación**:

```bash
docker exec paperless-webserver-1 python3 manage.py shell -c "
from documents.models import DocumentPersonRelation
import json

# Obtener última relación creada
relation = DocumentPersonRelation.objects.last()

if relation:
    print(json.dumps({
        'id': relation.id,
        'document_id': relation.document_id,
        'person_id': relation.person_id,
        'person_name': relation.person.get_full_name(),
        'document_type': relation.document_type,
        'nuip_sent': relation.nuip_sent_by_app,
        'association_method': relation.association_method,
    }, indent=2, ensure_ascii=False))
else:
    print('NO HAY RELACIONES')
"
```

**Output Esperado**:
```json
{
  "id": 1,
  "document_id": 123,
  "person_id": 3998,
  "person_name": "MARTIN HERRERA OCAMPO",
  "document_type": "Cédula de Ciudadanía",
  "nuip_sent": "1021315923",
  "association_method": "APP"
}
```

**Verificar**:
- [ ] `document_id` existe y es válido
- [ ] `person_id` = 3998 (correcto)
- [ ] `person_name` = "MARTIN HERRERA OCAMPO" (correcto)
- [ ] `document_type` = "Cédula de Ciudadanía" (correcto)
- [ ] `nuip_sent` = "1021315923" (correcto)
- [ ] `association_method` = "APP" (correcto)

**Resultado**: ✅ Aprobado / ❌ Fallido

---

#### TC-3-02: Verificar Documento en Paperless Web UI

**Objetivo**: Confirmar visualmente que el documento está asociado.

**Pasos**:

1. Abrir navegador en: `http://localhost:8001`
2. Login con credenciales de Paperless
3. Buscar el documento recién subido (por título o fecha)
4. Abrir detalles del documento

**Verificar**:
- [ ] Documento existe
- [ ] Tag "Cédula de Ciudadanía" aplicado
- [ ] Título contiene "MARTIN HERRERA OCAMPO"
- [ ] Custom fields incluyen `person_id` (si está configurado)
- [ ] En sección de relaciones (si existe): Muestra persona asociada

**Resultado**: ✅ Aprobado / ❌ Fallido

---

### FASE C: Test Case 2 - Múltiples Documentos para Misma Persona

#### TC-3-03: Upload de Tarjeta de Identidad (misma persona)

**Objetivo**: Verificar que múltiples documentos se pueden asociar a la misma persona.

**Pasos**:

1. **En Lumara**:
   - Seleccionar la misma persona: **MARTIN HERRERA OCAMPO**
   - Seleccionar tipo diferente: **Registro Civil** o **Certificado EPS**
   - Tomar/seleccionar imagen
   - Confirmar upload

2. **Verificar relaciones**:

```bash
docker exec paperless-webserver-1 python3 manage.py shell -c "
from documents.models import DocumentPersonRelation

# Contar relaciones para esta persona
person_id = 3998
relations_count = DocumentPersonRelation.objects.filter(person_id=person_id).count()

print(f'Total de documentos para persona {person_id}: {relations_count}')

# Listar todos
relations = DocumentPersonRelation.objects.filter(person_id=person_id)
for rel in relations:
    print(f'  - Doc {rel.document_id}: {rel.document_type}')
"
```

**Output Esperado**:
```
Total de documentos para persona 3998: 2
  - Doc 123: Cédula de Ciudadanía
  - Doc 124: Registro Civil
```

**Verificar**:
- [ ] 2 relaciones para la misma persona
- [ ] Diferentes `document_type`
- [ ] Ambos documentos válidos

**Resultado**: ✅ Aprobado / ❌ Fallido

---

### FASE D: Test Case 3 - Diferentes Personas

#### TC-3-04: Upload para Persona Diferente

**Objetivo**: Verificar que el sistema funciona para cualquier persona del censo.

**Pasos**:

1. **En Lumara**:
   - Buscar otra persona (ej: buscar por nombre "MARLEN")
   - Debería encontrar: **MARLEN RODRIGUEZ MIRANDA** (NUIP: 35476686, ID: 3999)
   - Seleccionar tipo: **Cédula de Ciudadanía**
   - Tomar/seleccionar imagen
   - Confirmar upload

2. **Verificar relación**:

```bash
docker exec paperless-webserver-1 python3 manage.py shell -c "
from documents.models import DocumentPersonRelation

# Buscar relación para segunda persona
person_id = 3999
relation = DocumentPersonRelation.objects.filter(person_id=person_id).last()

if relation:
    print(f'✅ Relación creada para persona {person_id}')
    print(f'   Nombre: {relation.person.get_full_name()}')
    print(f'   NUIP enviado: {relation.nuip_sent_by_app}')
else:
    print(f'❌ NO se creó relación para persona {person_id}')
"
```

**Verificar**:
- [ ] Relación creada para `person_id=3999`
- [ ] Nombre correcto: "MARLEN RODRIGUEZ MIRANDA"
- [ ] NUIP correcto: "35476686"

**Resultado**: ✅ Aprobado / ❌ Fallido

---

### FASE E: Test Case 4 - Detección de Duplicados

#### TC-3-05: Verificar check_exists Antes de Upload

**Objetivo**: Verificar que el sistema detecta documentos existentes.

**Pasos**:

1. **Test directo del endpoint** (simula lo que debería hacer Lumara):

```bash
curl -s -X GET "http://172.20.10.3:8001/api/documents/check_exists/?person_id=3998&document_type=Cédula%20de%20Ciudadanía" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  | jq '.'
```

**Output Esperado** (si ya existe el documento del TC-3-01):
```json
{
  "exists": true,
  "can_replace": false,
  "ocr_confidence": 0.95,
  "has_minimum_data": true,
  "existing_document": {
    "id": 123,
    "title": "Cédula de Ciudadanía - MARTIN HERRERA OCAMPO",
    "created": "2025-10-27T15:30:00Z"
  },
  "person": {
    "id": 3998,
    "full_name": "MARTIN HERRERA OCAMPO"
  },
  "message": "Ya existe un documento de buena calidad (OCR: 95%)"
}
```

2. **En Lumara** (si implementa la verificación):
   - Seleccionar persona: **MARTIN HERRERA OCAMPO**
   - Seleccionar tipo: **Cédula de Ciudadanía** (mismo que antes)
   - Tocar botón "Capturar"
   - **Debería** mostrar diálogo: "Ya existe un documento de este tipo"

**Verificar**:
- [ ] Endpoint `check_exists` funciona
- [ ] Devuelve `exists: true` para documentos ya subidos
- [ ] Lumara muestra advertencia (si implementado)
- [ ] Si `can_replace: true`, permite reemplazo

**Resultado**: ✅ Aprobado / ❌ Fallido / ⚠️ No implementado aún

---

### FASE F: Test Case 5 - Consulta de Documentos por Persona

#### TC-3-06: API para Obtener Documentos de una Persona

**Objetivo**: Verificar que se pueden consultar todos los documentos de una persona.

**Pasos**:

1. **Consultar relaciones por API**:

```bash
curl -s -X GET "http://172.20.10.3:8001/api/document-person-relations/?person=3998" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" \
  | jq '.results'
```

**Output Esperado**:
```json
[
  {
    "id": 1,
    "document": 123,
    "person": 3998,
    "document_type": "Cédula de Ciudadanía",
    "nuip_sent_by_app": "1021315923",
    "association_method": "APP",
    "created_at": "2025-10-27T15:30:00Z"
  },
  {
    "id": 2,
    "document": 124,
    "person": 3998,
    "document_type": "Registro Civil",
    "nuip_sent_by_app": "1021315923",
    "association_method": "APP",
    "created_at": "2025-10-27T15:35:00Z"
  }
]
```

**Verificar**:
- [ ] API devuelve lista de relaciones
- [ ] Todas las relaciones son para `person=3998`
- [ ] IDs de documentos son válidos
- [ ] Tipos de documentos correctos

**Resultado**: ✅ Aprobado / ❌ Fallido

---

### FASE G: Diagnóstico si Falla

#### Paso 1: Si NO se Crean Relaciones

**Buscar en logs de Lumara**:
```bash
# Filtrar logs de upload
./scripts/watch_logs.sh '' all | grep -E "(upload|Upload|person)"
```

**Buscar indicadores**:
- ❌ `Using generic upload endpoint` → Problema: usa endpoint incorrecto
- ❌ `person_id is null` → Problema: no se pasa person_id
- ❌ `Person not found in cache` → Problema: censo no cargado en Lumara
- ✅ `Using endpoint: upload_with_person` → Bien

**Verificar en código** (si logs no muestran nada):

```bash
# Ver qué endpoint se está llamando realmente
grep -n "uploadDocumentForPerson\|uploadGenericDocument" \
  lib/services/upload_service.dart
```

#### Paso 2: Si se Usa Endpoint Incorrecto

**Causa probable**: La condición en `upload_service.dart` no detecta que debe usar `uploadDocumentForPerson`.

**Verificar**:
```dart
// En _uploadDocument(), línea ~410
if (upload.personId != null) {
  // Debería entrar aquí si personId está presente
  final person = await _database.getPersonById(upload.personId);

  if (person == null) {
    // AQUÍ puede estar fallando
    _logger.e('Person $upload.personId not found in cache');
    // ¿Qué pasa después? ¿Falla o hace upload genérico?
  }
}
```

**Solución temporal**: Agregar más logs para debugging.

---

## 📊 Reporte de Resultados

### Template de Reporte

```markdown
# WORKFLOW 3: Testing de Sincronización - Reporte

**Fecha**: [Fecha de ejecución]
**Dispositivo**: [Modelo y Android version]
**Duración Total**: [XX minutos]
**APK Version**: 4.5.2 FASE_1_2_3_OPTIMIZADO

---

## Estado Inicial

- Personas en censo: 3998
- Relaciones documento-persona ANTES: X
- Relaciones documento-persona DESPUÉS: Y
- **Relaciones nuevas creadas**: Y - X

---

## Resultados por Test Case

| TC ID | Nombre | Resultado | Relación ID | Observaciones |
|-------|--------|-----------|-------------|---------------|
| TC-3-01 | Upload simple con persona | ✅/❌ | X | [Notas] |
| TC-3-02 | Verificar en Web UI | ✅/❌ | - | [Notas] |
| TC-3-03 | Múltiples docs misma persona | ✅/❌ | X, Y | [Notas] |
| TC-3-04 | Diferentes personas | ✅/❌ | Z | [Notas] |
| TC-3-05 | Detección de duplicados | ✅/❌/⚠️ | - | [Notas] |
| TC-3-06 | Consulta docs por persona | ✅/❌ | - | [Notas] |

---

## Criterios de Éxito

### Bloqueantes

- [ ] **B1**: Documento se crea en Paperless
- [ ] **B2**: Relación documento-persona se crea
- [ ] **B3**: person_id correcto en relación
- [ ] **B4**: document_type correcto
- [ ] **B5**: NUIP correcto en metadata

**Bloqueantes Cumplidos**: X/5

### Deseables

- [ ] **D1**: Múltiples docs para misma persona
- [ ] **D2**: Endpoint correcto usado
- [ ] **D3**: Consulta de docs por persona
- [ ] **D4**: Interfaz web muestra asociación
- [ ] **D5**: Detección de duplicados

**Deseables Cumplidos**: X/5

---

## Diagnóstico

### ✅ Si Todo Funciona

**Evidencia**:
- Relaciones creadas para cada upload
- person_id correcto en todas las relaciones
- Endpoint `upload_with_person` usado consistentemente

**Conclusión**: Sistema de sincronización funciona correctamente.

### ❌ Si NO se Crean Relaciones

**Evidencia**:
- 0 relaciones nuevas después de múltiples uploads
- Logs no muestran llamadas a `upload_with_person`
- Documentos se crean pero sin asociación

**Causa Probable**:
1. Lumara usa endpoint genérico en lugar de `upload_with_person`
2. person_id no se pasa correctamente
3. Error silencioso en el flujo

**Solución Recomendada**:
- Revisar `lib/services/upload_service.dart` línea ~410-460
- Agregar logs adicionales para debugging
- Verificar construcción del objeto Person

---

## Logs Relevantes

```
[Pegar logs importantes aquí]
```

---

## Issues Encontrados

### Críticos (🔴)
[Lista de issues que bloquean producción]

### Menores (🟡)
[Lista de issues que no bloquean pero deberían mejorarse]

### Observaciones (🔵)
[Notas generales, sugerencias de mejora]

---

## Conclusión

[Descripción breve del resultado general]

**Decisión Final**:
- ✅ **Aprobado**: Sincronización funciona correctamente
- ⚠️ **Requiere Fix**: Problema identificado, solución propuesta
- ❌ **Bloqueado**: Requiere investigación adicional

## Próximos Pasos

- [ ] [Acción 1]
- [ ] [Acción 2]
- [ ] [Acción 3]
```

---

## 🎯 Criterios de Aprobación

### ✅ Aprobar - Sincronización Funciona

**Condiciones**:
- 100% criterios BLOQUEANTES cumplidos (5/5)
- ≥60% criterios DESEABLES cumplidos (≥3/5)
- Relaciones creadas para todos los uploads de prueba
- API de consulta funciona correctamente

**Acción**: Sistema listo para producción

---

### ⚠️ Aprobar con Fix Requerido

**Condiciones**:
- <100% criterios BLOQUEANTES cumplidos
- Problema identificado y documentado
- Solución propuesta clara

**Acción**:
1. Documentar problema específico
2. Implementar fix
3. Re-ejecutar Workflow 3

---

### ❌ Rechazar - Requiere Investigación

**Condiciones**:
- Relaciones NO se crean
- Problema NO identificado claramente
- Logs no proporcionan información suficiente

**Acción**:
1. Agregar logging adicional en Lumara
2. Compilar APK de debug con logs verbosos
3. Re-ejecutar workflow con más instrumentación

---

## 📞 Troubleshooting

### Issue: Relaciones NO se Crean

**Síntoma**: Después de uploads, `DocumentPersonRelation.objects.count()` permanece en 0.

**Diagnóstico**:
1. Verificar qué endpoint se llama:
   ```bash
   # En logs de Paperless
   docker logs paperless-webserver-1 | grep "POST /api/documents"
   ```

2. Si muestra `POST /api/documents/post_document/`:
   - ❌ Problema: Lumara usa endpoint genérico
   - Solución: Modificar código para usar `upload_with_person`

3. Si muestra `POST /api/documents/upload_with_person/`:
   - ✅ Endpoint correcto usado
   - Verificar: ¿El request incluye person_id?

### Issue: person_id Incorrecto

**Síntoma**: Relaciones se crean pero con person_id equivocado.

**Diagnóstico**:
```bash
# Comparar person_id enviado vs. almacenado
# Ver logs de Lumara para person_id enviado
# Ver BD de Paperless para person_id almacenado
```

### Issue: NUIP No Coincide

**Síntoma**: NUIP almacenado difiere del NUIP de la persona en el censo.

**Causa**: Posible error de tipeo o formato.

**Solución**: Validar NUIP antes de enviar.

---

## 📚 Referencias

- [PROBLEMA_SINCRONIZACION_HALLAZGOS.md](./PROBLEMA_SINCRONIZACION_HALLAZGOS.md) - Investigación inicial
- [WORKFLOW_1_PERFORMANCE_BASICO.md](./WORKFLOW_1_PERFORMANCE_BASICO.md) - Workflow anterior
- [WORKFLOW_2_RED_LENTA.md](./WORKFLOW_2_RED_LENTA.md) - Workflow anterior
- Backend: `/src/documents/views_census.py` - Endpoint `upload_document_with_person`
- Frontend: `/lib/services/upload_service.dart` - Lógica de upload

---

**Última actualización**: 27 de octubre de 2025
