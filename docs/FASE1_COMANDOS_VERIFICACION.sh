#!/bin/bash
# FASE 1: Comandos de Verificación Ejecutados
# Generado: 2025-11-15
# Uso: Reproducir verificación completa

set -e

echo "═══════════════════════════════════════════════════════════"
echo "FASE 1: VERIFICACION E2E - Comandos de Reproducción"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 1. VERIFICACION GIT
echo "1. VERIFICACION GIT"
echo "-------------------"
ls -la .git/ 2>&1 | head -5
git branch --show-current
git status --short
git log -1 --oneline
echo "APKs rastreados por Git: $(git ls-files | grep '\.apk$' | wc -l)"
echo ".gitignore contiene *.apk: $(grep '\.apk' .gitignore > /dev/null && echo 'YES' || echo 'NO')"
echo ""

# 2. VERIFICACION VERSION
echo "2. VERIFICACION VERSION"
echo "-----------------------"
grep "^version:" pubspec.yaml
echo ""
echo "APKs funcionales en Descargas:"
ls -lh ~/Descargas/Lumara_*.apk 2>/dev/null | tail -5
echo ""
echo "APKs en root proyecto: $(find . -maxdepth 1 -name '*.apk' -type f 2>&1 | wc -l)"
echo ""

# 3. TESTING PROTOCOL
echo "3. TESTING PROTOCOL"
echo "-------------------"
test -f scripts/test_apk_before_release.sh && echo "✅ Testing script exists" || echo "❌ NO TESTING SCRIPT"
echo ""

# 4. FLUTTER ANALYZE
echo "4. FLUTTER ANALYZE (últimos 50 issues)"
echo "---------------------------------------"
flutter analyze 2>&1 | tail -50
echo ""

# 5. DOCKER STATUS
echo "5. DOCKER STATUS"
echo "----------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAME|paperless|postgres|redis)"
echo ""

# 6. BACKEND API
echo "6. BACKEND API VERIFICATION"
echo "----------------------------"
echo "Testing /api/ endpoint:"
curl -s -m 5 http://192.168.40.17:8001/api/ 2>&1 | head -20 || echo "⚠️  Timeout or error"
echo ""

echo "Testing /api/census/persons/ (count):"
curl -s -m 5 "http://192.168.40.17:8001/api/census/persons/?limit=1" 2>&1 | \
  python3 -c "import sys, json; data=json.load(sys.stdin); print(f'Total personas: {data.get(\"count\", \"ERROR\")}')" 2>&1 || echo "⚠️  Timeout or error"
echo ""

# 7. DATABASE VERIFICATION
echo "7. DATABASE VERIFICATION"
echo "------------------------"
echo "Verificando censo (requiere acceso a Docker):"
docker exec -it censo-postgres psql -U postgres -d censo_db -c "SELECT COUNT(*) as total_personas FROM persons;" 2>&1 || echo "⚠️  No se pudo conectar a base de datos"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "VERIFICACION COMPLETADA"
echo "═══════════════════════════════════════════════════════════"
