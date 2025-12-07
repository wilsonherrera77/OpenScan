#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════
# SCRIPT: Cargar Asignaciones de Prueba
# ═══════════════════════════════════════════════════════════════════════
# Fecha: 2025-10-31
# Propósito: Crear dataset de 15 asignaciones para testing E2E
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
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  📋 CARGAR ASIGNACIONES DE PRUEBA${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar backend disponible
echo -e "${YELLOW}1️⃣  Verificando backend...${NC}"
if curl -s "$API_URL/api/" > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Backend disponible${NC}"
else
    echo -e "${RED}   ❌ Backend no disponible${NC}"
    echo "   Por favor inicia el backend: docker-compose up -d"
    exit 1
fi

echo ""

# Obtener IDs de usuarios
echo -e "${YELLOW}2️⃣  Obteniendo IDs de digitalizadores...${NC}"

docker exec tejido_webserver_1 python3 manage.py shell -c "
from django.contrib.auth.models import User
from tejido_auth.models import UserProfile

digitadores = User.objects.filter(userprofile__role='DIGITALIZADOR')

print('Digitalizador      | User ID')
print('───────────────────|────────')
for user in digitadores:
    print(f'{user.username:18} | {user.id}')
" 2>&1 | grep -v "imported"

echo ""

# Crear asignaciones para Digitador (user_id=2)
echo -e "${YELLOW}3️⃣  Creando asignaciones para Digitador...${NC}"

RESPONSE=$(curl -s -X POST "$API_URL/api/auth/assignments/bulk_create/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "digitizer_id": 2,
    "person_ids": ["2086", "2087", "2088"],
    "required_documents": 2
  }')

if echo "$RESPONSE" | jq -e '.created' > /dev/null 2>&1; then
    COUNT=$(echo "$RESPONSE" | jq '.created | length')
    echo -e "${GREEN}   ✅ Creadas $COUNT asignaciones para Digitador${NC}"
else
    echo -e "${RED}   ❌ Error al crear asignaciones${NC}"
    echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
fi

echo ""

# Verificar IDs de digitalizador1 y digitalizador2
DIGITALIZADOR1_ID=$(docker exec tejido_webserver_1 python3 manage.py shell -c "
from django.contrib.auth.models import User
try:
    user = User.objects.get(username='digitalizador1')
    print(user.id)
except:
    print('0')
" 2>&1 | tail -1)

DIGITALIZADOR2_ID=$(docker exec tejido_webserver_1 python3 manage.py shell -c "
from django.contrib.auth.models import User
try:
    user = User.objects.get(username='digitalizador2')
    print(user.id)
except:
    print('0')
" 2>&1 | tail -1)

# Crear asignaciones para digitalizador1
if [ "$DIGITALIZADOR1_ID" != "0" ]; then
    echo -e "${YELLOW}4️⃣  Creando asignaciones para digitalizador1...${NC}"

    RESPONSE=$(curl -s -X POST "$API_URL/api/auth/assignments/bulk_create/" \
      -H "Authorization: Token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"digitizer_id\": $DIGITALIZADOR1_ID,
        \"person_ids\": [\"2089\", \"2090\", \"2091\", \"2092\"],
        \"required_documents\": 3
      }")

    if echo "$RESPONSE" | jq -e '.created' > /dev/null 2>&1; then
        COUNT=$(echo "$RESPONSE" | jq '.created | length')
        echo -e "${GREEN}   ✅ Creadas $COUNT asignaciones para digitalizador1${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Error o asignaciones ya existen${NC}"
    fi
else
    echo -e "${YELLOW}4️⃣  Saltando digitalizador1 (no existe)${NC}"
fi

echo ""

# Crear asignaciones para digitalizador2
if [ "$DIGITALIZADOR2_ID" != "0" ]; then
    echo -e "${YELLOW}5️⃣  Creando asignaciones para digitalizador2...${NC}"

    RESPONSE=$(curl -s -X POST "$API_URL/api/auth/assignments/bulk_create/" \
      -H "Authorization: Token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"digitizer_id\": $DIGITALIZADOR2_ID,
        \"person_ids\": [\"2093\", \"2094\", \"2095\"],
        \"required_documents\": 2
      }")

    if echo "$RESPONSE" | jq -e '.created' > /dev/null 2>&1; then
        COUNT=$(echo "$RESPONSE" | jq '.created | length')
        echo -e "${GREEN}   ✅ Creadas $COUNT asignaciones para digitalizador2${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Error o asignaciones ya existen${NC}"
    fi
else
    echo -e "${YELLOW}5️⃣  Saltando digitalizador2 (no existe)${NC}"
fi

echo ""

# Resumen final
echo -e "${YELLOW}6️⃣  Verificando total de asignaciones...${NC}"

docker exec tejido_webserver_1 python3 manage.py shell -c "
from tejido_auth.models import PersonAssignment

total = PersonAssignment.objects.count()
by_status = {}
by_digitizer = {}

for assignment in PersonAssignment.objects.all():
    status = assignment.status
    by_status[status] = by_status.get(status, 0) + 1

    digitizer = assignment.digitizer.username
    by_digitizer[digitizer] = by_digitizer.get(digitizer, 0) + 1

print(f'Total de asignaciones: {total}')
print('')
print('Por status:')
for status, count in sorted(by_status.items()):
    print(f'  {status}: {count}')
print('')
print('Por digitalizador:')
for digitizer, count in sorted(by_digitizer.items()):
    print(f'  {digitizer}: {count}')
" 2>&1 | grep -v "imported"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ASIGNACIONES CARGADAS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
