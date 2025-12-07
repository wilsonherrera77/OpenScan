#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# INSTALADOR AUTOMÁTICO - Lumara v5.6.0
# ═══════════════════════════════════════════════════════════════

set -e  # Exit on error

APK_PATH="/home/smt/Descargas/Lumara_v5.6.0_UPLOAD_WITH_PERSON_FIX_20251012_174106.apk"
EXPECTED_MD5="b12908e86be06d79bf6b4d50416c9da1"
PACKAGE_NAME="com.lumara.app"

echo "════════════════════════════════════════════════════════════════"
echo "INSTALADOR LUMARA v5.6.0 - Fix Sincronización con Tejido"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar que APK existe
# ═══════════════════════════════════════════════════════════════
echo "🔍 Verificando APK..."
if [ ! -f "$APK_PATH" ]; then
    echo "❌ ERROR: No se encuentra el APK en:"
    echo "   $APK_PATH"
    exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo "✅ APK encontrado (${APK_SIZE})"
echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar integridad (MD5)
# ═══════════════════════════════════════════════════════════════
echo "🔐 Verificando integridad del archivo..."
ACTUAL_MD5=$(md5sum "$APK_PATH" | cut -d' ' -f1)

if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
    echo "❌ ERROR: Checksum MD5 no coincide"
    echo "   Esperado: $EXPECTED_MD5"
    echo "   Obtenido: $ACTUAL_MD5"
    echo ""
    echo "   El archivo puede estar corrupto. Recompilar APK."
    exit 1
fi

echo "✅ Checksum MD5 correcto: $ACTUAL_MD5"
echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar dispositivo conectado
# ═══════════════════════════════════════════════════════════════
echo "📱 Verificando conexión con dispositivo Android..."

# Reiniciar servidor ADB (por si acaso)
adb kill-server > /dev/null 2>&1
adb start-server > /dev/null 2>&1

DEVICE_COUNT=$(adb devices | grep -v "List of devices" | grep "device$" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ ERROR: No hay dispositivos Android conectados"
    echo ""
    echo "   Soluciones:"
    echo "   1. Conectar dispositivo con cable USB"
    echo "   2. Habilitar 'Depuración USB' en el dispositivo"
    echo "   3. Autorizar el computador en el dispositivo"
    echo "   4. Ejecutar: adb devices"
    echo ""
    exit 1
fi

DEVICE_ID=$(adb devices | grep "device$" | head -1 | cut -f1)
DEVICE_MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r')

echo "✅ Dispositivo conectado: $DEVICE_MODEL ($DEVICE_ID)"
echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar versión actual instalada
# ═══════════════════════════════════════════════════════════════
echo "🔍 Verificando versión actual de Lumara..."

INSTALLED=$(adb -s "$DEVICE_ID" shell pm list packages | grep "$PACKAGE_NAME" || echo "")

if [ -n "$INSTALLED" ]; then
    CURRENT_VERSION=$(adb -s "$DEVICE_ID" shell dumpsys package "$PACKAGE_NAME" | grep "versionName" | head -1 | sed 's/.*versionName=//' | tr -d '\r')
    echo "📦 Versión actual instalada: $CURRENT_VERSION"
    echo ""

    echo "⚠️  Se desinstalará la versión anterior"
    read -p "   ¿Continuar? (y/n): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Instalación cancelada por el usuario"
        exit 0
    fi

    echo ""
    echo "🗑️  Desinstalando versión anterior..."
    adb -s "$DEVICE_ID" uninstall "$PACKAGE_NAME" > /dev/null 2>&1
    echo "✅ Desinstalación completa"
else
    echo "ℹ️  Lumara no está instalado (instalación limpia)"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# Instalar nueva versión
# ═══════════════════════════════════════════════════════════════
echo "📲 Instalando Lumara v5.6.0..."
echo "   (esto puede tomar 30-60 segundos)"
echo ""

adb -s "$DEVICE_ID" install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Instalación exitosa"
else
    echo ""
    echo "❌ ERROR: Falló la instalación"
    exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar instalación
# ═══════════════════════════════════════════════════════════════
echo "🔍 Verificando instalación..."

INSTALLED_VERSION=$(adb -s "$DEVICE_ID" shell dumpsys package "$PACKAGE_NAME" | grep "versionName" | head -1 | sed 's/.*versionName=//' | tr -d '\r')

if [ "$INSTALLED_VERSION" = "5.6.0" ]; then
    echo "✅ Versión correcta instalada: v$INSTALLED_VERSION"
else
    echo "⚠️  Versión instalada: v$INSTALLED_VERSION (esperaba 5.6.0)"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar backend
# ═══════════════════════════════════════════════════════════════
echo "🌐 Verificando conectividad con backend Tejido..."

BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://192.168.40.17:8001/api/" -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" --max-time 5)

if [ "$BACKEND_STATUS" = "200" ]; then
    echo "✅ Backend Tejido accesible (HTTP 200)"
else
    echo "⚠️  Backend Tejido: HTTP $BACKEND_STATUS"
    echo "   Verificar que Docker esté corriendo: docker ps"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# Verificar endpoint especializado
# ═══════════════════════════════════════════════════════════════
echo "🔍 Verificando endpoint /upload_with_person/..."

ENDPOINT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "http://192.168.40.17:8001/api/documents/upload_with_person/" -H "Authorization: Token e0282ce5e8fe0d64aee117cfba27b4082e32ce01" --max-time 5)

if [ "$ENDPOINT_STATUS" = "200" ] || [ "$ENDPOINT_STATUS" = "405" ]; then
    echo "✅ Endpoint correcto disponible (HTTP $ENDPOINT_STATUS)"
else
    echo "❌ Endpoint NO disponible (HTTP $ENDPOINT_STATUS)"
    echo "   Verificar que el backend tenga el fix del 2025-10-12"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "INSTALACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo ""
echo "1. Abrir Lumara en el dispositivo"
echo "2. Verificar que muestre 'v5.6.0' en la pantalla de inicio"
echo "3. Confirmar que cargó 3998 personas del censo"
echo "4. Capturar UN documento de prueba"
echo "5. Verificar sincronización con backend:"
echo ""
echo "   bash /tmp/diagnose_sync.sh"
echo ""
echo "6. Confirmar en Tejido (http://192.168.40.17:8001) que:"
echo "   - El documento aparece"
echo "   - Tiene relación con persona del censo"
echo "   - Tiene etiqueta del tipo de documento"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📖 Ver instrucciones completas en:"
echo "   INSTALL_v5.6.0.md"
echo ""
