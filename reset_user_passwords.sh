#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════
# SCRIPT: Resetear Passwords de Usuarios para Testing
# ═══════════════════════════════════════════════════════════════════════
# Fecha: 2025-10-31
# Propósito: Preparar usuarios con passwords conocidas para pruebas E2E
# ═══════════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔐 RESETEAR PASSWORDS - USUARIOS DE PRUEBA${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Reseteando passwords para 5 usuarios...${NC}"
echo ""

docker exec paperless_webserver_1 python3 manage.py shell -c "
from django.contrib.auth.models import User
from paperless_auth.models import UserProfile

users_passwords = {
    'digitalizador1': 'Indigena123',
    'digitalizador2': 'Indigena456',
    'revisor1': 'Revisor123',
    'viewer1': 'Viewer123',
    'admin': 'Admin123'
}

print('Usuario          | Password      | Role            | Status')
print('─────────────────|───────────────|─────────────────|────────')

for username, password in users_passwords.items():
    try:
        user = User.objects.get(username=username)
        user.set_password(password)
        user.is_active = True
        user.save()

        # Get role
        try:
            profile = UserProfile.objects.get(user=user)
            role = profile.role
        except UserProfile.DoesNotExist:
            role = 'NO PROFILE'

        print(f'{username:16} | {password:13} | {role:15} | ✅ OK')

    except User.DoesNotExist:
        print(f'{username:16} | {password:13} | N/A             | ❌ NO EXISTE')
"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ PASSWORDS RESETEADAS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

echo "📋 CREDENCIALES PARA TESTING:"
echo ""
echo "   digitalizador1 / Indigena123"
echo "   digitalizador2 / Indigena456"
echo "   revisor1       / Revisor123"
echo "   viewer1        / Viewer123"
echo "   admin          / Admin123"
echo ""
echo "   Digitador      / Indigena (ya existente)"
echo ""
