#!/bin/bash
# Valida que los índices SQLite existen y se usan

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
DB_PATH="/data/data/com.lumara.app/databases/lumara_indigenas.db"

echo "🔍 Validando índices SQLite..."
echo ""

# Función para ejecutar query SQLite
sqlite_query() {
  local query=$1
  adb -s $DEVICE shell "run-as com.lumara.app sqlite3 $DB_PATH \"$query\""
}

# Verificar existencia de índices
echo "📋 Índices existentes:"
sqlite_query "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%';" | nl

echo ""

# Verificar uso de índices en queries comunes
echo "🔍 Verificando uso de índices en queries comunes:"
echo ""

echo "1. Query: pending uploads by status"
sqlite_query "EXPLAIN QUERY PLAN SELECT * FROM pending_uploads WHERE status='pending' ORDER BY created_at;"
echo ""

echo "2. Query: upload history by person"
sqlite_query "EXPLAIN QUERY PLAN SELECT * FROM upload_history WHERE person_id='P001' ORDER BY uploaded_at DESC;"
echo ""

echo "3. Query: person search by name"
sqlite_query "EXPLAIN QUERY PLAN SELECT * FROM persons WHERE name LIKE '%Maria%';"
echo ""

echo "4. Query: cache expiration check"
sqlite_query "EXPLAIN QUERY PLAN SELECT MIN(cached_at) FROM tags;"
echo ""

echo "✅ Validación completa"
echo "⚠️  Verificar que cada query usa 'SEARCH ... USING INDEX' (no 'SCAN TABLE')"
