# AGENTES EXPERTOS NECESARIOS
## Análisis de Subagentes AI Assistant para Proyecto Lumara

**Basado en:** CLAUDE.md v2.0 + ESTRATEGIA_DEFINITIVA_RECUPERACION.md
**Fecha:** 2025-11-09

---

## 🎯 RESUMEN EJECUTIVO

Para recuperar el proyecto y establecer proceso sostenible, necesitamos **4 tipos de subagentes especializados** en diferentes fases:

| Fase | Subagent Type | Model | Uso Principal | Frecuencia |
|------|---------------|-------|---------------|------------|
| **FASE 1: Estabilización** | Explore | haiku | Auditar baseline | Una vez |
| **FASE 2: Implementación** | Plan + Explore + general-purpose | sonnet/haiku | Desarrollar features | Por feature |
| **FASE 3: Sostenibilidad** | Explore + general-purpose | sonnet | Tests + Docs | Continuo |

---

## 📋 DETALLE POR FASE

### FASE 1: ESTABILIZACIÓN (Usar 1 vez)

#### Agente #1: **Explore - Baseline Auditor**
**Prompt sugerido:**
```markdown
Task(
  subagent_type="Explore",
  model="haiku",  # Económico para auditoría rápida
  description="Audit Lumara v5.7.0 baseline",
  prompt="""
  Audit current state of Lumara app in baseline (v5.7.0):

  1. **Feature Inventory:**
     - List all screens in lib/presentation/
     - Identify which features are implemented
     - Map routes in navigation

  2. **State Management:**
     - Find all Providers
     - Document state flow
     - Identify data sources

  3. **Known Issues:**
     - Search for TODO comments
     - Find FIXME markers
     - Identify deprecated code

  4. **Dependencies:**
     - Analyze pubspec.yaml
     - Check for outdated packages
     - Identify security issues

  5. **Testing Coverage:**
     - Count test files in test/
     - Estimate coverage percentage
     - Find untested critical paths

  Output: Markdown report with bullet points
  Thoroughness: very thorough
  """
)
```

**Output esperado:**
- Inventario completo de features actuales
- Mapa de providers y state management
- Lista de issues conocidos
- Recomendaciones de cleanup

**Uso:** Una sola vez al establecer baseline

---

### FASE 2: IMPLEMENTACIÓN (Por cada feature)

#### Agente #2: **Plan - Feature Planner**
**Cuándo usar:** Antes de implementar cualquier feature nueva

**Ejemplo: Admin Digitization**
```markdown
Task(
  subagent_type="Plan",
  model="sonnet",  # Calidad para análisis
  description="Plan admin digitization feature",
  prompt="""
  Plan implementation of "Admin can digitize documents" feature:

  Current state:
  - Admin role exists
  - AdminDashboardScreen shows 4 quick action cards
  - Only Digitizer has "Capturar Documento" button

  Goal:
  - Add "Capturar Documento" button to AdminDashboardScreen
  - Navigate to PersonSelectionScreen on tap
  - Maintain all existing admin functionality

  Deliverables:
  1. Files to modify (list with line numbers)
  2. New imports needed
  3. Code snippet for button
  4. Testing checklist (5 test cases)
  5. Risk assessment (breaking changes?)
  6. Estimated effort (hours)

  Thoroughness: very thorough
  """
)
```

**Output esperado:**
- Plan detallado step-by-step
- Archivos a modificar
- Riesgos identificados
- Testing strategy

**Uso:** Una vez por feature, ANTES de implementar

---

#### Agente #3: **Explore - Code Navigator**
**Cuándo usar:** Cuando necesitas encontrar archivos relacionados

**Ejemplo: Buscar todos los dashboards**
```markdown
Task(
  subagent_type="Explore",
  model="haiku",  # Rápido para búsqueda
  description="Find all dashboard implementations",
  prompt="""
  Find all dashboard screens in Lumara app:

  1. List all files matching *dashboard*.dart
  2. For each dashboard, identify:
     - User role (Admin, Digitizer, Reviewer, Viewer)
     - Quick action cards present
     - Routes and navigation
     - Providers used

  3. Create comparison table showing differences

  Output: Markdown with file paths and table
  Thoroughness: medium
  """
)
```

**Output esperado:**
- Lista de todos los dashboards
- Tabla comparativa
- Patrones identificados

**Uso:** Al inicio de cada feature que toca múltiples archivos

---

#### Agente #4: **general-purpose - Feature Implementer**
**Cuándo usar:** Para implementar features complejas (>100 líneas)

**Ejemplo: Implementar Instant IP Config**
```markdown
Task(
  subagent_type="general-purpose",
  model="sonnet",  # Máxima calidad
  description="Implement instant IP configuration",
  prompt="""
  Implement instant IP configuration feature in LoginScreen:

  Requirements:
  1. Add button "Configurar IP Manualmente" below QR button
  2. Dialog with two text fields:
     - IP address (default: 192.168.40.17)
     - Port (default: 8001)
  3. On confirm:
     - Build server URL: http://{ip}:{port}
     - Save to SharedPreferences (keys: server_url, server_name, is_configured)
     - Update _baseUrlController.text
     - Show success SnackBar
  4. Handle errors (empty fields, invalid format)

  Files to modify:
  - lib/presentation/auth/login_screen.dart (add button + method)
  - Add import for shared_preferences

  Testing:
  1. Button appears below QR button
  2. Dialog opens on tap
  3. Fields pre-filled with defaults
  4. Validation works
  5. SharedPreferences saves correctly
  6. URL field updates
  7. Login works with new URL

  Return:
  - Complete modified login_screen.dart
  - Test checklist
  - No TODOs or placeholders

  IMPORTANT: Implement EVERYTHING, no partial code.
  """
)
```

**Output esperado:**
- Código completo ready-to-use
- Tests checklist
- Sin TODOs pendientes

**Uso:** Por feature mediana/grande (evita implementar manualmente)

---

#### Agente #5: **general-purpose - Test Generator**
**Cuándo usar:** Después de implementar feature

**Ejemplo: Generar tests para Admin Dashboard**
```markdown
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Generate admin dashboard tests",
  prompt="""
  Generate comprehensive Flutter test suite for AdminDashboardScreen:

  Test Categories:

  1. Widget Rendering (3 tests):
     - Dashboard shows 5 quick action cards
     - All cards have correct titles
     - All cards have correct icons

  2. Navigation (5 tests):
     - "Ver Reportes" navigates to ReportsScreen
     - "Análisis de Brechas" navigates to GapAnalysisScreen
     - "Capturar Documento" navigates to PersonSelectionScreen
     - "Configuración" navigates to SettingsScreen
     - "Sincronizar" triggers sync action

  3. Permissions (2 tests):
     - Admin user sees all 5 cards
     - Non-admin user sees error

  4. State Management (2 tests):
     - Dashboard updates after data change
     - Loading state shows spinner

  Requirements:
  - Use flutter_test
  - Use mockito for Provider mocks
  - Each test independent (setUp/tearDown)
  - Descriptive test names

  Return complete test file ready to run with:
  flutter test test/presentation/admin/admin_dashboard_screen_test.dart
  """
)
```

**Output esperado:**
- Test file completo
- 12 test cases implementados
- Mocks configurados

**Uso:** Por feature implementada (automatiza testing)

---

### FASE 3: SOSTENIBILIDAD (Continuo)

#### Agente #6: **Explore - Code Reviewer**
**Cuándo usar:** Antes de merge a main

**Ejemplo: Review multi-perspectiva**
```markdown
Task(
  subagent_type="Explore",
  model="sonnet",
  description="Multi-perspective code review",
  prompt="""
  Perform code review of feature/admin-digitization branch:

  Analyze from 4 expert perspectives:

  1. **Flutter Engineer:**
     - Widget optimization (const constructors)
     - State management efficiency
     - Memory leaks (dispose)
     - Performance bottlenecks

  2. **UX Designer:**
     - Button placement intuitive?
     - Loading states clear?
     - Error messages helpful?
     - Accessibility (semantic labels)

  3. **Security Specialist:**
     - Input validation
     - Authorization checks (admin only?)
     - Data exposure in logs
     - Secure navigation

  4. **QA Tester:**
     - Edge cases covered?
     - Error handling complete?
     - Race conditions possible?
     - Regression risks

  Output format:
  # Code Review: feature/admin-digitization

  ## Critical Issues (Fix before merge)
  - [Issue with file:line]

  ## Improvements (Fix soon)
  - [Suggestion with file:line]

  ## Nice to Have
  - [Enhancement ideas]

  ## Approval Status
  [✅ Approved / ❌ Needs work]

  Thoroughness: very thorough
  """
)
```

**Output esperado:**
- Reporte detallado multi-perspectiva
- Issues clasificados por severidad
- Approval status

**Uso:** Antes de merge cada feature branch

---

#### Agente #7: **Explore - Documentation Generator**
**Cuándo usar:** Al final de cada sprint

**Ejemplo: Generar docs actualizadas**
```markdown
Task(
  subagent_type="Explore",
  model="haiku",  # Suficiente para docs
  description="Generate updated documentation",
  prompt="""
  Generate updated documentation for Lumara v5.7.3:

  1. **FEATURES.md:**
     - List all implemented features
     - User role for each feature
     - Status (✅ Working / ⚠️ Partial / ❌ Broken)

  2. **ARCHITECTURE.md update:**
     - Current folder structure
     - Design patterns used
     - Data flow diagram (ASCII)

  3. **CHANGELOG.md entry:**
     - Version 5.7.3
     - Added/Fixed/Changed sections
     - APK info and MD5

  4. **README.md update:**
     - Current version number
     - Installation instructions
     - Known issues section

  Output: 4 markdown files ready to commit
  Thoroughness: medium
  """
)
```

**Output esperado:**
- 4 archivos markdown actualizados
- Información sincronizada
- Ready to commit

**Uso:** Final de cada sprint o cada 3 features

---

#### Agente #8: **general-purpose - Debugging Specialist**
**Cuándo usar:** Cuando un bug es difícil de reproducir/entender

**Ejemplo: Debug "0 personas" issue**
```markdown
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Debug censo loading issue",
  prompt="""
  Debug why Lumara v5.6.0 shows "0 Personas" instead of 3998:

  Known facts:
  - v5.5.0 works (shows 3998)
  - v5.6.0 same CSV file
  - CSV verified in APK (3998 lines)
  - Code looks correct

  Files to analyze:
  1. lib/data/datasources/census_data_source.dart
     - CSV loading logic
     - Parsing errors?
  2. lib/data/repositories/census_repository.dart
     - Data transformation
     - Filtering bugs?
  3. lib/presentation/providers/census_provider.dart
     - State initialization
     - Async loading issues?
  4. lib/presentation/census/person_selection_screen.dart
     - UI binding
     - Empty state logic?

  Investigate:
  - Diff between v5.5.0 and v5.6.0 (if git history)
  - Async/await race conditions
  - Exception swallowing
  - Cache corruption
  - Provider initialization order

  Provide:
  1. Root cause (most likely hypothesis)
  2. Specific fix with code
  3. Testing steps to verify
  4. Prevention strategy

  Thoroughness: very thorough
  """
)
```

**Output esperado:**
- Root cause identificado
- Fix específico con código
- Testing checklist
- Prevention tips

**Uso:** Cuando bug es complejo y no obvio

---

## 🔄 WORKFLOW COMPLETO CON SUBAGENTES

### Feature Implementation Flow

```
INICIO DE FEATURE
    ↓
┌───────────────────────────────────────────────┐
│ 1. Explore Agent: Code Navigator             │
│    Find all related files                    │
│    Model: haiku (rápido)                     │
└───────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────┐
│ 2. Plan Agent: Feature Planner               │
│    Create implementation plan                 │
│    Model: sonnet (calidad)                   │
└───────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────┐
│ 3. general-purpose: Feature Implementer      │
│    Write complete code                        │
│    Model: sonnet (calidad)                   │
└───────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────┐
│ 4. general-purpose: Test Generator           │
│    Generate test suite                        │
│    Model: sonnet (cobertura)                 │
└───────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────┐
│ MANUAL: Run tests + device testing           │
│         ./scripts/test_apk_before_release.sh │
└───────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────┐
│ 5. Explore Agent: Code Reviewer              │
│    Multi-perspective review                   │
│    Model: sonnet (análisis)                  │
└───────────────────────────────────────────────┘
    ↓
    ¿Approved?
    ├─ NO → Fix issues → Volver a paso 4
    └─ YES ↓
┌───────────────────────────────────────────────┐
│ GIT: Commit + Merge + Tag                    │
└───────────────────────────────────────────────┘
    ↓
FIN DE FEATURE
```

---

## 📊 ESTIMACIÓN DE RECURSOS

### Por Feature (Ejemplo: Admin Digitization)

| Etapa | Subagent | Model | Tokens est. | Tiempo est. | Costo est. |
|-------|----------|-------|-------------|-------------|------------|
| 1. Code Navigator | Explore | haiku | 5K | 2 min | $0.02 |
| 2. Feature Planner | Plan | sonnet | 15K | 5 min | $0.30 |
| 3. Implementation | general-purpose | sonnet | 25K | 10 min | $0.50 |
| 4. Test Generation | general-purpose | sonnet | 20K | 8 min | $0.40 |
| 5. Code Review | Explore | sonnet | 15K | 5 min | $0.30 |
| **TOTAL** | - | - | **80K** | **30 min** | **~$1.50** |

**Manual work:** ~2-3 horas (testing, fixes, git)

**Total por feature:** ~3 horas (vs 8-10 horas sin subagentes)

---

## 🎓 APRENDIZAJES CLAVE

### ✅ Hacer (Best Practices)

1. **Usar Explore antes de implementar** → Evita reinventar rueda
2. **Usar Plan para features >50 líneas** → Ahorra refactors
3. **Delegar tests a general-purpose** → 100% coverage rápido
4. **Usar haiku para búsquedas** → Económico y suficiente
5. **Usar sonnet para código crítico** → Calidad justifica costo
6. **Paralelizar Reads/Greps independientes** → 3x más rápido
7. **Code review con Explore** → Encuentra issues antes de merge

### ❌ NO Hacer (Anti-patterns)

1. **NO implementar código manualmente** si >100 líneas
   → Delegar a general-purpose agent

2. **NO usar Grep/Glob directo** para búsquedas complejas
   → Usar Explore agent con thoroughness

3. **NO mezclar features en un prompt** a subagente
   → Un agent = una tarea específica

4. **NO usar sonnet para tareas simples**
   → Usar haiku (5x más barato)

5. **NO ignorar output de Plan agent**
   → Seguir plan evita refactors

6. **NO lanzar múltiples agents en paralelo** si dependen entre sí
   → Secuenciar: Explore → Plan → Implement

7. **NO dejar TODOs en código** de general-purpose
   → Especificar "implement everything, no placeholders"

---

## 📝 TEMPLATES DE PROMPTS

### Template 1: Explore - Find Related Files
```markdown
Task(
  subagent_type="Explore",
  model="haiku",
  description="Find files related to [FEATURE]",
  prompt="""
  Find all files related to [FEATURE_NAME] in Lumara:

  1. Search patterns:
     - File names matching *[keyword]*.dart
     - Classes/functions referencing [FeatureName]
     - Routes containing '[route_name]'

  2. For each file found, provide:
     - Full path
     - Primary responsibility (1 sentence)
     - Dependencies (imports)

  3. Create dependency graph (ASCII)

  Output: Markdown with file list + graph
  Thoroughness: [quick/medium/very thorough]
  """
)
```

### Template 2: Plan - Feature Planning
```markdown
Task(
  subagent_type="Plan",
  model="sonnet",
  description="Plan [FEATURE_NAME]",
  prompt="""
  Plan implementation of [FEATURE_NAME]:

  Current state:
  - [What exists now]

  Goal:
  - [What should exist after]

  Deliverables:
  1. Files to modify (with line numbers if possible)
  2. New files to create
  3. Dependencies to add (pubspec.yaml)
  4. Testing checklist (5-10 test cases)
  5. Risk assessment
  6. Estimated effort (hours)
  7. Breaking changes (yes/no)

  Thoroughness: very thorough
  """
)
```

### Template 3: general-purpose - Implementation
```markdown
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Implement [FEATURE_NAME]",
  prompt="""
  Implement [FEATURE_NAME] in [FILE_NAME]:

  Requirements:
  1. [Requirement 1]
  2. [Requirement 2]
  ...

  Files to modify:
  - [file1.dart] (line X-Y)
  - [file2.dart] (add import)

  Testing:
  - [Test case 1]
  - [Test case 2]
  ...

  Return:
  - Complete modified files
  - No TODOs or placeholders
  - All edge cases handled

  IMPORTANT: Implement EVERYTHING. No partial code.
  """
)
```

### Template 4: Explore - Code Review
```markdown
Task(
  subagent_type="Explore",
  model="sonnet",
  description="Review [BRANCH_NAME]",
  prompt="""
  Code review [BRANCH_NAME] from [N] expert perspectives:

  1. [Expert 1]: [Focus area]
  2. [Expert 2]: [Focus area]
  ...

  For each expert, identify:
  - Critical issues (block merge)
  - Improvements (fix soon)
  - Nice to have (future)

  Output:
  # Code Review: [BRANCH_NAME]
  ## Critical Issues
  ## Improvements
  ## Nice to Have
  ## Approval: [✅/❌]

  Thoroughness: very thorough
  """
)
```

---

## 🚀 PRÓXIMOS PASOS

### Acción Inmediata

1. **Ejecutar Agent #1** (Baseline Auditor):
   ```bash
   # En AI Assistant:
   Task(subagent_type="Explore", model="haiku", prompt="[usar prompt de arriba]")
   ```

2. **Revisar output** y confirmar baseline features

3. **Comenzar Feature #1** con Agent #2 (Planner)

---

**Fin del Documento de Agentes Expertos**
**Referencia cruzada:** ESTRATEGIA_DEFINITIVA_RECUPERACION.md
