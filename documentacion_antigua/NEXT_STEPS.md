# 🚀 Próximos Pasos - Plan de Acción

**OpenScan Indígenas v3.0.0**
**Fecha:** 2025-10-07
**Para:** Todo el equipo

---

## ⚡ Acciones Inmediatas (Hoy)

### 1. Reunión de Kick-off (30 min)

**Participantes:** Stakeholders, DevOps, Seguridad, Admin

**Agenda:**
1. Revisar [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md) (10 min)
2. Aprobar presupuesto de pentesting: $3k-$8k USD (5 min)
3. Asignar responsables para cada bloqueador (10 min)
4. Acordar timeline de 5 semanas (5 min)

**Resultado esperado:**
- [ ] Presupuesto aprobado
- [ ] Responsables asignados
- [ ] Timeline confirmado
- [ ] Siguiente reunión agendada

---

### 2. Email de Soporte (2 horas) - ADMIN

**Responsable:** Admin/Soporte

**Pasos:**
```bash
1. Crear cuenta: soporte@openscan-indigenas.org
   - Opción A: Google Workspace ($6/mes)
   - Opción B: Email corporativo propio

2. Configurar:
   - Autoresponder inicial
   - Firma de email
   - Redirección si necesario

3. Asignar persona responsable:
   - Nombre: _______________
   - Horario: Lunes-Viernes 8AM-5PM
   - SLA: Respuesta < 24h

4. Actualizar código:
   Archivo: lib/core/config/production_config.dart
   Línea 245: static const String supportEmail = 'soporte@openscan-indigenas.org';
```

**Checklist:**
- [ ] Cuenta creada y verificada
- [ ] Email enviado y recibido (prueba)
- [ ] Persona asignada y capacitada
- [ ] Código actualizado
- [ ] Commit realizado: `git commit -m "Configure support email"`

**Deadline:** HOY al final del día

---

### 3. Solicitar Cotizaciones Pentesting (2 horas) - SEGURIDAD

**Responsable:** Equipo de Seguridad

**Firmas a contactar:**

**1. Soluciones Seguras**
- Web: https://www.solucionesseguras.com/
- Email: contacto@solucionesseguras.com
- Especialidad: Pentesting móvil

**2. Cipher**
- Web: https://cipher.com.co/
- Email: info@cipher.com.co
- Especialidad: Seguridad de aplicaciones

**3. InterNexa**
- Web: https://www.internexa.com/
- Email: seguridad@internexa.com
- Especialidad: Auditorías de seguridad

**Email template:**
```
Asunto: Solicitud de Cotización - Pentesting Aplicación Móvil

Estimados,

Solicito cotización para pruebas de penetración de nuestra aplicación móvil:

- Tipo: Aplicación Android (Flutter)
- Alcance: Ver adjunto (PENETRATION_TESTING.md)
- Duración estimada: 10 días laborales
- Timeline: Iniciar en próximos 7 días

Por favor incluir:
- Costo total
- Timeline propuesto
- Metodología (OWASP Mobile Top 10)
- Entregables
- Referencias

Adjunto: PENETRATION_TESTING.md (scope completo)

Saludos,
[Nombre]
```

**Checklist:**
- [ ] Email enviado a Soluciones Seguras
- [ ] Email enviado a Cipher
- [ ] Email enviado a InterNexa
- [ ] Adjunto PENETRATION_TESTING.md
- [ ] Seguimiento agendado para mañana

**Deadline:** HOY al final del día

---

## 📅 Semana 1 (Hoy - 7 días)

### Día 1 (HOY)
- [x] Desarrollo completado (ya hecho)
- [ ] Reunión de kick-off
- [ ] Crear email de soporte
- [ ] Solicitar cotizaciones pentesting

### Día 2-3: Infraestructura - DEVOPS

**Responsable:** Equipo DevOps

**Tarea 1: Desplegar Servidor Paperless-ngx**
```bash
# Opción A: Docker (recomendado)
docker run -d \
  --name paperless-ngx \
  -p 8000:8000 \
  -v paperless_data:/usr/src/paperless/data \
  -v paperless_media:/usr/src/paperless/media \
  -e PAPERLESS_URL=https://paperless.openscan-indigenas.org \
  ghcr.io/paperless-ngx/paperless-ngx:latest

# Verificar
curl http://localhost:8000/api/
```

**Tarea 2: Configurar DNS**
```bash
# Apuntar dominio a IP del servidor
# Ejemplo en Cloudflare/Route53:
A     paperless.openscan-indigenas.org     -> 123.456.789.10
CNAME staging.openscan-indigenas.org       -> paperless.openscan-indigenas.org

# Verificar DNS propagado
nslookup paperless.openscan-indigenas.org
```

**Tarea 3: Instalar SSL Certificate**
```bash
# Usando Let's Encrypt
sudo apt-get update
sudo apt-get install certbot

# Generar certificado
sudo certbot certonly --standalone \
  -d paperless.openscan-indigenas.org \
  -d staging.openscan-indigenas.org

# Verificar
curl -I https://paperless.openscan-indigenas.org
```

**Checklist:**
- [ ] Servidor Paperless desplegado
- [ ] DNS configurado y propagado
- [ ] SSL instalado y funcionando
- [ ] Firewall configurado (puerto 443 abierto)
- [ ] Backup configurado

---

### Día 4: Generar Fingerprints - DEVOPS

```bash
# En tu máquina de desarrollo
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan

# Generar fingerprints
./scripts/generate_cert_fingerprint.sh paperless.openscan-indigenas.org

# Output esperado:
# SHA-256 Fingerprint:
# sha256/r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=

# Guardar en archivo
# El script crea: cert_pinning_paperless.openscan-indigenas.org.txt
```

**Actualizar código:**
```dart
// Editar: lib/core/config/production_config.dart (líneas 98-102)
static const List<String> certificateFingerprints = [
  'sha256/[PEGAR_FINGERPRINT_PRINCIPAL]',  // Cert producción
  'sha256/[PEGAR_FINGERPRINT_BACKUP]',     // Cert backup/intermediate
];
```

**Checklist:**
- [ ] Script ejecutado exitosamente
- [ ] Fingerprints generados (mínimo 2)
- [ ] Código actualizado
- [ ] Commit: `git commit -m "Add production SSL fingerprints"`

---

### Día 5: Actualizar URLs - DEVOPS

**Páginas legales a crear:**

**1. Privacy Policy (Política de Privacidad)**
- Template: https://www.privacypolicygenerator.info/
- Contenido mínimo:
  - Qué datos se recopilan
  - Cómo se usan y almacenan
  - Derechos de los usuarios
  - Contacto para privacidad
- Publicar en: https://openscan-indigenas.org/politica-privacidad

**2. Terms of Service (Términos de Servicio)**
- Contenido mínimo:
  - Términos de uso
  - Limitaciones de responsabilidad
  - Derechos de propiedad
  - Jurisdicción aplicable
- Publicar en: https://openscan-indigenas.org/terminos-servicio

**Actualizar código:**
```dart
// Editar: lib/core/config/production_config.dart

// Línea 42
static const String paperlessProductionUrl = 'https://paperless.openscan-indigenas.org';

// Línea 50
static const String paperlessStagingUrl = 'https://staging.openscan-indigenas.org';

// Línea 254
static const String privacyPolicyUrl = 'https://openscan-indigenas.org/politica-privacidad';

// Línea 262
static const String termsOfServiceUrl = 'https://openscan-indigenas.org/terminos-servicio';
```

**Checklist:**
- [ ] Privacy Policy creada y publicada
- [ ] Terms of Service creados y publicados
- [ ] URLs verificadas (abren correctamente)
- [ ] Código actualizado
- [ ] Commit: `git commit -m "Update production URLs"`

---

### Día 6-7: Contratar Pentesting - SEGURIDAD

**Evaluar cotizaciones recibidas:**

| Criterio | Peso | Firma 1 | Firma 2 | Firma 3 |
|----------|------|---------|---------|---------|
| Experiencia móvil | 30% | | | |
| Precio | 25% | | | |
| Timeline | 20% | | | |
| Metodología | 15% | | | |
| Referencias | 10% | | | |
| **TOTAL** | 100% | | | |

**Seleccionar firma y firmar contrato:**
```
1. Seleccionar mejor opción
2. Negociar términos finales
3. Firmar NDA
4. Firmar contrato de servicio
5. Confirmar fecha de inicio
6. Preparar accesos y materiales
```

**Checklist:**
- [ ] Cotizaciones evaluadas
- [ ] Firma seleccionada
- [ ] NDA firmado
- [ ] Contrato firmado
- [ ] Pago inicial realizado (si aplica)
- [ ] Fecha de inicio confirmada
- [ ] Kick-off meeting agendado

---

## 📅 Semana 2-3 (Día 8-21)

### Día 8: Validar Configuración - DEVOPS

```bash
# Ejecutar script de validación
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan
./scripts/validate_production.sh

# Debe mostrar:
# ✅ All checks passed - Ready for production
# O al menos:
# ⚠ Passed with warnings
```

**Si hay errores:**
1. Revisar output del script
2. Corregir problemas identificados
3. Re-ejecutar hasta pasar

**Compilar APK staging:**
```bash
flutter clean
flutter pub get
flutter build apk --dart-define=STAGING=true

# APK en: build/app/outputs/flutter-apk/app-release.apk
```

**Checklist:**
- [ ] Validación pasada (0 errores críticos)
- [ ] APK staging compilado
- [ ] APK probado en dispositivo físico
- [ ] Funciona correctamente con servidor staging

---

### Día 8-17: Pentesting (10 días) - SEGURIDAD

**Coordinación diaria:**
- Daily standup: 9:00 AM (15 min)
- Reporte de progreso
- Disclosure de findings críticos

**Entregables esperados:**
- Día 3: Findings iniciales
- Día 7: Findings críticos disclosed
- Día 10: Reporte final

**Checklist:**
- [ ] Kick-off meeting completado
- [ ] APK y accesos proporcionados
- [ ] Daily standups realizados
- [ ] Findings críticos disclosed
- [ ] Reporte final recibido

---

### Día 18-21: Remediación - DESARROLLO

**Priorizar por severidad:**

**Crítico (CVSS 9.0-10.0):**
- Fix inmediato (mismo día)
- Re-test antes de continuar

**Alto (CVSS 7.0-8.9):**
- Fix en máximo 2 días
- Re-test al finalizar

**Medio/Bajo:**
- Fix en próximo release o documentar

**Proceso:**
```bash
1. Revisar finding del reporte
2. Entender root cause
3. Implementar fix
4. Escribir test que valide el fix
5. Commit: git commit -m "fix: [vulnerability description] (#issue)"
6. Re-test interno
7. Solicitar re-test a pentester
```

**Checklist:**
- [ ] Vulnerabilidades críticas: 100% remediadas
- [ ] Vulnerabilidades altas: 100% remediadas
- [ ] Vulnerabilidades medias: Plan de acción definido
- [ ] Re-test completado
- [ ] Carta de aprobación recibida

---

## 📅 Semana 4 (Día 22-28)

### Día 22-24: Testing en Staging - QA

**Testing exhaustivo:**

**Flujos principales:**
- [ ] Onboarding completo
- [ ] Login y autenticación
- [ ] Selección de persona
- [ ] Captura de documento
- [ ] Subida con progreso
- [ ] Modo offline → online
- [ ] Sincronización automática
- [ ] Dashboard de reportes
- [ ] Análisis de brechas
- [ ] Exportación a PDF/Excel
- [ ] Workflows automatizados
- [ ] Panel de admin

**Testing de escenarios:**
- [ ] 100+ documentos en cola
- [ ] Múltiples usuarios concurrentes
- [ ] Red lenta (3G)
- [ ] Pérdida de conexión durante subida
- [ ] Batería baja
- [ ] Espacio limitado

**Checklist:**
- [ ] Todos los flujos probados
- [ ] Sin crashes críticos
- [ ] Performance aceptable
- [ ] Bugs documentados en GitHub Issues
- [ ] Bugs críticos corregidos

---

### Día 25-26: UAT (User Acceptance Testing) - USUARIOS

**Participantes:**
- 5-10 field operators
- 2-3 administradores
- 1 representante de comunidad

**Proceso:**
```
1. Briefing (30 min)
   - Explicar objetivo del UAT
   - Entregar dispositivos con app
   - Explicar cómo reportar issues

2. Testing libre (2 horas)
   - Usuarios prueban libremente
   - Observar y tomar notas
   - Responder dudas

3. Testing guiado (1 hora)
   - Seguir escenarios específicos
   - Verificar tareas completadas

4. Feedback session (30 min)
   - Recopilar impresiones
   - Identificar pain points
   - Sugerencias de mejora

5. Análisis (1 hora)
   - Consolidar feedback
   - Priorizar cambios
   - Decidir qué incluir en launch
```

**Checklist:**
- [ ] UAT session completada
- [ ] Feedback consolidado
- [ ] Issues críticos identificados
- [ ] Issues críticos corregidos
- [ ] Aprobación de usuarios obtenida

---

### Día 27: Compilar APK Final - DEVOPS

**Preparación:**
```bash
# Verificar que TODO esté actualizado
git status  # Debe estar limpio
git log --oneline -5  # Revisar últimos commits

# Actualizar versión
# Editar: pubspec.yaml
version: 3.0.0+1  # 3.0.0 = version, 1 = build number

# Limpiar
flutter clean
rm -rf build/

# Instalar dependencias
flutter pub get

# Ejecutar validación final
./scripts/validate_production.sh

# Debe mostrar: ✅ All checks passed
```

**Compilación:**
```bash
# Build release con obfuscation
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --target-platform android-arm,android-arm64

# APK generado en:
# build/app/outputs/flutter-apk/app-release.apk

# Verificar tamaño (debe ser < 50MB)
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

**Firmar APK:**
```bash
# Generar keystore (solo primera vez)
keytool -genkey -v \
  -keystore openscan-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias openscan

# Firmar APK
jarsigner -verbose \
  -sigalg SHA256withRSA \
  -digestalg SHA-256 \
  -keystore openscan-release-key.jks \
  build/app/outputs/flutter-apk/app-release.apk \
  openscan

# Verificar firma
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk
```

**Checklist:**
- [ ] Versión actualizada
- [ ] APK compilado exitosamente
- [ ] Tamaño < 50MB
- [ ] APK firmado
- [ ] Firma verificada
- [ ] APK probado en dispositivo

---

### Día 28: Subir a Play Store - DEVOPS

**Crear cuenta Google Play Developer:**
```
1. Ir a: https://play.google.com/console
2. Crear cuenta ($25 USD one-time)
3. Completar información de desarrollador
4. Verificar identidad
```

**Crear aplicación:**
```
1. New application
2. Nombre: OpenScan Indígenas
3. Idioma: Español
4. Tipo: App
5. Gratis/Pago: Gratis
```

**Completar Store Listing:**
- Título (30 chars): "OpenScan Indígenas"
- Descripción corta (80 chars): "Digitaliza documentos de comunidades indígenas"
- Descripción completa (4000 chars): Ver docs/USER_MANUAL_ES.md
- Screenshots: Mínimo 2 por categoría (phone, tablet)
- Ícono: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Categoría: Productividad
- Contenido: Todas las edades

**Configurar release:**
```
1. Production → Create release
2. Upload APK firmado
3. Release name: "v3.0.0 - Launch"
4. Release notes:
   - Digitalización rápida de documentos
   - Modo offline con sincronización automática
   - Dashboard de reportes y analytics
   - Y más...
5. Review and rollout
```

**Checklist:**
- [ ] Cuenta Play Developer creada
- [ ] Aplicación creada
- [ ] Store listing completo
- [ ] Screenshots subidos
- [ ] APK subido
- [ ] Release creado
- [ ] Submitted for review

---

## 📅 Semana 5 (Día 29-35)

### Día 29-31: Beta Testing - USUARIOS

**Invitar beta testers:**
```
1. Play Console → Testing → Closed testing
2. Create new track: "Beta"
3. Add testers (emails)
4. Enviar invitación
```

**Monitorear:**
- Crashes (Play Console → Vitals → Crashes)
- ANRs (App Not Responding)
- Reviews de beta testers
- Métricas de uso

**Checklist:**
- [ ] Beta track creado
- [ ] 20+ testers invitados
- [ ] Beta activo por 3 días
- [ ] Crash-free rate > 99%
- [ ] Feedback positivo

---

### Día 32-33: Hotfixes - DESARROLLO

**Si se encuentran bugs:**
```bash
# Fix crítico
git checkout -b hotfix/critical-bug
# Implementar fix
git commit -m "hotfix: [bug description]"
git push

# Build nuevo APK
flutter build apk --release --obfuscate
# Subir a beta track
# Re-test
```

**Checklist:**
- [ ] Bugs críticos corregidos
- [ ] Nueva versión en beta
- [ ] Re-testing completado
- [ ] Aprobación de beta testers

---

### Día 34: Aprobación Final - STAKEHOLDERS

**Reunión de Go/No-Go:**

**Participantes:** Stakeholders, PM, Tech Lead

**Revisar:**
- [ ] Todos los bloqueadores resueltos
- [ ] Pentesting aprobado
- [ ] UAT exitoso
- [ ] Beta exitoso
- [ ] Crash-free rate > 99%
- [ ] Equipo de soporte listo
- [ ] Documentación completa
- [ ] Plan de rollback definido

**Decisión:**
- [ ] GO → Lanzamiento mañana
- [ ] NO-GO → Posponer y resolver pendientes

---

### Día 35: 🚀 LANZAMIENTO - TODO EL EQUIPO

**09:00 AM - Promover a Producción:**
```
1. Play Console → Beta track
2. Promote to Production
3. Rollout: 10% (gradual)
4. Confirm and publish
```

**Durante el día - Monitoreo intensivo:**
```
Cada hora revisar:
- Crashes (target: 0)
- ANRs (target: < 0.1%)
- Install/uninstall ratio
- User reviews
- Server logs
- Support emails
```

**Timeline de rollout:**
```
09:00 - 10% de usuarios
12:00 - Si todo OK → 25%
15:00 - Si todo OK → 50%
18:00 - Si todo OK → 100%
```

**Plan de rollback (si es necesario):**
```
1. Halt rollout
2. Revert to previous version (si existe)
3. Investigar issue
4. Fix y re-deploy cuando esté listo
```

**Checklist:**
- [ ] App publicada en Play Store
- [ ] Rollout gradual iniciado
- [ ] Monitoreo activo
- [ ] Sin crashes críticos
- [ ] Equipo de soporte respondiendo
- [ ] 🎉 Celebración de lanzamiento

---

## 📊 Métricas de Éxito

### Semana 1 Post-Launch

**Técnicas:**
- Crash-free rate > 99.5%
- ANR rate < 0.1%
- App start time < 3s
- Rating en Play Store > 4.0

**Negocio:**
- Instalaciones > 50
- Documentos digitalizados > 500
- Tasa de adopción (field operators) > 80%
- Tasa de error de subida < 5%

### Mes 1 Post-Launch

**Crecimiento:**
- Instalaciones > 200
- Documentos > 5,000
- MAU (Monthly Active Users) > 100
- Retención D30 > 70%

---

## 🚨 Contactos de Emergencia

### Durante Rollout (Día 35)

**Desarrollo:**
- Lead Developer: [nombre] - [phone]
- Backend: [nombre] - [phone]

**Infraestructura:**
- DevOps Lead: [nombre] - [phone]
- Server Admin: [nombre] - [phone]

**Soporte:**
- Support Lead: [nombre] - [phone]
- Email: soporte@openscan-indigenas.org

**Management:**
- PM: [nombre] - [phone]
- Stakeholder: [nombre] - [phone]

---

## ✅ Checklist General

### Pre-Lanzamiento
- [ ] Todos los bloqueadores resueltos
- [ ] Pentesting aprobado
- [ ] Configuración actualizada
- [ ] Tests pasando
- [ ] UAT completado
- [ ] Beta exitoso
- [ ] Documentación lista
- [ ] Equipo capacitado

### Lanzamiento
- [ ] APK en Play Store
- [ ] Monitoreo configurado
- [ ] Equipo en standby
- [ ] Plan de rollback listo
- [ ] Comunicación preparada

### Post-Lanzamiento
- [ ] Métricas monitoreadas
- [ ] Issues resueltos
- [ ] Feedback recopilado
- [ ] Retrospectiva realizada

---

## 📝 Notas Finales

**Este documento es tu roadmap de 5 semanas hacia producción.**

**Reglas de oro:**
1. Sigue el timeline pero sé flexible si surgen blockers
2. Comunica problemas inmediatamente
3. No saltarse el testing
4. Documentar todo lo que cambies
5. Celebrar los hitos alcanzados

**Próxima reunión:** Mañana a las 9:00 AM (Kick-off)

---

**¡Vamos a lanzar esta app! 🚀**

**Fecha de lanzamiento objetivo:** 15 de Noviembre, 2025
