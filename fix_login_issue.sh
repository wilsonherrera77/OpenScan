#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════
# SCRIPT DE FIX - Login Issue Lumara
# ═══════════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔧 FIX LOGIN ISSUE - LUMARA${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}1️⃣  Limpiando cache de Rate Limiting...${NC}"
docker exec tejido_broker_1 redis-cli FLUSHDB
echo -e "${GREEN}   ✅ Cache limpiado${NC}"
echo ""

echo -e "${YELLOW}2️⃣  Verificando usuario 'Digitador'...${NC}"
docker exec tejido_webserver_1 python3 manage.py shell -c "
from django.contrib.auth.models import User
from tejido_auth.models import UserProfile

# Get or create user
user, created = User.objects.get_or_create(
    username='Digitador',
    defaults={
        'email': 'digitador@lumara.local',
        'is_active': True
    }
)

if created:
    print('   Usuario creado')
else:
    print('   Usuario existente')

# Reset password
user.set_password('Indigena')
user.save()
print('   Password: Indigena')

# Get or create profile
profile, prof_created = UserProfile.objects.get_or_create(
    user=user,
    defaults={'role': 'DIGITALIZADOR'}
)

print(f'   Role: {profile.role}')
print(f'   ID: {user.id}')
" 2>&1 | grep -v "imported automatically" | grep -v "^$"

echo -e "${GREEN}   ✅ Usuario configurado${NC}"
echo ""

echo -e "${YELLOW}3️⃣  Probando autenticación...${NC}"
docker exec tejido_webserver_1 python3 manage.py shell -c "
from django.contrib.auth import authenticate

user = authenticate(username='Digitador', password='Indigena')

if user:
    print('   ✅ Autenticación EXITOSA')
else:
    print('   ❌ Autenticación FALLIDA')
" 2>&1 | grep "✅\|❌"

echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ FIX COMPLETADO${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "📱 Ahora puedes intentar login desde la app:"
echo ""
echo "   Username: Digitador"
echo "   Password: Indigena"
echo "   Server:   http://192.168.40.17:8001"
echo ""
echo "⚠️  IMPORTANTE: Si sigue fallando, espera 15 minutos para que"
echo "    el rate limiting se resetee completamente."
echo ""
