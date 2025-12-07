#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════
# SCRIPT: Verificar Estado del Sistema
# ═══════════════════════════════════════════════════════════════════════
# Fecha: 2025-10-31
# Propósito: Verificación completa del sistema antes de testing E2E
# ═══════════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

TOKEN="112fb331a1d5b9361446adffa7c6d9c576b98096"
API_URL="http://192.168.40.17:8001"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  🔍 VERIFICACIÓN DE ESTADO DEL SISTEMA - LUMARA"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# 1. Backend
echo -e "${BLUE}1. BACKEND${NC}"
echo "   ────────────────────────────────────────"
if curl -s --connect-timeout 5 "$API_URL/api/" > /dev/null 2>&1; then
    echo -e "   Status: ${GREEN}✅ Disponible${NC}"
    echo "   URL: $API_URL"

    # Verificar endpoints críticos
    ENDPOINTS=("/api/auth/" "/api/documents/" "/api/auth/my-assignments/")
    for endpoint in "${ENDPOINTS[@]}"; do
        if curl -s --connect-timeout 5 "$API_URL$endpoint" -H "Authorization: Token $TOKEN" > /dev/null 2>&1; then
            echo -e "   $endpoint: ${GREEN}✅${NC}"
        else
            echo -e "   $endpoint: ${RED}❌${NC}"
        fi
    done
else
    echo -e "   Status: ${RED}❌ No disponible${NC}"
    echo "   ACCIÓN: Ejecutar 'docker-compose up -d'"
fi

echo ""

# 2. Docker Containers
echo -e "${BLUE}2. DOCKER CONTAINERS${NC}"
echo "   ────────────────────────────────────────"
CONTAINERS=$(docker ps --filter "name=tejido" --format "{{.Names}}" | wc -l)
echo "   Containers corriendo: $CONTAINERS"

docker ps --filter "name=tejido" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | while read line; do
    if echo "$line" | grep -q "Up"; then
        echo -e "   ${GREEN}$line${NC}"
    else
        echo "   $line"
    fi
done

echo ""

# 3. Base de Datos - Usuarios
echo -e "${BLUE}3. USUARIOS${NC}"
echo "   ────────────────────────────────────────"

docker exec tejido_webserver_1 python3 manage.py shell -c "
from tejido_auth.models import UserProfile
from django.contrib.auth.models import User

total = User.objects.count()
active = User.objects.filter(is_active=True).count()

print(f'   Total usuarios: {total}')
print(f'   Activos: {active}')
print('')
print('   Por rol:')

by_role = {}
for profile in UserProfile.objects.all():
    role = profile.role
    by_role[role] = by_role.get(role, 0) + 1

for role in ['ADMIN', 'DIGITALIZADOR', 'REVISOR', 'VIEWER']:
    count = by_role.get(role, 0)
    print(f'     {role}: {count}')
" 2>&1 | grep -v "imported"

echo ""

# 4. Asignaciones
echo -e "${BLUE}4. ASIGNACIONES${NC}"
echo "   ────────────────────────────────────────"

docker exec tejido_webserver_1 python3 manage.py shell -c "
from tejido_auth.models import PersonAssignment

total = PersonAssignment.objects.count()
print(f'   Total asignaciones: {total}')
print('')
print('   Por status:')

by_status = {}
for assignment in PersonAssignment.objects.all():
    status = assignment.status
    by_status[status] = by_status.get(status, 0) + 1

for status in ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'APPROVED', 'REJECTED']:
    count = by_status.get(status, 0)
    print(f'     {status}: {count}')
" 2>&1 | grep -v "imported"

echo ""

# 5. Sesiones de Digitalización
echo -e "${BLUE}5. SESIONES DE DIGITALIZACIÓN${NC}"
echo "   ────────────────────────────────────────"

docker exec tejido_webserver_1 python3 manage.py shell -c "
from tejido_auth.models import DigitizationSession

total = DigitizationSession.objects.count()
active = DigitizationSession.objects.filter(ended_at__isnull=True).count()
completed = DigitizationSession.objects.filter(ended_at__isnull=False).count()

print(f'   Total sesiones: {total}')
print(f'   Activas: {active}')
print(f'   Completadas: {completed}')

if completed > 0:
    print('')
    print('   Últimas 3 sesiones completadas:')
    sessions = DigitizationSession.objects.filter(ended_at__isnull=False).order_by('-ended_at')[:3]
    for s in sessions:
        print(f'     User: {s.user.username} | Docs: {s.documents_count} | Duración: {s.duration_minutes}min')
" 2>&1 | grep -v "imported"

echo ""

# 6. Documentos en Tejido
echo -e "${BLUE}6. DOCUMENTOS EN TEJIDO${NC}"
echo "   ────────────────────────────────────────"

DOCS_RESPONSE=$(curl -s "$API_URL/api/documents/" -H "Authorization: Token $TOKEN")
DOCS_COUNT=$(echo "$DOCS_RESPONSE" | jq -r '.count' 2>/dev/null || echo "0")

echo "   Total documentos: $DOCS_COUNT"

if [ "$DOCS_COUNT" -gt 0 ]; then
    echo ""
    echo "   Últimos 5 documentos:"
    echo "$DOCS_RESPONSE" | jq -r '.results[:5] | .[] | "     ID: \(.id) | Título: \(.title)"' 2>/dev/null || echo "     (error al parsear)"
fi

echo ""

# 7. Redis (Rate Limiting / Cache)
echo -e "${BLUE}7. REDIS (CACHE)${NC}"
echo "   ────────────────────────────────────────"

REDIS_PING=$(docker exec tejido_broker_1 redis-cli PING 2>/dev/null || echo "ERROR")

if [ "$REDIS_PING" = "PONG" ]; then
    echo -e "   Status: ${GREEN}✅ Funcionando${NC}"

    KEYS_COUNT=$(docker exec tejido_broker_1 redis-cli DBSIZE 2>/dev/null | grep -oP '\d+' || echo "0")
    echo "   Keys en cache: $KEYS_COUNT"
else
    echo -e "   Status: ${RED}❌ No disponible${NC}"
fi

echo ""

# 8. APK Disponibles
echo -e "${BLUE}8. APKs DISPONIBLES${NC}"
echo "   ────────────────────────────────────────"

APK_COUNT=$(ls -1 ~/Descargas/Lumara_*.apk 2>/dev/null | wc -l)
echo "   APKs en ~/Descargas: $APK_COUNT"

if [ "$APK_COUNT" -gt 0 ]; then
    ls -lh ~/Descargas/Lumara_*.apk | awk '{print "     " $9 " (" $5 ")"}'
fi

echo ""

# 9. Dispositivo Android
echo -e "${BLUE}9. DISPOSITIVO ANDROID (ADB)${NC}"
echo "   ────────────────────────────────────────"

ADB_DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)

if [ "$ADB_DEVICES" -gt 0 ]; then
    echo -e "   Status: ${GREEN}✅ Conectado${NC}"
    adb devices | grep "device" | awk '{print "     " $1 " (" $2 ")"}'

    # Verificar si app instalada
    if adb shell pm list packages | grep -q "com.whsys.lumara"; then
        echo -e "   App Lumara: ${GREEN}✅ Instalada${NC}"

        # Obtener versión
        VERSION=$(adb shell dumpsys package com.whsys.lumara | grep versionName | head -1 | awk '{print $1}' | cut -d'=' -f2)
        echo "   Versión: $VERSION"
    else
        echo -e "   App Lumara: ${YELLOW}⚠️  No instalada${NC}"
    fi
else
    echo -e "   Status: ${YELLOW}⚠️  No conectado${NC}"
    echo "   ACCIÓN: Conectar dispositivo por USB y habilitar Depuración USB"
fi

echo ""

# 10. Resumen de Estado
echo "═══════════════════════════════════════════════════════════════════"
echo -e "${BLUE}  📊 RESUMEN DE ESTADO${NC}"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Determinar estado global
STATUS_OK=true

if ! curl -s --connect-timeout 5 "$API_URL/api/" > /dev/null 2>&1; then
    STATUS_OK=false
    echo -e "   ${RED}❌ Backend no disponible${NC}"
fi

if [ "$ADB_DEVICES" -eq 0 ]; then
    STATUS_OK=false
    echo -e "   ${YELLOW}⚠️  Dispositivo Android no conectado${NC}"
fi

if [ "$DOCS_COUNT" -eq 0 ]; then
    echo -e "   ${YELLOW}⚠️  No hay documentos en el sistema (esperado en testing inicial)${NC}"
fi

if $STATUS_OK; then
    echo -e "   ${GREEN}✅ SISTEMA LISTO PARA TESTING${NC}"
else
    echo -e "   ${RED}❌ SISTEMA NO LISTO - Revisar errores arriba${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
