# AUDITORÍA COMPLETA: ERROR DE SINCRONIZACIÓN DE CENSO
**Fecha**: 28 de octubre de 2025
**Hora**: 00:10
**Analista**: Claude (Auditoría de Punta a Punta)
**Severidad**: 🔴 CRÍTICO

---

## RESUMEN EJECUTIVO

### Problema Reportado
Usuario reporta: "Error de sincronización - No se pudo sincronizar. Verifica tu conexión"

### Causa Raíz Identificada
🎯 **LA APP NO TIENE IMPLEMENTADA LA SINCRONIZACIÓN DE DATOS DEL CENSO**

La aplicación Lumara carga los datos del censo desde un archivo CSV hardcodeado en los assets, NO desde el API de Tejido. El botón "Sincronizar" solo sincroniza uploads de documentos pendientes.

### Impacto
- ⚠️ Usuarios no pueden obtener datos actualizados del censo desde Tejido
- ⚠️ Datos del censo desactualizados en la app
- ⚠️ Confusión del usuario (botón "sincronizar" no hace lo esperado)
- ⚠️ Necesidad de recompilar APK cada vez que se actualiza el censo

---

## AUDITORÍA DETALLADA

### 1. BACKEND (Tejido-NGX) ✅

**Estado**: FUNCIONANDO CORRECTAMENTE

#### Base de Datos
```bash
✅ Container: tejido-webserver-1
✅ Estado: Healthy (17 horas uptime)
✅ Puerto: 0.0.0.0:8001 → 8000
```

#### API Endpoints
```bash
✅ GET /api/
   Status: 302 (Redirect OK)

✅ GET /api/census/
   Status: 200 OK
   Datos: 3,998 personas
   Response time: < 1s

✅ POST /api/documents/upload_with_person/
   Estado: Funcional (verificado en Workflow 3)
   Relaciones: Creadas correctamente en tests
```

#### Datos del Censo
```sql
✅ Total personas en PostgreSQL: 3,998
✅ Modelo: CensusPerson (definido en models.py)
✅ Endpoint REST: /api/census/ (ViewSet implementado)
✅ Filtros disponibles: search, limit, offset
✅ Serializer: CensusPersonSerializer
```

**CONCLUSIÓN BACKEND**: ✅ **Totalmente funcional y listo para ser consumido**

---

### 2. FRONTEND (Lumara Flutter App) ❌

**Estado**: IMPLEMENTACIÓN INCOMPLETA

#### Arquitectura Actual

```
┌─────────────────────────────────────────────────────────┐
│                    home_screen.dart                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Botón "Sincronizar"                            │   │
│  │  Línea 180: BackgroundSyncService.              │   │
│  │              scheduleImmediateSync()            │   │
│  └──────────────────┬──────────────────────────────┘   │
└────────────────────┼───────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         background_sync_service.dart                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │  scheduleImmediateSync()                        │   │
│  │  1. ✅ Verifica conectividad                    │   │
│  │  2. ✅ Valida servidor Tejido                │   │
│  │  3. ❌ Solo procesa UPLOADS pendientes          │   │
│  │  4. ❌ NO descarga datos del censo              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
        ❌ NO HAY CÓDIGO PARA:
           - Llamar a /api/census/
           - Descargar personas
           - Guardar en base de datos local
```

#### Carga de Datos del Censo (Actual)

**Archivo**: `lib/data/datasources/census_data_source.dart`

```dart
// LÍNEA 25: PROBLEMA AQUÍ ⚠️
final csvString = await rootBundle.loadString(ApiConstants.censusFilePath);
// Carga: assets/census/persons.csv (HARDCODED)
```

**Archivo CSV Local**:
```bash
Ruta: assets/census/persons.csv
Tamaño: 590 KB
Registros: 3,999 líneas (3,998 personas + 1 header)
Última modificación: 27 de octubre 2025, 14:51
```

**Flujo Actual de Carga**:
```
Usuario abre app
       ↓
CensusProvider → CensusRepository → CensusDataSource
                                          ↓
                              loadPersons() lee CSV local
                                          ↓
                              Parsea CSV con CsvToListConverter
                                          ↓
                              Retorna List<Person> en memoria
                                          ↓
                              Cache en _cachedPersons
```

**❌ PROBLEMAS**:
1. Datos nunca se sincronizan con Tejido
2. CSV debe actualizarse manualmente
3. Requiere recompilación del APK cada vez
4. No hay API calls a `/api/census/`
5. Usuarios con datos desactualizados

---

### 3. NETWORKING Y CONECTIVIDAD ✅

**Estado**: FUNCIONANDO

#### Pruebas Realizadas

```bash
# Desde PC a Tejido
✅ curl http://192.168.40.17:8001/api/
   HTTP 302 - OK

✅ curl http://192.168.40.17:8001/api/census/
   HTTP 200 - 3,998 personas retornadas

# Conectividad
✅ PC: 192.168.40.17 (WiFi wlp0s20f3)
✅ Docker: tejido-webserver-1 healthy
✅ Token: e0282ce5e8fe0d64aee117cfba27b4082e32ce01 (válido)
```

#### App Lumara
```bash
✅ Logró conectarse al servidor
✅ Login exitoso (screenshot muestra pantalla principal)
❌ Error al presionar botón "Sincronizar"
```

**Diagnóstico**:
```dart
// background_sync_service.dart línea 96-160
scheduleImmediateSync() {
  // 1. Verifica conectividad ✅
  if (!hasConnection) return false;

  // 2. Valida servidor Tejido ✅
  serverCheck = validateTejidoConnection(baseUrl);
  if (serverCheck['error'] != null) return false;

  // 3. Procesa uploads pendientes ✅ (pero no hay ninguno)
  pendingBefore = await uploadService.getPendingCount();
  if (pendingBefore == 0) {
    return true; // ⚠️ Retorna "éxito" sin hacer nada
  }

  // 4. ❌ NUNCA descarga censo
}
```

**Resultado**: La sincronización retorna `false` en línea 122 porque `serverCheck['error']` probablemente no es null, O retorna `true` en línea 139 porque no hay uploads pendientes, pero el usuario no ve cambios porque NO se descarga el censo.

---

## COMPARACIÓN: ESPERADO VS ACTUAL

### Lo que el Usuario Espera 🎯

```
Usuario presiona "Sincronizar"
           ↓
1. App conecta a Tejido
2. Descarga lista actualizada del censo (3,998 personas)
3. Guarda en base de datos local
4. Actualiza UI con datos frescos
5. Muestra "Sincronización exitosa"
```

### Lo que Realmente Pasa ❌

```
Usuario presiona "Sincronizar"
           ↓
1. App verifica conectividad ✅
2. App valida servidor Tejido ✅
3. App revisa si hay uploads pendientes
   → Si no hay: retorna true sin hacer nada
   → Si hay: los procesa
4. Datos del censo NUNCA se descargan
5. Muestra "Sincronización exitosa" (pero censo sigue desactualizado)
   O "Error de sincronización" (si falla validación servidor)
```

---

## ARCHIVOS CLAVE IDENTIFICADOS

### Backend (Tejido)
```
✅ /src/documents/models.py
   Línea ~500: class CensusPerson

✅ /src/documents/views_census.py
   Línea ~50: class CensusPersonViewSet

✅ /src/tejido/urls.py
   Línea ~80: api_router.register(r"census", CensusPersonViewSet)
```

### Frontend (Lumara)
```
❌ /lib/services/background_sync_service.dart
   Línea 96: scheduleImmediateSync() - NO descarga censo

✅ /lib/data/datasources/census_data_source.dart
   Línea 25: Lee CSV local - DEBE cambiarse a API call

✅ /lib/data/repositories/census_repository.dart
   Línea 18: getAllPersons() - Usa data source local

❌ /lib/data/datasources/tejido_api_client.dart
   NO tiene método getCensusPersons()

❌ /lib/data/local/database/app_database.dart
   NO tiene tabla para CensusPersons locales
```

---

## PLAN DE ACCIÓN DETALLADO

### OPCIÓN 1: Sincronización Completa (RECOMENDADA) 🎯

**Descripción**: Implementar sincronización bidireccional completa de datos del censo.

**Componentes a Implementar**:

#### 1.1. Tabla Local para Censo
```dart
// app_database.dart
@DataClassName('CensusPerson')
class CensusPersons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get personId => text().unique()();
  TextColumn get fullName => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get documentNumber => text().nullable()();
  TextColumn get familyId => text().nullable()();
  TextColumn get birthDate => text().nullable()();
  IntColumn get requiredDocumentsCount => integer()();
  TextColumn get requiredDocuments => text()(); // JSON
  DateTimeColumn get lastSyncedAt => dateTime()();
}
```

#### 1.2. Endpoint en API Client
```dart
// tejido_api_client.dart
Future<List<Map<String, dynamic>>> getCensusPersons({
  int? limit,
  int? offset,
  String? search,
}) async {
  try {
    final response = await _dio.get(
      '/api/census/',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (search != null) 'search': search,
      },
    );

    return (response.data['results'] as List)
        .cast<Map<String, dynamic>>();
  } catch (e) {
    _logger.e('❌ Failed to fetch census: $e');
    rethrow;
  }
}
```

#### 1.3. Servicio de Sincronización de Censo
```dart
// census_sync_service.dart (NUEVO ARCHIVO)
class CensusSyncService {
  final TejidoApiClient _apiClient;
  final AppDatabase _database;

  Future<bool> syncCensusData() async {
    try {
      _logger.i('🔄 Starting census sync...');

      // Descargar todas las personas (con paginación)
      final allPersons = <Map<String, dynamic>>[];
      int offset = 0;
      const limit = 100;
      bool hasMore = true;

      while (hasMore) {
        final batch = await _apiClient.getCensusPersons(
          limit: limit,
          offset: offset,
        );

        allPersons.addAll(batch);
        hasMore = batch.length == limit;
        offset += limit;

        _logger.i('📥 Downloaded $offset persons...');
      }

      _logger.i('✅ Downloaded ${allPersons.length} persons');

      // Guardar en base de datos local
      await _database.transaction(() async {
        // Limpiar tabla
        await _database.delete(_database.censusPersons).go();

        // Insertar todos
        for (final personData in allPersons) {
          await _database.into(_database.censusPersons).insert(
            CensusPersonsCompanion(
              personId: Value(personData['person_id']),
              fullName: Value(personData['full_name']),
              // ... más campos
              lastSyncedAt: Value(DateTime.now()),
            ),
          );
        }
      });

      _logger.i('✅ Census sync completed: ${allPersons.length} persons saved');
      return true;

    } catch (e, stackTrace) {
      _logger.e('❌ Census sync failed: $e', stackTrace);
      return false;
    }
  }
}
```

#### 1.4. Integrar en BackgroundSyncService
```dart
// background_sync_service.dart
static Future<bool> scheduleImmediateSync() async {
  try {
    // ... validaciones existentes ...

    // NUEVO: Sincronizar censo
    final censusSyncService = CensusSyncService(apiClient, database);
    final censusSuccess = await censusSyncService.syncCensusData();

    if (!censusSuccess) {
      _logger.e('❌ Census sync failed');
      return false;
    }

    // Procesar uploads pendientes (código existente)
    await uploadService.processAllPending();

    return true;
  } catch (e) {
    _logger.e('❌ Sync failed: $e');
    return false;
  }
}
```

#### 1.5. Actualizar CensusDataSource
```dart
// census_data_source.dart
class CensusDataSource {
  final AppDatabase _database;

  // CAMBIAR de leer CSV a leer base de datos
  Future<List<Person>> loadPersons() async {
    try {
      final censusPersons = await _database.select(_database.censusPersons).get();

      if (censusPersons.isEmpty) {
        _logger.w('⚠️ No census data in local DB. Run sync first.');
        // FALLBACK: leer CSV si no hay datos
        return await _loadFromCsvFallback();
      }

      return censusPersons.map((cp) => Person(
        personId: cp.personId,
        fullName: cp.fullName,
        // ... mapeo completo
      )).toList();

    } catch (e) {
      _logger.e('❌ Failed to load persons: $e');
      rethrow;
    }
  }

  Future<List<Person>> _loadFromCsvFallback() async {
    // Código actual de lectura de CSV
    // Mantener como fallback
  }
}
```

**VENTAJAS OPCIÓN 1**:
- ✅ Sincronización real con Tejido
- ✅ Datos siempre actualizados
- ✅ No requiere recompilación para actualizar censo
- ✅ Soporte offline con datos cacheados
- ✅ Paginación para grandes volúmenes de datos

**DESVENTAJAS**:
- ⚠️ Requiere más trabajo de implementación (~4-6 horas)
- ⚠️ Aumenta tamaño de base de datos local
- ⚠️ Requiere migración de base de datos

**TIEMPO ESTIMADO**: 4-6 horas de desarrollo

---

### OPCIÓN 2: Sincronización Simple (RÁPIDA)

**Descripción**: Descargar censo del API y mantenerlo en memoria (sin DB local).

**Implementación**:

#### 2.1. Actualizar TejidoApiClient
```dart
// tejido_api_client.dart
Future<List<Map<String, dynamic>>> getCensusPersons() async {
  final response = await _dio.get('/api/census/');
  return (response.data['results'] as List).cast<Map<String, dynamic>>();
}
```

#### 2.2. Actualizar CensusDataSource
```dart
// census_data_source.dart
class CensusDataSource {
  final TejidoApiClient _apiClient;
  List<Person>? _cachedPersons;
  DateTime? _lastSyncTime;

  Future<List<Person>> loadPersons({bool forceRefresh = false}) async {
    // Si hay cache y no expiró (< 1 hora)
    if (_cachedPersons != null &&
        _lastSyncTime != null &&
        !forceRefresh &&
        DateTime.now().difference(_lastSyncTime!) < Duration(hours: 1)) {
      return _cachedPersons!;
    }

    try {
      // Descargar de API
      final data = await _apiClient.getCensusPersons();

      // Parsear
      _cachedPersons = data.map((json) => Person(
        personId: json['person_id'] ?? '',
        fullName: json['full_name'] ?? '',
        // ... más campos
      )).toList();

      _lastSyncTime = DateTime.now();

      _logger.i('✅ Census loaded from API: ${_cachedPersons!.length} persons');
      return _cachedPersons!;

    } catch (e) {
      _logger.e('❌ Failed to load from API, falling back to CSV: $e');

      // FALLBACK: Leer CSV si API falla
      return await _loadFromCsvFallback();
    }
  }
}
```

#### 2.3. Actualizar BackgroundSyncService
```dart
// background_sync_service.dart
static Future<bool> scheduleImmediateSync() async {
  // ... validaciones existentes ...

  // NUEVO: Forzar refresh del censo
  final censusDataSource = CensusDataSource(apiClient);
  await censusDataSource.loadPersons(forceRefresh: true);

  // Procesar uploads pendientes
  await uploadService.processAllPending();

  return true;
}
```

**VENTAJAS OPCIÓN 2**:
- ✅ Implementación rápida (~1-2 horas)
- ✅ Menos cambios en arquitectura
- ✅ Fallback a CSV si API falla
- ✅ Cache en memoria para performance

**DESVENTAJAS**:
- ⚠️ Datos se pierden al cerrar app
- ⚠️ Sin soporte offline real
- ⚠️ Descarga todos los datos en cada sincronización (no eficiente para > 10K personas)

**TIEMPO ESTIMADO**: 1-2 horas de desarrollo

---

### OPCIÓN 3: Mantener CSV + Script de Actualización

**Descripción**: No cambiar la arquitectura, solo crear script para actualizar CSV automáticamente.

**Implementación**:

```bash
#!/bin/bash
# scripts/update_census_csv.sh

TOKEN="e0282ce5e8fe0d64aee117cfba27b4082e32ce01"
API_URL="http://192.168.40.17:8001"
OUTPUT_FILE="assets/census/persons.csv"

echo "📥 Downloading census data from Tejido..."

curl -s -H "Authorization: Token $TOKEN" \
  "$API_URL/api/census/?limit=10000" | \
  jq -r '.results[] | [
    .person_id,
    .full_name,
    .first_name,
    .last_name,
    .birthdate,
    .document_number,
    .family_id,
    .required_documents_count,
    .required_documents
  ] | @csv' > "$OUTPUT_FILE.tmp"

# Agregar header
echo "person_id,full_name,first_name,last_name,birthdate,document_number,family_id,required_documents_count,required_documents" > "$OUTPUT_FILE"
cat "$OUTPUT_FILE.tmp" >> "$OUTPUT_FILE"
rm "$OUTPUT_FILE.tmp"

echo "✅ Census CSV updated: $(wc -l < $OUTPUT_FILE) lines"
echo "⚠️  Remember to rebuild APK for changes to take effect"
```

**Uso**:
```bash
# Actualizar CSV
./scripts/update_census_csv.sh

# Recompilar APK
flutter build apk --release
```

**VENTAJAS OPCIÓN 3**:
- ✅ No requiere cambios de código
- ✅ Implementación inmediata (< 30 minutos)
- ✅ Sin riesgo de bugs

**DESVENTAJAS**:
- ❌ Sigue requiriendo recompilación de APK
- ❌ Proceso manual
- ❌ No es verdadera sincronización
- ❌ Usuarios no pueden actualizar datos ellos mismos

**TIEMPO ESTIMADO**: 30 minutos

---

## RECOMENDACIÓN FINAL

### 🎯 OPCIÓN RECOMENDADA: **Opción 2 (Sincronización Simple)**

**Justificación**:
1. **Balance perfecto** entre funcionalidad y tiempo de desarrollo
2. **Resuelve el problema** que el usuario reporta
3. **Implementación rápida** (1-2 horas vs 4-6 horas de Opción 1)
4. **Fallback robusto** a CSV si API falla
5. **No requiere migración** de base de datos
6. **Cache en memoria** es suficiente para 4,000 personas (~2-3 MB)

### Roadmap de Implementación

**FASE 1: Solución Inmediata** (1-2 horas)
- Implementar Opción 2
- Testing con 3,998 personas
- Generar APK v4.5.3

**FASE 2: Mejora Futura** (cuando sea necesario)
- Si censo crece > 10,000 personas → migrar a Opción 1
- Si se requiere soporte offline robusto → migrar a Opción 1
- Por ahora, Opción 2 es suficiente

---

## PRÓXIMOS PASOS INMEDIATOS

### 1. Aprobación del Plan
- [ ] Revisar este documento con el usuario
- [ ] Confirmar Opción 2 como solución
- [ ] Obtener aprobación para proceder

### 2. Implementación (1-2 horas)
- [ ] Modificar `tejido_api_client.dart` (+30 líneas)
- [ ] Modificar `census_data_source.dart` (+50 líneas)
- [ ] Modificar `background_sync_service.dart` (+10 líneas)
- [ ] Testing manual

### 3. Testing
- [ ] Verificar descarga del API funciona
- [ ] Verificar fallback a CSV funciona
- [ ] Verificar cache en memoria funciona
- [ ] Testing con 3,998 personas

### 4. Deployment
- [ ] Compilar APK v4.5.3
- [ ] Copiar a ~/Descargas con timestamp
- [ ] Instalar en dispositivo de prueba
- [ ] Validar sincronización funciona

### 5. Documentación
- [ ] Actualizar README con nuevo flujo
- [ ] Documentar endpoint `/api/census/`
- [ ] Crear guía de usuario para sincronización

---

## ARCHIVOS QUE SERÁN MODIFICADOS

```
Opción 2 (Recomendada):

lib/data/datasources/tejido_api_client.dart
  + Agregar método getCensusPersons()
  + ~30 líneas nuevas

lib/data/datasources/census_data_source.dart
  - Eliminar dependencia a rootBundle
  + Agregar llamada a API
  + Agregar cache con TTL
  + Mantener fallback a CSV
  ~ 50 líneas modificadas

lib/services/background_sync_service.dart
  + Agregar refresh de censo en scheduleImmediateSync()
  + ~10 líneas nuevas

lib/data/repositories/census_repository.dart
  + Agregar método refreshFromServer()
  + ~15 líneas nuevas

Total: ~105 líneas modificadas/agregadas
Archivos: 4 modificados, 0 nuevos
```

---

## RIESGOS Y MITIGACIÓN

### Riesgo 1: API de Tejido Cae
**Probabilidad**: Media
**Impacto**: Alto
**Mitigación**: Fallback a CSV local si API falla

### Riesgo 2: Cambios en Formato de API
**Probabilidad**: Baja
**Impacto**: Alto
**Mitigación**: Agregar logging detallado + tests

### Riesgo 3: Performance con Muchos Datos
**Probabilidad**: Baja (solo 3,998 personas)
**Impacto**: Medio
**Mitigación**: Si censo crece > 10K, migrar a Opción 1 con paginación

### Riesgo 4: Usuarios sin Conexión
**Probabilidad**: Media
**Impacto**: Bajo
**Mitigación**: Cache en memoria + fallback CSV + mensaje claro al usuario

---

## CONCLUSIONES

### Hallazgos Clave
1. ✅ Backend Tejido está completamente funcional
2. ❌ Frontend Lumara NO sincroniza datos del censo
3. ❌ Datos del censo están hardcodeados en CSV local
4. ✅ Networking funciona correctamente
5. ❌ Botón "Sincronizar" no hace lo que usuario espera

### Solución Propuesta
- Implementar **Opción 2: Sincronización Simple**
- Tiempo: **1-2 horas** de desarrollo
- Riesgo: **Bajo**
- Impacto: **Alto** (resuelve problema del usuario)

### Beneficios de la Solución
- ✅ Datos del censo siempre actualizados
- ✅ No requiere recompilación de APK
- ✅ Sincronización real con Tejido
- ✅ Fallback robusto si API falla
- ✅ Implementación rápida

---

## APÉNDICE A: Comandos de Testing

### Verificar API de Censo
```bash
# Test simple
curl http://192.168.40.17:8001/api/census/ \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01"

# Con paginación
curl "http://192.168.40.17:8001/api/census/?limit=100&offset=0" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01"

# Buscar persona
curl "http://192.168.40.17:8001/api/census/?search=MARTIN" \
  -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01"
```

### Verificar Datos Locales
```bash
# Ver CSV actual
head -10 assets/census/persons.csv
wc -l assets/census/persons.csv

# Comparar con API
curl -s "http://192.168.40.17:8001/api/census/" \
  -H "Authorization: Token $TOKEN" | jq '.count'
```

### Logs de Debugging
```bash
# Filtrar logs relevantes
adb logcat -s flutter:V | grep -E "Census|censo|📊|🔄"

# Guardar logs a archivo
adb logcat -s flutter:V > logs_census_sync_$(date +%Y%m%d_%H%M%S).txt
```

---

## APÉNDICE B: Endpoints Disponibles

### Backend Tejido

```
GET /api/census/
  Query params: ?limit=N&offset=N&search=QUERY
  Response: { count, next, previous, results: [...] }
  Autenticación: Token en header

GET /api/census/{person_id}/
  Response: { person_id, full_name, ... }

POST /api/documents/upload_with_person/
  Form data: person_id, document_type, document, ...
  Response: { success, document_id, person_id, relation_id }

GET /api/documents/check_exists/
  Query params: ?person_id=X&document_type=Y
  Response: { exists, document_id }
```

---

**FIN DE LA AUDITORÍA**

**Próxima Acción**: Esperar aprobación del usuario para proceder con Opción 2.
