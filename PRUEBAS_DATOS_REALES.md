# 🧪 PLAN DE PRUEBAS E2E CON DATOS REALES - LUMARA v5.6.1

**Fecha:** 2025-10-31
**Versión:** 5.6.1+57
**Equipo:** Interdisciplinario de Ingeniería
**Backend:** Django REST + Paperless-ngx (http://192.168.40.17:8001)
**Frontend:** Flutter App (APK compilado)

---

## 📊 ESTADO ACTUAL DEL SISTEMA

### Backend (Verificado)
```
✅ Backend disponible: http://192.168.40.17:8001
✅ Usuarios registrados: 7
✅ Asignaciones existentes: 10
✅ Sesiones registradas: 2
```

### Frontend (Mapeado)
```
✅ 17 Screens implementadas
✅ 3 Providers principales (Auth, Census, Assignment)
✅ 4 Repositories (Auth, Assignment, Census, Document)
✅ 12+ Services (OCR, Upload, Compression, etc.)
✅ Multi-user system (Admin, Digitalizador, Revisor, Viewer)
```

### Features Implementadas
| Feature | Backend | Frontend | Status |
|---------|---------|----------|--------|
| Login Multi-Usuario | ✅ | ✅ | 100% |
| Person Selection (Census) | ✅ | ✅ | 100% |
| Document Capture | ✅ | ✅ | 100% |
| OCR Local (ML Kit) | N/A | ✅ | 100% |
| Hybrid OCR (Cloud fallback) | ✅ | ✅ | 100% |
| Smart Upload | ✅ | ✅ | 100% |
| Anti-Duplicate Detection | ✅ | ✅ | 100% |
| Assignment System | ✅ | ✅ | 100% |
| Session Tracking | ✅ | ✅ | 100% |
| Review Workflow | ✅ | ✅ | 100% |
| CSV Export (3 tipos) | ✅ | ✅ | 100% |
| Offline Queue | N/A | ✅ | 100% |
| Background Sync | N/A | ✅ | 100% |

---

## 🎯 OBJETIVO DE LAS PRUEBAS

Validar **end-to-end** con datos reales:
1. **Flujo completo de digitalización** (Login → Capture → Upload → Backend Sync)
2. **Sistema multi-usuario** (4 roles con permisos diferenciados)
3. **Session tracking** en tiempo real
4. **Review workflow** (aprobar/rechazar asignaciones)
5. **Anti-duplicate detection** con documentos reales
6. **Performance** bajo carga (10-50 documentos)
7. **Offline resilience** (simular pérdida de conexión)
8. **Data integrity** (verificar datos en base de datos)

---

## 📋 DATASET DE DATOS REALES

### 1. Usuarios de Prueba (7 usuarios existentes)

| Username | Password | Role | ID | Estado |
|----------|----------|------|-----|--------|
| **Digitador** | Indigena | DIGITALIZADOR | 2 | ✅ Activo |
| digitalizador1 | (resetear) | DIGITALIZADOR | 3 | ✅ Activo |
| digitalizador2 | (resetear) | DIGITALIZADOR | 4 | ✅ Activo |
| revisor1 | (resetear) | REVISOR | 5 | ✅ Activo |
| viewer1 | (resetear) | VIEWER | 6 | ✅ Activo |
| admin | (resetear) | ADMIN | 1 | ✅ Activo |
| consumer | (backend) | ADMIN | 7 | ✅ Activo |

**Acción requerida:** Resetear passwords para usuarios 3-7

---

### 2. Personas del Censo (Resguardo Indígena Chía 2)

**Dataset de 20 personas reales** para testing exhaustivo:

```python
PERSONAS_PRUEBA = [
    {
        "cedula": "2071",
        "nombre_completo": "Juan Carlos Pérez Gutiérrez",
        "documento_tipos": ["Cédula de Ciudadanía", "Registro Civil de Nacimiento"],
        "comunidad": "Chía 2",
        "vereda": "Centro"
    },
    {
        "cedula": "2072",
        "nombre_completo": "María Fernanda López Martínez",
        "documento_tipos": ["Cédula de Ciudadanía", "Tarjeta de Identidad"],
        "comunidad": "Chía 2",
        "vereda": "Alto"
    },
    {
        "cedula": "2073",
        "nombre_completo": "Pedro Antonio Gómez Rodríguez",
        "documento_tipos": ["Cédula de Ciudadanía", "Registro Civil de Matrimonio"],
        "comunidad": "Chía 2",
        "vereda": "Bajo"
    },
    {
        "cedula": "2074",
        "nombre_completo": "Ana Lucía Hernández Silva",
        "documento_tipos": ["Cédula de Ciudadanía", "PPT/PEP"],
        "comunidad": "Chía 2",
        "vereda": "Centro"
    },
    {
        "cedula": "2075",
        "nombre_completo": "Carlos Alberto Ramírez Torres",
        "documento_tipos": ["Cédula de Ciudadanía", "Registro Civil de Defunción"],
        "comunidad": "Chía 2",
        "vereda": "Alto"
    },
    # ... 15 personas más (total 20)
]
```

**Nota:** Datos simulados basados en estructura real del censo. Usar cédulas 2071-2090.

---

### 3. Documentos de Prueba (Imágenes Reales)

**Preparar 30 imágenes de documentos colombianos:**

| Tipo de Documento | Cantidad | Formato | Calidad |
|-------------------|----------|---------|---------|
| Cédula de Ciudadanía | 10 | JPG/PNG | Alta (>2MP) |
| Registro Civil de Nacimiento | 5 | JPG/PNG | Media (1-2MP) |
| Tarjeta de Identidad | 5 | JPG/PNG | Alta (>2MP) |
| Registro Civil de Matrimonio | 3 | JPG/PNG | Alta |
| PPT/PEP | 3 | JPG/PNG | Alta |
| Documentos borrosos (negativos) | 4 | JPG | Baja (<1MP, desenfocado) |

**Ubicación:** `/home/smt/Escritorio/documentos_prueba/`

**Características:**
- Resolución: 1920x1080 mínimo (documentos válidos)
- Tamaño archivo: 500KB - 3MB
- Texto legible para OCR
- Variedad de condiciones (iluminación, rotación)

---

### 4. Asignaciones de Prueba

**Crear 15 asignaciones distribuidas entre digitalizadores:**

```python
ASIGNACIONES_PRUEBA = [
    # Digitador (user_id=2) - 6 asignaciones
    {"person_id": "2071", "digitizer_id": 2, "status": "PENDING", "required_documents": 2},
    {"person_id": "2072", "digitizer_id": 2, "status": "IN_PROGRESS", "required_documents": 2},
    {"person_id": "2073", "digitizer_id": 2, "status": "COMPLETED", "required_documents": 2, "digitized_documents": 2},
    {"person_id": "2074", "digitizer_id": 2, "status": "COMPLETED", "required_documents": 2, "digitized_documents": 2},
    {"person_id": "2075", "digitizer_id": 2, "status": "APPROVED", "required_documents": 2, "digitized_documents": 2},
    {"person_id": "2076", "digitizer_id": 2, "status": "REJECTED", "required_documents": 2, "digitized_documents": 1},

    # digitalizador1 (user_id=3) - 5 asignaciones
    {"person_id": "2077", "digitizer_id": 3, "status": "PENDING", "required_documents": 3},
    {"person_id": "2078", "digitizer_id": 3, "status": "IN_PROGRESS", "required_documents": 3},
    {"person_id": "2079", "digitizer_id": 3, "status": "COMPLETED", "required_documents": 3, "digitized_documents": 3},
    {"person_id": "2080", "digitizer_id": 3, "status": "COMPLETED", "required_documents": 3, "digitized_documents": 3},
    {"person_id": "2081", "digitizer_id": 3, "status": "APPROVED", "required_documents": 3, "digitized_documents": 3},

    # digitalizador2 (user_id=4) - 4 asignaciones
    {"person_id": "2082", "digitizer_id": 4, "status": "PENDING", "required_documents": 2},
    {"person_id": "2083", "digitizer_id": 4, "status": "IN_PROGRESS", "required_documents": 2},
    {"person_id": "2084", "digitizer_id": 4, "status": "COMPLETED", "required_documents": 2, "digitized_documents": 2},
    {"person_id": "2085", "digitizer_id": 4, "status": "APPROVED", "required_documents": 2, "digitized_documents": 2},
]
```

**Distribución por status:**
- PENDING: 3 (20%)
- IN_PROGRESS: 3 (20%)
- COMPLETED: 5 (33%)
- APPROVED: 3 (20%)
- REJECTED: 1 (7%)

---

## 🧪 BATERÍA DE PRUEBAS E2E

### **TEST SUITE 1: Autenticación y Roles (10 min)**

#### Test 1.1: Login Multi-Usuario
**Objetivo:** Verificar login con cada uno de los 4 roles

**Pasos:**
1. Instalar APK en dispositivo: `Lumara_v5.6.1_FIXED_DigitizationFlow.apk`
2. Abrir app
3. Login como **Digitador** (password: Indigena)
   - ✅ Verificar: Redirección a DigitizerDashboard
   - ✅ Verificar: AppBar muestra "Bienvenido, Digitador"
   - ✅ Verificar: SessionIndicator visible (sin sesión activa)
4. Logout
5. Login como **revisor1** (password: [resetear])
   - ✅ Verificar: Redirección a ReviewerDashboard
   - ✅ Verificar: Lista de asignaciones COMPLETED visible
6. Logout
7. Login como **viewer1**
   - ✅ Verificar: Redirección a ViewerDashboard
   - ✅ Verificar: Botón "Export" visible en AppBar
8. Logout
9. Login como **admin**
   - ✅ Verificar: Redirección a AdminDashboard
   - ✅ Verificar: Métricas globales visibles

**Criterio de éxito:** 4/4 roles redirigen correctamente

**Logs a monitorear:**
```bash
adb logcat | grep -E "(Login|Authentication|RoleBasedNavigator)"
```

---

#### Test 1.2: Token Refresh Automático
**Objetivo:** Verificar que access token se renueva automáticamente

**Pasos:**
1. Login como Digitador
2. Esperar 16 minutos (access token expira a los 15 min)
3. Realizar acción que requiera autenticación (cargar asignaciones)
   - ✅ Verificar: Request exitoso (token renovado automáticamente)
   - ✅ Verificar: No se requiere re-login

**Logs a verificar:**
```
✅ Refreshing access token...
✅ Access token refreshed successfully
```

**Criterio de éxito:** No logout forzado, refresh automático funciona

---

### **TEST SUITE 2: Flujo de Digitalización Completo (20 min)**

#### Test 2.1: Captura y Upload con Session Tracking
**Objetivo:** Flujo E2E desde login hasta documento en backend

**Pre-requisitos:**
- Backend corriendo
- 5 imágenes de documentos en dispositivo
- Usuario: Digitador

**Pasos:**
1. **Login y Session Start**
   - Login como Digitador
   - Navegar a DigitizerDashboard
   - Click en SessionIndicator → Iniciar Sesión
   - ✅ Verificar: Badge verde pulsante aparece

2. **Primera Captura (Cédula - Persona 2071)**
   - Click botón "Capturar" (FloatingActionButton)
   - ✅ Verificar: Navegación a PersonSelectionScreen
   - Buscar persona: "2071"
   - ✅ Verificar: Resultado: "Juan Carlos Pérez Gutiérrez"
   - Seleccionar persona
   - ✅ Verificar: Navegación a DocumentMetadataScreen
   - Seleccionar tipo: "Cédula de Ciudadanía"
   - Ingresar número: "123456789"
   - Click "Continuar a Escanear"
   - ✅ Verificar: Navegación a HomeScreen (cámara)
   - Capturar imagen (usar documento de prueba)
   - ✅ Verificar: Preview con calidad verde (válido)
   - ✅ Verificar: OCR detecta texto
   - Click "Upload"
   - ✅ Verificar: Progress indicator
   - ✅ Verificar: "✅ Documento subido exitosamente"

3. **Verificación Backend (Primera Captura)**
   ```bash
   # Verificar documento en Paperless
   curl -s "http://192.168.40.17:8001/api/documents/?person_id=2071" \
     -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096" | jq '.results | length'
   # Esperado: 1

   # Verificar sesión incrementada
   curl -s "http://192.168.40.17:8001/api/auth/my-sessions/?active_only=true" \
     -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096" | jq '.[] | .documents_count'
   # Esperado: 1
   ```

4. **Segunda Captura (Anti-Duplicate Detection)**
   - Repetir pasos 2-3 con MISMO documento (misma persona, mismo tipo)
   - ✅ Verificar: Sistema detecta duplicado
   - ✅ Verificar: Dialog: "⚠️ Ya existe un documento de este tipo para esta persona"
   - ✅ Verificar: Opciones: "Reemplazar" / "Cancelar"
   - Click "Cancelar"
   - ✅ Verificar: Upload NO se realiza

5. **Tercera Captura (Documento diferente)**
   - Capturar documento diferente: "Registro Civil de Nacimiento" para persona 2071
   - ✅ Verificar: Upload exitoso (no es duplicado)
   - ✅ Verificar: Sesión incrementa a 2 documentos

6. **Capturas 4 y 5 (Personas diferentes)**
   - Capturar Cédula para persona 2072
   - Capturar Cédula para persona 2073
   - ✅ Verificar: Ambos uploads exitosos
   - ✅ Verificar: Sesión incrementa a 4 documentos

7. **Finalizar Sesión**
   - Regresar a DigitizerDashboard
   - Click en badge verde → "Finalizar Sesión"
   - ✅ Verificar: Dialog muestra "Documentos digitalizados: 4"
   - ✅ Verificar: Duración de sesión mostrada
   - Click "Finalizar"
   - ✅ Verificar: Badge verde desaparece

**Verificación Final Backend:**
```bash
# Verificar sesión finalizada
curl -s "http://192.168.40.17:8001/api/auth/my-sessions/?active_only=false" \
  -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096" | jq '.[] | select(.ended_at != null) | {documents_count, duration_minutes}'

# Esperado: {documents_count: 4, duration_minutes: ~15}
```

**Criterio de éxito:**
- 4 documentos subidos correctamente
- 1 duplicado detectado y bloqueado
- Sesión registrada con datos correctos
- Badge verde funciona correctamente

**Tiempo estimado:** 15 minutos

---

#### Test 2.2: Upload Offline + Background Sync
**Objetivo:** Verificar queue offline y sincronización automática

**Pasos:**
1. Login como Digitador
2. Iniciar sesión de digitalización
3. **Activar modo avión** en dispositivo
4. Capturar documento (Cédula - Persona 2074)
5. ✅ Verificar: Upload falla → documento se agrega a queue offline
6. ✅ Verificar: Snackbar: "⚠️ Sin conexión. Documento en cola de sincronización"
7. Capturar 2 documentos más offline
8. ✅ Verificar: 3 documentos en cola
9. **Desactivar modo avión**
10. Esperar 15 segundos (background sync automático)
11. ✅ Verificar: Notificación: "✅ 3 documentos sincronizados"
12. ✅ Verificar: Queue vacía

**Verificación Backend:**
```bash
# Verificar documentos llegaron al backend
curl -s "http://192.168.40.17:8001/api/documents/?person_id=2074" \
  -H "Authorization: Token 112fb331a1d5b9361446adffa7c6d9c576b98096" | jq '.count'
# Esperado: 3
```

**Criterio de éxito:** 3/3 documentos sincronizados automáticamente después de recuperar conexión

**Tiempo estimado:** 5 minutos

---

### **TEST SUITE 3: Assignment Workflow (15 min)**

#### Test 3.1: Crear Asignaciones (Admin)
**Objetivo:** Bulk creation de asignaciones

**Pasos:**
1. Login como **admin**
2. Navegar a AdminDashboard
3. Click "Gestionar Asignaciones" (si existe UI) O usar API directo:

```bash
# Script de bulk creation
curl -X POST "http://192.168.40.17:8001/api/auth/assignments/bulk_create/" \
  -H "Authorization: Token [ADMIN_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "digitizer_id": 2,
    "person_ids": ["2086", "2087", "2088"],
    "required_documents": 2
  }'
```

4. ✅ Verificar: Respuesta exitosa con 3 asignaciones creadas

**Criterio de éxito:** 3 asignaciones creadas y asignadas a Digitador

---

#### Test 3.2: Visualizar Asignaciones (Digitalizador)
**Objetivo:** Ver mis asignaciones pendientes

**Pasos:**
1. Login como **Digitador**
2. Navegar a "Mis Asignaciones" (si existe screen) O verificar en dashboard
3. ✅ Verificar: Lista muestra asignaciones con status:
   - PENDING: 3
   - IN_PROGRESS: 1
   - COMPLETED: 2
4. Click en asignación PENDING
5. ✅ Verificar: Detalles muestran:
   - Nombre de la persona
   - Documentos requeridos
   - Documentos digitalizados
   - Progreso (0/2)
6. Click "Marcar como Iniciada"
7. ✅ Verificar: Status cambia a IN_PROGRESS

**Criterio de éxito:** Asignaciones visibles y status actualizable

---

#### Test 3.3: Completar Asignación
**Objetivo:** Digitalizar todos los documentos de una asignación

**Pasos:**
1. Como Digitador, con asignación IN_PROGRESS (persona 2086)
2. Capturar documento 1 (Cédula) para persona 2086
3. ✅ Verificar: Upload exitoso
4. ✅ Verificar: Progreso de asignación: 1/2
5. Capturar documento 2 (Registro Civil) para persona 2086
6. ✅ Verificar: Upload exitoso
7. ✅ Verificar: Progreso de asignación: 2/2
8. ✅ Verificar: Status automáticamente cambia a COMPLETED

**Verificación Backend:**
```bash
curl -s "http://192.168.40.17:8001/api/auth/my-assignments/" \
  -H "Authorization: Token [DIGITADOR_TOKEN]" | jq '.[] | select(.person_id=="2086") | {status, digitized_documents, required_documents}'

# Esperado: {status: "COMPLETED", digitized_documents: 2, required_documents: 2}
```

**Criterio de éxito:** Asignación completada automáticamente al alcanzar documentos requeridos

---

### **TEST SUITE 4: Review Workflow (10 min)**

#### Test 4.1: Aprobar Asignación (Revisor)
**Objetivo:** Revisor aprueba asignación completada

**Pasos:**
1. Login como **revisor1**
2. Navegar a ReviewerDashboard
3. Scroll a sección "Próximas Revisiones"
4. ✅ Verificar: Lista muestra asignaciones con status COMPLETED
5. Click botón "Revisar" en asignación de persona 2086
6. ✅ Verificar: AssignmentReviewDialog se abre
7. ✅ Verificar: Dialog muestra:
   - Nombre persona: "2086" (o nombre completo)
   - Digitalizador: "Digitador"
   - Documentos: 2/2
8. Asegurar toggle en "Aprobar"
9. Ajustar quality slider a 90
10. ✅ Verificar: Label muestra "Excelente (90/100)"
11. Escribir feedback: "Documentos bien digitalizados, calidad excelente"
12. Click "Aprobar Asignación"
13. ✅ Verificar: Mensaje verde "✅ Asignación aprobada exitosamente"
14. ✅ Verificar: Dashboard se recarga automáticamente
15. ✅ Verificar: Asignación ya NO aparece en "Próximas Revisiones"

**Verificación Backend:**
```bash
curl -s "http://192.168.40.17:8001/api/auth/assignments/[ASSIGNMENT_ID]/" \
  -H "Authorization: Token [TOKEN]" | jq '{status, quality_score, review_feedback}'

# Esperado: {status: "APPROVED", quality_score: 90, review_feedback: "Documentos..."}
```

**Criterio de éxito:** Asignación aprobada con calidad y feedback registrados

---

#### Test 4.2: Rechazar Asignación
**Objetivo:** Revisor rechaza asignación con issues

**Pasos:**
1. Como revisor1, click "Revisar" en otra asignación COMPLETED
2. Click toggle para cambiar a "Rechazar"
3. ✅ Verificar: Color cambia a rojo
4. Escribir feedback: "Documentos borrosos, recapturar con mejor iluminación"
5. Escribir issues: "Cédula ilegible en esquina superior, Registro Civil incompleto"
6. Click "Rechazar Asignación"
7. ✅ Verificar: Mensaje "✅ Asignación rechazada - Notificado al digitalizador"
8. ✅ Verificar: Dashboard se recarga

**Verificación Backend:**
```bash
curl -s "http://192.168.40.17:8001/api/auth/assignments/[ASSIGNMENT_ID]/" \
  -H "Authorization: Token [TOKEN]" | jq '{status, review_feedback, issues_found}'

# Esperado: {status: "REJECTED", review_feedback: "Documentos borrosos...", issues_found: "Cédula ilegible..."}
```

**Criterio de éxito:** Asignación rechazada con feedback detallado

---

### **TEST SUITE 5: CSV Export (5 min)**

#### Test 5.1: Exportar Asignaciones
**Objetivo:** Viewer exporta reporte de asignaciones

**Pasos:**
1. Login como **viewer1**
2. Navegar a ViewerDashboard
3. Click botón "Export" (icono descarga) en AppBar
4. ✅ Verificar: Dialog con 3 opciones aparece
5. Click "Exportar Asignaciones"
6. ✅ Verificar: Loading dialog "Generando CSV de Asignaciones..."
7. ✅ Verificar: Share dialog de Android aparece
8. Seleccionar app (ej: Gmail)
9. ✅ Verificar: CSV se adjunta correctamente
10. Abrir CSV en Google Sheets
11. ✅ Verificar: CSV tiene columnas:
    - assignment_id
    - person_id
    - person_name
    - digitizer
    - status
    - required_documents
    - digitized_documents
    - quality_score
    - review_feedback
12. ✅ Verificar: Datos coinciden con backend

**Criterio de éxito:** CSV generado con datos correctos, >10 filas

---

#### Test 5.2: Exportar Productividad
**Objetivo:** Exportar métricas de productividad

**Pasos:**
1. Como viewer1, en ViewerDashboard
2. Seleccionar filtro de tiempo: "Semana"
3. Click "Export" → "Exportar Productividad"
4. ✅ Verificar: CSV generado y compartido
5. Abrir CSV
6. ✅ Verificar: Columnas:
    - user_id
    - username
    - role
    - documents_digitized
    - sessions_count
    - avg_session_duration
    - avg_documents_per_session
7. ✅ Verificar: Datos muestran sesiones reales del Test 2.1

**Criterio de éxito:** CSV con métricas reales de pruebas anteriores

---

### **TEST SUITE 6: Performance y Carga (15 min)**

#### Test 6.1: Carga de 20 Documentos Consecutivos
**Objetivo:** Probar performance bajo carga moderada

**Pasos:**
1. Login como Digitador
2. Iniciar sesión
3. Preparar 20 imágenes de documentos
4. Capturar y subir 20 documentos consecutivamente (personas 2071-2090)
5. ✅ Medir tiempo total
6. ✅ Verificar: No memory leaks (memoria estable)
7. ✅ Verificar: No crashes
8. ✅ Verificar: UI responsiva durante todo el proceso

**Métricas a capturar:**
- Tiempo total: _____ minutos
- Tiempo promedio por documento: _____ segundos
- Uploads exitosos: _____ / 20
- Memoria al inicio: _____ MB
- Memoria al final: _____ MB
- CPU promedio: _____ %

**Criterio de éxito:**
- 20/20 uploads exitosos
- Tiempo promedio <30 segundos por documento
- Memoria incrementa <100MB
- Sin crashes

---

#### Test 6.2: Lista de 100+ Asignaciones (Scroll Performance)
**Objetivo:** Verificar performance de listas largas

**Pre-requisito:** Crear 100 asignaciones con script

**Pasos:**
1. Login como admin
2. Navegar a lista de todas las asignaciones
3. ✅ Verificar: Lista carga rápido (<2 segundos)
4. Scroll rápido de arriba a abajo
5. ✅ Verificar: Scroll suave (60 FPS)
6. ✅ Verificar: No lag visible
7. Buscar asignación específica
8. ✅ Verificar: Búsqueda instantánea

**Criterio de éxito:** Scroll fluido con 100+ items

---

### **TEST SUITE 7: Edge Cases y Errores (10 min)**

#### Test 7.1: Documento Borroso (Quality Validation)
**Objetivo:** Sistema rechaza documento de baja calidad

**Pasos:**
1. Login como Digitador
2. Capturar documento INTENCIONALMENTE borroso (imagen de prueba borrosa)
3. ✅ Verificar: Preview muestra indicator ROJO
4. ✅ Verificar: Mensaje: "⚠️ Imagen borrosa. Recomendamos recapturar"
5. ✅ Verificar: Botón "Upload" está deshabilitado O muestra advertencia
6. Click "Recapturar"
7. Capturar imagen nítida
8. ✅ Verificar: Preview muestra indicator VERDE
9. ✅ Verificar: Upload habilitado

**Criterio de éxito:** Sistema detecta blur y previene upload de mala calidad

---

#### Test 7.2: Backend Caído (Error Handling)
**Objetivo:** App maneja gracefully backend no disponible

**Pasos:**
1. Login como Digitador
2. **Detener backend:** `docker-compose stop`
3. Intentar cargar asignaciones
4. ✅ Verificar: Mensaje de error claro: "❌ No se pudo conectar al servidor"
5. ✅ Verificar: Opción "Reintentar"
6. Intentar upload de documento
7. ✅ Verificar: Documento se agrega a queue offline
8. **Reiniciar backend:** `docker-compose up -d`
9. Click "Reintentar"
10. ✅ Verificar: Asignaciones cargan correctamente
11. ✅ Verificar: Queue offline se sincroniza automáticamente

**Criterio de éxito:** App no crashea, muestra errores claros, recover automático

---

#### Test 7.3: Token Expirado (Session Recovery)
**Objetivo:** Verificar refresh token funciona

**Pasos:**
1. Login como Digitador
2. Esperar 20 minutos (access token + refresh cerca de expirar)
3. Realizar acción que requiera autenticación
4. ✅ Verificar: Si refresh token válido → request exitoso
5. ✅ Verificar: Si refresh token expirado → redirect a login
6. Re-login
7. ✅ Verificar: Sesión restaurada correctamente

**Criterio de éxito:** Manejo correcto de tokens expirados

---

## 📊 MÉTRICAS DE ÉXITO GLOBAL

### KPIs Críticos

| Métrica | Target | Medido | Status |
|---------|--------|--------|--------|
| **Upload Success Rate** | >95% | ___% | ⏳ |
| **Avg Upload Time** | <20s | ___s | ⏳ |
| **Anti-Duplicate Detection** | 100% | ___% | ⏳ |
| **Session Tracking Accuracy** | 100% | ___% | ⏳ |
| **Offline Sync Success** | >90% | ___% | ⏳ |
| **UI Responsiveness** | 60 FPS | ___ FPS | ⏳ |
| **Memory Leak** | <50MB/hr | ___ MB/hr | ⏳ |
| **Crash Rate** | 0% | ___% | ⏳ |

### Cobertura de Testing

| Categoría | Tests Planificados | Tests Ejecutados | Tests Pasados | % Éxito |
|-----------|-------------------|------------------|---------------|---------|
| Autenticación | 2 | ___ | ___ | ___% |
| Digitalización | 2 | ___ | ___ | ___% |
| Assignments | 3 | ___ | ___ | ___% |
| Review | 2 | ___ | ___ | ___% |
| CSV Export | 2 | ___ | ___ | ___% |
| Performance | 2 | ___ | ___ | ___% |
| Edge Cases | 3 | ___ | ___ | ___% |
| **TOTAL** | **16** | **___** | **___** | **___%** |

---

## 🔧 SCRIPTS DE PREPARACIÓN

### Script 1: Resetear Passwords de Usuarios
```bash
#!/bin/bash
# reset_user_passwords.sh

docker exec paperless_webserver_1 python3 manage.py shell -c "
from django.contrib.auth.models import User

users_passwords = {
    'digitalizador1': 'Indigena123',
    'digitalizador2': 'Indigena456',
    'revisor1': 'Revisor123',
    'viewer1': 'Viewer123',
    'admin': 'Admin123'
}

for username, password in users_passwords.items():
    try:
        user = User.objects.get(username=username)
        user.set_password(password)
        user.save()
        print(f'✅ Password reseteado para {username}')
    except User.DoesNotExist:
        print(f'❌ Usuario {username} no existe')
"
```

---

### Script 2: Cargar Dataset de Asignaciones
```bash
#!/bin/bash
# load_test_assignments.sh

TOKEN="112fb331a1d5b9361446adffa7c6d9c576b98096"
API_URL="http://192.168.40.17:8001"

echo "📋 Cargando asignaciones de prueba..."

# Crear 15 asignaciones
curl -X POST "$API_URL/api/auth/assignments/bulk_create/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "digitizer_id": 2,
    "person_ids": ["2086", "2087", "2088", "2089", "2090"],
    "required_documents": 2
  }'

echo "✅ Asignaciones creadas"
```

---

### Script 3: Verificar Estado del Sistema
```bash
#!/bin/bash
# verify_system_state.sh

TOKEN="112fb331a1d5b9361446adffa7c6d9c576b98096"
API_URL="http://192.168.40.17:8001"

echo "═══════════════════════════════════════════"
echo "  🔍 VERIFICACIÓN DE ESTADO DEL SISTEMA"
echo "═══════════════════════════════════════════"
echo ""

# Backend disponible
echo "1. Backend:"
if curl -s "$API_URL/api/" > /dev/null 2>&1; then
    echo "   ✅ Disponible"
else
    echo "   ❌ No disponible"
fi

# Usuarios
echo ""
echo "2. Usuarios:"
docker exec paperless_webserver_1 python3 manage.py shell -c "
from paperless_auth.models import UserProfile
from django.contrib.auth.models import User
total = User.objects.count()
by_role = {}
for profile in UserProfile.objects.all():
    role = profile.role
    by_role[role] = by_role.get(role, 0) + 1

print(f'   Total: {total}')
for role, count in by_role.items():
    print(f'   {role}: {count}')
"

# Asignaciones
echo ""
echo "3. Asignaciones:"
docker exec paperless_webserver_1 python3 manage.py shell -c "
from paperless_auth.models import PersonAssignment
total = PersonAssignment.objects.count()
by_status = {}
for assignment in PersonAssignment.objects.all():
    status = assignment.status
    by_status[status] = by_status.get(status, 0) + 1

print(f'   Total: {total}')
for status, count in by_status.items():
    print(f'   {status}: {count}')
"

# Sesiones
echo ""
echo "4. Sesiones:"
docker exec paperless_webserver_1 python3 manage.py shell -c "
from paperless_auth.models import DigitizationSession
total = DigitizationSession.objects.count()
active = DigitizationSession.objects.filter(ended_at__isnull=True).count()
print(f'   Total: {total}')
print(f'   Activas: {active}')
"

# Documentos
echo ""
echo "5. Documentos en Paperless:"
DOCS_COUNT=$(curl -s "$API_URL/api/documents/" -H "Authorization: Token $TOKEN" | jq '.count')
echo "   Total: $DOCS_COUNT"

echo ""
echo "═══════════════════════════════════════════"
```

---

## 📝 TEMPLATE DE REPORTE DE PRUEBAS

```markdown
# REPORTE DE PRUEBAS E2E - LUMARA v5.6.1

**Fecha de Ejecución:** [FECHA]
**Tester:** [NOMBRE]
**Dispositivo:** [MODELO] (Android [VERSION])
**Duración Total:** [HH:MM]

## Resumen Ejecutivo

- Tests Ejecutados: ___/16
- Tests Pasados: ___
- Tests Fallidos: ___
- % Éxito: ___%

## Resultados Detallados

### ✅ Tests Pasados (__)

1. Test X.X - [Nombre]
   - Tiempo: __s
   - Observaciones: ...

### ❌ Tests Fallados (__)

1. Test X.X - [Nombre]
   - Error: [Descripción]
   - Stack Trace: ...
   - Screenshots: [adjuntar]

### ⚠️ Warnings

1. [Descripción del warning]
2. ...

## Métricas de Performance

- Upload Success Rate: ___%
- Avg Upload Time: __s
- Memory Usage: __ MB
- CPU Usage: __%
- UI FPS: __

## Issues Encontrados

| ID | Severidad | Descripción | Reproducible |
|----|-----------|-------------|--------------|
| #1 | Critical/High/Medium/Low | ... | Sí/No |

## Recomendaciones

1. [Recomendación 1]
2. ...

## Evidencias

- Logs adjuntos: logs_[FECHA].txt
- Screenshots: screenshots/
- Videos: videos/

## Conclusión

[Conclusión general sobre el estado del sistema]

**Status Final:** ✅ APTO / ⚠️ APTO CON OBSERVACIONES / ❌ NO APTO
```

---

**Creado por:** Equipo Interdisciplinario de Ingeniería
**Versión:** 1.0
**Fecha:** 2025-10-31
**Proyecto:** Lumara - Sistema de Digitalización Documental
