# WORKFLOW SECUENCIAL DE AGENTES
## Guía de Ejecución Paso a Paso

**Fecha de Creación:** 2025-11-09
**Versión:** 1.0
**Propósito:** Clarificar que agentes se ejecutan SECUENCIALMENTE, no en paralelo

---

## ⚠️ REGLA DE ORO

**LOS AGENTES SE EJECUTAN UNO DESPUÉS DEL OTRO, NO EN PARALELO.**

**Excepción:** Solo paralelizar cuando las tareas son 100% independientes.

---

## 🚫 ANTI-PATTERN: Paralelización Incorrecta

### Ejemplo de LO QUE NO HACER:

```markdown
# ❌ MAL: Lanzar múltiples agentes juntos

Voy a usar 3 agentes para acelerar el proceso:

Task(subagent_type="Explore", model="haiku", prompt="Find all dashboard files...")
Task(subagent_type="Plan", model="sonnet", prompt="Plan admin digitization...")
Task(subagent_type="general-purpose", model="sonnet", prompt="Implement admin button...")

# Esperando resultados de los 3 agentes...
```

### ¿Por qué está MAL?

1. **Agente Plan** no tiene información de Agente Explore
   - No sabe qué archivos existen
   - Puede planificar modificar archivos incorrectos

2. **Agente Implementer** no tiene el plan
   - No sabe qué implementar exactamente
   - Puede crear código que contradice el plan

3. **Re-trabajo inevitable:**
   - Cuando llegan los resultados, hay conflictos
   - Hay que re-ejecutar agentes con información correcta
   - Tiempo perdido

---

## ✅ PATTERN CORRECTO: Workflow Secuencial

### Ejemplo de LO QUE SÍ HACER:

```markdown
# ✅ BIEN: Paso a paso con análisis entre pasos

═══════════════════════════════════════════════════════════
PASO 1: EXPLORACIÓN
═══════════════════════════════════════════════════════════

Voy a usar el Agente Explore para encontrar archivos relacionados:

Task(
  subagent_type="Explore",
  model="haiku",
  description="Find admin dashboard files",
  prompt="""
  Find all files related to admin dashboard in Lumara:

  1. Files matching *admin*dashboard*.dart
  2. Provider files for admin
  3. Navigation routes for admin

  Output: File list with descriptions
  Thoroughness: medium
  """
)

# ESPERANDO RESULTADO DEL AGENTE...
# (30 segundos - 2 minutos)

═══════════════════════════════════════════════════════════
RESULTADO DEL AGENTE EXPLORE:
═══════════════════════════════════════════════════════════

[Agente retorna:]
- lib/presentation/admin/admin_dashboard_screen.dart (screen principal)
- lib/presentation/providers/admin_provider.dart (state management)
- lib/core/navigation/app_router.dart (ruta: /admin/dashboard)
- lib/presentation/widgets/quick_action_card.dart (widget reutilizable)

═══════════════════════════════════════════════════════════
ANÁLISIS DEL RESULTADO:
═══════════════════════════════════════════════════════════

Ahora sé que:
- Screen principal está en admin_dashboard_screen.dart
- Ya existe widget reutilizable (quick_action_card.dart)
- No necesito crear nuevos archivos, solo modificar existente

Esta información la usaré en el siguiente paso.

═══════════════════════════════════════════════════════════
PASO 2: PLANIFICACIÓN (usando info de Paso 1)
═══════════════════════════════════════════════════════════

Ahora voy a planificar basándome en los archivos encontrados:

Task(
  subagent_type="Plan",
  model="sonnet",
  description="Plan admin digitization button",
  prompt="""
  Plan implementation of admin digitization button:

  Files encontrados por Explore:
  - admin_dashboard_screen.dart (modificar este)
  - quick_action_card.dart (reutilizar este widget)

  Goal: Agregar 5to botón "Capturar Documento"

  Deliverables:
  1. Exact line numbers to modify
  2. Import statements needed
  3. Code snippet for new button
  4. Testing checklist
  5. Risk assessment

  Thoroughness: very thorough
  """
)

# ESPERANDO RESULTADO DEL AGENTE...
# (1-3 minutos)

═══════════════════════════════════════════════════════════
RESULTADO DEL AGENTE PLAN:
═══════════════════════════════════════════════════════════

[Agente retorna:]
Plan de Implementación:

1. Files to modify:
   - lib/presentation/admin/admin_dashboard_screen.dart (línea 287)

2. Import needed:
   - import '../census/person_selection_screen.dart';

3. Code snippet:
   ```dart
   _buildQuickActionCard(
     icon: Icons.camera_alt,
     title: 'Capturar Documento',
     color: Colors.teal,
     onTap: () => Navigator.pushNamed(context, PersonSelectionScreen.route),
   ),
   ```

4. Testing checklist:
   - Admin login → ver 5 botones
   - Click botón → navega a PersonSelectionScreen
   - Captura completa funciona
   - No regresiones en otros 4 botones

5. Risk: Bajo (solo UI, no afecta lógica)

═══════════════════════════════════════════════════════════
ANÁLISIS DEL PLAN:
═══════════════════════════════════════════════════════════

El plan es claro y detallado:
- Solo 1 archivo a modificar (bajo riesgo)
- Widget ya existe (no crear nuevo)
- Testing simple (4 test cases)
- Riesgo bajo identificado

Decisión: Implementar manualmente (es <20 líneas)
NO necesito Agente Implementer para esto.

═══════════════════════════════════════════════════════════
PASO 3: IMPLEMENTACIÓN MANUAL
═══════════════════════════════════════════════════════════

Voy a usar la herramienta Edit para agregar el código:

Edit(
  file_path="lib/presentation/admin/admin_dashboard_screen.dart",
  old_string="...",
  new_string="..."
)

# Implementación completa

═══════════════════════════════════════════════════════════
PASO 4: BUILD Y TESTING
═══════════════════════════════════════════════════════════

flutter clean
flutter pub get
flutter build apk --release

./scripts/test_apk_before_release.sh build/app/outputs/flutter-apk/app-release.apk

# Testing manual con checklist del Plan
```

---

## 📊 COMPARACIÓN: Paralelo vs Secuencial

### Escenario: Implementar Admin Digitization

| Aspecto | Paralelo (❌) | Secuencial (✅) |
|---------|--------------|-----------------|
| **Tiempo inicial** | 2 min (todos a la vez) | 6 min (uno por uno) |
| **Re-trabajo** | 15-30 min (conflictos) | 0 min (sin conflictos) |
| **Tiempo total** | 17-32 min | 6 min |
| **Calidad output** | Baja (contradicciones) | Alta (coherente) |
| **Riesgo de error** | Alto | Bajo |
| **Debugging** | Difícil (múltiples fuentes) | Fácil (paso a paso) |

**Conclusión:** Secuencial es MÁS RÁPIDO porque evita re-trabajo.

---

## ✅ CASOS VÁLIDOS DE PARALELIZACIÓN

### Caso 1: Lectura de Múltiples Archivos Independientes

```markdown
# ✅ OK: Archivos no relacionados

Voy a leer 3 archivos que no dependen entre sí:

Read("lib/core/constants/api_constants.dart")
Read("pubspec.yaml")
Read("android/app/build.gradle")

# Estos son independientes, paralelizar está bien
```

### Caso 2: Búsquedas en Diferentes Directorios

```markdown
# ✅ OK: Búsquedas independientes

Grep(pattern="TODO", path="lib/presentation/", output_mode="count")
Grep(pattern="FIXME", path="lib/data/", output_mode="count")
Grep(pattern="HACK", path="lib/services/", output_mode="count")

# Cada búsqueda es independiente
```

### Caso 3: Comandos Bash Independientes

```markdown
# ✅ OK: Verificaciones independientes

Bash("git status")
Bash("docker ps")
Bash("flutter doctor")

# Ninguno depende del resultado del otro
```

### Caso 4: Generación de Docs + Tests (Raro)

```markdown
# ✅ OK (pero raro): Tareas completamente independientes

Task(subagent_type="Explore", model="haiku",
     prompt="Generate updated README.md for v5.7.0")

Task(subagent_type="general-purpose", model="sonnet",
     prompt="Generate tests for EXISTING AdminDashboardScreen (no changes, just tests for current code)")

# Ambos trabajan en código existente, sin modificar
# Documentación no afecta tests, tests no afectan docs
```

---

## 🎯 REGLA PRÁCTICA SIMPLE

**Pregúntate:**

1. ¿El Agente B necesita información del Agente A?
   - **SÍ** → Ejecutar secuencialmente ✅
   - **NO** → Considerar paralelo (raro)

2. ¿Voy a analizar el resultado antes del siguiente paso?
   - **SÍ** → Ejecutar secuencialmente ✅
   - **NO** → ¿Por qué no? Deberías analizar

3. ¿Estoy 100% seguro de que son independientes?
   - **NO** → Ejecutar secuencialmente ✅
   - **SÍ** → Verificar dos veces, luego considerar paralelo

**REGLA DE ORO:**
> **En caso de duda, ejecuta secuencialmente.**
> **Mejor lento y correcto que rápido y erróneo.**

---

## 📝 PLANTILLA DE WORKFLOW SECUENCIAL

```markdown
═══════════════════════════════════════════════════════════
FEATURE: [Nombre de la feature]
FECHA: [YYYY-MM-DD]
═══════════════════════════════════════════════════════════

PASO 1: EXPLORACIÓN
-------------------
Agente: Explore
Objetivo: [Qué información necesito]
Prompt: [Prompt completo]

ESPERANDO RESULTADO...

RESULTADO:
[Copiar output del agente aquí]

ANÁLISIS:
[Mi interpretación del resultado]
[Qué usaré en el siguiente paso]

═══════════════════════════════════════════════════════════

PASO 2: PLANIFICACIÓN
---------------------
Agente: Plan
Objetivo: [Qué planeo basándome en Paso 1]
Información del Paso 1: [Resumen de lo relevante]
Prompt: [Prompt completo]

ESPERANDO RESULTADO...

RESULTADO:
[Copiar plan del agente aquí]

ANÁLISIS:
[Mi evaluación del plan]
[Decisión: implementar manual o con agente?]

═══════════════════════════════════════════════════════════

PASO 3: IMPLEMENTACIÓN
----------------------
[Si manual: usar Edit/Write]
[Si con agente: usar general-purpose con plan incluido]

ESPERANDO RESULTADO...

═══════════════════════════════════════════════════════════

PASO 4: TESTING
--------------
[Build + testing manual]

RESULTADO:
[Tests pasaron? Logs?]

═══════════════════════════════════════════════════════════

PASO 5: CODE REVIEW (antes de commit)
-------------------------------------
Agente: Explore (Code Reviewer)
Prompt: [Review del código implementado]

ESPERANDO RESULTADO...

RESULTADO:
[Approval? Issues?]

═══════════════════════════════════════════════════════════

PASO 6: COMMIT + TAG
-------------------
git add .
git commit -m "..."
git tag vX.X.X

═══════════════════════════════════════════════════════════
FEATURE COMPLETADA
═══════════════════════════════════════════════════════════
```

---

## 🆘 TROUBLESHOOTING

### Problema: "Tardé mucho esperando agentes"

**Causa:** Workflow secuencial es inherentemente más lento que paralelo.

**Solución:**
- Esto es NORMAL y ESPERADO
- Secuencial previene re-trabajo que tomaría MÁS tiempo
- Si urgencia extrema: implementar manual sin agentes

### Problema: "Agente retornó error / output incompleto"

**Causa:** Agente no entendió prompt o tuvo problema técnico.

**Solución:**
1. NO continuar con siguiente agente
2. Revisar prompt del agente que falló
3. Re-ejecutar con prompt mejorado
4. Solo continuar cuando output sea satisfactorio

### Problema: "Quiero ir más rápido"

**Causa:** Impaciencia (comprensible).

**Solución:**
- Para features simples (<50 líneas): implementar manual
- Para features medianas: usar solo Agente Plan, implementar manual
- Para features grandes: usar workflow completo (vale la pena)

---

## 📖 REFERENCIAS

- **CLAUDE.md:** Guía completa de subagentes (sección actualizada)
- **ESTRATEGIA_DEFINITIVA_RECUPERACION.md:** Contexto del círculo vicioso
- **AGENTES_EXPERTOS_NECESARIOS.md:** 8 agentes con prompts

---

**Fin del Documento de Workflow Secuencial**
**Versión:** 1.0 - 2025-11-09
