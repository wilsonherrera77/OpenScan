#!/bin/bash
# MONITOR DE SINCRONIZACIÓN DOBLE VÍA (Lumara ↔ Tejido)
# Captura logs en tiempo real durante la sincronización

echo "═══════════════════════════════════════════════════════"
echo "🔍 MONITOR DOBLE VÍA: Lumara ↔ Tejido"
echo "═══════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check device connected
echo "1️⃣ Verificando dispositivo Android..."
DEVICE=$(adb devices | grep -w "device" | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo -e "${RED}❌ No hay dispositivo Android conectado${NC}"
    echo "Por favor conecta el dispositivo vía USB y habilita USB debugging"
    exit 1
fi
echo -e "${GREEN}✅ Dispositivo conectado: $DEVICE${NC}"
echo ""

# Check backend
echo "2️⃣ Verificando backend (Tejido)..."
BACKEND_STATUS=$(curl -o /dev/null -s -w "%{http_code}" http://192.168.40.17:8001/api/ 2>/dev/null)
if [ "$BACKEND_STATUS" == "302" ] || [ "$BACKEND_STATUS" == "200" ]; then
    echo -e "${GREEN}✅ Backend responde: HTTP $BACKEND_STATUS${NC}"
else
    echo -e "${RED}❌ Backend no responde correctamente: HTTP $BACKEND_STATUS${NC}"
fi
echo ""

# Check installed app version
echo "3️⃣ Verificando versión instalada de Lumara..."
APP_VERSION=$(adb shell dumpsys package com.ethereal.openscan | grep versionName | head -1 | awk '{print $1}')
echo "   Versión: $APP_VERSION"
echo ""

echo "═══════════════════════════════════════════════════════"
echo "🚀 INICIANDO MONITOREO EN TIEMPO REAL"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Ahora en la app Lumara:"
echo "  1. Ir a Home screen"
echo "  2. Tap en 'Sincronizar ahora'"
echo "  3. Observar los logs a continuación"
echo ""
echo "Presiona Ctrl+C para detener el monitoreo"
echo ""
echo "--- LOGS FLUTTER (Lumara) -----------------------------------"
echo ""

# Monitor logs in real-time
# Filter for relevant logs: sync, upload, document, dio, paperless
adb logcat -c  # Clear logcat
adb logcat | grep -E "(flutter|Lumara|openscan|BackgroundSyncService|PaperlessApiClient|DocumentRepository|DIO|HTTP)" --line-buffered | while IFS= read -r line; do
    # Highlight errors in red
    if echo "$line" | grep -qi "error\|exception\|failed\|timeout"; then
        echo -e "${RED}$line${NC}"
    # Highlight success in green
    elif echo "$line" | grep -qi "success\|completed\|uploaded\|✅"; then
        echo -e "${GREEN}$line${NC}"
    # Highlight warnings in yellow
    elif echo "$line" | grep -qi "warning\|⚠️"; then
        echo -e "${YELLOW}$line${NC}"
    else
        echo "$line"
    fi
done
