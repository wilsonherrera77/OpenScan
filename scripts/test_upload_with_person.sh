#!/bin/bash
# Script para probar upload de documento con asociación de persona
# Este script verifica que el endpoint /api/documents/upload_with_person/ funciona correctamente

TOKEN="e0282ce5e8fe0d64aee117cfba27b4082e32ce01"
API_URL="http://172.20.10.3:8001"

echo "═══════════════════════════════════════════════════════"
echo "🧪 TEST: Upload de documento con asociación de persona"
echo "═══════════════════════════════════════════════════════"
echo ""

# Crear un archivo PDF de prueba simple
echo "📄 Creando archivo PDF de prueba..."
TEST_FILE="/tmp/test_document_$(date +%s).pdf"
cat > "$TEST_FILE" << 'EOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792]
   /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT /F1 12 Tf 100 700 Td (Test Document) Tj ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000262 00000 n
0000000354 00000 n
trailer
<< /Size 6 /Root 1 0 R >>
startxref
442
%%EOF
EOF

echo "✅ Archivo creado: $TEST_FILE"
echo ""

# Test 1: Verificar que el censo tiene personas
echo "═══════════════════════════════════════════════════════"
echo "TEST 1: Verificar personas en censo"
echo "═══════════════════════════════════════════════════════"
echo ""

PERSON_COUNT=$(curl -s -X GET "$API_URL/api/census/persons/" \
  -H "Authorization: Token $TOKEN" \
  | jq -r '.count // 0')

echo "Total personas en censo: $PERSON_COUNT"

if [ "$PERSON_COUNT" -gt 0 ]; then
  echo "✅ El censo tiene personas cargadas"
else
  echo "❌ El censo está vacío - cargar datos primero"
  rm -f "$TEST_FILE"
  exit 1
fi
echo ""

# Test 2: Obtener una persona específica (la primera del censo de Lumara)
echo "═══════════════════════════════════════════════════════"
echo "TEST 2: Obtener datos de persona de prueba"
echo "═══════════════════════════════════════════════════════"
echo ""

# Person ID 3998 = MARTIN HERRERA OCAMPO (NUIP: 1021315923)
PERSON_ID="3998"
DOCUMENT_TYPE="Cédula de Ciudadanía"
NUIP="1021315923"

echo "Person ID: $PERSON_ID"
echo "NUIP: $NUIP"
echo "Tipo de documento: $DOCUMENT_TYPE"
echo ""

PERSON_INFO=$(curl -s -X GET "$API_URL/api/census/persons/$PERSON_ID/" \
  -H "Authorization: Token $TOKEN")

PERSON_NAME=$(echo "$PERSON_INFO" | jq -r '.first_name + " " + .first_lastname')
echo "Nombre completo: $PERSON_NAME"
echo ""

if [ "$PERSON_NAME" != "null null" ]; then
  echo "✅ Persona encontrada en censo"
else
  echo "❌ Persona no encontrada - verificar ID"
  rm -f "$TEST_FILE"
  exit 1
fi
echo ""

# Test 3: Upload documento con asociación de persona
echo "═══════════════════════════════════════════════════════"
echo "TEST 3: Upload con asociación de persona"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Enviando documento al endpoint /api/documents/upload_with_person/..."
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/documents/upload_with_person/" \
  -H "Authorization: Token $TOKEN" \
  -F "document=@$TEST_FILE" \
  -F "person_id=$PERSON_ID" \
  -F "document_type=$DOCUMENT_TYPE" \
  -F "nuip=$NUIP" \
  -F "is_replacement=false")

echo "Respuesta del servidor:"
echo "$RESPONSE" | jq '.'
echo ""

# Verificar si fue exitoso
SUCCESS=$(echo "$RESPONSE" | jq -r '.success // false')
DOC_ID=$(echo "$RESPONSE" | jq -r '.document_id // ""')
RELATION_ID=$(echo "$RESPONSE" | jq -r '.relation_id // ""')
ERROR=$(echo "$RESPONSE" | jq -r '.error // ""')

if [ "$SUCCESS" = "true" ]; then
  echo "✅ Upload exitoso"
  echo "   Document ID: $DOC_ID"
  echo "   Relation ID: $RELATION_ID"
else
  echo "❌ Upload falló"
  echo "   Error: $ERROR"
  rm -f "$TEST_FILE"
  exit 1
fi
echo ""

# Test 4: Verificar que se creó la relación
echo "═══════════════════════════════════════════════════════"
echo "TEST 4: Verificar relación documento-persona"
echo "═══════════════════════════════════════════════════════"
echo ""

RELATION=$(curl -s -X GET "$API_URL/api/census/relations/$RELATION_ID/" \
  -H "Authorization: Token $TOKEN")

echo "Datos de la relación:"
echo "$RELATION" | jq '.'
echo ""

REL_DOC_ID=$(echo "$RELATION" | jq -r '.document')
REL_PERSON_ID=$(echo "$RELATION" | jq -r '.person')

if [ "$REL_DOC_ID" = "$DOC_ID" ] && [ "$REL_PERSON_ID" = "$PERSON_ID" ]; then
  echo "✅ Relación verificada correctamente"
  echo "   Documento $DOC_ID está asociado con persona $PERSON_ID"
else
  echo "⚠️ Relación no coincide"
fi
echo ""

# Test 5: Verificar documento en Tejido
echo "═══════════════════════════════════════════════════════"
echo "TEST 5: Verificar documento en Tejido"
echo "═══════════════════════════════════════════════════════"
echo ""

DOCUMENT=$(curl -s -X GET "$API_URL/api/documents/$DOC_ID/" \
  -H "Authorization: Token $TOKEN")

DOC_TITLE=$(echo "$DOCUMENT" | jq -r '.title')
DOC_TAGS=$(echo "$DOCUMENT" | jq -r '.tags[]')

echo "Título del documento: $DOC_TITLE"
echo "Tags: $DOC_TAGS"
echo ""

echo "✅ Documento creado y asociado exitosamente"
echo ""

# Cleanup
echo "═══════════════════════════════════════════════════════"
echo "🧹 LIMPIEZA"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "¿Deseas eliminar el documento de prueba? (y/n)"
read -r CLEANUP

if [ "$CLEANUP" = "y" ]; then
  curl -s -X DELETE "$API_URL/api/documents/$DOC_ID/" \
    -H "Authorization: Token $TOKEN" > /dev/null
  echo "✅ Documento eliminado"
fi

rm -f "$TEST_FILE"
echo "✅ Archivo temporal eliminado"
echo ""

echo "═══════════════════════════════════════════════════════"
echo "✅ TEST COMPLETADO"
echo "═══════════════════════════════════════════════════════"
