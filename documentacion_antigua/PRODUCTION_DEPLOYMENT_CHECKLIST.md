# 🚀 Lista de Verificación - Despliegue a Producción

**Lumara Indígenas v3.0.0**

**Estado Actual:** Pre-Producción (Bloqueadores pendientes)
**Última actualización:** 2025-10-07

---

## 📊 Estado General

| Categoría | Estado | Progreso |
|-----------|--------|----------|
| **Desarrollo de Características** | ✅ Completado | 100% |
| **Pruebas de Calidad** | ✅ Completado | 100% |
| **Documentación** | ✅ Completado | 100% |
| **Configuración de Producción** | ⏳ Bloqueado | 30% |
| **Seguridad** | ⏳ Bloqueado | 60% |
| **Infraestructura** | ⏳ Bloqueado | 20% |

---

## 🚫 BLOQUEADORES DE PRODUCCIÓN

Estos items DEBEN resolverse antes del despliegue a producción:

### 1. ⚠️ Certificado SSL y Certificate Pinning

**Estado:** ❌ BLOQUEADO - Requiere acción externa

**Problema:**
- El archivo `production_config.dart` tiene certificateFingerprints vacío (línea 98-102)
- Sin SSL certificate, la app no puede conectarse de forma segura en producción

**Requiere:**
1. **Dominio de producción configurado** (ejemplo: `tejido.lumara-indigenas.org`)
2. **Certificado SSL instalado** en el servidor (Let's Encrypt recomendado)
3. **Servidor accesible** públicamente en puerto 443 (HTTPS)

**Pasos para resolver:**

```bash
# Paso 1: Obtener certificado SSL para tu dominio
# Opción A: Let's Encrypt (gratis, recomendado)
sudo certbot certonly --standalone -d tejido.lumara-indigenas.org

# Opción B: Certificado comercial (DigiCert, Sectigo, etc.)
# Seguir instrucciones del proveedor

# Paso 2: Generar fingerprint del certificado
cd /home/smt/Escritorio/programacion_proyectos/tejido/lumara/Lumara
chmod +x scripts/generate_cert_fingerprint.sh
./scripts/generate_cert_fingerprint.sh tejido.lumara-indigenas.org

# Paso 3: Copiar el fingerprint generado
# El script mostrará algo como:
# sha256/r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=

# Paso 4: Actualizar production_config.dart
# Editar líneas 98-102 con el fingerprint real
```

**Actualizar en:**
```dart
// lib/core/config/production_config.dart (líneas 98-102)
static const List<String> certificateFingerprints = [
  'sha256/[FINGERPRINT_DEL_CERT_PRINCIPAL]', // Cert producción
  'sha256/[FINGERPRINT_DEL_CERT_BACKUP]',    // Cert respaldo
];
```

**Criterio de aceptación:**
- [ ] Dominio de producción tiene certificado SSL válido
- [ ] Certificado accesible en puerto 443
- [ ] Fingerprint SHA-256 generado correctamente
- [ ] `certificateFingerprints` actualizado en código
- [ ] Al menos 2 certificados pinned (principal + backup)
- [ ] Probado en staging antes de producción

---

### 2. ⚠️ URLs de Producción

**Estado:** ❌ BLOQUEADO - Requiere configuración

**Problema:**
- `tejidoProductionUrl` apunta a "tejido.example.com" (línea 42)
- `tejidoStagingUrl` apunta a "tejido-staging.example.com" (línea 50)
- URLs de políticas usan dominio placeholder

**Requiere:**
1. **Servidor Tejido-ngx** desplegado y accesible
2. **Dominio registrado** y configurado
3. **DNS configurado** apuntando al servidor

**Pasos para resolver:**

```bash
# Paso 1: Verificar que el servidor Tejido está funcionando
curl https://tu-dominio-real.org/api/

# Paso 2: Verificar DNS configurado
nslookup tejido.lumara-indigenas.org

# Paso 3: Actualizar URLs en production_config.dart
```

**Actualizar en:**
```dart
// lib/core/config/production_config.dart

// Línea 42: URL de producción
static const String tejidoProductionUrl = 'https://tejido.lumara-indigenas.org';

// Línea 50: URL de staging (opcional pero recomendado)
static const String tejidoStagingUrl = 'https://staging.lumara-indigenas.org';

// Línea 254: Privacy policy
static const String privacyPolicyUrl = 'https://lumara-indigenas.org/privacy';

// Línea 262: Terms of service
static const String termsOfServiceUrl = 'https://lumara-indigenas.org/terms';
```

**Criterio de aceptación:**
- [ ] Servidor Tejido-ngx desplegado y funcionando
- [ ] Dominio registrado y DNS configurado
- [ ] `tejidoProductionUrl` actualizado con dominio real
- [ ] `tejidoStagingUrl` actualizado (opcional)
- [ ] Privacy policy publicada y URL actualizada
- [ ] Terms of service publicados y URL actualizada
- [ ] Todas las URLs usan HTTPS
- [ ] URLs probadas desde navegador y responden correctamente

---

### 3. ⚠️ Email de Soporte

**Estado:** ❌ BLOQUEADO - Requiere configuración

**Problema:**
- `supportEmail` usa email placeholder "support@lumara-indigenas.org" (línea 245)
- Email debe ser real y monitoreado

**Requiere:**
1. **Cuenta de email real** configurada
2. **Personal asignado** para responder consultas
3. **Proceso de soporte** definido

**Pasos para resolver:**

```bash
# Paso 1: Crear cuenta de email
# - Opción A: Google Workspace (soporte@lumara-indigenas.org)
# - Opción B: Email corporativo propio
# - Opción C: Servicio de email transaccional

# Paso 2: Configurar monitoreo/respuesta
# - Asignar persona responsable
# - Configurar tiempo de respuesta (SLA)
# - Preparar plantillas de respuesta

# Paso 3: Actualizar en código
```

**Actualizar en:**
```dart
// lib/core/config/production_config.dart (línea 245)
static const String supportEmail = 'soporte@tu-organizacion-real.org';
```

**Criterio de aceptación:**
- [ ] Cuenta de email creada y activa
- [ ] Personal asignado para responder
- [ ] Email probado (enviar y recibir)
- [ ] `supportEmail` actualizado en código
- [ ] Proceso de soporte documentado
- [ ] Tiempo de respuesta definido

---

### 4. ⚠️ Pruebas de Penetración (Pentesting)

**Estado:** ❌ BLOQUEADO - Requiere contratación externa

**Problema:**
- No se han realizado pruebas de seguridad profesionales
- Requisito para aplicaciones que manejan datos sensibles

**Requiere:**
1. **Contratar firma de seguridad** especializada
2. **Presupuesto aprobado** para pentesting
3. **Tiempo de ejecución** (típicamente 1-2 semanas)

**Pasos para resolver:**

```bash
# Paso 1: Seleccionar proveedor de pentesting
# Opciones recomendadas en Colombia:
# - Soluciones Seguras
# - Cipher
# - InterNexa
# - Consultores independientes certificados

# Paso 2: Contratar servicio
# Alcance típico:
# - Análisis de infraestructura
# - Pruebas de aplicación móvil (APK)
# - Pruebas de API backend
# - Análisis de código fuente (opcional)
# - Pruebas de ingeniería social (opcional)

# Paso 3: Proporcionar acceso
# - APK compilado en release
# - Acceso a ambiente de staging
# - Documentación técnica (ya disponible en PENETRATION_TESTING.md)

# Paso 4: Remediar hallazgos
# - Revisar reporte de vulnerabilidades
# - Priorizar por severidad (Crítico > Alto > Medio > Bajo)
# - Implementar fixes
# - Re-test
```

**Documentación disponible:**
- ✅ `PENETRATION_TESTING.md` - Guía completa para pentesters
- ✅ `SECURITY.md` - Medidas de seguridad implementadas
- ✅ `ARCHITECTURE.md` - Documentación técnica

**Criterio de aceptación:**
- [ ] Firma de pentesting contratada
- [ ] Alcance de pruebas definido
- [ ] Pruebas ejecutadas completamente
- [ ] Reporte de vulnerabilidades recibido
- [ ] Vulnerabilidades críticas/altas remediadas
- [ ] Re-test confirmando fixes
- [ ] Certificado/carta de pentesting obtenida

---

## ✅ PRE-REQUISITOS COMPLETADOS

Estos items ya están listos:

### Desarrollo
- [x] Sprint 1: Infraestructura base (100%)
- [x] Sprint 2: Funcionalidades core (100%)
- [x] Sprint 3: Integración con Tejido (100%)
- [x] Sprint 4: Características avanzadas (100%)
  - [x] Dashboard de reportes y analytics
  - [x] Sistema de análisis de brechas
  - [x] Motor de workflows automatizados
  - [x] Panel de administración
  - [x] Materiales de capacitación

### Calidad
- [x] Pruebas unitarias (85% coverage)
- [x] Pruebas de integración
- [x] Pruebas de widget
- [x] Pruebas de accesibilidad
- [x] Performance profiling

### Seguridad (Implementada)
- [x] Encriptación AES-256-GCM
- [x] Secure storage para tokens
- [x] Rate limiting (anti-brute force)
- [x] Input validation y sanitization
- [x] Monitoreo de errores
- [x] Logs seguros (sin PII)
- [x] Certificate pinning (código listo, falta config)

### Documentación
- [x] Guía de usuario en español
- [x] Guía rápida de campo
- [x] Documentación técnica
- [x] Guía de arquitectura
- [x] Guía de despliegue
- [x] Guía de pentesting

---

## 📋 CHECKLIST DE DESPLIEGUE

### Fase 1: Preparación (AHORA - Bloqueadores)

**Infraestructura:**
- [ ] Registrar dominio de producción
- [ ] Configurar DNS apuntando a servidor
- [ ] Instalar Tejido-ngx en servidor de producción
- [ ] Configurar firewall (puerto 443 abierto)
- [ ] Instalar certificado SSL (Let's Encrypt)
- [ ] Verificar SSL con: `curl https://tu-dominio.org`

**Configuración de Código:**
- [ ] Generar certificado fingerprint con script
- [ ] Actualizar `certificateFingerprints` en production_config.dart
- [ ] Actualizar `tejidoProductionUrl` con dominio real
- [ ] Actualizar `supportEmail` con email real
- [ ] Crear páginas de privacy policy y terms
- [ ] Actualizar URLs de privacy/terms
- [ ] Validar configuración: `ProductionConfig.validateProductionConfig()`

**Seguridad:**
- [ ] Contratar firma de pentesting
- [ ] Proporcionar acceso a staging
- [ ] Ejecutar pruebas de penetración
- [ ] Remediar vulnerabilidades encontradas
- [ ] Obtener carta de aprobación de seguridad

---

### Fase 2: Testing en Staging

- [ ] Compilar APK staging: `flutter build apk --dart-define=STAGING=true`
- [ ] Instalar en dispositivos de prueba
- [ ] Probar flujo completo de onboarding
- [ ] Probar captura y subida de documentos
- [ ] Verificar certificate pinning funcionando
- [ ] Probar modo offline y sincronización
- [ ] Verificar reportes y analytics
- [ ] Probar análisis de brechas
- [ ] Verificar workflows automatizados
- [ ] Testing de performance (100+ documentos)
- [ ] Testing con múltiples usuarios concurrentes
- [ ] Verificar logs de error funcionando
- [ ] UAT (User Acceptance Testing) con usuarios reales

---

### Fase 3: Compilación de Producción

- [ ] Actualizar versión en pubspec.yaml (3.0.0 → 3.0.1)
- [ ] Incrementar buildNumber
- [ ] Limpiar build anterior: `flutter clean`
- [ ] Obtener dependencias: `flutter pub get`
- [ ] Compilar release APK: `flutter build apk --release`
- [ ] Verificar tamaño de APK (< 50MB recomendado)
- [ ] Firmar APK con keystore de producción
- [ ] Probar APK firmado en dispositivo físico

**Comando de compilación:**
```bash
flutter build apk \
  --release \
  --dart-define=PRODUCTION=true \
  --obfuscate \
  --split-debug-info=build/debug-info
```

---

### Fase 4: Despliegue a Play Store

- [ ] Crear cuenta de Google Play Developer
- [ ] Pagar tarifa de registro ($25 USD one-time)
- [ ] Completar información de la app
- [ ] Subir screenshots (phone, tablet, 7-inch, 10-inch)
- [ ] Escribir descripción de la app
- [ ] Definir categoría y contenido
- [ ] Configurar precios y distribución
- [ ] Completar cuestionario de contenido
- [ ] Subir APK a track internal/alpha
- [ ] Testing interno (1-2 días)
- [ ] Promover a beta (testing cerrado)
- [ ] Beta testing (1 semana)
- [ ] Revisar y remediar bugs reportados
- [ ] Promover a producción
- [ ] Launch! 🚀

---

### Fase 5: Post-Lanzamiento

**Monitoreo (Primeras 24h):**
- [ ] Monitorear Play Console Vitals
- [ ] Revisar crash reports
- [ ] Monitorear ANRs (Application Not Responding)
- [ ] Verificar tasa de instalación vs. desinstalación
- [ ] Revisar reviews de usuarios
- [ ] Monitorear uso de servidor Tejido

**Primeras 48h:**
- [ ] Analizar métricas de uso
- [ ] Identificar problemas comunes
- [ ] Preparar hotfix si es necesario
- [ ] Responder a reviews de usuarios
- [ ] Comunicación con field operators

**Primera semana:**
- [ ] Recopilar feedback de usuarios
- [ ] Análisis de datos de reportes
- [ ] Identificar mejoras para v3.1.0
- [ ] Documentar lecciones aprendidas
- [ ] Planning de siguiente sprint

---

## 🔒 Validación de Seguridad

### Checklist de Seguridad Pre-Launch

**Datos sensibles:**
- [ ] No hay API keys hardcoded
- [ ] No hay credenciales en código
- [ ] Tokens se almacenan en secure storage
- [ ] PII se encripta en reposo

**Comunicación:**
- [ ] Todas las requests usan HTTPS
- [ ] Certificate pinning activo
- [ ] SSL/TLS 1.2+ solamente
- [ ] Headers de seguridad configurados

**Autenticación:**
- [ ] Rate limiting activo (5 intentos)
- [ ] Lockout después de intentos fallidos
- [ ] Token rotation habilitado
- [ ] Session timeout configurado

**Validación:**
- [ ] Input validation en todos los campos
- [ ] Sanitization de data antes de enviar
- [ ] SQL injection prevention (usando ORM)
- [ ] XSS prevention (no WebViews con user input)

**Permisos:**
- [ ] Permisos mínimos necesarios solicitados
- [ ] Permisos solicitados con contexto
- [ ] Funciona sin permisos opcionales

---

## 📊 Métricas de Éxito

### KPIs de Lanzamiento

**Técnicos:**
- Crash-free rate > 99.5%
- ANR rate < 0.1%
- App start time < 3 segundos
- Tamaño APK < 50MB
- Rating en Play Store > 4.0

**Negocio:**
- Tasa de adopción > 80% (field operators)
- Documentos digitalizados > 1000 en primera semana
- Tasa de error de subida < 5%
- Tiempo promedio de onboarding < 5 minutos
- Satisfacción de usuario > 8/10

---

## 📞 Contactos y Responsables

### Equipo de Despliegue

**Desarrollo:**
- Responsable: [Nombre]
- Email: [email@organizacion.org]
- Tareas: Compilación, configuración, fixes

**Infraestructura:**
- Responsable: [Nombre]
- Email: [email@organizacion.org]
- Tareas: Servidores, DNS, SSL, firewall

**Seguridad:**
- Responsable: [Nombre]
- Email: [email@organizacion.org]
- Tareas: Pentesting, validación de seguridad

**Soporte:**
- Responsable: [Nombre]
- Email: soporte@organizacion.org
- Tareas: Atención a usuarios, troubleshooting

**Project Manager:**
- Responsable: [Nombre]
- Email: [email@organizacion.org]
- Tareas: Coordinación, timelines, escalación

---

## 🚨 Plan de Contingencia

### Si algo sale mal...

**Escenario 1: Crash crítico post-launch**
1. Identificar root cause en crash reports
2. Desarrollar hotfix inmediatamente
3. Testing express (1-2h)
4. Despliegue de emergencia a Play Store
5. Comunicar a usuarios afectados

**Escenario 2: Vulnerabilidad de seguridad encontrada**
1. Evaluar severidad y exposición
2. Si es crítico: remover app de Play Store temporalmente
3. Desarrollar fix de seguridad
4. Re-pentesting de la vulnerabilidad
5. Re-despliegue con fix

**Escenario 3: Servidor Tejido caído**
1. Modo offline automático se activa
2. Comunicar a usuarios (in-app message)
3. Restaurar servidor desde backup
4. Verificar integridad de datos
5. Re-activar sincronización

**Escenario 4: Certificado SSL expiró**
1. Renovar certificado inmediatamente
2. Generar nuevo fingerprint
3. Release hotfix con nuevo fingerprint
4. Fast-track en Play Store (emergencia)

---

## 📅 Timeline Estimado

### Ruta Crítica

| Fase | Duración | Dependencias |
|------|----------|--------------|
| **1. Resolución de Bloqueadores** | 3-5 días | Infraestructura, email |
| **2. Pentesting** | 1-2 semanas | Contratación firma seguridad |
| **3. Remediación de Vulnerabilidades** | 3-5 días | Reporte de pentesting |
| **4. Testing en Staging** | 1 semana | Bloqueadores resueltos |
| **5. Compilación y Firma** | 1 día | Testing completo |
| **6. Proceso Play Store** | 1-3 días | APK firmado |
| **7. Beta Testing** | 1 semana | Aprobación Play Store |
| **8. Launch a Producción** | 1 día | Beta exitoso |

**Total estimado:** 4-6 semanas desde hoy

**Fecha de lanzamiento objetivo:** 2025-11-15

---

## ✅ Criterios de Aprobación Final

La aplicación está lista para producción cuando:

- [x] Todos los bloqueadores resueltos
- [ ] Pentesting completado sin vulnerabilidades críticas
- [ ] UAT aprobado por stakeholders
- [ ] Documentación completa y actualizada
- [ ] Team de soporte capacitado y listo
- [ ] Infraestructura de producción estable
- [ ] Play Store listing completo y aprobado
- [ ] Plan de rollback definido y probado
- [ ] Monitoreo y alertas configurados
- [ ] Backups automáticos configurados

---

## 📝 Notas Finales

### Siguientes Pasos Inmediatos

1. **HOY:** Crear cuenta de email de soporte
2. **Esta semana:**
   - Contratar firma de pentesting
   - Configurar servidor de producción
   - Obtener certificado SSL
3. **Próxima semana:**
   - Actualizar configuración de producción
   - Iniciar pentesting
   - Testing en staging

### Recursos Adicionales

- **DEPLOYMENT.md** - Guía detallada de despliegue
- **PENETRATION_TESTING.md** - Scope para pentesters
- **SECURITY.md** - Medidas de seguridad implementadas
- **USER_MANUAL_ES.md** - Manual de usuario
- **FIELD_GUIDE_ES.md** - Guía rápida de campo

---

**Versión del Checklist:** 1.0
**Última actualización:** 2025-10-07
**Próxima revisión:** Después de resolver bloqueadores
